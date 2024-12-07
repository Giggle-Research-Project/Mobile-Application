import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:giggle/core/widgets/bottom_navbar.dart';
import 'package:giggle/features/personalized_cources/personalized_cources.dart';

class PerformanceResultScreen extends StatefulWidget {
  const PerformanceResultScreen({Key? key}) : super(key: key);

  @override
  _PerformanceResultScreenState createState() =>
      _PerformanceResultScreenState();
}

class _PerformanceResultScreenState extends State<PerformanceResultScreen> {
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    // Delay showing details for animation
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _showDetails = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Test Results',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1D1D1F)),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainScreen(),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildScoreCard(),
            if (_showDetails) ...[
              _buildPerformanceBreakdown(),
              _buildStrengthsWeaknesses(),
              _buildRecommendations(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildScoreRing(),
          const SizedBox(height: 24),
          const Text(
            'Great Performance!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ve shown strong understanding in multiple areas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 24),
          _buildQuickStats(),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildScoreRing() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CircularProgressIndicator(
            value: 0.85, // Example score
            strokeWidth: 12,
            backgroundColor: const Color(0xFFE5E5EA),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '85%',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Text(
              'Score',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF1D1D1F).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    ).animate().scale(delay: 400.ms);
  }

  Widget _buildQuickStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          icon: Icons.timer_outlined,
          label: 'Time Taken',
          value: '22m',
          color: const Color(0xFF5856D6),
        ),
        _buildStatItem(
          icon: Icons.check_circle_outline,
          label: 'Correct',
          value: '17/20',
          color: const Color(0xFF34C759),
        ),
        _buildStatItem(
          icon: Icons.trending_up,
          label: 'Percentile',
          value: '92nd',
          color: const Color(0xFFFF9500),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6E6E73),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBreakdown() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 24),
          _buildPerformanceBar(
            'Logical Reasoning',
            0.9,
            const Color(0xFF5E5CE6),
          ),
          const SizedBox(height: 16),
          _buildPerformanceBar(
            'Problem Solving',
            0.85,
            const Color(0xFF34C759),
          ),
          const SizedBox(height: 16),
          _buildPerformanceBar(
            'Pattern Recognition',
            0.75,
            const Color(0xFFFF9500),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX();
  }

  Widget _buildPerformanceBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildStrengthsWeaknesses() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Strengths & Areas for Improvement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 24),
          _buildStrengthItem(
            Icons.star,
            'Strong analytical thinking',
            const Color(0xFF34C759),
          ),
          _buildStrengthItem(
            Icons.trending_up,
            'Excellent problem-solving speed',
            const Color(0xFF5E5CE6),
          ),
          _buildStrengthItem(
            Icons.warning_amber_rounded,
            'Pattern recognition needs attention',
            const Color(0xFFFF3B30),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideX();
  }

  Widget _buildStrengthItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommendations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 24),
          _buildRecommendationCard(
            'Practice Pattern Recognition',
            'Focus on identifying complex patterns in sequences and shapes',
            Icons.auto_graph,
            const Color(0xFF5E5CE6),
            () {
              // Implement onTap functionality
            },
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            'Personalized Courses',
            'Enroll in courses tailored to your strengths and weaknesses',
            Icons.school_outlined,
            const Color(0xFFFF9500),
            () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PersonalizedCourses(),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideX();
  }

  Widget _buildRecommendationCard(
    String title,
    String description,
    IconData icon,
    Color color,
    void Function() onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.withOpacity(0.8),
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
