import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildFeaturedChallengeCard();
  }

  Widget _buildFeaturedChallengeCard() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E5CE6), Color(0xFF9891FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.explore,
              size: 180,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeaturedChallengeLabel(),
                const SizedBox(height: 12),
                const Text(
                  'Space Explorer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Learn about planets and stars',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                _buildStartAdventureButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedChallengeLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Featured Challenge',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStartAdventureButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5E5CE6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Start Adventure',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
