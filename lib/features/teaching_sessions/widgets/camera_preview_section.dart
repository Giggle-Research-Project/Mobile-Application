import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewSection extends StatelessWidget {
  final CameraController? _cameraController;
  final double _concentrationScore;
  final String _emotionStatus;

  const CameraPreviewSection({
    Key? key,
    required CameraController? cameraController,
    required double concentrationScore,
    required String emotionStatus,
  })  : _cameraController = cameraController,
        _concentrationScore = concentrationScore,
        _emotionStatus = emotionStatus,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildCameraPreviewSection();
  }

  Widget _buildCameraPreviewSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 100,
              width: 100,
              child: CameraPreview(_cameraController!),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus Score: ${(_concentrationScore * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current Emotion: $_emotionStatus',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep your eyes on the video to maintain focus',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF1D1D1F).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
