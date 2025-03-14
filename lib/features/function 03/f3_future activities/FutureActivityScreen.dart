import 'package:flutter/material.dart';
import 'package:giggle/features/function%2003/f3_future%20activities/f3_activity.dart';

class ProceduralDyscalculiaScreen extends StatelessWidget {
  final String difficultyLevel;

  const ProceduralDyscalculiaScreen({
    Key? key,
    required this.difficultyLevel,
  }) : super(key: key);

  Color get levelColor {
    switch (difficultyLevel) {
      case 'Beginner':
        return Colors.green;
      case 'Elementary':
        return Colors.blue;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.purple;
      case 'Expert':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  List<Map<String, dynamic>> get levelActivities {
    switch (difficultyLevel) {
      case 'Beginner':
        return [
          {
            'title': 'Basic Number Recognition',
            'description': 'Learn to identify numbers from 1 to 20',
            'duration': '10 mins',
            'icon': Icons.looks_one,
            'color': Colors.green,
          },
          {
            'title': 'Simple Addition',
            'description': 'Add single-digit numbers with visual aids',
            'duration': '12 mins',
            'icon': Icons.add_circle,
            'color': Colors.green[600],
          },
          {
            'title': 'Number Sequence',
            'description': 'Complete basic number patterns',
            'duration': '8 mins',
            'icon': Icons.repeat,
            'color': Colors.green[700],
          },
        ];
      case 'Elementary':
        return [
          {
            'title': 'Double-Digit Addition',
            'description': 'Add numbers up to 100 step by step',
            'duration': '15 mins',
            'icon': Icons.add_chart,
            'color': Colors.blue,
          },
          {
            'title': 'Simple Subtraction',
            'description': 'Learn basic subtraction with visual guides',
            'duration': '12 mins',
            'icon': Icons.remove_circle,
            'color': Colors.blue[600],
          },
          {
            'title': 'Skip Counting',
            'description': 'Count by 2s, 5s, and 10s',
            'duration': '10 mins',
            'icon': Icons.skip_next,
            'color': Colors.blue[700],
          },
        ];
      case 'Intermediate':
        return [
          {
            'title': 'Mental Math Strategies',
            'description': 'Learn tricks for quick calculations',
            'duration': '15 mins',
            'icon': Icons.psychology,
            'color': Colors.orange,
          },
          {
            'title': 'Mixed Operations',
            'description': 'Solve problems with addition and subtraction',
            'duration': '18 mins',
            'icon': Icons.calculate,
            'color': Colors.orange[600],
          },
          {
            'title': 'Word Problems',
            'description': 'Solve simple word-based math problems',
            'duration': '20 mins',
            'icon': Icons.menu_book,
            'color': Colors.orange[700],
          },
        ];
      case 'Advanced':
        return [
          {
            'title': 'Complex Calculations',
            'description': 'Multi-step math problems with mixed operations',
            'duration': '20 mins',
            'icon': Icons.functions,
            'color': Colors.purple,
          },
          {
            'title': 'Problem Solving',
            'description': 'Advanced word problems with multiple steps',
            'duration': '25 mins',
            'icon': Icons.psychology_outlined,
            'color': Colors.purple[600],
          },
          {
            'title': 'Math Patterns',
            'description': 'Identify and complete complex number patterns',
            'duration': '18 mins',
            'icon': Icons.auto_graph,
            'color': Colors.purple[700],
          },
        ];
      case 'Expert':
        return [
          {
            'title': 'Speed Mathematics',
            'description': 'Quick mental math with time pressure',
            'duration': '25 mins',
            'icon': Icons.speed,
            'color': Colors.red,
          },
          {
            'title': 'Advanced Problem Solving',
            'description': 'Complex multi-step word problems',
            'duration': '30 mins',
            'icon': Icons.extension,
            'color': Colors.red[600],
          },
          {
            'title': 'Mathematical Reasoning',
            'description': 'Logic-based mathematical challenges',
            'duration': '28 mins',
            'icon': Icons.psychology_alt,
            'color': Colors.red[700],
          },
        ];
      default:
        return [];
    }
  }

  Widget _buildProgressItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required String title,
    required String description,
    required String duration,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 5),
              Text(
                duration,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProceduralDyscalculiaHandwritingScreen(
                        activityTitle: title,
                        activityDescription: description,
                      ),
                    ),
                  );
                },
                child: const Text('Start'),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$difficultyLevel Activities',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Progress Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [levelColor.withOpacity(0.8), levelColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$difficultyLevel Progress',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildProgressItem('Activities\nCompleted',
                          '0/${levelActivities.length}'),
                      _buildProgressItem('Average\nAccuracy', '0%'),
                      _buildProgressItem('Time\nSpent', '0m'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Activity Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$difficultyLevel Activities',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${levelActivities.length} Activities',
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Activities List
            ...levelActivities.map((activity) => _buildActivityCard(
                  context,
                  title: activity['title'],
                  description: activity['description'],
                  duration: activity['duration'],
                  icon: activity['icon'],
                  color: activity['color'],
                )),

            // Daily Challenge
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: levelColor.withOpacity(0.3), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars, color: levelColor),
                      const SizedBox(width: 10),
                      const Text(
                        'Daily Challenge',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Complete all ${levelActivities.length} activities today',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: levelColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '0/${levelActivities.length} Completed',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
