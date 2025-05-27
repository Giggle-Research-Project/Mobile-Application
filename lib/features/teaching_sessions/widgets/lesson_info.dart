import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LessonInfo extends StatelessWidget {
  final String dyscalculiaType;
  final String courseName;
  final double concentrationScore;
  final VideoPlayerController? videoController;

  const LessonInfo({
    Key? key,
    required this.dyscalculiaType,
    required this.courseName,
    required this.concentrationScore,
    required this.videoController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildLessonInfo();
  }

  Widget _buildLessonInfo() {
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
          const Text(
            'Lesson Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.category, 'Type', dyscalculiaType),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.book, 'Course', courseName),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.access_time, 'Duration', _formatVideoDuration()),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.show_chart, 'Average Focus',
              '${(concentrationScore * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  String _formatVideoDuration() {
    if (videoController == null || !videoController!.value.isInitialized) {
      return 'Loading...';
    }

    final Duration duration = videoController!.value.duration;
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF5E5CE6),
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            color: const Color(0xFF1D1D1F).withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1D1F),
          ),
        ),
      ],
    );
  }
}
