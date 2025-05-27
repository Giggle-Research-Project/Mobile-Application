import 'dart:ui';
import 'package:flutter/material.dart';

class AssessmentCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String duration;
  final String questions;
  final VoidCallback onTap;
  final bool isCompleted;

  const AssessmentCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.duration,
    required this.questions,
    required this.onTap,
    required this.isCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.grey.shade200 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: isCompleted ? null : onTap,
              splashColor: isCompleted ? Colors.transparent : null,
              highlightColor: isCompleted ? Colors.transparent : null,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.grey.withOpacity(0.2)
                                : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_circle : icon,
                            color: isCompleted ? Colors.grey : color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? const Color(0xFF1D1D1F).withOpacity(0.7)
                                      : const Color(0xFF1D1D1F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color(0xFF1D1D1F).withOpacity(
                                    isCompleted ? 0.5 : 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 14),
                                  const SizedBox(width: 4),
                                  Text(duration),
                                  const SizedBox(width: 14),
                                  Icon(Icons.quiz_outlined, size: 14),
                                  const SizedBox(width: 4),
                                  Text(questions),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.arrow_forward_ios,
                          size: isCompleted ? 20 : 16,
                          color: isCompleted
                              ? Colors.green
                              : const Color(0xFF1D1D1F).withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildCompletedLabel(),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Completion overlay (subtle)
        if (isCompleted)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.2, sigmaY: 0.2),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                isCompleted ? const Color(0xFF999999) : const Color(0xFF6E6E73),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isCompleted
                  ? const Color(0xFF999999)
                  : const Color(0xFF6E6E73),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Completed',
        style: TextStyle(
          fontSize: 12,
          color: Colors.green,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
