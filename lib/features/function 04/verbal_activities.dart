import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ActivitiesScreen extends StatefulWidget {
  final String level;
  final String description;
  final List<Map<String, dynamic>> questions;
  final int timeLimit;
  final Color color;

  const ActivitiesScreen({
    Key? key,
    required this.level,
    required this.description,
    required this.questions,
    required this.timeLimit,
    required this.color,
  }) : super(key: key);

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  late FlutterTts _tts;
  late stt.SpeechToText _speech;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showHint = false;
  bool _isListening = false;
  String _lastWords = '';
  int _timeRemaining = 0;
  Timer? _timer;
  List<Map<String, dynamic>> _shuffledQuestions = [];
  List<String> _userAnswers = [];
  bool _showVisualAids = true;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _initializeSpeech();
    _shuffledQuestions = List.from(widget.questions)..shuffle();
    _timeRemaining = widget.timeLimit;
    _userAnswers = List.filled(widget.questions.length, '');
    _startTimer();
  }

  Future<void> _initializeTTS() async {
    _tts = FlutterTts();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.8);
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    await _speech.initialize();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _timer?.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _lastWords = result.recognizedWords;
              // Try to extract number from speech
              String? number = _extractNumberFromSpeech(_lastWords);
              if (number != null) {
                _checkAnswer(number);
              }
            });
          },
          listenFor: const Duration(seconds: 5),
          cancelOnError: true,
          partialResults: false,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  String? _extractNumberFromSpeech(String speech) {
    // Map of number words to digits
    final numberWords = {
      'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
      'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
      'ten': '10', 'eleven': '11', 'twelve': '12', 'thirteen': '13',
      'fourteen': '14', 'fifteen': '15', 'sixteen': '16', 'seventeen': '17',
      'eighteen': '18', 'nineteen': '19', 'twenty': '20',
      // Add more number mappings as needed
    };

    // First try to find direct number in speech
    RegExp numRegex = RegExp(r'\d+');
    var match = numRegex.firstMatch(speech.toLowerCase());
    if (match != null) {
      return match.group(0);
    }

    // Then try to find number words
    for (var entry in numberWords.entries) {
      if (speech.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  void _speakText(String text) async {
    await _tts.speak(text);
  }

  void _checkAnswer(String selected) {
    final isCorrect =
        selected == _shuffledQuestions[_currentQuestionIndex]['correct'];

    if (isCorrect) {
      setState(() => _score++);
    }

    _userAnswers[_currentQuestionIndex] = selected;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect ? 'Correct! Well done!' : 'Try again!',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );

    if (_currentQuestionIndex < _shuffledQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showHint = false;
      });
    } else {
      _showResultDialog();
    }
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up!'),
        content:
            const Text('Would you like to review your answers or try again?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showResultDialog();
            },
            child: const Text('Review Answers'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _timeRemaining = widget.timeLimit;
                _currentQuestionIndex = 0;
                _userAnswers = List.filled(widget.questions.length, '');
                _startTimer();
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Activity Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $_score/${_shuffledQuestions.length}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Accuracy: ${(_score / _shuffledQuestions.length * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Finish'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentQuestionIndex = 0;
                _score = 0;
                _shuffledQuestions.shuffle();
                _timeRemaining = widget.timeLimit;
                _userAnswers = List.filled(widget.questions.length, '');
                _startTimer();
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _shuffledQuestions[_currentQuestionIndex];

    return Hero(
      tag: 'difficulty_${widget.level}',
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: widget.color,
          title: Text(
            '${widget.level} Level',
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _showVisualAids ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() => _showVisualAids = !_showVisualAids);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            '${_timeRemaining ~/ 60}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () =>
                          _speakText(currentQuestion['numberWord']),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _shuffledQuestions.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'What number is "${currentQuestion['numberWord']}"?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_showVisualAids) ...[
                      const SizedBox(height: 16),
                      Text(
                        '●' * (int.tryParse(currentQuestion['correct']) ?? 1),
                        style: const TextStyle(
                          color: Colors.blue,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: List.generate(
                    currentQuestion['options'].length,
                    (index) {
                      final option = currentQuestion['options'][index];
                      final isSelected =
                          _userAnswers[_currentQuestionIndex] == option;

                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelected ? widget.color : Colors.white,
                          foregroundColor:
                              isSelected ? Colors.white : Colors.black87,
                          padding: const EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => _checkAnswer(option),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              option,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (_showVisualAids) ...[
                              const SizedBox(height: 8),
                              Text(
                                '●' * int.parse(option),
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.blue,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!_showHint)
                      TextButton.icon(
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('Show Hint'),
                        onPressed: () => setState(() => _showHint = true),
                      ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.grey,
                        size: 36,
                      ),
                      onPressed: _listen,
                    ),
                  ],
                ),
              ),
              if (_showHint)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.yellow[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        currentQuestion['hint'],
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}
