import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/models/user_model.dart';
import 'package:giggle/core/providers/auth_provider.dart';
import 'package:giggle/features/auth/profile/profile.dart';
import 'package:giggle/features/future_activity_screens/future_courses.dart';
import 'package:giggle/features/index.dart';
import 'package:giggle/features/skill_assessment/skill_assessment.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  bool _isFutureCoursesUnlocked = false;

  void _onItemTapped(int index) {
    // Check if future courses is locked and the user is trying to access it
    if (index == 2 && !_isFutureCoursesUnlocked) {
      // Show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Complete the Addition Verbal Dyscalculia session to unlock Future Courses'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // Check if the future courses should be unlocked
  Future<void> _checkFutureCoursesUnlock(String userId) async {
    try {
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(userId)
          .collection('Addition')
          .doc('Verbal Dyscalculia')
          .collection('solo_sessions')
          .doc('progress')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final bool isCompleted = data['completed'] ?? false;

        setState(() {
          _isFutureCoursesUnlocked = isCompleted;
        });
      }
    } catch (e) {
      print('Error checking future courses unlock status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (AppUser? user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink();
        }

        // Check the future courses unlock status
        _checkFutureCoursesUnlock(user.uid);

        final List<Widget> screens = [
          TestSelectionScreen(
            userId: user.uid,
          ),
          DashBoardScreen(),
          FutureCourses(userId: user.uid),
          const ProfileScreen(),
        ];

        return Scaffold(
          body: screens[_selectedIndex],
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
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon:
                          Icon(Icons.home_rounded, color: Color(0xFF6C63FF)),
                      label: 'Home',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon:
                          Icon(Icons.dashboard, color: Color(0xFF6C63FF)),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.school_outlined,
                        color: _isFutureCoursesUnlocked ? null : Colors.grey,
                      ),
                      selectedIcon: Icon(
                        Icons.school,
                        color: const Color(0xFF6C63FF),
                      ),
                      label: 'Courses',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon:
                          Icon(Icons.person, color: Color(0xFF6C63FF)),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error: ${error.toString()}'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // We'll check unlock status in the build method when we have the user
  }
}
