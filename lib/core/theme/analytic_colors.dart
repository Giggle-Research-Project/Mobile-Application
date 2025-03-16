import 'package:flutter/material.dart';

final Map<String, Color> emotionColors = {
  'happy': const Color(0xFF30D158), // Green
  'neutral': const Color(0xFFFFD60A), // Yellow
  'confused': const Color(0xFFFF9F0A), // Orange
  'frustrated': const Color(0xFFFF453A), // Red
  'anxious': const Color(0xFFFF375F), // Pink
  'joy': const Color(0xFF30D158), // Green
  'worried': const Color(0xFFFF375F), // Pink
  'angry': const Color(0xFFFF453A), // Red
};

Color getConcentrationColor(double score) {
  if (score >= 80) return const Color(0xFF30D158); // Green
  if (score >= 60) return const Color(0xFFFFD60A); // Yellow
  if (score >= 40) return const Color(0xFFFF9F0A); // Orange
  return const Color(0xFFFF453A); // Red
}

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'focused':
      return const Color(0xFF30D158); // Green
    case 'engaged':
      return const Color(0xFF5E5CE6); // Purple
    case 'distracted':
      return const Color(0xFFFFD60A); // Yellow
    case 'confused':
      return const Color(0xFFFF9F0A); // Orange
    case 'frustrated':
      return const Color(0xFFFF453A); // Red
    default:
      return const Color(0xFF8E8E93); // Gray
  }
}
