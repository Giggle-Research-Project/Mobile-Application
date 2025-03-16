import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:giggle/core/theme/analytic_colors.dart';
import 'package:giggle/features/dashboard/services/learninig_analytics.dart';
import 'package:giggle/features/dashboard/widgets/dashboard_section_title.dart';
import 'package:giggle/features/performance_result/performance_result_screen.dart';

class SemanticAnalyticsSection extends StatefulWidget {
  const SemanticAnalyticsSection({Key? key}) : super(key: key);

  @override
  SemanticAnalyticsSectionState createState() =>
      SemanticAnalyticsSectionState();
}

class SemanticAnalyticsSectionState extends State<SemanticAnalyticsSection> {
  final SemanticDyscalculiaAnalyticsService _analyticsService =
      SemanticDyscalculiaAnalyticsService();
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  Map<String, dynamic> _insights = {};
  String _selectedOperation = 'Overall';

  final List<String> _operations = [
    'Overall',
    'Addition',
    'Subtraction',
    'Multiplication',
    'Division'
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final analytics = await _analyticsService.getDyscalculiaAnalytics();
      final insights = _analyticsService.getLearningInsights(analytics);

      setState(() {
        _analyticsData = analytics;
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      print('[ERROR] Error loading analytics data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle(title: 'Learning Analytics'),
        const SizedBox(height: 16),
        _isLoading
            ? _buildLoadingIndicator()
            : _analyticsData.isEmpty
                ? _buildNoDataMessage()
                : Column(
                    children: [
                      _buildOperationSelector(),
                      const SizedBox(height: 16),
                      _buildAnalyticsCards(),
                      const SizedBox(height: 20),
                      _buildInsightsCard(),
                    ],
                  ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(
          color: Color(0xFF5E5CE6),
        ),
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No analytics data available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete more lessons to generate learning analytics',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationSelector() {
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _operations.length,
        itemBuilder: (context, index) {
          final operation = _operations[index];
          final isSelected = operation == _selectedOperation;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedOperation = operation;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF5E5CE6) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF5E5CE6)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  operation,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    final Map<String, dynamic> data = _selectedOperation == 'Overall'
        ? _analyticsData['overall'] ?? {}
        : _analyticsData[_selectedOperation] ?? {};

    if (data.isEmpty) {
      return _buildNoOperationDataCard();
    }

    final double concentrationScore = _selectedOperation == 'Overall'
        ? (data['averageConcentration'] ?? 0.0)
        : (data['averageConcentration'] ?? 0.0);

    final String emotion = _selectedOperation == 'Overall'
        ? (data['dominantEmotion'] ?? 'neutral')
        : (data['emotion'] != null && data['emotion']['primaryEmotion'] != null
            ? data['emotion']['primaryEmotion']
            : 'neutral');

    final double emotionPercentage = _selectedOperation == 'Overall'
        ? (data['dominantEmotionPercentage'] ?? 0.0)
        : (data['emotion'] != null &&
                data['emotion']['primaryEmotionPercentage'] != null
            ? data['emotion']['primaryEmotionPercentage']
            : 0.0);

    // For concentration status breakdown
    final Map<String, double> concentrationBreakdown = _selectedOperation ==
            'Overall'
        ? {} // Overall doesn't have detailed breakdown
        : (data['concentration'] != null &&
                data['concentration']['statusBreakdown'] != null
            ? Map<String, double>.from(data['concentration']['statusBreakdown'])
            : {});

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Concentration',
                value: '${concentrationScore.toStringAsFixed(1)}%',
                icon: Icons.psychology,
                color: getConcentrationColor(concentrationScore),
                subtitle: _getConcentrationLabel(concentrationScore),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Primary Emotion',
                value: emotion.isEmpty ? 'N/A' : emotion.capitalize(),
                icon: Icons.emoji_emotions,
                color: _getEmotionColor(emotion),
                subtitle: '${emotionPercentage.toStringAsFixed(1)}% of session',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedOperation != 'Overall' &&
            concentrationBreakdown.isNotEmpty)
          _buildConcentrationBreakdownCard(concentrationBreakdown),
      ],
    );
  }

  Widget _buildNoOperationDataCard() {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No data for $_selectedOperation',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete lessons in $_selectedOperation to generate analytics',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConcentrationBreakdownCard(Map<String, double> breakdown) {
    // Convert to list for chart
    final List<MapEntry<String, double>> entries = breakdown.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value)); // Sort by highest value

    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Concentration Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: breakdown.isEmpty
                  ? Center(
                      child: Text(
                        'No breakdown data available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    )
                  : PieChart(
                      PieChartData(
                        sections: _getConcentrationPieSections(breakdown),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Column(
              children: entries.map((entry) {
                final color = getStatusColor(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatStatusName(entry.key),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getConcentrationPieSections(
      Map<String, double> breakdown) {
    final List<PieChartSectionData> sections = [];

    breakdown.forEach((status, percentage) {
      sections.add(
        PieChartSectionData(
          value: percentage,
          title: percentage >= 10 ? '${percentage.toStringAsFixed(0)}%' : '',
          color: getStatusColor(status),
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    });

    return sections;
  }

  Widget _buildInsightsCard() {
    Map<String, dynamic> operationInsights = {};
    String insightText = '';
    String recommendationText = '';

    if (_selectedOperation == 'Overall') {
      insightText = _insights.containsKey('concentration')
          ? _insights['concentration']['insight'] ??
              'No concentration insight available'
          : 'No concentration insight available';

      final emotionInsight =
          _insights.containsKey('emotion') ? _insights['emotion'] ?? {} : {};

      recommendationText = emotionInsight.containsKey('recommendation')
          ? emotionInsight['recommendation'] ?? 'No recommendation available'
          : 'No recommendation available';
    } else {
      operationInsights = _insights.containsKey('operations') &&
              _insights['operations'].containsKey(_selectedOperation)
          ? _insights['operations'][_selectedOperation] ?? {}
          : {};

      final status = operationInsights.containsKey('status')
          ? operationInsights['status'] ?? 'Unknown'
          : 'Unknown';

      insightText = 'Performance is $status in $_selectedOperation';

      // Use general recommendations based on status
      if (status == 'Strong') {
        recommendationText =
            'Continue with current approach and challenge with more complex problems';
      } else if (status == 'Moderate') {
        recommendationText =
            'Focus on building stronger fundamentals and practice regularly';
      } else {
        recommendationText =
            'Consider additional support and break down problems into smaller steps';
      }
    }

    final String recommendedFocus = _insights.containsKey('recommendedFocus')
        ? _insights['recommendedFocus'] ?? ''
        : '';

    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Learning Insights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E5CE6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF5E5CE6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insightText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendationText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (recommendedFocus.isNotEmpty && _selectedOperation == 'Overall')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9F0A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.priority_high,
                          color: Color(0xFFFF9F0A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recommended Focus',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Focus on improving your $recommendedFocus skills',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildCard({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  String _getConcentrationLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Moderate';
    return 'Needs improvement';
  }

  Color _getEmotionColor(String emotion) {
    final lowerEmotion = emotion.toLowerCase();
    return emotionColors[lowerEmotion] ??
        const Color(0xFF5E5CE6); // Default purple
  }

  String _formatStatusName(String status) {
    // Convert camelCase or snake_case to Title Case with spaces
    final words = status.split(RegExp(r'(?=[A-Z])|_'));
    return words.map((word) => word.capitalize()).join(' ');
  }
}

// Import this widget to use with the dashboard
class AnalyticsDashboardSection extends StatelessWidget {
  const AnalyticsDashboardSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const SemanticAnalyticsSection(),
      ],
    );
  }
}
