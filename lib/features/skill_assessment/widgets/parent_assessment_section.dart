import 'package:flutter/material.dart';
import 'package:giggle/core/data/questions_english.dart' as english;
import 'package:giggle/core/data/questions_sinhala.dart' as sinhala;
import 'package:giggle/core/enums/enums.dart';
import 'package:giggle/features/skill_assessment/widgets/index.dart';
import 'package:giggle/features/skill_assessment/widgets/language_selection_dialog.dart';

class OtherAssessmentsSection extends StatelessWidget {
  final Color themeColor;
  final bool isParentQuestionnaireCompleted;
  final Function(TestScreenType, List<Map<String, dynamic>>) onTap;

  const OtherAssessmentsSection({
    Key? key,
    required this.onTap,
    required this.themeColor,
    required this.isParentQuestionnaireCompleted,
  }) : super(key: key);

  void _showLanguageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LanguageSelectionDialog(
        onLanguageSelected: (language) {
          Navigator.pop(context); // Close the dialog
          final questions = language == 'english'
              ? english.parentQuestions
              : sinhala.parentQuestions;
          onTap(TestScreenType.parentQuestionnaire, questions);
        },
      ),
    );
  }

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
          questions: '${english.parentQuestions.length} questions',
          isCompleted: isParentQuestionnaireCompleted,
          onTap: () => _showLanguageSelectionDialog(context),
        ),
      ],
    );
  }
}
