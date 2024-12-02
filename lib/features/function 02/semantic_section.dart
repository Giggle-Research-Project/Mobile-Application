import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:giggle/features/function%2002/interactive_session.dart';

// Camera Lesson Screen
class CameraLessonScreen extends StatefulWidget {
  const CameraLessonScreen({Key? key}) : super(key: key);

  @override
  _CameraLessonScreenState createState() => _CameraLessonScreenState();
}

class _CameraLessonScreenState extends State<CameraLessonScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            _cameraController != null && _cameraController!.value.isInitialized
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator()),

            // Overlay with Start Interactive Session Button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InteractiveSessionScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Start Interactive Session',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
