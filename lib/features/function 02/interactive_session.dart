import 'dart:async';

import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/constants/3d_models_constants.dart';
import 'package:giggle/core/constants/teachers_list_constants.dart';
import 'package:giggle/core/models/teacher_model.dart';
import 'package:giggle/core/providers/theme_provider.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'widgets/index.dart';

class SemanticInteractiveSessionScreen extends ConsumerStatefulWidget {
  final Map<String, String>? difficultyLevels;
  final String dyscalculiaType;
  final String courseName;
  final String selectedTeacher;
  final List<Map<String, dynamic>> questions;
  final String userId;

  const SemanticInteractiveSessionScreen({
    Key? key,
    this.difficultyLevels,
    required this.dyscalculiaType,
    required this.courseName,
    required this.selectedTeacher,
    required this.questions,
    required this.userId,
  }) : super(key: key);

  @override
  _SemanticInteractiveSessionScreenState createState() =>
      _SemanticInteractiveSessionScreenState();
}

class _SemanticInteractiveSessionScreenState
    extends ConsumerState<SemanticInteractiveSessionScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  Map<String, String> nodeTypes = {};
  bool showTutorial = false;
  String? lastTappedNode;
  late TeacherCharacter selectedTeacher;

  String selectedModel = "Apple";
  double modelScale = 0.2;
  late ValueNotifier<Map<String, int>> modelCountNotifier;

  // Add debounce variables
  DateTime? lastTapTime;
  static const tapDebounceTime = Duration(milliseconds: 1000);
  bool isProcessingTap = false;

  // Add a variable to track numeric keyboard visibility
  bool _showNumericKeyboard = false;

  // Add a variable to hold error text for the input field
  String? _errorText;

  // Add a TextEditingController for the answer input
  final TextEditingController _answerController = TextEditingController();

  late FlutterTts flutterTts;

  // Track if feedback is currently being spoken
  bool isSpeaking = false;

  int _timeElapsed = 0;
  Timer? _timer;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInputResult = '';
  bool _showVoicePrompt = false;

  // Improved showResultDialog method with better alignment and z-ordering
  void showResultDialog({
    required bool isCorrect,
    required int actualCount,
    required int expectedCount,
    int? appleCount,
    int? orangeCount,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        // Prevent accidental dismissal with back button
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment
                .topCenter, // Changed to topCenter for better alignment
            children: [
              Container(
                width: MediaQuery.of(context).size.width *
                    0.85, // Control width for better layout
                padding: const EdgeInsets.fromLTRB(
                    24, 36, 24, 24), // Add more padding at top for avatar
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.error,
                      size: 64,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCorrect ? "Correct!" : "Keep Trying!",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.courseName == 'Addition' &&
                        appleCount != null &&
                        orangeCount != null)
                      Text(
                        "Current count:\nApples: $appleCount (need ${widget.questions[0]['num1']})\nOranges: $orangeCount (need ${widget.questions[0]['num2']})",
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        "Your answer: $actualCount\nCorrect answer: $expectedCount",
                        textAlign: TextAlign.center,
                      ),
                    if (!isCorrect) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Hint: You can add or remove objects\nuntil you get the right combination!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (isCorrect) {
                          _speakTeacherGuidance(
                              "Great job! You've completed this exercise successfully!");

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

                          // Clean up AR resources before navigation
                          _cleanUpARResources();

                          // Close the dialog
                          Navigator.of(context).pop();

                          // Reset voice prompt state to ensure it's fresh
                          setState(() {
                            _showVoicePrompt = false;
                            _voiceInputResult = '';
                            _isListening = false;
                          });

                          // Show voice input prompt after lesson completion with delay
                          Future.delayed(Duration(milliseconds: 800), () {
                            if (mounted) {
                              _showVoiceInputPrompt();
                            }
                          });
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCorrect ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isCorrect ? "Great Job!" : "Continue"),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -40,
                child: Hero(
                  // Add Hero animation for smoother transition
                  tag: "teacher_avatar",
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(selectedTeacher.avatar),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Enhanced _showVoiceInputPrompt with improved state management
  void _showVoiceInputPrompt() {
    // Reset any previous state first
    _speech.cancel();
    setState(() {
      _showVoicePrompt = true;
      _voiceInputResult = '';
      _isListening = false;
    });

    _speakTeacherGuidance(
        "Did you understand the lesson? Please say 'yes' or 'no'.");

    // Schedule listening to start after speaking is done
    Future.delayed(Duration(milliseconds: 2500), () {
      if (mounted && _showVoicePrompt) {
        _startListening();
      }
    });
  }

// Improved voice prompt overlay with better z-index handling and positioning
  Widget _buildVoicePromptOverlay() {
    if (!_showVoicePrompt) return SizedBox.shrink();

    return Material(
      type: MaterialType.transparency,
      elevation: 100, // High elevation to ensure it's on top
      child: Positioned(
        top: 120,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Hero(
                      // Match hero tag with dialog
                      tag: "teacher_avatar",
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage(selectedTeacher.avatar),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Did you understand the lesson?",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Colors.red.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 36,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  _isListening
                      ? "Listening..."
                      : _voiceInputResult.isEmpty
                          ? "Ready to listen"
                          : "I heard: \"$_voiceInputResult\"",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    color: _isListening ? Colors.red : Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSpeechChip("Yes"),
                    _buildSpeechChip("No"),
                  ],
                ),
                // Add a manual close button
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showVoicePrompt = false;
                      _speech.cancel();
                    });
                    Navigator.of(context).pop(); // Return to previous screen
                  },
                  child: Text("Close"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Improved _processVoiceInput with better state management
  void _processVoiceInput() {
    print('Recognized: $_voiceInputResult');

    if (_voiceInputResult.toLowerCase().contains('yes')) {
      _speakTeacherGuidance(
          "Great! I'm glad you understood the lesson. Let's continue our learning journey!");

      // Navigate away after a delay
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _showVoicePrompt = false);
          Navigator.of(context).pop(); // Return to previous screen
        }
      });
    } else if (_voiceInputResult.toLowerCase().contains('no')) {
      _speakTeacherGuidance(
          "That's okay! Learning takes time. Would you like to try again or perhaps try a different approach?");

      // Show options for the user
      Future.delayed(Duration(seconds: 6), () {
        if (mounted) {
          setState(() => _showVoicePrompt = false);
          _showRetryOptions();
        }
      });
    } else {
      // Handle other responses or unclear input
      _speakTeacherGuidance(
          "I didn't quite catch that. Please let me know if you understood the lesson by saying yes or no.");

      // Reset for another attempt with delay
      Future.delayed(Duration(milliseconds: 3000), () {
        if (mounted && _showVoicePrompt) {
          _startListening();
        }
      });
    }
  }

// Improved _startListening with better error handling
  Future<void> _startListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    try {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceInputResult = result.recognizedWords.toLowerCase();

            // Auto-process if we get a clear yes/no
            if (result.finalResult &&
                (_voiceInputResult.contains('yes') ||
                    _voiceInputResult.contains('no'))) {
              _isListening = false;
              _processVoiceInput();
            }
          });
        },
        listenFor: Duration(seconds: 5),
        pauseFor: Duration(seconds: 2),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      print("Exception during speech recognition: $e");
      setState(() => _isListening = false);

      // Fallback to manual input
      if (_showVoicePrompt) {
        _speakTeacherGuidance(
            "I'm having trouble with voice recognition. You can use the buttons to respond.");
      }
    }
  }

// Enhanced build method to properly layer the voice prompt
  @override
  Widget build(BuildContext context) {
    print(widget.questions);
    final themeData = ref.watch(themeProvider).valueOrNull ??
        const AppTheme(primaryColor: Color(0xFF4F46E5));
    final themeColor = themeData.primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          // Base layer - AR View
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          // Main UI layer
          SafeArea(
            child: Column(
              children: [
                QuestionCard(
                  questions: widget.questions,
                  courseName: widget.courseName,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildTeacherInfo(),
                  ),
                ),
                const Spacer(),
                _buildControlPanel(themeColor: themeColor),
              ],
            ),
          ),

          // Speaking indicator
          if (isSpeaking)
            Positioned(
              top: 120,
              right: 30,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_up, color: themeColor),
                    SizedBox(width: 8),
                    Text(
                      "Teacher is speaking...",
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Tutorial layer
          if (showTutorial)
            TutorialWidget(
              courseName: widget.courseName,
              themeColor: themeColor,
              questions: widget.questions,
            ),

          // Voice prompt layer - ensure this is on top
          if (_showVoicePrompt) _buildVoicePromptOverlay(),

          // Help button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton(
              onPressed: () => setState(() => showTutorial = true),
              backgroundColor: Colors.white,
              elevation: 4,
              child: Icon(Icons.help_outline, color: themeColor),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced _speakTeacherGuidance method with more detailed feedback
  Future<void> _speakTeacherGuidance(String text) async {
    if (isSpeaking) {
      await flutterTts.stop();
    }

    setState(() {
      isSpeaking = true;
    });

    await flutterTts.speak(text);
  }

// Improved object placement feedback in onPlaneOrPointTapped method
  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    if (isProcessingTap || arObjectManager == null || arAnchorManager == null)
      return;

    final now = DateTime.now();
    if (lastTapTime != null && now.difference(lastTapTime!) < tapDebounceTime) {
      return;
    }
    lastTapTime = now;

    setState(() => isProcessingTap = true);

    try {
      ARHitTestResult? planeHitResult;
      try {
        planeHitResult = hitTestResults.firstWhere(
          (result) => result.type == ARHitTestResultType.plane,
        );
      } catch (e) {
        setState(() => isProcessingTap = false);
        return;
      }

      {
        final newAnchor = ARPlaneAnchor(
          transformation: planeHitResult.worldTransform,
        );

        final anchorAdded = await arAnchorManager!.addAnchor(newAnchor);
        if (anchorAdded == true) {
          final nodeName =
              '${selectedModel.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';

          final newNode = ARNode(
            name: nodeName,
            type: NodeType.webGLB,
            uri: availableModels[selectedModel]!,
            scale: vector_math.Vector3(modelScale, modelScale, modelScale),
            position: vector_math.Vector3(0.0, 0.0, 0.0),
            rotation: vector_math.Vector4(1.0, 0.0, 0.0, 0.0),
          );

          final nodeAdded = await arObjectManager!.addNode(
            newNode,
            planeAnchor: newAnchor,
          );

          if (nodeAdded == true) {
            setState(() {
              nodes.add(newNode);
              anchors.add(newAnchor);
              nodeToAnchorMap[nodeName] = newAnchor;
              nodeTypes[nodeName] = selectedModel;
              _recalculateModelCounts();
            });

            // Enhanced guidance based on current counts vs. needed counts
            if (selectedModel == "Apple") {
              final appleCount = modelCounts['Apple'] ?? 0;
              final appleTarget = widget.courseName == 'Addition'
                  ? widget.questions[0]['num1']
                  : int.parse(widget.questions[0]['correctAnswer'].toString());

              if (appleCount < appleTarget) {
                _speakTeacherGuidance(
                    "You've placed an apple! You need ${appleTarget - appleCount} more.");
              } else if (appleCount == appleTarget) {
                _speakTeacherGuidance(
                    "Perfect! You've placed exactly $appleTarget apples.");
              } else {
                _speakTeacherGuidance(
                    "You've placed too many apples. Try removing some.");
              }
            } else if (selectedModel == "Orange") {
              if (widget.courseName == 'Addition') {
                final orangeCount = modelCounts['Orange'] ?? 0;
                final orangeTarget = widget.questions[0]['num2'];

                if (orangeCount < orangeTarget) {
                  _speakTeacherGuidance(
                      "You've placed an orange! You need ${orangeTarget - orangeCount} more.");
                } else if (orangeCount == orangeTarget) {
                  _speakTeacherGuidance(
                      "Great job! You've placed exactly $orangeTarget oranges.");
                } else {
                  _speakTeacherGuidance(
                      "That's too many oranges. You can remove some if needed.");
                }
              }
            }
          } else {
            await arAnchorManager!.removeAnchor(newAnchor);
          }
        }
      }
    } catch (e) {
      print('Error in onPlaneOrPointTapped: $e');
    } finally {
      setState(() => isProcessingTap = false);
    }
  }

// Enhanced object removal feedback
  Future<void> onRemoveSelectedNode() async {
    if (lastTappedNode == null ||
        arObjectManager == null ||
        arAnchorManager == null) return;

    try {
      ARNode? nodeToRemove;
      try {
        nodeToRemove = nodes.firstWhere(
          (node) => node.name == lastTappedNode,
        );
      } catch (e) {
        return;
      }

      final anchorToRemove = nodeToAnchorMap[lastTappedNode];
      final removedType = nodeTypes[lastTappedNode];

      if (anchorToRemove != null) {
        await arObjectManager!.removeNode(nodeToRemove);
        await arAnchorManager!.removeAnchor(anchorToRemove);

        setState(() {
          nodes.removeWhere((node) => node.name == lastTappedNode);
          anchors.remove(anchorToRemove);
          nodeToAnchorMap.remove(lastTappedNode);
          nodeTypes.remove(lastTappedNode);
          lastTappedNode = null;

          _recalculateModelCounts();
        });

        // Enhanced removal feedback based on current state
        if (removedType == 'Apple') {
          final appleCount = modelCounts['Apple'] ?? 0;
          final appleTarget = widget.courseName == 'Addition'
              ? widget.questions[0]['num1']
              : int.parse(widget.questions[0]['correctAnswer'].toString());

          if (appleCount < appleTarget) {
            _speakTeacherGuidance(
                "You removed an apple. You now need ${appleTarget - appleCount} more apples.");
          } else if (appleCount == appleTarget) {
            _speakTeacherGuidance(
                "Perfect! You now have exactly the right number of apples.");
          }
        } else if (removedType == 'Orange' && widget.courseName == 'Addition') {
          final orangeCount = modelCounts['Orange'] ?? 0;
          final orangeTarget = widget.questions[0]['num2'];

          if (orangeCount < orangeTarget) {
            _speakTeacherGuidance(
                "You removed an orange. You now need ${orangeTarget - orangeCount} more oranges.");
          } else if (orangeCount == orangeTarget) {
            _speakTeacherGuidance(
                "Great! You now have exactly the right number of oranges.");
          }
        }
      }
    } catch (e) {
      print('Error removing node: $e');
    }
  }

// Enhanced answer checking with better feedback
  void checkAnswer() {
    int? manualAnswer;
    if (_answerController.text.isNotEmpty) {
      manualAnswer = int.tryParse(_answerController.text);
      if (manualAnswer == null) {
        setState(() => _errorText = 'Please enter a valid number');
        return;
      }
    }

    if (widget.courseName == 'Addition') {
      final appleCount = modelCounts['Apple'] ?? 0;
      final orangeCount = modelCounts['Orange'] ?? 0;
      final int totalCount = appleCount + orangeCount;
      final int expectedApples = widget.questions[0]['num1'];
      final int expectedOranges = widget.questions[0]['num2'];
      final int expectedTotal = expectedApples + expectedOranges;

      final bool isCorrect = manualAnswer != null
          ? manualAnswer == expectedTotal
          : (appleCount == expectedApples && orangeCount == expectedOranges);

      // Provide specific guidance before showing the result dialog
      if (!isCorrect) {
        if (appleCount < expectedApples) {
          _speakTeacherGuidance(
              "I notice you need ${expectedApples - appleCount} more apples. Keep trying!");
        } else if (appleCount > expectedApples) {
          _speakTeacherGuidance(
              "You have ${appleCount - expectedApples} too many apples. Try removing some.");
        }

        if (orangeCount < expectedOranges) {
          Future.delayed(Duration(milliseconds: 2500), () {
            if (mounted) {
              _speakTeacherGuidance(
                  "And you need ${expectedOranges - orangeCount} more oranges.");
            }
          });
        } else if (orangeCount > expectedOranges) {
          Future.delayed(Duration(milliseconds: 2500), () {
            if (mounted) {
              _speakTeacherGuidance(
                  "And you have ${orangeCount - expectedOranges} too many oranges.");
            }
          });
        }

        // Delay showing the dialog to allow for speech guidance
        Future.delayed(Duration(seconds: 4), () {
          if (mounted) {
            showResultDialog(
              isCorrect: isCorrect,
              actualCount: manualAnswer ?? totalCount,
              expectedCount: expectedTotal,
              appleCount: appleCount,
              orangeCount: orangeCount,
            );
          }
        });
      } else {
        _speakTeacherGuidance("Amazing work! Let's check your answer.");

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            showResultDialog(
              isCorrect: isCorrect,
              actualCount: manualAnswer ?? totalCount,
              expectedCount: expectedTotal,
              appleCount: appleCount,
              orangeCount: orangeCount,
            );
          }
        });
      }
    } else {
      final appleCount = modelCounts['Apple'] ?? 0;
      final int expectedCount =
          int.parse(widget.questions[0]['correctAnswer'].toString());
      final int actualCount = manualAnswer ?? appleCount;
      final bool isCorrect = actualCount == expectedCount;

      // Provide specific guidance for counting exercises
      if (!isCorrect) {
        if (actualCount < expectedCount) {
          _speakTeacherGuidance(
              "I see you have $actualCount apples, but you need $expectedCount. Try adding ${expectedCount - actualCount} more.");
        } else {
          _speakTeacherGuidance(
              "I see you have $actualCount apples, but you need $expectedCount. Try removing ${actualCount - expectedCount}.");
        }

        // Delay showing the dialog
        Future.delayed(Duration(seconds: 4), () {
          if (mounted) {
            showResultDialog(
              isCorrect: isCorrect,
              actualCount: actualCount,
              expectedCount: expectedCount,
            );
          }
        });
      } else {
        _speakTeacherGuidance("Wonderful counting! Let's check your answer.");

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            showResultDialog(
              isCorrect: isCorrect,
              actualCount: actualCount,
              expectedCount: expectedCount,
            );
          }
        });
      }
    }
  }

// Enhanced initState with more helpful initial guidance
  @override
  void initState() {
    super.initState();
    _startTimer();
    _speech = stt.SpeechToText();
    _initSpeech();

    modelCountNotifier = ValueNotifier<Map<String, int>>({
      'Apple': 0,
      'Orange': 0,
    });
    selectedTeacher = teachers.firstWhere(
      (teacher) => teacher.name == widget.selectedTeacher,
      orElse: () => teachers[0],
    );

    // Initialize text-to-speech
    initTts();

    // Enhanced initial guidance
    Future.delayed(Duration(seconds: 1), () {
      if (widget.courseName == 'Addition') {
        _speakTeacherGuidance(
            "Welcome! Let's solve this ${widget.courseName} problem together. You need to place ${widget.questions[0]['num1']} apples and ${widget.questions[0]['num2']} oranges. Tap on the screen to place objects.");
      } else {
        _speakTeacherGuidance(
            "Welcome! In this counting exercise, you need to place exactly ${widget.questions[0]['correctAnswer']} apples. Tap on the screen to begin.");
      }

      // Follow up with an additional hint after the initial greeting
      Future.delayed(Duration(seconds: 6), () {
        if (mounted) {
          _speakTeacherGuidance(
              "You can tap the '?' button anytime for help, or tap on objects to remove them.");
        }
      });
    });
  }

// New method to show retry options
  void _showRetryOptions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("What would you like to do?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.refresh),
              title: Text("Try again"),
              onTap: () {
                Navigator.pop(context); // Close dialog

                // Reset the exercise
                setState(() {
                  nodes.clear();
                  anchors.clear();
                  nodeTypes.clear();
                  nodeToAnchorMap.clear();
                  modelCounts = {
                    'Apple': 0,
                    'Orange': 0,
                  };
                  modelCountNotifier.value = modelCounts;
                });

                _speakTeacherGuidance(
                    "Let's try again! Take your time and I'm here to help.");
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text("Show tutorial"),
              onTap: () {
                Navigator.pop(context); // Close dialog
                _showTutorial();
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text("Return to menu"),
              onTap: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to previous screen
              },
            ),
          ],
        ),
      ),
    );
  }

// Helper widget for showing speech suggestions
  Widget _buildSpeechChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Initialize speech recognition
  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() => _isListening = false);
          _processVoiceInput();
        }
      },
      onError: (errorMsg) {
        print('Speech recognition error: $errorMsg');
        setState(() => _isListening = false);
      },
    );
    if (!available) {
      print('Speech recognition not available on this device');
    }
  }

  // Improved model counting
  Map<String, int> modelCounts = {
    'Apple': 0,
    'Orange': 0,
  };

  Map<String, int> get currentModelCounts {
    Map<String, int> counts = {'Apple': 0, 'Orange': 0};

    for (String type in nodeTypes.values) {
      if (type == 'Apple') counts['Apple'] = counts['Apple']! + 1;
      if (type == 'Orange') counts['Orange'] = counts['Orange']! + 1;
    }

    return counts;
  }

  void _debugPrintState() {
    print('\===============- Current State =================');
    print('Nodes length: ${nodes.length}');
    print('Anchors length: ${anchors.length}');
    print('NodeTypes: $nodeTypes');
    print('Model counts: $modelCounts');
    print('==================================================\n');
  }

  final Map<String, ARAnchor> nodeToAnchorMap = {};

  void _recalculateModelCounts() {
    final newCounts = <String, int>{
      'Apple': 0,
      'Orange': 0,
    };

    for (final type in nodeTypes.values) {
      if (newCounts.containsKey(type)) {
        newCounts[type] = newCounts[type]! + 1;
      }
    }

    setState(() {
      modelCounts = newCounts;
      modelCountNotifier.value = newCounts;
    });

    print('Recalculated counts: $modelCounts');
    _debugPrintState();
  }

  void updateModelCounts() {
    Map<String, int> newCounts = {
      'Apple': 0,
      'Orange': 0,
    };

    nodeTypes.forEach((nodeName, type) {
      if (newCounts.containsKey(type)) {
        newCounts[type] = (newCounts[type] ?? 0) + 1;
      }
    });

    setState(() {
      modelCounts = newCounts;
      print('Model counts updated: $modelCounts');
    });
  }

  Widget _buildCounterPill(String label, int target, IconData icon) {
    final current = currentModelCounts[label] ?? 0;
    final isComplete = current == target;
    final color = isComplete ? Colors.green : Colors.grey[800]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$current/$target',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(SemanticInteractiveSessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('Widget updated. Current counts: $modelCounts');
  }

  void printCurrentState() {
    print('Current State:');
    print('Nodes count: ${nodes.length}');
    print('Anchors count: ${anchors.length}');
    print('NodeTypes: $nodeTypes');
    print('ModelCounts: $modelCounts');
    print('LastTappedNode: $lastTappedNode');
    print('SelectedModel: $selectedModel');
  }

  int getModelCount(String modelType) {
    return modelCounts[modelType] ?? 0;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeElapsed++;
      });
    });
  }

  // Initialize text-to-speech
  Future<void> initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts
        .setSpeechRate(0.5); // Slower speech for better understanding
    await flutterTts.setVolume(1.0);

    // Set voice based on teacher character gender
    List<dynamic> voices = await flutterTts.getVoices;
    String voiceToUse = selectedTeacher.name == 'Ms. Emma'
        ? "en-us-x-sfg-local"
        : "en-us-x-tpf-local";
    await flutterTts.setVoice({"name": voiceToUse, "locale": "en-US"});

    // Listen for TTS completion
    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });
  }

  void _cleanUpARResources() async {
    print("Cleaning up AR resources");
    try {
      // Clear all nodes first
      if (arObjectManager != null && nodes.isNotEmpty) {
        for (final node in List.from(nodes)) {
          await arObjectManager!.removeNode(node);
        }
      }

      // Clear all anchors
      if (arAnchorManager != null && anchors.isNotEmpty) {
        for (final anchor in List.from(anchors)) {
          await arAnchorManager!.removeAnchor(anchor);
        }
      }

      // Reset lists and maps
      nodes.clear();
      anchors.clear();
      nodeTypes.clear();
      nodeToAnchorMap.clear();

      // Dispose session manager last
      if (arSessionManager != null) {
        await arSessionManager!.dispose();
      }

      arSessionManager = null;
      arObjectManager = null;
      arAnchorManager = null;
    } catch (e) {
      print("Error cleaning up AR resources: $e");
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    flutterTts.stop();
    print("Disposing SemanticInteractiveSessionScreen");
    _cleanUpARResources();
    modelCountNotifier.dispose();
    _timer?.cancel();
    _speech.cancel();
    super.dispose();
  }

  void _showTutorial() {
    setState(() => showTutorial = true);
    _speakTeacherGuidance(
        "Let me show you how to use this interactive exercise. Follow the instructions to solve the ${widget.courseName} problem!");
  }

  Widget _buildKeyboardButton(Color themeColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _showNumericKeyboard = !_showNumericKeyboard);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.keyboard,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel({required Color themeColor}) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            // Existing counter pills row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  widget.courseName == 'Addition'
                      ? Row(
                          children: [
                            _buildCounterPill(
                              "Apple",
                              int.parse(widget.questions[0]['num1'].toString()),
                              Icons.apple,
                            ),
                            const SizedBox(width: 12),
                            _buildCounterPill(
                              "Orange",
                              int.parse(widget.questions[0]['num2'].toString()),
                              Icons.circle,
                            ),
                          ],
                        )
                      : _buildCounterPill(
                          "Apple",
                          int.parse(
                              widget.questions[0]['correctAnswer'].toString()),
                          Icons.apple,
                        ),
                  const Spacer(),
                  if (lastTappedNode != null) _buildDeleteButton(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // New numeric input field
            if (_showNumericKeyboard)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _answerController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter your answer',
                    errorText: _errorText,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle),
                      onPressed: () {
                        // Hide keyboard
                        FocusScope.of(context).unfocus();
                        setState(() => _showNumericKeyboard = false);
                        checkAnswer();
                      },
                    ),
                  ),
                  onSubmitted: (_) {
                    setState(() => _showNumericKeyboard = false);
                    checkAnswer();
                  },
                ),
              ),
            const SizedBox(height: 16),
            // Bottom row with model selector and buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModelSelector(themeColor),
                  ),
                  const SizedBox(width: 12),
                  _buildKeyboardButton(themeColor),
                  const SizedBox(width: 12),
                  _buildCheckButton(themeColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRemoveSelectedNode,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.red,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildModelSelector(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (widget.courseName == 'Addition') ...[
            Expanded(
              child: _buildModelOption("Apple", Icons.apple, themeColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModelOption("Orange", Icons.circle, themeColor),
            ),
          ] else
            Expanded(
              child: _buildModelOption("Apple", Icons.apple, themeColor),
            )
        ],
      ),
    );
  }

  Widget _buildModelOption(String model, IconData icon, Color themeColor) {
    final isSelected = selectedModel == model;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => selectedModel = model),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? themeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                model,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckButton(Color themeColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: checkAnswer,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherInfo() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF5E5CE6),
                      const Color(0xFF5E5CE6).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(selectedTeacher.avatar),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(
                    color: isSpeaking ? Colors.green : Colors.white,
                    width: isSpeaking ? 4 : 3,
                  ),
                ),
              ),
              if (isSpeaking)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            selectedTeacher.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
            textAlign: TextAlign.center,
          ),
          if (isSpeaking)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Speaking...",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> onNodeTapped(List<String> tappedNodes) async {
    if (tappedNodes.isNotEmpty) {
      final nodeExists = nodes.any((node) => node.name == tappedNodes.first);
      setState(() {
        lastTappedNode = nodeExists ? tappedNodes.first : null;
      });
    } else {
      setState(() {
        lastTappedNode = null;
      });
    }
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          showWorldOrigin: true,
          handlePans: true,
          handleRotation: true,
        );

    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager!.onNodeTap = onNodeTapped;
    this.arObjectManager!.onPanStart = onPanStarted;
    this.arObjectManager!.onPanChange = onPanChanged;
    this.arObjectManager!.onPanEnd = onPanEnded;
    this.arObjectManager!.onRotationStart = onRotationStarted;
    this.arObjectManager!.onRotationChange = onRotationChanged;
    this.arObjectManager!.onRotationEnd = onRotationEnded;
  }

  // Gesture handlers
  void onPanStarted(String nodeName) {
    print("Started panning node $nodeName");
  }

  void onPanChanged(String nodeName) {
    print("Continued panning node $nodeName");
  }

  void onPanEnded(String nodeName, Matrix4 newTransform) {
    print("Ended panning node $nodeName");
  }

  void onRotationStarted(String nodeName) {
    print("Started rotating node $nodeName");
  }

  void onRotationChanged(String nodeName) {
    print("Continued rotating node $nodeName");
  }

  void onRotationEnded(String nodeName, Matrix4 newTransform) {
    print("Ended rotating node $nodeName");
  }
}