import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vectorMath;

class ARMathGame extends StatefulWidget {
  const ARMathGame({Key? key}) : super(key: key);

  @override
  _ARMathGameState createState() => _ARMathGameState();
}

class _ARMathGameState extends State<ARMathGame> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;

  List<int> numbers = List.generate(10, (index) => index);
  List<ARNode> numberNodes = [];
  List<ARNode> bucketNodes = [];
  List<List<ARNode>> stoneNodes = [[], []];
  List<int> selectedNumbers = [];

  bool isInitialized = false;
  bool isSelectingNumbers = true;
  bool isPlacingStones = false;
  bool isLoading = false;
  String? errorMessage;

  final TextEditingController answerController = TextEditingController();

  @override
  void dispose() {
    arSessionManager.dispose();
    answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Math Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          if (errorMessage != null) _buildErrorWidget(),
          if (isLoading) _buildLoadingWidget(),
          _buildSelectedNumbersPanel(),
          _buildInstructionOverlay(),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildSelectedNumbersPanel() {
    if (selectedNumbers.isEmpty) return Container();

    return Positioned(
      top: 80,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Selected Numbers:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...selectedNumbers.map((number) => Text(
                  number.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => errorMessage = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildInstructionOverlay() {
    String message = isSelectingNumbers
        ? 'Tap on the numbers to select two numbers'
        : isPlacingStones
            ? 'Count the stones in both buckets and enter their sum'
            : '';

    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black54,
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    if (!isInitialized) return Container();

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPlacingStones) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'What is ${selectedNumbers[0]} + ${selectedNumbers[1]}?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: answerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter your answer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _checkAnswer,
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Check Answer',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isSelectingNumbers && selectedNumbers.length == 2)
              ElevatedButton(
                onPressed: _startPlacingStones,
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
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

    this.arSessionManager.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          showWorldOrigin: false,
          handleTaps: true,
          handlePans: true,
          handleRotation: true,
        );

    this.arObjectManager.onInitialize();
    this.arSessionManager.onPlaneOrPointTap = _handleTap;

    // Initialize gesture handlers
    this.arObjectManager.onPanStart = _onPanStarted;
    this.arObjectManager.onPanChange = _onPanChanged;
    this.arObjectManager.onPanEnd = _onPanEnded;
    this.arObjectManager.onRotationStart = _onRotationStarted;
    this.arObjectManager.onRotationChange = _onRotationChanged;
    this.arObjectManager.onRotationEnd = _onRotationEnded;

    setState(() {
      isInitialized = true;
    });

    _setupInitialNumbers();
  }

  Future<void> _setupInitialNumbers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      double radius = 1.0;
      for (int i = 0; i < numbers.length; i++) {
        double angle = (i / numbers.length) * 2 * pi;
        vectorMath.Vector3 position = vectorMath.Vector3(
          radius * cos(angle),
          0,
          radius * sin(angle),
        );

        ARNode node = ARNode(
          type: NodeType.webGLB,
          uri:
              "file:///android_asset/flutter_assets/assets/3d_models/numbers/number_${numbers[i]}.glb",
          position: position,
          scale: vectorMath.Vector3.all(0.2),
        );

        bool? didAddNode = await arObjectManager.addNode(node);
        if (didAddNode == true) {
          numberNodes.add(node);
        } else {
          throw Exception('Failed to add number node ${numbers[i]}');
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error setting up numbers: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleTap(List<ARHitTestResult> hitTestResults) {
    if (!isInitialized || hitTestResults.isEmpty || !isSelectingNumbers) return;

    final hit = hitTestResults.first;
    final worldTransform = hit.worldTransform;
    _handleNumberSelection(worldTransform);
  }

  void _handleNumberSelection(Matrix4 tapTransform) {
    if (selectedNumbers.length >= 2) return;

    vectorMath.Vector3 tapPosition = vectorMath.Vector3(
      tapTransform.getTranslation().x,
      tapTransform.getTranslation().y,
      tapTransform.getTranslation().z,
    );

    for (int i = 0; i < numberNodes.length; i++) {
      if (_isNearPosition(tapPosition, numberNodes[i].position) &&
          !selectedNumbers.contains(numbers[i])) {
        setState(() {
          selectedNumbers.add(numbers[i]);
          // Visual feedback for selection
          numberNodes[i].scale = vectorMath.Vector3.all(0.3);
        });
        break;
      }
    }
  }

  bool _isNearPosition(vectorMath.Vector3 tap, vectorMath.Vector3 target) {
    return (tap - target).length < 0.2;
  }

  Future<void> _startPlacingStones() async {
    setState(() {
      isLoading = true;
      isSelectingNumbers = false;
      isPlacingStones = true;
    });

    try {
      // Remove number nodes
      for (var node in numberNodes) {
        await arObjectManager.removeNode(node);
      }
      numberNodes.clear();

      // Create buckets
      for (int i = 0; i < 2; i++) {
        vectorMath.Vector3 position = vectorMath.Vector3(
          i * 0.6 - 0.3,
          0,
          -0.5,
        );

        ARNode bucketNode = ARNode(
          type: NodeType.webGLB,
          uri:
              "file:///android_asset/flutter_assets/assets/3d_models/bucket.glb",
          position: position,
          scale: vectorMath.Vector3.all(0.2),
        );

        bool? didAddNode = await arObjectManager.addNode(bucketNode);
        if (didAddNode == true) {
          bucketNodes.add(bucketNode);
        } else {
          throw Exception('Failed to add bucket node');
        }

        // Add stones for each bucket
        await _addStonesToBucket(i, selectedNumbers[i]);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error creating game objects: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addStonesToBucket(int bucketIndex, int count) async {
    for (int i = 0; i < count; i++) {
      vectorMath.Vector3 position = vectorMath.Vector3(
        bucketNodes[bucketIndex].position.x +
            (Random().nextDouble() * 0.1 - 0.05),
        0.05 + (i * 0.03),
        bucketNodes[bucketIndex].position.z +
            (Random().nextDouble() * 0.1 - 0.05),
      );

      ARNode stoneNode = ARNode(
        type: NodeType.webGLB,
        uri: "file:///android_asset/flutter_assets/assets/3d_models/stone.glb",
        position: position,
        scale: vectorMath.Vector3.all(0.1),
      );

      bool? didAddNode = await arObjectManager.addNode(stoneNode);
      if (didAddNode == true) {
        stoneNodes[bucketIndex].add(stoneNode);
      }
    }
  }

  void _checkAnswer() {
    int userAnswer = int.tryParse(answerController.text) ?? -1;
    int correctAnswer = selectedNumbers[0] + selectedNumbers[1];

    if (userAnswer == correctAnswer) {
      _showSuccessDialog();
    } else {
      _showTryAgainDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Correct! 🎉'),
        content: Text(
          '${selectedNumbers[0]} + ${selectedNumbers[1]} = ${selectedNumbers[0] + selectedNumbers[1]}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _showTryAgainDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not quite right'),
        content: const Text('Try counting the stones again!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              answerController.clear();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetGame() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Remove all nodes
      for (var node in [
        ...numberNodes,
        ...bucketNodes,
        ...stoneNodes.expand((x) => x)
      ]) {
        await arObjectManager.removeNode(node);
      }

      // Clear all lists
      setState(() {
        numberNodes.clear();
        selectedNumbers.clear();
        bucketNodes.clear();
        stoneNodes = [[], []];
        isSelectingNumbers = true;
        isPlacingStones = false;
        answerController.clear();
      });

      // Setup new game
      await _setupInitialNumbers();
    } catch (e) {
      setState(() {
        errorMessage = 'Error resetting game: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Gesture control methods
  void _onPanStarted(String nodeName) {
    print("Started panning node $nodeName");
  }

  void _onPanChanged(String nodeName) {
    print("Continued panning node $nodeName");
  }

  void _onPanEnded(String nodeName, Matrix4 newTransform) {
    print("Ended panning node $nodeName");

    // Find the node that was panned
    ARNode? pannedNode;

    // Check in number nodes
    pannedNode = numberNodes.firstWhere(
      (node) => node.name == nodeName,
      orElse: () => ARNode(type: NodeType.webGLB, uri: ''), // dummy node
    );

    // Check in bucket nodes if not found
    if (pannedNode.name.isEmpty) {
      pannedNode = bucketNodes.firstWhere(
        (node) => node.name == nodeName,
        orElse: () => ARNode(type: NodeType.webGLB, uri: ''),
      );
    }

    // Check in stone nodes if not found
    if (pannedNode.name.isEmpty) {
      for (var bucketStones in stoneNodes) {
        pannedNode = bucketStones.firstWhere(
          (node) => node.name == nodeName,
          orElse: () => ARNode(type: NodeType.webGLB, uri: ''),
        );
        if (pannedNode.name.isNotEmpty) break;
      }
    }

    // Update the node's transform if found
    if (pannedNode != null && pannedNode.name.isNotEmpty) {
      pannedNode?.transform = newTransform;
    }
  }

  void _onRotationStarted(String nodeName) {
    print("Started rotating node $nodeName");
  }

  void _onRotationChanged(String nodeName) {
    print("Continued rotating node $nodeName");
  }

  void _onRotationEnded(String nodeName, Matrix4 newTransform) {
    print("Ended rotating node $nodeName");

    // Find the node that was rotated
    ARNode? rotatedNode;

    // Check in number nodes
    rotatedNode = numberNodes.firstWhere(
      (node) => node.name == nodeName,
      orElse: () => ARNode(type: NodeType.webGLB, uri: ''), // dummy node
    );

    // Check in bucket nodes if not found
    if (rotatedNode.name.isEmpty) {
      rotatedNode = bucketNodes.firstWhere(
        (node) => node.name == nodeName,
        orElse: () => ARNode(type: NodeType.webGLB, uri: ''),
      );
    }

    // Check in stone nodes if not found
    if (rotatedNode.name.isEmpty) {
      for (var bucketStones in stoneNodes) {
        rotatedNode = bucketStones.firstWhere(
          (node) => node.name == nodeName,
          orElse: () => ARNode(type: NodeType.webGLB, uri: ''),
        );
        if (rotatedNode.name.isNotEmpty) break;
      }
    }

    // Update the node's transform if found
    if (rotatedNode != null && rotatedNode.name.isNotEmpty) {
      rotatedNode.transform = newTransform;
    }
  }
}
