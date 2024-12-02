import 'package:flutter/material.dart';

class ThemeOption {
  final String name;
  final Color primaryColor;
  final List<Color> gradient;
  final String emoji;

  ThemeOption({
    required this.name,
    required this.primaryColor,
    required this.gradient,
    required this.emoji,
  });
}
