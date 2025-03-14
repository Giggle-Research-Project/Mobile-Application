import 'dart:math';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:vector_math/vector_math_64.dart' as vectorMath;

class TouchedNode {
  final int number;
  final int order;
  final String nodeName;

  TouchedNode({
    required this.number,
    required this.order,
    required this.nodeName,
  });
}

class ARMathGameInteractive extends StatefulWidget {
  const ARMathGameInteractive({Key? key}) : super(key: key);

  @override
  _ARMathGameInteractiveState createState() => _ARMathGameInteractiveState();
}

class _ARMathGameInteractiveState extends State<ARMathGameInteractive> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;

  List<int> numbers = List.generate(3, (index) => index);
  List<ARNode> numberNodes = [];
  List<ARNode> markerNodes = [];
  Set<String> uniqueTouchedNodes = {}; // Track unique touched nodes
  List<TouchedNode> touchedNodes = [];

  bool isInitialized = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    arSessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Math Counter'),
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
          _buildCounterPanel(),
          _buildInstructionOverlay(),
        ],
      ),
    );
  }

  Widget _buildCounterPanel() {
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
            Text(
              'Models Touched: ${uniqueTouchedNodes.length}/10',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Touched: ${touchedNodes.isNotEmpty ? touchedNodes.last.number : '-'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
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
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black54,
        child: const Text(
          'Tap on the numbers to count unique touches',
          style: TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
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
          handlePans: false,
          handleRotation: false,
        );

    this.arObjectManager.onInitialize();
    this.arObjectManager.onNodeTap = onNodeTapped;

    setState(() {
      isInitialized = true;
    });

    _setupInitialNumbers();
  }

  void onNodeTapped(List<String> nodeNames) {
    if (nodeNames.isEmpty) return;

    String tappedNodeName = nodeNames.first;

    // Only process the tap if this node hasn't been touched before
    if (!uniqueTouchedNodes.contains(tappedNodeName)) {
      int nodeIndex =
          numberNodes.indexWhere((node) => node.name == tappedNodeName);
      if (nodeIndex != -1) {
        setState(() {
          uniqueTouchedNodes.add(tappedNodeName);
          touchedNodes.add(TouchedNode(
            number: numbers[nodeIndex],
            order: touchedNodes.length + 1,
            nodeName: tappedNodeName,
          ));
        });
        _highlightNode(nodeIndex);
      }
    }
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
          name: "number_$i", // Ensure unique names for tracking
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

  Future<void> _highlightNode(int index) async {
    // Highlight the selected number by scaling it up
    numberNodes[index].scale = vectorMath.Vector3.all(0.3);

    // Add a visual indicator (optional)
    vectorMath.Vector3 position = numberNodes[index].position.clone();
    position.y += 0.2;

    ARNode highlightNode = ARNode(
      type: NodeType.webGLB,
      uri: "file:///android_asset/flutter_assets/assets/3d_models/cube.glb",
      position: position,
      scale: vectorMath.Vector3.all(0.1),
    );

    await arObjectManager.addNode(highlightNode);
    markerNodes.add(highlightNode);
  }

  Future<void> _resetGame() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Remove all nodes
      for (var node in [...numberNodes, ...markerNodes]) {
        await arObjectManager.removeNode(node);
      }

      // Clear all lists and sets
      setState(() {
        numberNodes.clear();
        markerNodes.clear();
        touchedNodes.clear();
        uniqueTouchedNodes.clear();
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
}
