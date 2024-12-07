import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme;
  final String _themePreferenceKey = 'selected_theme';

  ThemeProvider() : _currentTheme = defaultTheme;

  static final ThemeData defaultTheme = ThemeData(
    primaryColor: const Color(0xFF4F46E5),
    scaffoldBackgroundColor: const Color(0xFFF5F5F7),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      background: const Color(0xFFF5F5F7),
    ),
  );

  ThemeData get currentTheme => _currentTheme;

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColorHex = prefs.getInt(_themePreferenceKey);
    if (savedColorHex != null) {
      final color = Color(savedColorHex);
      updateTheme(color);
    }
  }

  Future<void> updateTheme(Color primaryColor) async {
    _currentTheme = ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        background: const Color(0xFFF5F5F7),
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, primaryColor.value);
    notifyListeners();
  }
}
