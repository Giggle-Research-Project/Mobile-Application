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

  int _timeElapsed = 0;
  Timer? _timer;

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
    } catch (e) {
      print('Error removing node: $e');
    }
  }

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

  @override
  void initState() {
    super.initState();
    _startTimer();
    modelCountNotifier = ValueNotifier<Map<String, int>>({
      'Apple': 0,
      'Orange': 0,
    });
    selectedTeacher = teachers.firstWhere(
      (teacher) => teacher.name == widget.selectedTeacher,
      orElse: () => teachers[0],
    );
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
    print("Disposing SemanticInteractiveSessionScreen");
    _cleanUpARResources();
    modelCountNotifier.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.questions);
    final themeData = ref.watch(themeProvider).valueOrNull ??
        const AppTheme(primaryColor: Color(0xFF4F46E5));
    final themeColor = themeData.primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
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
          if (showTutorial)
            TutorialWidget(
              courseName: widget.courseName,
              themeColor: themeColor,
              questions: widget.questions,
            ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModelSelector(themeColor),
                  ),
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
                    color: Colors.white,
                    width: 3,
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

  void checkAnswer() {
    if (widget.courseName == 'Addition') {
      final appleCount = modelCounts['Apple'] ?? 0;
      final orangeCount = modelCounts['Orange'] ?? 0;
      final isCorrect = appleCount == widget.questions[0]['num1'] &&
          orangeCount == widget.questions[0]['num2'];

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
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
                Text(
                  "Current count:\nApples: $appleCount (need ${widget.questions[0]['num1']})\nOranges: $orangeCount (need ${widget.questions[0]['num2']})",
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

                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    } else {
                      Navigator.pop(context);
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
        ),
      );
    } else {
      final appleCount = modelCounts['Apple'] ?? 0;

      final int expectedCount =
          int.parse(widget.questions[0]['correctAnswer'].toString());
      final int actualCount = appleCount;

      print("Expected count: $expectedCount (${expectedCount.runtimeType})");
      print("Actual count: $actualCount (${actualCount.runtimeType})");

      final bool isCorrect = actualCount == expectedCount;
      print("Is correct? $isCorrect");

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
                Text(
                  "Current count: $actualCount (need $expectedCount)",
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
                      await FirebaseFirestore.instance
                          .collection('functionActivities')
                          .doc(widget.userId)
                          .collection(widget.courseName)
                          .doc(widget.dyscalculiaType)
                          .collection('interactive_session')
                          .doc('progress')
                          .set({'completed': true, 'timeElapsed': _timeElapsed},
                              SetOptions(merge: true));
                      // Clean up AR resources before navigation
                      _cleanUpARResources();

                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    } else {
                      Navigator.pop(context);
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
        ),
      );
    }
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
