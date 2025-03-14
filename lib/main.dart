import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:giggle/core/providers/auth_provider.dart';
import 'package:giggle/core/providers/theme_provider.dart';
import 'package:giggle/core/widgets/bottom_navbar.dart';

import 'features/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  try {
    await dotenv.load(fileName: 'lib/config/.env');
    print('Dotenv loaded successfully: ${dotenv.env}');
  } catch (e) {
    print('Failed to load .env file: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeProvider);

    return themeAsync.when(
      data: (themeData) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Survey Camp',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeData.primaryColor,
            ),
            useMaterial3: true,
          ),
          initialRoute: '/splash',
          home: const AuthWrapper(),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginPage(),
            '/main': (context) => const MainScreen(),
            '/home': (context) => const AuthWrapper(),
            '/theme': (context) => const ThemeSelectionScreen(),
            '/guide': (context) => const MonsterGuideScreen(),
            '/dashboard': (context) => const DashboardScreen(),
          },
        );
      },
      loading: () => MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error loading theme: $error'),
          ),
        ),
      ),
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

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }
        return const MainScreen();
      },
      loading: () => const SplashScreen(),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
