import 'package:flutter/material.dart';
import 'package:giggle/features/monster_guide/monster_guide.dart';

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
