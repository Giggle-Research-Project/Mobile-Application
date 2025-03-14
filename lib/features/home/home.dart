import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:giggle/core/providers/theme_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final String username = "Praveen";
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDashboard() => Navigator.of(context).pushNamed('/dashboard');
  void _navigateToThemeSelection() => Navigator.pushNamed(context, '/theme');
  void _navigateToWelcome() => Navigator.pushNamed(context, '/guide');

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider).valueOrNull ??
        const AppTheme(primaryColor: Color(0xFF4F46E5));
    final themeColor = themeData.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Stack(
        children: [
          _buildBackgroundPattern(themeColor),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        MathHeroSection(themeColor: themeColor),
                        const SizedBox(height: 25),
                        _buildRecentActivity(themeColor),
                        const SizedBox(height: 25),
                        DetailedSubjectCard(
                          mathSubject: getMathSubject(themeColor),
                        ),
                        const SizedBox(height: 25),
                        QuickActions(
                          navigateToDashboard: _navigateToDashboard,
                          navigateToThemeSelection: _navigateToThemeSelection,
                          navigateToWelcome: _navigateToWelcome,
                          themeColor: themeColor,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPattern(Color themeColor) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 15,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.03),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See All',
                  style: TextStyle(color: themeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildActivityItem(
            icon: Icons.timer,
            title: 'Time spent learning',
            subtitle: '2.5 hours this week',
            color: themeColor,
          ),
          const SizedBox(height: 15),
          _buildActivityItem(
            icon: Icons.star,
            title: 'Problems solved',
            subtitle: '24 problems this week',
            color: themeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF1D1D1F).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $username',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to learn something new?',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF1D1D1F).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  ProfileIcon(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> getMathSubject(Color themeColor) {
    return {
      'title': 'Mathematics',
      'subtitle': 'Advanced Algebra',
      'icon': Icons.functions,
      'color': themeColor,
      'progress': 0.75,
      'details': [
        'Linear Equations',
        'Quadratic Functions',
        'Polynomials',
        'Complex Numbers',
        'Matrices',
      ],
    };
  }
}

class MathHeroSection extends StatelessWidget {
  final Color themeColor;

  const MathHeroSection({Key? key, required this.themeColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor,
            themeColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.calculate,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Math Journey',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continue your learning adventure',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('Continue Learning'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActions extends StatelessWidget {
  final VoidCallback navigateToDashboard;
  final VoidCallback navigateToThemeSelection;
  final VoidCallback navigateToWelcome;
  final Color themeColor;

  const QuickActions({
    Key? key,
    required this.navigateToDashboard,
    required this.navigateToThemeSelection,
    required this.navigateToWelcome,
    required this.themeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              QuickActionButton(
                label: 'Dashboard',
                icon: Icons.dashboard_outlined,
                color: themeColor,
                onPressed: navigateToDashboard,
              ),
              QuickActionButton(
                label: 'Themes',
                icon: Icons.palette_outlined,
                color: themeColor,
                onPressed: navigateToThemeSelection,
              ),
              QuickActionButton(
                label: 'Get Started',
                icon: Icons.play_arrow_outlined,
                color: themeColor,
                onPressed: navigateToWelcome,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const QuickActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: const Icon(
              Icons.person,
              size: 32,
              color: Color(0xFF1D1D1F),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF30D158),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Constants
final Map<String, dynamic> kMathSubject = {
  'title': 'Mathematics',
  'subtitle': 'Advanced Algebra',
  'icon': Icons.functions,
  'color': const Color(0xFF5E5CE6),
  'progress': 0.75,
  'details': [
    'Linear Equations',
    'Quadratic Functions',
    'Polynomials',
    'Complex Numbers',
    'Matrices',
  ],
};

class DetailedSubjectCard extends StatelessWidget {
  final Map<String, dynamic> mathSubject;

  const DetailedSubjectCard({required this.mathSubject});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _buildBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _buildDetails(),
        ],
      ),
    );
  }

  BoxDecoration _buildBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        children: [
          SubjectIcon(mathSubject: mathSubject),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mathSubject['title'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mathSubject['subtitle'],
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF1D1D1F).withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                ProgressBar(
                  progress: mathSubject['progress'],
                  color: mathSubject['color'],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(mathSubject['progress'] * 100).toInt()}% Complete',
                  style: TextStyle(
                    fontSize: 14,
                    color: mathSubject['color'],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Focus',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _buildDetailItems(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetailItems() {
    return mathSubject['details'].map<Widget>((detail) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: mathSubject['color'].withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          detail,
          style: TextStyle(
            color: mathSubject['color'],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList();
  }
}

class ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  const ProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SubjectIcon extends StatelessWidget {
  final Map<String, dynamic> mathSubject;

  const SubjectIcon({required this.mathSubject});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: mathSubject['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Icon(
          mathSubject['icon'],
          size: 40,
          color: mathSubject['color'],
        ),
      ),
    );
  }
}
