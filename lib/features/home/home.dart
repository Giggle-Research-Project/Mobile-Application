import 'package:flutter/material.dart';
import 'package:giggle/features/home/widgets/feature_card.dart';
import 'package:giggle/features/home/widgets/quick_action_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String username = "Praveen";

  final Map<String, dynamic> mathSubject = {
    'title': 'Math',
    'subtitle': 'Addition',
    'progress': 0.7,
    'color': const Color(0xFF5E5CE6),
    'icon': Icons.calculate,
    'details': [
      'Addition',
      'Subtraction',
      'Division',
      'Multiplication',
    ]
  };

  void _navigateToDashboard() => Navigator.of(context).pushNamed('/dashboard');
  void _navigateToThemeSelection() => Navigator.pushNamed(context, '/theme');
  void _navigateToWelcome() => Navigator.pushNamed(context, '/guide');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMathHeroSection(),
                  const SizedBox(height: 20),
                  _buildDetailedSubjectCard(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMathHeroSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5E5CE6),
            const Color(0xFF5E5CE6).withOpacity(0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E5CE6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.calculate,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Math Journey',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore numbers, patterns, and problem-solving',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
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

  Widget _buildDetailedSubjectCard() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildSubjectIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mathSubject['title'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mathSubject['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF1D1D1F).withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProgressBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learning Focus',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: mathSubject['details'].map<Widget>((detail) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: mathSubject['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        detail,
                        style: TextStyle(
                          color: mathSubject['color'],
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: mathSubject['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildProgressBar() {
    return Stack(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        FractionallySizedBox(
          widthFactor: mathSubject['progress'],
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: mathSubject['color'],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      backgroundColor: const Color(0xFFF2F4F8),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hello, $username',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              _buildProfileIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIcon() {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: const Icon(
          Icons.person,
          size: 40,
          color: Color(0xFF1D1D1F),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
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
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              QuickActionButton(
                label: 'Dashboard',
                icon: Icons.dashboard_outlined,
                color: const Color(0xFF5E5CE6),
                onPressed: _navigateToDashboard,
              ),
              QuickActionButton(
                label: 'Themes',
                icon: Icons.palette_outlined,
                color: const Color(0xFF30D158),
                onPressed: _navigateToThemeSelection,
              ),
              QuickActionButton(
                label: 'Get Started',
                icon: Icons.play_arrow_outlined,
                color: const Color(0xFFFF9F0A),
                onPressed: _navigateToWelcome,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
