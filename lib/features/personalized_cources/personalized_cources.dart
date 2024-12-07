import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:giggle/features/lessons/lessons.dart';

class PersonalizedCourses extends StatefulWidget {
  const PersonalizedCourses({Key? key}) : super(key: key);

  @override
  _PersonalizedCoursesState createState() => _PersonalizedCoursesState();
}

class _PersonalizedCoursesState extends State<PersonalizedCourses> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom AppBar with Modern Design
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Math Learning Paths',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
            ),

            // Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Playful Intro Text
                    Text(
                      'Your Math Adventure Awaits!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Math Operations Grid
                    _buildMathOperationsGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMathOperationsGrid() {
    final mathOperations = [
      {
        'title': 'Addition',
        'subtitle': 'Learn to add numbers like a math wizard!',
        'icon': Icons.add_circle_outline,
        'color': const Color(0xFF30D158),
        'progress': 0.7,
      },
      {
        'title': 'Subtraction',
        'subtitle': 'Subtract with speed and precision',
        'icon': Icons.remove_circle_outline,
        'color': const Color(0xFF5E5CE6),
        'progress': 0.5,
      },
      {
        'title': 'Multiplication',
        'subtitle': 'Multiply your math superpowers',
        'icon': Icons.close,
        'color': const Color(0xFFFF9500),
        'progress': 0.3,
      },
      {
        'title': 'Division',
        'subtitle': 'Master the art of fair sharing',
        'icon': Icons.pie_chart_outline,
        'color': const Color(0xFFFF3B30),
        'progress': 0.2,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: mathOperations.length,
      itemBuilder: (context, index) {
        final operation = mathOperations[index];
        return _buildMathOperationCard(
          title: operation['title'] as String,
          subtitle: operation['subtitle'] as String,
          icon: operation['icon'] as IconData,
          color: operation['color'] as Color,
          progress: operation['progress'] as double,
        );
      },
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildMathOperationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // TODO: Navigate to specific math operation screen
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and Start Learning
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => LessonsScreen(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      Text(
                        'Start',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Title and Subtitle
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Progress Indicator
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
