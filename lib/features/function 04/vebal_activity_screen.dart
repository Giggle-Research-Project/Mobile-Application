// difficulty_levels_screen.dart
import 'package:flutter/material.dart';
import 'package:giggle/features/function%2004/verbal_activities.dart';

class VerbalDifficultyLevelsScreen extends StatelessWidget {
  VerbalDifficultyLevelsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Difficulty',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose your practice level',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildDifficultyCard(
                context,
                'Novice',
                'Basic number recognition (1-10)',
                Colors.green.shade300,
                const Icon(Icons.star_border),
                _noviceQuestions,
              ),
              const SizedBox(height: 16),
              _buildDifficultyCard(
                context,
                'Beginner',
                'Simple number words (11-30)',
                Colors.green.shade600,
                const Icon(Icons.star_half),
                _beginnerQuestions,
              ),
              const SizedBox(height: 16),
              _buildDifficultyCard(
                context,
                'Intermediate',
                'Two-digit numbers (31-50)',
                Colors.orange,
                const Icon(Icons.star),
                _intermediateQuestions,
              ),
              const SizedBox(height: 16),
              _buildDifficultyCard(
                context,
                'Advanced',
                'Complex numbers (51-80)',
                Colors.red.shade300,
                const Icon(Icons.stars, size: 24),
                _advancedQuestions,
              ),
              const SizedBox(height: 16),
              _buildDifficultyCard(
                context,
                'Expert',
                'Master level (81-100)',
                Colors.red.shade600,
                const Icon(Icons.workspace_premium, size: 24),
                _expertQuestions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(
    BuildContext context,
    String title,
    String description,
    Color color,
    Widget icon,
    List<Map<String, dynamic>> questions,
  ) {
    return Hero(
      tag: 'difficulty_$title',
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivitiesScreen(
                  color: color,
                  questions: questions,
                  timeLimit: _getTimeLimit(title),
                  level: title,
                  description: description,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: icon,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _getTimeLimit(String level) {
    switch (level) {
      case 'Novice':
        return 720; // 12 minutes
      case 'Beginner':
        return 600; // 10 minutes
      case 'Intermediate':
        return 480; // 8 minutes
      case 'Advanced':
        return 360; // 6 minutes
      case 'Expert':
        return 300; // 5 minutes
      default:
        return 600;
    }
  }

  // Add these question sets at the top level of difficulty_levels_screen.dart

  final List<Map<String, dynamic>> _noviceQuestions = [
    {
      'numberWord': 'one',
      'options': ['1', '2', '10', '11'],
      'correct': '1',
      'hint': 'This is the first number when counting',
    },
    {
      'numberWord': 'five',
      'options': ['4', '5', '6', '15'],
      'correct': '5',
      'hint': 'Count the fingers on one hand',
    },
    {
      'numberWord': 'eight',
      'options': ['7', '8', '9', '18'],
      'correct': '8',
      'hint': 'Two less than ten',
    },
    {
      'numberWord': 'three',
      'options': ['13', '2', '3', '4'],
      'correct': '3',
      'hint': 'Count: one, two, ...',
    },
    {
      'numberWord': 'ten',
      'options': ['10', '12', '20', '11'],
      'correct': '10',
      'hint': 'Count all fingers on both hands',
    },
  ];

  final List<Map<String, dynamic>> _beginnerQuestions = [
    {
      'numberWord': 'sixteen',
      'options': ['16', '60', '6', '26'],
      'correct': '16',
      'hint': 'Think of it as "six" plus "teen" (which means add 10)',
    },
    {
      'numberWord': 'twenty-three',
      'options': ['13', '23', '32', '3'],
      'correct': '23',
      'hint': '"Twenty" means 2 tens, then add "three"',
    },
    {
      'numberWord': 'eighteen',
      'options': ['8', '18', '80', '28'],
      'correct': '18',
      'hint': 'Think of it as "eight" plus "teen" (which means add 10)',
    },
    {
      'numberWord': 'twenty-five',
      'options': ['25', '52', '15', '35'],
      'correct': '25',
      'hint': '"Twenty" means 2 tens, then add "five"',
    },
    {
      'numberWord': 'fourteen',
      'options': ['40', '14', '4', '24'],
      'correct': '14',
      'hint': 'Think of it as "four" plus "teen" (which means add 10)',
    },
  ];

  final List<Map<String, dynamic>> _intermediateQuestions = [
    {
      'numberWord': 'thirty-eight',
      'options': ['38', '83', '48', '28'],
      'correct': '38',
      'hint': '"Thirty" means 3 tens, then add "eight"',
    },
    {
      'numberWord': 'forty-two',
      'options': ['24', '42', '44', '32'],
      'correct': '42',
      'hint': '"Forty" means 4 tens, then add "two"',
    },
    {
      'numberWord': 'thirty-five',
      'options': ['35', '53', '45', '25'],
      'correct': '35',
      'hint': '"Thirty" means 3 tens, then add "five"',
    },
    {
      'numberWord': 'forty-seven',
      'options': ['47', '74', '37', '57'],
      'correct': '47',
      'hint': '"Forty" means 4 tens, then add "seven"',
    },
    {
      'numberWord': 'thirty-nine',
      'options': ['39', '93', '49', '29'],
      'correct': '39',
      'hint': '"Thirty" means 3 tens, then add "nine"',
    },
  ];

  final List<Map<String, dynamic>> _advancedQuestions = [
    {
      'numberWord': 'sixty-five',
      'options': ['56', '65', '75', '55'],
      'correct': '65',
      'hint': '"Sixty" means 6 tens, then add "five"',
    },
    {
      'numberWord': 'seventy-one',
      'options': ['71', '61', '17', '81'],
      'correct': '71',
      'hint': '"Seventy" means 7 tens, then add "one"',
    },
    {
      'numberWord': 'fifty-eight',
      'options': ['58', '85', '48', '68'],
      'correct': '58',
      'hint': '"Fifty" means 5 tens, then add "eight"',
    },
    {
      'numberWord': 'seventy-six',
      'options': ['67', '76', '66', '86'],
      'correct': '76',
      'hint': '"Seventy" means 7 tens, then add "six"',
    },
    {
      'numberWord': 'sixty-three',
      'options': ['63', '36', '73', '53'],
      'correct': '63',
      'hint': '"Sixty" means 6 tens, then add "three"',
    },
  ];

  final List<Map<String, dynamic>> _expertQuestions = [
    {
      'numberWord': 'ninety-three',
      'options': ['83', '93', '39', '92'],
      'correct': '93',
      'hint': '"Ninety" means 9 tens, then add "three"',
    },
    {
      'numberWord': 'eighty-four',
      'options': ['84', '48', '94', '74'],
      'correct': '84',
      'hint': '"Eighty" means 8 tens, then add "four"',
    },
    {
      'numberWord': 'ninety-seven',
      'options': ['97', '79', '87', '96'],
      'correct': '97',
      'hint': '"Ninety" means 9 tens, then add "seven"',
    },
    {
      'numberWord': 'eighty-eight',
      'options': ['88', '98', '78', '86'],
      'correct': '88',
      'hint': '"Eighty" means 8 tens, then add "eight"',
    },
    {
      'numberWord': 'ninety-six',
      'options': ['96', '69', '86', '98'],
      'correct': '96',
      'hint': '"Ninety" means 9 tens, then add "six"',
    },
  ];
}
