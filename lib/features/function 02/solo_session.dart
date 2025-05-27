import 'dart:async';

import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

import 'package:giggle/core/constants/3d_models_constants.dart';
import 'package:giggle/core/models/user_model.dart';
import 'package:giggle/core/providers/auth_provider.dart';
import 'package:giggle/core/providers/theme_provider.dart';

import 'widgets/index.dart';

class SemanticSoloSessionScreen extends ConsumerStatefulWidget {
  final String index;
  final String courseName;
  final List<Map<String, dynamic>> questions;
  final String userId;
  final Function() onQuestionCompleted;

  const SemanticSoloSessionScreen({
    Key? key,
    required this.questions,
    required this.courseName,
    required this.index,
    required this.userId,
    required this.onQuestionCompleted,
  }) : super(key: key);

  @override
  _SemanticSoloSessionScreenState createState() =>
      _SemanticSoloSessionScreenState();
}

class _SemanticSoloSessionScreenState
    extends ConsumerState<SemanticSoloSessionScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  Map<String, String> nodeTypes = {};
  bool showTutorial = false;
  String? lastTappedNode;

  String selectedModel = "Apple";
  double modelScale = 0.2;
  late ValueNotifier<Map<String, int>> modelCountNotifier;

  // Add debounce variables
  DateTime? lastTapTime;
  static const tapDebounceTime = Duration(milliseconds: 1000);
  bool isProcessingTap = false;

  int _timeElapsed = 0;
  Timer? _timer;

  // Define _showKeyboardInput
  bool _showKeyboardInput = false;

  // Define _answerController
  final TextEditingController _answerController = TextEditingController();

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

  Future<void> onRemoveSelectedNode() async {
    if (lastTappedNode == null) return;

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
      }
    } catch (e) {}
  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    if (isProcessingTap) return;

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

  // Modify the updateModelCounts method
  void updateModelCounts() {
    Map<String, int> newCounts = {
      'Apple': 0,
      'Orange': 0,
    };

    // Count directly from nodeTypes
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
    // Get real-time count
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

// Add this method to the class to help track state changes
  @override
  void didUpdateWidget(SemanticSoloSessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('Widget updated. Current counts: $modelCounts');
  }

// Add this method to help with debugging
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

  @override
  void initState() {
    super.initState();
    _startTimer();
    modelCountNotifier = ValueNotifier<Map<String, int>>({
      'Apple': 0,
      'Orange': 0,
    });
  }

  // Properly clean up all AR resources
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
    _answerController.dispose();
    super.dispose();
    arSessionManager!.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Remove or modify this debug print
    // print(widget.questions);  // This can cause issues if questions is null
    
    // Add this check
    if (widget.questions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No questions available'),
        ),
      );
    }

    final authState = ref.watch(authProvider);
    final themeData = ref.watch(themeProvider).valueOrNull ??
        const AppTheme(primaryColor: Color(0xFF4F46E5));
    final themeColor = themeData.primaryColor;

    return authState.when(
      data: (AppUser? user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        return Scaffold(
          body: Stack(
            children: [
              ARView(
                onARViewCreated: onARViewCreated,
                planeDetectionConfig:
                    PlaneDetectionConfig.horizontalAndVertical,
              ),
              SafeArea(
                child: Column(
                  children: [
                    QuestionCard(
                        index: widget.index,
                        questions: widget.questions,
                        courseName: widget.courseName),
                    const Spacer(),
                    _buildControlPanel(
                      themeColor: themeColor,
                      userId: user.uid,
                    ),
                  ],
                ),
              ),
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

  Widget _buildControlPanel({required Color themeColor, required String userId}) {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  if (lastTappedNode != null) _buildDeleteButton(),
                  const Spacer(),
                  // Add keyboard toggle button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showKeyboardInput = !_showKeyboardInput;
                      });
                    },
                    icon: Icon(
                      _showKeyboardInput ? Icons.keyboard_hide : Icons.keyboard,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
            ),
            if (_showKeyboardInput) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _answerController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter your answer',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => checkAnswer(userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModelSelector(themeColor),
                    ),
                    const SizedBox(width: 12),
                    _buildCheckButton(themeColor, userId),
                  ],
                ),
              ),
            ],
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

  Widget _buildCheckButton(Color themeColor, String userId) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => checkAnswer(userId),
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

  void checkAnswer(String userId) {
    // Add null check at the beginning
    if (widget.questions.isEmpty) {
      print('No questions available to check');
      return;
    }

    String getQuestionKey(String index) {
      // Parse out the challenge number and question number
      final parts = index.split('-');
      if (parts.length == 2) {
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

    bool isCorrect = false;
    
    if (_showKeyboardInput) {
      // Handle keyboard input with null safety
      final userAnswer = int.tryParse(_answerController.text);
      final question = widget.questions[0];
      
      if (userAnswer != null && question != null) {
        if (widget.courseName == 'Addition') {
          final num1 = question['num1'] as int? ?? 0;
          final num2 = question['num2'] as int? ?? 0;
          final expectedSum = num1 + num2;
          isCorrect = userAnswer == expectedSum;
        } else {
          final expectedCount = int.tryParse(question['correctAnswer']?.toString() ?? '0') ?? 0;
          isCorrect = userAnswer == expectedCount;
        }
      }
    } else {
      // Handle AR counting with null safety
      final question = widget.questions[0];
      if (question != null) {
        if (widget.courseName == 'Addition') {
          final appleCount = modelCounts['Apple'] ?? 0;
          final orangeCount = modelCounts['Orange'] ?? 0;
          final num1 = question['num1'] as int? ?? 0;
          final num2 = question['num2'] as int? ?? 0;
          isCorrect = appleCount == num1 && orangeCount == num2;
        } else {
          final appleCount = modelCounts['Apple'] ?? 0;
          final expectedCount = int.tryParse(question['correctAnswer']?.toString() ?? '0') ?? 0;
          isCorrect = appleCount == expectedCount;
        }
      }
    }

    // Show result dialog and handle Firebase updates
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCorrect ? 'Completed' : 'Completed',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Always save progress regardless of correct/incorrect
                  _cleanUpARResources();
                  
                  // Extract challenge and question numbers from the index
                  final parts = widget.index.split('-');
                  final challengeNumber = parts[0];
                  final questionNumber = parts[1];
                  
                  final questionKey = getQuestionKey(widget.index);
                  
                  try {
                    // Get a reference to the base path
                    final baseRef = FirebaseFirestore.instance
                        .collection('functionActivities')
                        .doc(userId)
                        .collection(widget.courseName)
                        .doc('Semantic Dyscalculia')
                        .collection('solo_sessions')
                        .doc('progress');

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
                      final challengesStatus = await Future.wait([
                        baseRef.collection('questionOne').doc('status').get(),
                        baseRef.collection('questionTwo').doc('status').get(),
                        baseRef.collection('questionThree').doc('status').get(),
                      ]);

                      final allChallengesCompleted = challengesStatus.every(
                        (doc) => doc.exists && doc.data()?['completed'] == true
                      );

                      // If all challenges are completed, update the progress document
                      if (allChallengesCompleted) {
                        await baseRef.set({
                          'completed': true,
                          'timeElapsed': _timeElapsed,
                        }, SetOptions(merge: true));
                      }
                    }

                  } catch (error) {
                    print('Error saving progress: $error');
                  }

                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen

                  if (_showKeyboardInput) {
                    _answerController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? Colors.blue : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
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
