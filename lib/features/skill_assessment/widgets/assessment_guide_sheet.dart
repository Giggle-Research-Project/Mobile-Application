import 'package:flutter/material.dart';
import 'package:giggle/features/skill_assessment/widgets/guide_widget.dart';

class AssessmentGuideSheet extends StatelessWidget {
  const AssessmentGuideSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.6,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: ListView(
          controller: controller,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assessment Guide',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  GuideSection(
                    title: 'Test Duration',
                    description:
                        'The skill assessment test takes 30 minutes to complete.',
                  ),
                  GuideSection(
                    title: 'Question Types',
                    description:
                        'The test includes multiple-choice and problem-solving questions.',
                  ),
                  GuideSection(
                    title: 'Scoring',
                    description:
                        'Your performance is evaluated based on accuracy and speed.',
                  ),
                  GuideSection(
                    title: 'Preparation',
                    description:
                        'Ensure a quiet environment and have necessary resources ready.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
