import 'package:flutter/material.dart';
import 'package:giggle/features/function%2003/f3_future%20activities/FutureActivityScreen.dart';

class DifficultyLevelScreen extends StatelessWidget {
  const DifficultyLevelScreen({Key? key}) : super(key: key);

  Widget _buildLevelCard({
    required BuildContext context,
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required int activitiesCount,
    required String estimatedTime,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProceduralDyscalculiaScreen(
                  difficultyLevel: title,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: Colors.white, size: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$activitiesCount Activities',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: Colors.white.withOpacity(0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      estimatedTime,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
        title: const Text(
          'Choose Difficulty',
          style: TextStyle(
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
            const Text(
              'Select Your Level',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose a difficulty level that matches your comfort. You can always change it later.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            _buildLevelCard(
              context: context,
              title: 'Beginner',
              description: 'Perfect for those just starting their journey',
              color: Colors.green,
              icon: Icons.star_border,
              activitiesCount: 5,
              estimatedTime: '15-20 mins',
            ),
            _buildLevelCard(
              context: context,
              title: 'Elementary',
              description: 'Basic concepts with guided assistance',
              color: Colors.blue,
              icon: Icons.star_half,
              activitiesCount: 7,
              estimatedTime: '20-25 mins',
            ),
            _buildLevelCard(
              context: context,
              title: 'Intermediate',
              description: 'More challenging exercises with less guidance',
              color: Colors.orange,
              icon: Icons.star,
              activitiesCount: 8,
              estimatedTime: '25-30 mins',
            ),
            _buildLevelCard(
              context: context,
              title: 'Advanced',
              description: 'Complex problems for experienced learners',
              color: Colors.purple,
              icon: Icons.stars,
              activitiesCount: 10,
              estimatedTime: '30-35 mins',
            ),
            _buildLevelCard(
              context: context,
              title: 'Expert',
              description: 'Master-level challenges for complete mastery',
              color: Colors.red,
              icon: Icons.workspace_premium,
              activitiesCount: 12,
              estimatedTime: '35-40 mins',
            ),
          ],
        ),
      ),
    );
  }
}
