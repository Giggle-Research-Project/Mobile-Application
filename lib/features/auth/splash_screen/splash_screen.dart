import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giggle/core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Light theme color scheme
  static const Color primary = Color(0xFFFF7E5F);
  static const Color backgroundColor = Color(0xFFF9F7F7);
  static const Color accentColor = Color(0xFF54D2D2);
  static const Color textColor = Color(0xFF2C3E50);

  late AnimationController _controller;
  late AnimationController _loadingController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    // Playful bounce effect for logo
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
      ),
    );

    // Light rotation for logo
    _logoRotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    // Text slides in from side
    _textSlideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Background color animation
    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
    _initSplash();
  }

  Future<void> _initSplash() async {
    await Future.delayed(const Duration(milliseconds: 4500));
    if (!mounted) return;

    final authState = await ref.read(authProvider.future);
    if (!mounted) return;

    if (authState == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Color.lerp(
            backgroundColor,
            const Color(0xFFF0F7FA),
            _backgroundAnimation.value,
          ),
          body: Stack(
            children: [
              // Decorative background elements
              ...List.generate(
                10,
                (index) => Positioned(
                  right: index % 2 == 0
                      ? null
                      : MediaQuery.of(context).size.width * 0.1 * (index ~/ 2),
                  left: index % 2 == 0
                      ? MediaQuery.of(context).size.width * 0.1 * (index ~/ 2)
                      : null,
                  top: MediaQuery.of(context).size.height * 0.1 * index,
                  child: Opacity(
                    opacity:
                        0.06 + (0.005 * index * _backgroundAnimation.value),
                    child: Container(
                      width: 100 - (index * 4),
                      height: 100 - (index * 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(index * 2.0),
                        color: index % 3 == 0
                            ? primary
                            : (index % 3 == 1 ? accentColor : Colors.amber),
                      ),
                    ),
                  ),
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with soft shadow and light reflection
                    Transform.rotate(
                      angle: _logoRotateAnimation.value * 3.14159,
                      child: ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Circle gradient background
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      primary.withOpacity(0.8),
                                      accentColor.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),

                              // Shine effect
                              Positioned(
                                top: 45,
                                left: 45,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),

                              // Logo in center
                              Center(
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  padding: const EdgeInsets.all(15),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Image.asset(
                                    'assets/images/booze.png',
                                    width: 110,
                                    height: 110,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App name and tagline with slide animation
                    Transform.translate(
                      offset: Offset(_textSlideAnimation.value, 0),
                      child: Opacity(
                        opacity: 1 - (_textSlideAnimation.value / 30),
                        child: Column(
                          children: [
                            // App name
                            RichText(
                              text: const TextSpan(
                                text: 'G',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: primary,
                                  letterSpacing: -1,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'iggle',
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Discover Your Insights',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6C757D),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Animated progress bar
                            Container(
                              width: 180,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey.withOpacity(0.2),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedBuilder(
                                    animation: _loadingController,
                                    builder: (context, _) {
                                      return Positioned(
                                        left: 0,
                                        right: 180 *
                                            (1 - _loadingController.value),
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            gradient: const LinearGradient(
                                              colors: [primary, accentColor],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
