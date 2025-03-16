import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:giggle/core/models/user_model.dart';
import 'package:giggle/core/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:giggle/core/providers/theme_provider.dart';
import 'package:giggle/core/widgets/sub_page_header.widget.dart';

class VerbalFutureScreen extends ConsumerStatefulWidget {
  final String dyscalculiaType;
  final String courseName;
  final List<Map<String, dynamic>> questions;
  final String index;

  const VerbalFutureScreen({
    required this.dyscalculiaType,
    required this.courseName,
    required this.questions,
    required this.index,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<VerbalFutureScreen> createState() => _VerbalFutureScreenState();
}

class _VerbalFutureScreenState extends ConsumerState<VerbalFutureScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final _recorder = AudioRecorder();

  bool _isSpeaking = false;
  bool _isRecording = false;
  String _recordedFilePath = '';
  String _transcribedText = '';
  bool _isProcessing = false;
  Timer? _timer;
  bool _isStoppingRecording = false;
  final bool _showCongratulations = false;

  int _timeElapsed = 0;

  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initTts();
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

  Future<void> _stopRecording(String userId) async {
    if (!_isRecording || _isStoppingRecording) return;

    try {
      setState(() => _isStoppingRecording = true);
      await _recorder.stop();
      setState(() => _isRecording = false);
      await _processRecording(userId);
    } catch (e) {
      _showSnackBar('Failed to stop recording: $e', true);
    } finally {
      setState(() => _isStoppingRecording = false);
    }
  }

  Future<void> _processRecording(String userId) async {
    setState(() => _isProcessing = true);
    try {
      final audioFile = File(_recordedFilePath);
      final transcription = await sendAudioToML(audioFile, _showSnackBar);
      setState(() => _transcribedText = transcription.toLowerCase());
      _checkAnswer(userId);
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

  void _checkAnswer(String userId) {
    final currentQuestion = widget.questions[_currentQuestionIndex];
    String correctAnswer =
        currentQuestion['correctAnswer'].toString().toLowerCase();

    if (_transcribedText.toLowerCase().contains(correctAnswer)) {
      _showResultDialog(true, userId);
    } else {
      _showResultDialog(false, userId);
    }
  }

  void _showResultDialog(bool isCorrect, String userId) {
    String getQuestionKey(String index) {
      switch (index) {
        case '0':
          return 'questionOne';
        case '1':
          return 'questionTwo';
        case '2':
          return 'questionThree';
        default:
          return index;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Time Elapsed: $_timeElapsed seconds',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              onPressed: () async {
                if (isCorrect) {
                  // Save progress to Firestore
                  await FirebaseFirestore.instance
                      .collection('futureActivities')
                      .doc(userId)
                      .collection(widget.courseName)
                      .doc('Verbal Dyscalculia')
                      .collection('solo_sessions')
                      .doc('progress')
                      .collection(getQuestionKey(widget.index))
                      .doc('status')
                      .set({
                    'completed': true,
                    'isCorrect': true,
                    'timeTaken': _timeElapsed,
                  }, SetOptions(merge: true));

                  if (widget.index == '2') {
                    FirebaseFirestore.instance
                        .collection('futureActivities')
                        .doc(userId)
                        .collection(widget.courseName)
                        .doc('Verbal Dyscalculia')
                        .collection('solo_sessions')
                        .doc('progress')
                        .set({
                          'completed': true,
                          'isCorrect': true,
                          'timeTaken': _timeElapsed,
                        }, SetOptions(merge: true))
                        .then((_) => print('Progress saved to Firestore'))
                        .catchError((error) =>
                            print('Failed to save progress: $error'));
                  }
                } else {
                  await FirebaseFirestore.instance
                      .collection('futureActivities')
                      .doc(userId)
                      .collection(widget.courseName)
                      .doc('Verbal Dyscalculia')
                      .collection('solo_sessions')
                      .doc('progress')
                      .collection(getQuestionKey(widget.index))
                      .doc('status')
                      .set({
                    'completed': true,
                    'isCorrect': false,
                    'timeTaken': _timeElapsed,
                  }, SetOptions(merge: true));

                  if (widget.index == '2') {
                    FirebaseFirestore.instance
                        .collection('futureActivities')
                        .doc(userId)
                        .collection(widget.courseName)
                        .doc('Verbal Dyscalculia')
                        .collection('solo_sessions')
                        .doc('progress')
                        .set({
                          'completed': true,
                          'isCorrect': false,
                          'timeTaken': _timeElapsed,
                        }, SetOptions(merge: true))
                        .then((_) => print('Progress saved to Firestore'))
                        .catchError((error) =>
                            print('Failed to save progress: $error'));
                  }
                }
                if (isCorrect) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Complete',
                style: TextStyle(fontSize: 16),
              ),
            )
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

  Widget _buildProgressIndicator() {
    final totalQuestions = widget.questions.length;
    final currentQuestion = _currentQuestionIndex + 1;

    final minutes = _timeElapsed ~/ 60;
    final seconds = _timeElapsed % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $currentQuestion of $totalQuestions',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Time: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _timeElapsed > 180
                      ? Colors.red
                      : Colors.black, // Highlight if over 3 minutes
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: currentQuestion / totalQuestions,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider).valueOrNull ??
        const AppTheme(primaryColor: Color(0xFF4F46E5));
    final themeColor = themeData.primaryColor;
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (AppUser? user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }
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
                    const SizedBox(height: 30),
                    _buildProgressIndicator(),
                    const SizedBox(height: 20),
                    _buildQuestionCard(themeColor),
                    const Spacer(),
                    _buildControlButtons(themeColor, user.uid),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (_showCongratulations)
                _buildCongratulationsOverlay(themeColor),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('Error: ${error.toString()}')),
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

  Widget _buildControlButtons(Color themeColor, String userId) {
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
                _stopRecording(userId);
              }
            },
            onTapCancel: () {
              if (_isRecording && !_isStoppingRecording) {
                _stopRecording(userId);
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
