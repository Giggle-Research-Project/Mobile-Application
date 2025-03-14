import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:giggle/features/lessons/question_generate.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:giggle/core/constants/teachers_list_constants.dart';
import 'package:giggle/core/models/teacher_model.dart';
import 'package:giggle/core/providers/theme_provider.dart';
import 'package:giggle/core/widgets/sub_page_header.widget.dart';

class VerbalInteractiveSessionScreen extends ConsumerStatefulWidget {
  final Map<String, String>? difficultyLevels;
  final String dyscalculiaType;
  final String selectedTeacher;
  final String courseName;
  final List<Map<String, dynamic>> questions;
  final String userId;

  const VerbalInteractiveSessionScreen({
    Key? key,
    this.difficultyLevels,
    required this.dyscalculiaType,
    required this.selectedTeacher,
    required this.courseName,
    required this.questions,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<VerbalInteractiveSessionScreen> createState() =>
      _VerbalInteractiveSessionScreenState();
}

class _VerbalInteractiveSessionScreenState
    extends ConsumerState<VerbalInteractiveSessionScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final _recorder = AudioRecorder();
  late TeacherCharacter selectedTeacher;

  bool _isSpeaking = false;
  bool _isRecording = false;
  String _recordedFilePath = '';
  String _transcribedText = '';
  bool _isProcessing = false;
  int _timeElapsed = 0;
  Timer? _timer;
  bool _isStoppingRecording = false;
  final bool _showCongratulations = false;

  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initTts();
    selectedTeacher = teachers.firstWhere(
      (teacher) => teacher.name == widget.selectedTeacher,
      orElse: () => teachers[0],
    );
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    final voices = await _flutterTts.getVoices;
    if (voices != null && voices is List) {
      final preferredVoice = voices.firstWhere(
        (voice) => (voice as Map)['name'].toString().contains('en-US'),
        orElse: () => voices.first,
      );
      if (preferredVoice != null) {
        await _flutterTts.setVoice({
          'name': (preferredVoice as Map)['name'],
          'locale': (preferredVoice)['locale'],
        });
      }
    }

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((error) {
      setState(() => _isSpeaking = false);
      _showSnackBar('TTS Error: $error', true);
    });
  }

  Future<String> sendAudioToML(File audioFile,
      Function(String message, bool isError) showSnackBar) async {
    final String mlIP = dotenv.env['MLIP'] ?? '127.0.0.1';
    final url = Uri.parse('http://$mlIP:8000/transcribe');

    if (!audioFile.existsSync()) {
      return 'Error: Audio file does not exist';
    }

    final fileSize = await audioFile.length();
    if (fileSize == 0) {
      return 'Error: Audio file is empty';
    }

    var request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Content-Type': 'multipart/form-data',
        'accept': 'application/json',
      })
      ..files.add(await http.MultipartFile.fromPath(
        'audio_file',
        audioFile.path,
        contentType: MediaType('audio', 'wav'),
      ));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decoded = json.decode(responseBody);
        return decoded['Transcription'] ??
            decoded['transcription'] ??
            'Error: No transcription found';
      } else {
        return 'Error: Failed to get transcription';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeElapsed++;
      });
    });
  }

  Future<void> _speakQuestion() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      // Use the question from widget.questions instead of static list
      final question = widget.questions[_currentQuestionIndex]['question'];
      await _flutterTts.speak(question);
    }
  }

  Future<void> _startRecording() async {
    if (_isStoppingRecording || _isRecording) return;

    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _recordedFilePath = '${directory.path}/answer.wav';
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav),
            path: _recordedFilePath);
        setState(() => _isRecording = true);
      } else {
        _showSnackBar('Microphone permission not granted', true);
      }
    } catch (e) {
      _showSnackBar('Failed to start recording: $e', true);
      setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _isStoppingRecording) return;

    try {
      setState(() => _isStoppingRecording = true);
      await _recorder.stop();
      setState(() => _isRecording = false);
      await _processRecording();
    } catch (e) {
      _showSnackBar('Failed to stop recording: $e', true);
    } finally {
      setState(() => _isStoppingRecording = false);
    }
  }

  Future<void> _processRecording() async {
    setState(() => _isProcessing = true);
    try {
      final audioFile = File(_recordedFilePath);
      final transcription = await sendAudioToML(audioFile, _showSnackBar);
      setState(() => _transcribedText = transcription.toLowerCase());
      _checkAnswer();
    } catch (e) {
      _showSnackBar('Error processing recording: $e', true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, bool isError) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  void _checkAnswer() {
    final currentQuestion = widget.questions[_currentQuestionIndex];
    // Compare with the correct answer from the question props
    String correctAnswer =
        currentQuestion['correctAnswer'].toString().toLowerCase();

    if (_transcribedText.toLowerCase().contains(correctAnswer)) {
      _showResultDialog(true);
    } else {
      _showResultDialog(false);
    }
  }

  void _showResultDialog(bool isCorrect) {
    List<Map<String, dynamic>> newQuestions = generatePersonalizedQuestions(
        widget.courseName, widget.difficultyLevels);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isCorrect ? 'Great job!' : 'Try Again',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.error,
                color: isCorrect ? Colors.green : Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                isCorrect
                    ? 'You answered correctly!'
                    : 'Your answer was incorrect. Please try again.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            if (isCorrect)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                onPressed: () async {
                  if (isCorrect) {
                    await FirebaseFirestore.instance
                        .collection('functionActivities')
                        .doc(widget.userId)
                        .collection(widget.courseName)
                        .doc(widget.dyscalculiaType)
                        .collection('interactive_session')
                        .doc('progress')
                        .set({
                      'completed': true,
                      'timeElapsed': _timeElapsed,
                    }, SetOptions(merge: true));

                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Complete',
                  style: TextStyle(fontSize: 16),
                ),
              )
            else
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _transcribedText = '');
                },
                child: const Text('Try Again', style: TextStyle(fontSize: 16)),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flutterTts.stop();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider).valueOrNull ??
        const AppTheme(primaryColor: Color(0xFF4F46E5));
    final themeColor = themeData.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColor.withOpacity(0.1),
                  Colors.green.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SubPageHeader(
                  title: 'Verbal Exercise',
                  desc: '${widget.courseName} - ${widget.dyscalculiaType}',
                ),
                const SizedBox(height: 20),
                _buildTeacherAndTimer(),
                const SizedBox(height: 30),
                _buildQuestionCard(themeColor),
                const Spacer(),
                _buildControlButtons(themeColor),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_showCongratulations) _buildCongratulationsOverlay(themeColor),
        ],
      ),
    );
  }

  Widget _buildTeacherAndTimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(selectedTeacher.avatar),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedTeacher.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Color themeColor) {
    // Use the question from props
    final currentQuestion = widget.questions[_currentQuestionIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            currentQuestion['question'],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_transcribedText.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Your answer: $_transcribedText',
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: _speakQuestion,
            icon: Icon(_isSpeaking ? Icons.pause : Icons.play_arrow),
            label: Text(_isSpeaking ? 'Stop' : 'Listen'),
          ),
          GestureDetector(
            onTapDown: (_) {
              if (!_isStoppingRecording && !_isProcessing) {
                _startRecording();
              }
            },
            onTapUp: (_) {
              if (_isRecording && !_isStoppingRecording) {
                _stopRecording();
              }
            },
            onTapCancel: () {
              if (_isRecording && !_isStoppingRecording) {
                _stopRecording();
              }
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : themeColor,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : themeColor)
                        .withOpacity(0.3),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCongratulationsOverlay(Color themeColor) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, color: themeColor, size: 60),
              const SizedBox(height: 20),
              const Text(
                'Great job!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'You answered the question correctly!',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
