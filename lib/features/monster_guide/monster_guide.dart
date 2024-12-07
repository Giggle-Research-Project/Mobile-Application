import 'package:flutter/material.dart';

class MonsterGuideScreen extends StatefulWidget {
  const MonsterGuideScreen({super.key});

  @override
  State<MonsterGuideScreen> createState() => _MonsterGuideScreenState();
}

class _MonsterGuideScreenState extends State<MonsterGuideScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
  int _currentFeatureIndex = 0;

  final List<FeatureGuide> features = [
    FeatureGuide(
      title: 'Track Your Progress',
      description:
          'Watch your learning journey with fun progress bars and achievements! The more you learn, the higher your level goes! 🚀',
      emoji: '📊',
      color: const Color(0xFF4F46E5),
      tips: [
        'Check your daily progress',
        'Complete activities to level up',
        'Earn special badges',
        'View your learning statistics',
      ],
    ),
    FeatureGuide(
      title: 'Learn With Games',
      description:
          'Play exciting educational games that make learning super fun! Challenge yourself and earn rewards along the way! 🎮',
      emoji: '🎲',
      color: const Color(0xFF059669),
      tips: [
        'Choose from different subjects',
        'Compete with friends',
        'Unlock new game modes',
        'Collect special power-ups',
      ],
    ),
    FeatureGuide(
      title: 'Get Rewards',
      description:
          'Earn awesome rewards for your hard work! Collect stars, badges, and unlock special features as you progress! ⭐',
      emoji: '🏆',
      color: const Color(0xFFEA580C),
      tips: [
        'Complete daily challenges',
        'Earn bonus points',
        'Unlock special characters',
        'Share achievements with friends',
      ],
    ),
    FeatureGuide(
      title: 'Ask For Help',
      description:
          'Need help? I\'m here to assist you! Tap the monster buddy icon anytime to get help with your learning journey! 🤝',
      emoji: '👾',
      color: const Color(0xFF7C3AED),
      tips: [
        'Get instant help',
        'Find learning resources',
        'Get homework tips',
        'Access video tutorials',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: features.length,
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 65.0,
      ),
    ]).animate(_bounceController);

    _tabController.addListener(() {
      setState(() {
        _currentFeatureIndex = _tabController.index;
      });
    });

    _startBounceAnimation();
  }

  void _startBounceAnimation() {
    _bounceController.repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: features.map((feature) {
                  return _buildFeatureContent(feature);
                }).toList(),
              ),
            ),
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(width: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monster Guide',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'Learn how to use the app',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureContent(FeatureGuide feature) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildFeatureCard(feature),
            const SizedBox(height: 30),
            _buildTipsCard(feature),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(FeatureGuide feature) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            feature.color,
            feature.color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: feature.color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      feature.emoji,
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            feature.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            feature.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(FeatureGuide feature) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Tips',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 15),
          ...feature.tips.map((tip) => _buildTipItem(tip, feature.color)),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.star,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentFeatureIndex > 0)
            _buildNavigationButton(
              'Previous',
              Icons.arrow_back_rounded,
              () {
                _tabController.animateTo(_currentFeatureIndex - 1);
              },
            )
          else
            const SizedBox(width: 110),
          Row(
            children: List.generate(
              features.length,
              (index) => _buildPageIndicator(index),
            ),
          ),
          if (_currentFeatureIndex < features.length - 1)
            _buildNavigationButton(
              'Next',
              Icons.arrow_forward_rounded,
              () {
                _tabController.animateTo(_currentFeatureIndex + 1);
              },
              isNext: true,
            )
          else
            _buildNavigationButton(
              'Done',
              Icons.check_rounded,
              () {
                Navigator.pop(context);
              },
              isNext: true,
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isNext = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isNext ? features[_currentFeatureIndex].color : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: isNext
              ? null
              : Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
          boxShadow: isNext
              ? [
                  BoxShadow(
                    color:
                        features[_currentFeatureIndex].color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            if (!isNext) Icon(icon, color: const Color(0xFF1A1A1A)),
            if (!isNext) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isNext ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            if (isNext) const SizedBox(width: 8),
            if (isNext) Icon(icon, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index == _currentFeatureIndex
            ? features[_currentFeatureIndex].color
            : const Color(0xFFE5E7EB),
      ),
    );
  }
}

class FeatureGuide {
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final List<String> tips;

  FeatureGuide({
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.tips,
  });
}
