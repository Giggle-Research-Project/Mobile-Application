import 'package:flutter/material.dart';
import 'package:giggle/features/monster_guide/monster_guide.dart';

class MonsterGuideFeatureCard extends StatelessWidget {
  final FeatureGuide feature;
  final Animation<double> bounceAnimation;

  const MonsterGuideFeatureCard({
    required this.feature,
    required this.bounceAnimation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildBoxDecoration(),
      child: Column(
        children: [
          _buildAnimatedEmoji(),
          const SizedBox(height: 20),
          _buildTitle(),
          const SizedBox(height: 10),
          _buildDescription(),
        ],
      ),
    );
  }

  /// Builds the box decoration for the feature card.
  BoxDecoration _buildBoxDecoration() {
    return BoxDecoration(
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
    );
  }

  /// Builds the animated emoji widget.
  Widget _buildAnimatedEmoji() {
    return AnimatedBuilder(
      animation: bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: bounceAnimation.value,
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
    );
  }

  /// Builds the title widget.
  Widget _buildTitle() {
    return Text(
      feature.title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// Builds the description widget.
  Widget _buildDescription() {
    return Text(
      feature.description,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withOpacity(0.9),
        height: 1.5,
      ),
    );
  }
}
