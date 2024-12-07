import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:giggle/core/widgets/bottom_navbar.dart';
import 'package:giggle/features/function%2002/semantic_section.dart';
import 'package:giggle/features/function%2003/procedural_section.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            _buildMainContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: Colors.black.withOpacity(0.8),
          size: 24,
        ),
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(),
          ),
        ),
      ),
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Dyscalculia Lessons',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 4),
              )
            ],
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Learning Path',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            _buildDyscalculiaLearningPaths(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDyscalculiaLearningPaths(BuildContext context) {
    final learningPaths = [
      {
        'title': 'Semantic Dyscalculia',
        'description':
            'Understand the true meaning of numbers and mathematical concepts through visual and conceptual learning.',
        'color': const Color(0xFF30D158),
        'illustration': 'assets/images/semantic_dyscalculia_icon.png',
        'screen': const CameraLessonScreen(),
      },
      {
        'title': 'Procedural Dyscalculia',
        'description':
            'Learn step-by-step problem-solving techniques and mathematical procedures with guided support.',
        'color': const Color(0xFF5E5CE6),
        'illustration': 'assets/images/procedural_dyscalculia_icon.png',
        'screen': const VideoLessonScreen(
          videoUrl: 'assets/videos/procedural_dyscalculia.mp4',
        ),
      },
      {
        'title': 'Verbal Dyscalculia',
        'description':
            'Improve mathematical language comprehension and communication skills through interactive lessons.',
        'color': const Color(0xFFFF9500),
        'illustration': 'assets/images/verbal_dyscalculia_icon.png',
        'screen': const VideoLessonScreen(
          videoUrl: '',
        ),
      },
    ];

    return Column(
      children: learningPaths.map((path) {
        return _buildLearningPathCard(
          context,
          title: path['title'] as String,
          description: path['description'] as String,
          color: path['color'] as Color,
          illustration: path['illustration'] as String,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => path['screen'] as Widget,
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildLearningPathCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
    required String illustration,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildIllustrationContainer(color, illustration),
                const SizedBox(width: 20),
                _buildCardContent(title, description),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustrationContainer(Color color, String illustration) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Image.asset(
          illustration,
          width: 50,
          height: 50,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCardContent(String title, String description) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.5),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
