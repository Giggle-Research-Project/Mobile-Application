import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final List<Map<String, dynamic>> weeklyProgress = [
    {'day': 'Mon', 'minutes': 45},
    {'day': 'Tue', 'minutes': 30},
    {'day': 'Wed', 'minutes': 60},
    {'day': 'Thu', 'minutes': 20},
    {'day': 'Fri', 'minutes': 45},
    {'day': 'Sat', 'minutes': 15},
    {'day': 'Sun', 'minutes': 0},
  ];

  final List<Map<String, dynamic>> achievements = [
    {
      'title': 'Quick Learner',
      'description': 'Completed 5 lessons in one day',
      'icon': Icons.bolt,
      'color': const Color(0xFF5E5CE6),
      'progress': 0.8,
    },
    {
      'title': 'Math Wizard',
      'description': 'Solved 50 math problems',
      'icon': Icons.stars,
      'color': const Color(0xFF30D158),
      'progress': 0.6,
    },
    {
      'title': 'Science Explorer',
      'description': 'Completed all space missions',
      'icon': Icons.rocket_launch,
      'color': const Color(0xFFFF9F0A),
      'progress': 0.4,
    },
  ];

  final List<Map<String, dynamic>> suggestions = [
    {
      'title': 'Complete Daily Goal',
      'subtitle': '15 minutes left',
      'icon': Icons.timer,
      'color': Color(0xFF5E5CE6),
    },
    {
      'title': 'Take Science Quiz',
      'subtitle': 'Boost your progress',
      'icon': Icons.science,
      'color': Color(0xFF30D158),
    },
    {
      'title': 'New Reading Adventure',
      'subtitle': 'Story unlocked',
      'icon': Icons.menu_book,
      'color': Color(0xFFFF9F0A),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeeklyProgressCard(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Achievements'),
                      const SizedBox(height: 16),
                      _buildAchievementsList(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Suggested for You'),
                      const SizedBox(height: 16),
                      _buildSuggestionsList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
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
          const SizedBox(width: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'Your daily progress',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard() {
    return Container(
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
          const Text(
            'Weekly Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weeklyProgress.map((day) {
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        FractionallySizedBox(
                          heightFactor: day['minutes'] / 60,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF5E5CE6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day['day'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1D1D1F),
      ),
    );
  }

  Widget _buildAchievementsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: achievement['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  achievement['icon'],
                  color: achievement['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF1D1D1F).withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: achievement['progress'],
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: achievement['color'],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSuggestionsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: suggestion['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                suggestion['icon'],
                color: suggestion['color'],
                size: 24,
              ),
            ),
            title: Text(
              suggestion['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            subtitle: Text(
              suggestion['subtitle'],
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF1D1D1F).withOpacity(0.6),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF1D1D1F),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
}
