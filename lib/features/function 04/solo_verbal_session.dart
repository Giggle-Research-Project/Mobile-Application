import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:giggle/core/constants/api_endpoints.dart';
import 'package:giggle/core/models/user_model.dart';
import 'package:giggle/core/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:giggle/core/providers/theme_provider.dart';
import 'package:giggle/core/widgets/sub_page_header.widget.dart';

class SoloVerbalSessionScreen extends ConsumerStatefulWidget {
  final String dyscalculiaType;
  final String courseName;
  final List<Map<String, dynamic>> questions;
  final String index;
  final String userId;

  const SoloVerbalSessionScreen({
    required this.dyscalculiaType,
    required this.courseName,
    required this.questions,
    required this.index,
    required this.userId,
    Key? key, required Null Function(bool isCorrect, double timeElapsed) onQuestionCompleted,
  }) : super(key: key);

  @override
  ConsumerState<SoloVerbalSessionScreen> createState() =>
      _SoloVerbalSessionScreenState();
}

class _SoloVerbalSessionScreenState
    extends ConsumerState<SoloVerbalSessionScreen> {
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

// In SoloVerbalSessionScreen.dart
  Future<void> _processRecording() async {
    setState(() => _isProcessing = true);
    try {
      final audioFile = File(_recordedFilePath);
      final transcription = await sendAudioToML(audioFile, _showSnackBar);
      print('Transcription: $transcription');

      setState(() => _transcribedText = transcription.toLowerCase());
      
      // Add delay before showing the result dialog
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _checkAnswer();
      }
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
    String correctAnswer = currentQuestion['correctAnswer'].toString().toLowerCase();
    String userAnswer = _transcribedText.toLowerCase();

    // Handle different operation types
    switch (widget.courseName.toUpperCase()) {
      case 'ADDITION':
        // Check for variations of addition answers
        if (userAnswer.contains(correctAnswer) ||
            userAnswer.replaceAll(RegExp(r'[^0-9]'), '') == correctAnswer) {
          _showResultDialog(true);
        } else {
          _showResultDialog(false);
        }
        break;
      case 'SUBTRACTION':
        // Check for variations of subtraction answers
        if (userAnswer.contains(correctAnswer) ||
            userAnswer.replaceAll(RegExp(r'[^0-9-]'), '') == correctAnswer) {
          _showResultDialog(true);
        } else {
          _showResultDialog(false);
        }
        break;
      case 'MULTIPLICATION':
        // Check for variations of multiplication answers
        if (userAnswer.contains(correctAnswer) ||
            userAnswer.replaceAll(RegExp(r'[^0-9]'), '') == correctAnswer) {
          _showResultDialog(true);
        } else {
          _showResultDialog(false);
        }
        break;
      case 'DIVISION':
        // Check for variations of division answers
        if (userAnswer.contains(correctAnswer) ||
            userAnswer.replaceAll(RegExp(r'[^0-9.]'), '') == correctAnswer) {
          _showResultDialog(true);
        } else {
          _showResultDialog(false);
        }
        break;
      default:
        // Default case - strict equality check
        if (userAnswer.contains(correctAnswer)) {
          _showResultDialog(true);
        } else {
          _showResultDialog(false);
        }
    }
  }

  void _showResultDialog(bool isCorrect) {
    String getQuestionKey(String index) {
      // Parse out the challenge number and question number
      final parts = index.split('-');
      if (parts.length == 2) {
        // For challenge-specific questions (e.g., "1-0")
        switch (parts[0]) {
          case '1':
            return 'questionOne';
          case '2':
            return 'questionTwo';
          case '3':
            return 'questionThree';
          default:
            return 'questionOne';
        }
      } else {
        // For legacy format
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
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          content: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Result Icon with Animation
                AnimatedScale(
                  duration: const Duration(milliseconds: 500),
                  scale: 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    ),
                    child: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 64,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Result Text
                Text(
                  isCorrect ? 'Excellent!' : 'Keep Trying!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Time Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Time: $_timeElapsed seconds',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Answer Details
                if (!isCorrect) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Answer:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _transcribedText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Correct Answer:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.questions[_currentQuestionIndex]['correctAnswer'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Complete Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCorrect ? Colors.green : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    final parts = widget.index.split('-');
                    final challengeNumber = parts[0];
                    final questionNumber = parts[1];
                    final questionKey = getQuestionKey(widget.index);
                    
                    // Get reference to the base path
                    final baseRef = FirebaseFirestore.instance
                        .collection('functionActivities')
                        .doc(widget.userId)
                        .collection(widget.courseName)
                        .doc('Verbal Dyscalculia')
                        .collection('solo_sessions')
                        .doc('progress');

                    try {
                      // Save individual question progress
                      await baseRef
                          .collection(questionKey)
                          .doc('status')
                          .collection('questionDetails')
                          .doc('question-$questionNumber')
                          .set({
                            'completed': true,
                            'isCorrect': isCorrect,
                            'timestamp': FieldValue.serverTimestamp(),
                            'timeElapsed': _timeElapsed,
                            'transcribedAnswer': _transcribedText,
                          }, SetOptions(merge: true));

                      // If this is question 9 (the last question), mark the challenge as completed
                      if (int.parse(questionNumber) == 9) {
                        await baseRef
                            .collection(questionKey)
                            .doc('status')
                            .set({
                              'completed': true,
                              'completedAt': FieldValue.serverTimestamp(),
                              'challengeNumber': challengeNumber,
                            }, SetOptions(merge: true));
            
                        // Check if all challenges are completed
                        final challengeOneStatus = await baseRef.collection('questionOne').doc('status').get();
                        final challengeTwoStatus = await baseRef.collection('questionTwo').doc('status').get();
                        final challengeThreeStatus = await baseRef.collection('questionThree').doc('status').get();
                        
                        if (challengeOneStatus.data()?['completed'] == true &&
                            challengeTwoStatus.data()?['completed'] == true &&
                            challengeThreeStatus.data()?['completed'] == true) {
                          // All challenges are completed, update the progress document
                          await baseRef.set({
                            'completed': true,
                            'timeElapsed': _timeElapsed,
                          }, SetOptions(merge: true));
                        }
                      }

                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Return to previous screen
                    } catch (error) {
                      print('Error saving progress: $error');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to save progress')),
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                    _buildControlButtons(themeColor),
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

  // Add helper method to format verbal questions based on operation
String _formatVerbalQuestion(String operation, String question) {
  switch (operation.toUpperCase()) {
    case 'ADDITION':
      return question.replaceAll('+', 'plus');
    case 'SUBTRACTION':
      return question.replaceAll('-', 'minus');
    case 'MULTIPLICATION':
      return question.replaceAll('×', 'times');
    case 'DIVISION':
      return question.replaceAll('÷', 'divided by');
    default:
      return question;
  }
}

  Widget _buildQuestionCard(Color themeColor) {
    final currentQuestion = widget.questions[_currentQuestionIndex];
    final formattedQuestion = _formatVerbalQuestion(
      widget.courseName,
      currentQuestion['question'],
    );

    return Column(
      children: [
        Container(
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
          child: Text(
            formattedQuestion,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        if (_transcribedText.isNotEmpty) ...[
          const SizedBox(height: 20),
          AnimatedOpacity(
            opacity: _transcribedText.isEmpty ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.record_voice_over, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Your Answer:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _transcribedText.isEmpty ? 'Your answer will appear here...' : _transcribedText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: _transcribedText.isEmpty ? Colors.grey : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControlButtons(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Recording status indicator
          if (_isRecording || _isProcessing)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.grey[100],
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
                    _isProcessing ? 'Processing...' : 'Recording...',
                    style: TextStyle(
                      color: _isRecording ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Row(
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
