import 'package:flutter/material.dart';
import 'package:giggle/core/constants/monster_guide_constants.dart';
import 'package:giggle/core/widgets/header.dart';
import 'package:giggle/features/monster_guide/widgets/feature_content.dart';

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
                  return FeatureContent(
                    feature: feature,
                    bounceAnimation: _bounceAnimation,
                  );
                }).toList(),
              ),
            ),
            Navigation(
              currentFeatureIndex: _currentFeatureIndex,
              tabController: _tabController,
              features: features,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Header(
        title: "Monster Guide", desc: "Learn how to use the app");
  }
}

class TipItem extends StatelessWidget {
  final String tip;
  final Color color;

  const TipItem({required this.tip, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
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
}

class Navigation extends StatelessWidget {
  final int currentFeatureIndex;
  final TabController tabController;
  final List<FeatureGuide> features;

  const Navigation({
    required this.currentFeatureIndex,
    required this.tabController,
    required this.features,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
          if (currentFeatureIndex > 0)
            NavigationButton(
              label: 'Previous',
              icon: Icons.arrow_back_rounded,
              onTap: () {
                tabController.animateTo(currentFeatureIndex - 1);
              },
            )
          else
            const SizedBox(width: 110),
          Row(
            children: List.generate(
              features.length,
              (index) => PageIndicator(
                index: index,
                currentFeatureIndex: currentFeatureIndex,
                color: features[currentFeatureIndex].color,
              ),
            ),
          ),
          if (currentFeatureIndex < features.length - 1)
            NavigationButton(
              label: 'Next',
              icon: Icons.arrow_forward_rounded,
              onTap: () {
                tabController.animateTo(currentFeatureIndex + 1);
              },
              isNext: true,
              color: features[currentFeatureIndex].color,
            )
          else
            NavigationButton(
              label: 'Done',
              icon: Icons.check_rounded,
              onTap: () {
                Navigator.pop(context);
              },
              isNext: true,
              color: features[currentFeatureIndex].color,
            ),
        ],
      ),
    );
  }
}

class NavigationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isNext;
  final Color? color;

  const NavigationButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isNext = false,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isNext ? color : Colors.white,
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
                    color: color!.withOpacity(0.3),
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
}

class PageIndicator extends StatelessWidget {
  final int index;
  final int currentFeatureIndex;
  final Color color;

  const PageIndicator({
    required this.index,
    required this.currentFeatureIndex,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index == currentFeatureIndex ? color : const Color(0xFFE5E7EB),
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
