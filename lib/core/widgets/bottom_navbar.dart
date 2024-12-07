import 'package:flutter/material.dart';
import 'package:giggle/features/home/home.dart';
import 'package:giggle/features/overall_performance/overall_performance.dart';
import 'package:giggle/features/performance_analysis/performance_analysis.dart';
import 'package:giggle/features/personalized_cources/personalized_cources.dart';
import 'package:giggle/features/test_selection/test_selection_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of screens
  final List<Widget> _screens = [
    const HomeScreen(),
    const TestSelectionScreen(),
    const PersonalizedCourses(),
    const OverallPerformanceScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: NavigationBar(
              height: 65,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: Colors.transparent,
              indicatorColor: const Color(0xFF6C63FF).withOpacity(0.2),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon:
                      Icon(Icons.home_rounded, color: Color(0xFF6C63FF)),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore, color: Color(0xFF6C63FF)),
                  label: 'Explore',
                ),
                NavigationDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  selectedIcon:
                      Icon(Icons.emoji_events, color: Color(0xFF6C63FF)),
                  label: 'Awards',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: Color(0xFF6C63FF)),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
