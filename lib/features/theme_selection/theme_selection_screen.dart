import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/models/theme_option.dart';
import 'package:giggle/core/providers/theme_provider.dart';

class ThemeSelectionScreen extends ConsumerStatefulWidget {
  final bool isInitialSelection;

  const ThemeSelectionScreen({
    super.key,
    this.isInitialSelection = false,
  });

  @override
  ConsumerState<ThemeSelectionScreen> createState() =>
      _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends ConsumerState<ThemeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _selectedThemeIndex = 0;

  final List<ThemeOption> themeOptions = [
    ThemeOption(
      name: 'Royal Purple',
      primaryColor: const Color(0xFF4F46E5),
      gradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      emoji: '👑',
    ),
    ThemeOption(
      name: 'Ocean Blue',
      primaryColor: const Color(0xFF0EA5E9),
      gradient: const [Color(0xFF0EA5E9), Color(0xFF2563EB)],
      emoji: '🌊',
    ),
    ThemeOption(
      name: 'Forest Green',
      primaryColor: const Color(0xFF059669),
      gradient: const [Color(0xFF059669), Color(0xFF047857)],
      emoji: '🌿',
    ),
    ThemeOption(
      name: 'Sunset Orange',
      primaryColor: const Color(0xFFEA580C),
      gradient: const [Color(0xFFEA580C), Color(0xFFD97706)],
      emoji: '🌅',
    ),
    ThemeOption(
      name: 'Berry Pink',
      primaryColor: const Color(0xFFDB2777),
      gradient: const [Color(0xFFDB2777), Color(0xFFBE185D)],
      emoji: '🫐',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isInitialSelection) ...[
                  _buildHeader(),
                  const SizedBox(height: 30),
                ],
                const Text(
                  'Choose Your Theme',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Select a color theme for your learning experience',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: themeOptions.length,
                    itemBuilder: (context, index) {
                      return _buildThemeOption(themeOptions[index], index);
                    },
                  ),
                ),
                _buildConfirmButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
      ],
    );
  }

  Widget _buildThemeOption(ThemeOption theme, int index) {
    final isSelected = _selectedThemeIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedThemeIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  theme.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tap to preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: theme.primaryColor,
                      size: 20,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: () async {
        final selectedTheme = themeOptions[_selectedThemeIndex];

        // Using Riverpod instead of Provider
        await ref
            .read(themeProvider.notifier)
            .updateTheme(selectedTheme.primaryColor);

        if (mounted) {
          if (widget.isInitialSelection) {
            Navigator.pushReplacementNamed(context, '/main');
          } else {
            Navigator.pop(context);
          }
        }
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeOptions[_selectedThemeIndex].gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: themeOptions[_selectedThemeIndex]
                  .primaryColor
                  .withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Confirm Theme',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
