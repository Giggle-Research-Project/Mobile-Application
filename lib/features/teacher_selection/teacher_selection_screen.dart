import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:giggle/core/constants/teachers_list_constants.dart';
import 'package:giggle/core/models/teacher_model.dart';
import 'package:giggle/core/providers/theme_provider.dart';
import 'package:giggle/core/widgets/bg_pattern.dart';
import 'package:giggle/core/widgets/next_button.dart';
import 'package:giggle/core/widgets/sub_page_header.widget.dart';
import 'package:giggle/features/function%2002/interactive_session.dart';
import 'package:giggle/features/function%2003/interactive_session.dart';
import 'package:giggle/features/function%2004/verbal_interactive_session.dart';

class TeacherSelectionScreen extends ConsumerStatefulWidget {
  final Map<String, String>? difficultyLevels;
  final List<Map<String, dynamic>> questions;
  final String dyscalculiaType;
  final String courseName;
  final String userId;

  const TeacherSelectionScreen({
    super.key,
    this.difficultyLevels,
    required this.courseName,
    required this.dyscalculiaType,
    required this.questions,
    required this.userId,
  });

  @override
  ConsumerState<TeacherSelectionScreen> createState() =>
      _TeacherSelectionScreenState();
}

class _TeacherSelectionScreenState extends ConsumerState<TeacherSelectionScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  double _currentPage = 0;
  late TeacherCharacter _selectedTeacher;

  @override
  void initState() {
    super.initState();
    _selectedTeacher = teachers[0];
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: 0,
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
        _selectedTeacher = teachers[_currentPage.round()];
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider).valueOrNull ??
        const AppTheme(primaryColor: Color(0xFF4F46E5));
    final themeColor = themeData.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Stack(
        children: [
          BackgroundPattern(),
          SafeArea(
            child: SingleChildScrollView( // Wrap with SingleChildScrollView
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SubPageHeader(
                    title: 'Choose Your Teacher',
                    desc: '${widget.courseName} - ${widget.dyscalculiaType}',
                  ),
                  const SizedBox(height: 20),
                  _buildTitle(),
                  const SizedBox(height: 40),
                  _buildCharacterCarousel(themeColor),
                  const SizedBox(height: 30),
                  _buildCharacterInfo(),
                  const SizedBox(height: 20),
                  _buildNavigationButtons(themeColor: themeColor),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: NextButton(
                      text: 'Start Learning with ${_selectedTeacher.name}',
                      onTap: () {
                        if (widget.dyscalculiaType == 'Semantic Dyscalculia') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SemanticInteractiveSessionScreen(
                                difficultyLevels: widget.difficultyLevels,
                                dyscalculiaType: widget.dyscalculiaType,
                                questions: widget.questions,
                                courseName: widget.courseName,
                                selectedTeacher: _selectedTeacher.name,
                                userId: widget.userId,
                              ),
                            ),
                          );
                        } else if (widget.dyscalculiaType ==
                            'Procedural Dyscalculia') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProceduralInteractiveSession(
                                difficultyLevels: widget.difficultyLevels,
                                dyscalculiaType: widget.dyscalculiaType,
                                questions: widget.questions,
                                courseName: widget.courseName,
                                // selectedTeacher: _selectedTeacher.name,
                                userId: widget.userId,
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerbalInteractiveSessionScreen(
                                difficultyLevels: widget.difficultyLevels,
                                dyscalculiaType: widget.dyscalculiaType,
                                questions: widget.questions,
                                courseName: widget.courseName,
                                userId: widget.userId,
                                
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Select your preferred teaching assistant for a personalized learning experience',
        style: TextStyle(
          fontSize: 16,
          color: const Color(0xFF1D1D1F).withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildCharacterCarousel(Color themeColor) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _pageController,
        itemCount: teachers.length,
        itemBuilder: (context, index) {
          final scale =
              1.0 - ((_currentPage - index).abs() * 0.1).clamp(0.0, 0.4);
          return TweenAnimationBuilder(
            tween: Tween(begin: scale, end: scale),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value as double,
                child: _buildCharacterCard(teachers[index], themeColor),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCharacterCard(TeacherCharacter teacher, Color themeColor) {
    final isSelected = teacher == _selectedTeacher;
    return GestureDetector(
      onTap: () {
        final index = teachers.indexOf(teacher);
        _navigateToPage(index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5E5CE6).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image container
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(teacher.avatar),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Selection indicator
            if (isSelected)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons({required Color themeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavigationButton(
            themeColor: themeColor,
            icon: Icons.arrow_back_ios,
            onTap: _currentPage > 0
                ? () {
                    _navigateToPage(_currentPage.round() - 1);
                  }
                : null,
          ),
          const SizedBox(width: 20),
          _buildNavigationButton(
            themeColor: themeColor,
            icon: Icons.arrow_forward_ios,
            onTap: _currentPage < teachers.length - 1
                ? () {
                    _navigateToPage(_currentPage.round() + 1);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required Color themeColor,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: onTap != null ? themeColor : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: themeColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white : Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCharacterInfo() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_selectedTeacher.name),
        margin: const EdgeInsets.symmetric(horizontal: 20),
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
            Text(
              _selectedTeacher.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedTeacher.specialization,
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF1D1D1F).withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedTeacher.description,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF1D1D1F).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
