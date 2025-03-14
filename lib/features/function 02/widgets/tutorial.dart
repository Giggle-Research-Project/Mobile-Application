import 'package:flutter/material.dart';
import 'package:giggle/features/function%2002/widgets/tutorial_steps.dart';

class TutorialWidget extends StatefulWidget {
  final Color themeColor;
  final List<Map<String, dynamic>> questions;
  final String courseName;

  const TutorialWidget({
    Key? key,
    required this.themeColor,
    required this.questions,
    required this.courseName,
  }) : super(key: key);

  @override
  _TutorialWidgetState createState() => _TutorialWidgetState();
}

class _TutorialWidgetState extends State<TutorialWidget> {
  bool showTutorial = true;

  Widget _buildGradientButton(
    String text, {
    required VoidCallback onPressed,
    required Color themeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTutorial({required Color themeColor}) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "How to Play",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    if (widget.courseName == "Addition") ...[
                      TutorialStep(
                        number: "1",
                        text:
                            "Select 'Apple' and place ${widget.questions[0]['num1']} apples in the AR space",
                        icon: Icons.apple,
                      ),
                      const SizedBox(height: 16),
                      TutorialStep(
                        number: "2",
                        text:
                            "Select 'Orange' and place ${widget.questions[0]['num2']} oranges",
                        icon: Icons.circle,
                      ),
                      const SizedBox(height: 16),
                      const TutorialStep(
                        number: "3",
                        text: "Tap on any model to select and remove if needed",
                        icon: Icons.touch_app,
                      ),
                      const SizedBox(height: 16),
                      const TutorialStep(
                        number: "4",
                        text: "Press 'Check Answer' to verify your solution",
                        icon: Icons.check_circle,
                      ),
                    ] else ...[
                      TutorialStep(
                        number: "1",
                        text:
                            "Select 'Apple' and place ${widget.questions[0]['correctAnswer']} apples in the AR space",
                        icon: Icons.apple,
                      ),
                      const SizedBox(height: 16),
                      const TutorialStep(
                        number: "2",
                        text: "Tap on any model to select and remove if needed",
                        icon: Icons.touch_app,
                      ),
                      const SizedBox(height: 16),
                      const TutorialStep(
                        number: "3",
                        text: "Press 'Check Answer' to verify your solution",
                        icon: Icons.check_circle,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildGradientButton(
                "Got it!",
                onPressed: () => setState(() => showTutorial = false),
                themeColor: themeColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return showTutorial
        ? _buildTutorial(themeColor: widget.themeColor)
        : Container();
  }
}
