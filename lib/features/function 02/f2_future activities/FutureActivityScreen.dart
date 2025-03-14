import 'package:flutter/material.dart';

// Difficulty Selection Screen
class DyscalculiaActivityScreen extends StatelessWidget {
  const DyscalculiaActivityScreen({Key? key}) : super(key: key);

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
        title: const Text(
          'Select Difficulty Level',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildUserStats(),
                    const SizedBox(height: 30),
                    const Text(
                      'Choose Your Level',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Select a difficulty level that matches your skills',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                delegate: SliverChildListDelegate([
                  _buildDifficultyCard(
                    context: context,
                    title: 'Beginner',
                    icon: Icons.child_care,
                    color: const Color(0xFF4CAF50),
                    description: 'Perfect for starting',
                    level: 1,
                  ),
                  _buildDifficultyCard(
                    context: context,
                    title: 'Easy',
                    icon: Icons.stars_outlined,
                    color: const Color(0xFF2196F3),
                    description: 'Basic challenges',
                    level: 2,
                  ),
                  _buildDifficultyCard(
                    context: context,
                    title: 'Medium',
                    icon: Icons.trending_up,
                    color: const Color(0xFFFF9800),
                    description: 'Intermediate tasks',
                    level: 3,
                  ),
                  _buildDifficultyCard(
                    context: context,
                    title: 'Hard',
                    icon: Icons.psychology,
                    color: const Color(0xFFE91E63),
                    description: 'Advanced challenges',
                    level: 4,
                  ),
                  _buildDifficultyCard(
                    context: context,
                    title: 'Expert',
                    icon: Icons.workspace_premium,
                    color: const Color(0xFF9C27B0),
                    description: 'Master level tasks',
                    level: 5,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6200EA), Color(0xFF3F51B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6200EA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(value: '75%', label: 'Accuracy'),
              _buildStatItem(value: '12', label: 'Activities'),
              _buildStatItem(value: '320', label: 'Points'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
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

  Widget _buildDifficultyCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required int level,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivitiesScreen(
              difficulty: title,
              level: level,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 35),
            ),
            const SizedBox(height: 15),
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
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Icon(
                  Icons.star,
                  size: 12,
                  color: index < level ? color : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Activities Screen
class ActivitiesScreen extends StatelessWidget {
  final String difficulty;
  final int level;

  const ActivitiesScreen({
    Key? key,
    required this.difficulty,
    required this.level,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activities = _getActivitiesByLevel(level);

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
          '$difficulty Activities',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildLevelHeader(level),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _buildActivityCard(
                    context: context,
                    activity: activity,
                    index: index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelHeader(int level) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getLevelColor(level),
            _getLevelColor(level).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getLevelColor(level).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _getLevelIcon(level),
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level $level - $difficulty',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _getLevelDescription(level),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required BuildContext context,
    required Activity activity,
    required int index,
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
                  color: _getLevelColor(level).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  activity.icon,
                  color: _getLevelColor(level),
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      activity.description,
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
                '${activity.duration} mins',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 20),
              Icon(Icons.bar_chart, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 5),
              Text(
                '${activity.points} points',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Navigate to AR activity
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getLevelColor(level),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF4CAF50);
      case 2:
        return const Color(0xFF2196F3);
      case 3:
        return const Color(0xFFFF9800);
      case 4:
        return const Color(0xFFE91E63);
      case 5:
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(int level) {
    switch (level) {
      case 1:
        return Icons.child_care;
      case 2:
        return Icons.stars_outlined;
      case 3:
        return Icons.trending_up;
      case 4:
        return Icons.psychology;
      case 5:
        return Icons.workspace_premium;
      default:
        return Icons.error;
    }
  }

  String _getLevelDescription(int level) {
    switch (level) {
      case 1:
        return 'Start your journey with basic activities';
      case 2:
        return 'Build your confidence with simple challenges';
      case 3:
        return 'Test your skills with intermediate tasks';
      case 4:
        return 'Challenge yourself with complex problems';
      case 5:
        return 'Master level activities for experts';
      default:
        return 'Unknown level';
    }
  }

  List<Activity> _getActivitiesByLevel(int level) {
    switch (level) {
      case 1:
        return [
          Activity(
            title: 'Basic Counting',
            description: 'Count objects from 1 to 3',
            duration: 5,
            points: 50,
            icon: Icons.looks_one,
          ),
          Activity(
            title: 'Number Recognition',
            description: 'Identify numbers 1-5',
            duration: 7,
            points: 75,
            icon: Icons.filter_1,
          ),
          Activity(
            title: 'Simple Matching',
            description: 'Match similar objects',
            duration: 6,
            points: 60,
            icon: Icons.compare_arrows,
          ),
        ];
      case 2:
        return [
          Activity(
            title: 'Extended Counting',
            description: 'Count objects from 1 to 5',
            duration: 8,
            points: 100,
            icon: Icons.looks_two,
          ),
          Activity(
            title: 'Basic Addition',
            description: 'Add numbers up to 5',
            duration: 10,
            points: 120,
            icon: Icons.add_circle_outline,
          ),
          Activity(
            title: 'Pattern Recognition',
            description: 'Identify simple patterns',
            duration: 9,
            points: 110,
            icon: Icons.grid_on,
          ),
        ];
      case 3:
        return [
          Activity(
            title: 'Advanced Counting',
            description: 'Count objects from 1 to 10',
            duration: 12,
            points: 150,
            icon: Icons.looks_3,
          ),
          Activity(
            title: 'Subtraction Basics',
            description: 'Subtract numbers up to 10',
            duration: 15,
            points: 180,
            icon: Icons.remove_circle_outline,
          ),
          Activity(
            title: 'Shape Sorting',
            description: 'Sort objects by shape and size',
            duration: 13,
            points: 160,
            icon: Icons.category,
          ),
        ];
      case 4:
        return [
          Activity(
            title: 'Complex Operations',
            description: 'Mixed addition and subtraction',
            duration: 18,
            points: 200,
            icon: Icons.looks_4,
          ),
          Activity(
            title: 'Number Sequences',
            description: 'Complete number patterns',
            duration: 20,
            points: 220,
            icon: Icons.linear_scale,
          ),
          Activity(
            title: 'Problem Solving',
            description: 'Solve word problems',
            duration: 17,
            points: 210,
            icon: Icons.psychology,
          ),
        ];
      case 5:
        return [
          Activity(
            title: 'Master Challenge',
            description: 'Complex mathematical operations',
            duration: 25,
            points: 300,
            icon: Icons.workspace_premium,
          ),
          Activity(
            title: 'Speed Math',
            description: 'Quick calculations under time',
            duration: 22,
            points: 280,
            icon: Icons.speed,
          ),
          Activity(
            title: 'Logic Puzzles',
            description: 'Advanced problem solving',
            duration: 23,
            points: 290,
            icon: Icons.extension,
          ),
        ];
      default:
        return [];
    }
  }
}

class Activity {
  final String title;
  final String description;
  final int duration;
  final int points;
  final IconData icon;

  Activity({
    required this.title,
    required this.description,
    required this.duration,
    required this.points,
    required this.icon,
  });
}
