import 'package:flutter/material.dart';
import 'package:giggle/core/providers/theme_provider.dart';
import 'package:giggle/core/widgets/bottom_navbar.dart';
import 'package:giggle/features/dashboard/dashboard.dart';
import 'package:giggle/features/home/home.dart';
import 'package:giggle/features/monster_guide/monster_guide.dart';
import 'package:giggle/features/personalized_cources/personalized_cources.dart';
import 'package:giggle/features/theme_selection/theme_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  await themeProvider.loadSavedTheme();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: FutureBuilder<bool>(
            future: _checkFirstRun(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final isFirstRun = snapshot.data ?? true;
              if (isFirstRun) {
                return const ThemeSelectionScreen(isInitialSelection: true);
              }

              return const MainScreen();
            },
          ),
          routes: {
            '/main': (context) => const MainScreen(),
            '/home': (context) => const HomeScreen(),
            '/theme': (context) => const ThemeSelectionScreen(),
            '/guide': (context) => const MonsterGuideScreen(),
            '/lessons': (context) => const PersonalizedCourses(),
            '/dashboard': (context) => const DashboardScreen(),
          },
        );
      },
    );
  }

  Future<bool> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('is_first_run') ?? true;
    if (isFirstRun) {
      await prefs.setBool('is_first_run', false);
    }
    return isFirstRun;
  }
}
