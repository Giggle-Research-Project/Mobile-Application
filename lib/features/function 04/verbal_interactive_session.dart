import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:giggle/core/constants/api_endpoints.dart';
import 'package:giggle/features/lessons/question_generate.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:chat_bubbles/chat_bubbles.dart';

import 'package:giggle/core/models/teacher_model.dart';
import 'package:giggle/core/providers/theme_provider.dart';
import 'package:giggle/core/widgets/sub_page_header.widget.dart';
import 'service/verbal_question_generator.dart';

class VerbalInteractiveSessionScreen extends ConsumerStatefulWidget {
  final Map<String, String>? difficultyLevels;
  final String dyscalculiaType;
  final String courseName;
  final List<Map<String, dynamic>> questions;
  final String userId;

  const VerbalInteractiveSessionScreen({
    Key? key,
    this.difficultyLevels,
    required this.dyscalculiaType,
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
  bool _isInitialized = false;
  String _recordedFilePath = '';
  String _transcribedText = '';
  bool _isProcessing = false;
  int _timeElapsed = 0;
  Timer? _timer;
  bool _isStoppingRecording = false;
  final bool _showCongratulations = false;
  String _recordingStatus = '';

  late Future<List<VerbalQuestion>> _questionsFuture;
  List<VerbalQuestion>? _questions;
  int _currentQuestionIndex = 0;
  int _currentGuidanceIndex = 0;
  bool _isSessionComplete = false;

  final List<String> _guidanceMessages = [
    "Hello! Let's practice solving this problem together.",
    "Listen to the question carefully by pressing the 'Listen' button.",
    "When you're ready to answer, press and hold the microphone button.",
    "Speak clearly and release the button when you're done.",
  ];

  @override
  void initState() {
    super.initState();
    _questionsFuture = generateVerbalQuestions(widget.userId, widget.courseName);
    _initializeQuestions();
    _startTimer();
    _initTts();
  }

  Future<void> _initializeQuestions() async {
    _questions = await _questionsFuture;
    if (mounted) {
      setState(() {});
    }
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
      setState(() {
        _isSpeaking = false;
        _updateGuidance();
      });
    });

    _flutterTts.setErrorHandler((error) {
      setState(() => _isSpeaking = false);
      _showSnackBar('TTS Error: $error', true);
    });
  }

  void _updateGuidance() {
    if (_currentGuidanceIndex < _guidanceMessages.length - 1) {
      setState(() {
        _currentGuidanceIndex++;
      });
    }
  }

  Future<String> sendAudioToML(File audioFile,
      Function(String message, bool isError) showSnackBar) async {
    final url = Uri.parse(ApiEndpoints.transcribe);

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
      // Use the question from _questions list instead of widget.questions
      final question = _questions![_currentQuestionIndex].question;
      await _flutterTts.speak(question);
    }
  }

  Future<void> _startRecording() async {
    if (_isStoppingRecording || _isRecording) return;

    try {
      if (!_isInitialized) {
        _isInitialized = true;
      }

      if (await _recorder.hasPermission()) {
        setState(() => _recordingStatus = 'Initializing...');

        final directory = await getTemporaryDirectory();
        _recordedFilePath = '${directory.path}/answer_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordedFilePath,
        );

        setState(() {
          _isRecording = true;
          _recordingStatus = 'Recording...';
        });
      } else {
        _showSnackBar('Please grant microphone permission in your device settings', true);
      }
    } catch (e) {
      _showSnackBar('Recording error: $e', true);
      setState(() {
        _isRecording = false;
        _recordingStatus = 'Error';
      });
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
    String correctAnswer = _questions![_currentQuestionIndex].correctAnswer.toLowerCase();

    if (_transcribedText.toLowerCase().contains(correctAnswer)) {
      if (_currentQuestionIndex < _questions!.length - 1) {
        // Move to next question
        _showResultDialog(true, false);
      } else {
        // Session complete
        _showResultDialog(true, true);
      }
    } else {
      _showResultDialog(false, false);
    }
  }

  void _showResultDialog(bool isCorrect, bool isSessionComplete) {
    if (isCorrect) {
      _saveProgress(isSessionComplete);
    }

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
                    ? isSessionComplete
                        ? 'Congratulations! You\'ve completed all questions!'
                        : 'You answered correctly! Ready for the next question?'
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
                onPressed: () {
                  Navigator.of(context).pop();
                  if (isSessionComplete) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      _currentQuestionIndex++;
                      _transcribedText = '';
                      _currentGuidanceIndex = 0;
                    });
                  }
                },
                child: Text(
                  isSessionComplete ? 'Complete' : 'Next Question',
                  style: const TextStyle(fontSize: 16),
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

  Future<void> _saveProgress(bool isSessionComplete) async {
    try {
      await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(widget.userId)
          .collection(widget.courseName)
          .doc(widget.dyscalculiaType)
          .collection('interactive_session')
          .doc('progress')
          .set({
        'completed': isSessionComplete,
        'currentQuestion': _currentQuestionIndex + 1,
        'totalQuestions': _questions!.length,
        'timeElapsed': _timeElapsed,
      }, SetOptions(merge: true));
    } catch (e) {
      _showSnackBar('Error saving progress: $e', true);
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getDifficultyColor() {
    final difficulty = _questions![_currentQuestionIndex].difficulty.toLowerCase();
    
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyLabel() {
    final currentQuestion = _questions![_currentQuestionIndex];
    return currentQuestion.difficulty.substring(0, 1).toUpperCase() + 
           currentQuestion.difficulty.substring(1).toLowerCase();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flutterTts.stop();
    if (_isInitialized) {
      _recorder.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider).valueOrNull ??
        const AppTheme(primaryColor: Color(0xFF4F46E5));
    final themeColor = themeData.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<VerbalQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No questions available'));
          }

          // Use the existing UI code here, but make sure _questions is initialized
          return Stack(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Changed from end to spaceBetween
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getDifficultyColor().withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.track_changes,
                                  size: 14,
                                  color: _getDifficultyColor(),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getDifficultyLabel(),
                                  style: TextStyle(
                                    color: _getDifficultyColor(),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(_timeElapsed),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              // Question Card
                              _buildQuestionCard(themeColor),
                              const SizedBox(height: 16),
                              // Chat Bubble
                              Column(
                                children: [
                                  for (int i = 0; i <= _currentGuidanceIndex; i++)
                                    BubbleNormal(
                                      text: _guidanceMessages[i],
                                      isSender: false,
                                      color: Colors.blue.shade100,
                                      tail: true,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  if (_transcribedText.isNotEmpty)
                                    BubbleNormal(
                                      text: _transcribedText,
                                      isSender: true,
                                      color: Colors.green.shade100,
                                      tail: true,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Recording Status
                              if (_recordingStatus.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isRecording
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isRecording ? Icons.mic : Icons.mic_off,
                                        color: _isRecording ? Colors.red : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _recordingStatus,
                                        style: TextStyle(
                                          color: _isRecording ? Colors.red : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Control Buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: _buildControlButtons(themeColor),
                    ),
                  ],
                ),
              ),
              if (_showCongratulations) _buildCongratulationsOverlay(themeColor),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(Color themeColor) {
    final currentQuestion = _questions![_currentQuestionIndex];

    return Container(
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
            'Question ${_currentQuestionIndex + 1} of ${_questions!.length}',
            style: TextStyle(
              fontSize: 16,
              color: themeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currentQuestion.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
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
