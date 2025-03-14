import 'dart:ui';

import 'package:flutter/material.dart';

class FeaturedAssessmentCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String duration;
  final String questions;
  final Color themeColor;
  final bool isCompleted;

  const FeaturedAssessmentCard({
    Key? key,
    required this.onTap,
    required this.duration,
    required this.questions,
    required this.themeColor,
    required this.isCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main card container
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCompleted
                  ? [Colors.grey.shade600, Colors.grey.shade400]
                  : [themeColor, themeColor.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: isCompleted ? null : onTap,
              splashColor: isCompleted ? Colors.transparent : null,
              highlightColor: isCompleted ? Colors.transparent : null,
              child: Stack(
                children: [
                  // Background icon
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.psychology,
                      size: 180,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  // Card content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(isCompleted ? 'Completed' : 'Recommended'),
                        const SizedBox(height: 12),
                        const Text(
                          'Student Skill Assessment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Evaluate your current knowledge and abilities',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            _buildInfoChipWhite(Icons.timer_outlined, duration),
                            const SizedBox(width: 12),
                            _buildInfoChipWhite(Icons.quiz_outlined, questions),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Completion overlay
        if (isCompleted)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Container(
                  color: Colors.black.withOpacity(0.05),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Assessment Completed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChipWhite(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
