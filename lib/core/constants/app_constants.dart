import 'package:flutter/material.dart';
import 'package:giggle/config/env_config.dart';

final String mlIP = EnvConfig.mlServerIP;

class AppConstants {
  static final List<Map<String, dynamic>> mathOperations = [
    {
      'title': 'Addition',
      'icon': Icons.add_circle,
      'color': Color(0xFF5E5CE6),
    },
    {
      'title': 'Subtraction',
      'icon': Icons.remove_circle,
      'color': Color(0xFF30D158),
    },
    {
      'title': 'Multiplication',
      'icon': Icons.close,
      'color': Color(0xFFFF9F0A),
    },
    {
      'title': 'Division',
      'icon': Icons.difference,
      'color': Color(0xFFFF375F),
    },
  ];

  static const List<String> dyscalculiaTypes = [
    'Procedural Dyscalculia',
    'Semantic Dyscalculia',
    'Verbal Dyscalculia',
  ];
}
