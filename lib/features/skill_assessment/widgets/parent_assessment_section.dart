import 'package:flutter/material.dart';
import 'package:giggle/core/data/questions.dart';
import 'package:giggle/core/enums/enums.dart';
import 'package:giggle/features/skill_assessment/widgets/index.dart';

class OtherAssessmentsSection extends StatelessWidget {
  final Color themeColor;
  final bool isParentQuestionnaireCompleted;
  final Function(TestScreenType) onTap;

  const OtherAssessmentsSection({
    Key? key,
    required this.onTap,
    required this.themeColor,
    required this.isParentQuestionnaireCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Other Assessments',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 16),
        AssessmentCard(
          title: 'Parent Questionnaire',
          description: 'Help us understand your child better',
          icon: Icons.family_restroom,
          color: themeColor,
          duration: '20 mins',
          questions: '${parentQuestions.length} questions',
          isCompleted: isParentQuestionnaireCompleted,
          onTap: () => onTap(TestScreenType.parentQuestionnaire),
        ),
      ],
    );
  }
}
