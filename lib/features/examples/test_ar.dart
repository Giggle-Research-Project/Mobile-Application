import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

class GiggleTest extends StatefulWidget {
  GiggleTest({Key? key}) : super(key: key);
  @override
  _GiggleTestState createState() => _GiggleTestState();
}

class _GiggleTestState extends State<GiggleTest> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  String? lastTappedNode;
  String selectedModel = "Astronaut";
  double modelScale = 0.2;

  final Map<String, String> availableModels = {
    "Astronaut": "https://modelviewer.dev/shared-assets/models/Astronaut.glb",
    "Robot": "file:///android_asset/flutter_assets/assets/3d_models/tpose.glb",
    "Duck":
        "file:///android_asset/flutter_assets/assets/3d_models/chin_chest.glb",
    "Car":
        "file:///android_asset/flutter_assets/assets/3d_models/animated_a.glb",
    "Table": "file:///android_asset/flutter_assets/assets/3d_models/A.glb",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Model Placer'),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Models in Scene: ${nodes.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (lastTappedNode != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected: $lastTappedNode',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => onRemoveSelectedNode(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: const Text('Remove Selected'),
                            ),
                          ],
                        ),
                      ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedModel,
                      items: availableModels.keys.map((String model) {
                        return DropdownMenuItem<String>(
                          value: model,
                          child: Text(model),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedModel = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Scale: '),
                        Expanded(
                          child: Slider(
                            value: modelScale,
                            min: 0.1,
                            max: 1.0,
                            divisions: 18,
                            label: modelScale.toStringAsFixed(1),
                            onChanged: (double value) {
                              setState(() {
                                modelScale = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: onRemoveEverything,
                    child: const Text("Remove All"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onRemoveSelectedNode() async {
    if (lastTappedNode != null) {
      // Find the node and its corresponding anchor
      final nodeToRemove = nodes.firstWhere(
        (node) => node.name == lastTappedNode,
        orElse: () => null as ARNode,
      );

      if (nodeToRemove != null) {
        // Find the anchor for this node
        final anchorToRemove = anchors[nodes.indexOf(nodeToRemove)];

        // Remove the node and anchor
        await arObjectManager.removeNode(nodeToRemove);
        await arAnchorManager.removeAnchor(anchorToRemove);

        setState(() {
          nodes.remove(nodeToRemove);
          anchors.remove(anchorToRemove);
          lastTappedNode = null; // Clear the selection
        });
      }
    }
  }

  Future<void> onNodeTapped(List<String> nodes) async {
    if (nodes.isNotEmpty) {
      setState(() {
        lastTappedNode = nodes.first;
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

    this.arSessionManager.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          showWorldOrigin: true,
          handlePans: true,
          handleRotation: true,
        );
    this.arObjectManager.onInitialize();

    this.arSessionManager.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager.onPanStart = onPanStarted;
    this.arObjectManager.onPanChange = onPanChanged;
    this.arObjectManager.onPanEnd = onPanEnded;
    this.arObjectManager.onRotationStart = onRotationStarted;
    this.arObjectManager.onRotationChange = onRotationChanged;
    this.arObjectManager.onRotationEnd = onRotationEnded;
    this.arObjectManager.onNodeTap = onNodeTapped;
  }

  Future<void> onRemoveEverything() async {
    for (var anchor in anchors) {
      await arAnchorManager.removeAnchor(anchor);
    }
    for (var node in nodes) {
      await arObjectManager.removeNode(node);
    }
    setState(() {
      anchors = [];
      nodes = [];
      lastTappedNode = null;
    });
  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);

    if (singleHitTestResult != null) {
      var newAnchor =
          ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      bool didAddAnchor = await arAnchorManager.addAnchor(newAnchor) ?? false;

      if (didAddAnchor) {
        anchors.add(newAnchor);
        var newNode = ARNode(
          type: NodeType.webGLB,
          uri: availableModels[selectedModel]!,
          scale: vector_math.Vector3(modelScale, modelScale, modelScale),
          position: vector_math.Vector3(0.0, 0.0, 0.0),
          rotation: vector_math.Vector4(1.0, 0.0, 0.0, 0.0),
        );

        bool didAddNodeToAnchor =
            await arObjectManager.addNode(newNode, planeAnchor: newAnchor) ??
                false;

        if (didAddNodeToAnchor) {
          setState(() {
            nodes.add(newNode);
          });
        } else {
          arSessionManager.onError("Adding Node to Anchor failed");
        }
      } else {
        arSessionManager.onError("Adding Anchor failed");
      }
    }
  }

  onPanStarted(String nodeName) {
    print("Started panning node $nodeName");
  }

  onPanChanged(String nodeName) {
    print("Continued panning node $nodeName");
  }

  onPanEnded(String nodeName, Matrix4 newTransform) {
    print("Ended panning node $nodeName");
    final pannedNode = nodes.firstWhere((element) => element.name == nodeName);
  }

  onRotationStarted(String nodeName) {
    print("Started rotating node $nodeName");
  }

  onRotationChanged(String nodeName) {
    print("Continued rotating node $nodeName");
  }

  onRotationEnded(String nodeName, Matrix4 newTransform) {
    print("Ended rotating node $nodeName");
    final rotatedNode = nodes.firstWhere((element) => element.name == nodeName);
  }
}
