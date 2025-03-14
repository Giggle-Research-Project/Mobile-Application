import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

// Persistent provider for the shared preferences instance
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(SharedPreferencesRef ref) async {
  return await SharedPreferences.getInstance();
}

// Model class to hold theme data - renamed to AppTheme to avoid conflict
class AppTheme {
  final Color primaryColor;

  const AppTheme({required this.primaryColor});

  // Get a lighter shade of the primary color
  Color get lightShade => Color.lerp(primaryColor, Colors.white, 0.7)!;

  // Get a darker shade of the primary color
  Color get darkShade => Color.lerp(primaryColor, Colors.black, 0.2)!;

  // Get the complementary color
  Color get complementaryColor {
    final hslColor = HSLColor.fromColor(primaryColor);
    return HSLColor.fromAHSL(
      hslColor.alpha,
      (hslColor.hue + 180) % 360,
      hslColor.saturation,
      hslColor.lightness,
    ).toColor();
  }

  AppTheme copyWith({
    Color? primaryColor,
  }) {
    return AppTheme(
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}

@Riverpod(keepAlive: true)
class Theme extends _$Theme {
  static const String _themeColorKey = 'theme_color';

  @override
  Future<AppTheme> build() async {
    return _loadThemeData();
  }

  Future<AppTheme> _loadThemeData() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final colorValue = prefs.getInt(_themeColorKey);

    return AppTheme(
      primaryColor:
          colorValue != null ? Color(colorValue) : const Color(0xFF4F46E5),
    );
  }

  Future<void> updateTheme(Color newColor) async {
    state = const AsyncValue.loading();

    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setInt(_themeColorKey, newColor.value);

      state = AsyncValue.data(AppTheme(primaryColor: newColor));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
