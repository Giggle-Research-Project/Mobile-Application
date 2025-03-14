import 'package:flutter/material.dart';
import 'package:giggle/features/teaching_sessions/widgets/camera_preview_section.dart';
import 'package:giggle/features/teaching_sessions/widgets/voice_emotion_detector.dart';

class ConcentrationMonitor extends StatelessWidget {
  final Color statusColor;
  final String concentrationStatus;
  final double concentrationScore;
  final bool isCameraInitialized;
  final dynamic cameraController;
  final String emotionStatus;
  final Function(String) onEmotionDetected;

  const ConcentrationMonitor({
    Key? key,
    required this.statusColor,
    required this.concentrationStatus,
    required this.concentrationScore,
    required this.isCameraInitialized,
    required this.cameraController,
    required this.emotionStatus,
    required this.onEmotionDetected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Learning Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      concentrationStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: concentrationScore,
              backgroundColor: Colors.grey.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          if (isCameraInitialized && cameraController != null)
            CameraPreviewSection(
              cameraController: cameraController,
              concentrationScore: concentrationScore,
              emotionStatus: emotionStatus,
            ),
          const SizedBox(height: 20),
          VoiceEmotionDetector(
            onEmotionDetected: onEmotionDetected,
          ),
        ],
      ),
    );
  }
}
