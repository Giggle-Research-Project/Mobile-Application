import 'package:flutter/material.dart';
import 'package:giggle/features/monster_guide/monster_guide.dart';
import 'package:giggle/features/monster_guide/widgets/feature_card.dart';
import 'package:giggle/features/monster_guide/widgets/tips_card.dart';

class FeatureContent extends StatelessWidget {
  final FeatureGuide feature;
  final Animation<double> bounceAnimation;

  const FeatureContent({
    required this.feature,
    required this.bounceAnimation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            MonsterGuideFeatureCard(
              feature: feature,
              bounceAnimation: bounceAnimation,
            ),
            const SizedBox(height: 30),
            TipsCard(feature: feature),
          ],
        ),
      ),
    );
  }
}
