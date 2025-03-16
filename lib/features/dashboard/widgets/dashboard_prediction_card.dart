import 'package:flutter/material.dart';
import 'package:giggle/core/constants/app_constants.dart';

class DashboardPredictionCard extends StatelessWidget {
  final Map<String, Map<String, dynamic>> _operationData;

  DashboardPredictionCard(this._operationData);

  @override
  Widget build(BuildContext context) {
    return _buildPredictionCard();
  }

  final List<Map<String, dynamic>> _mathOperations =
      AppConstants.mathOperations;

  Widget _buildPredictionCard() {
    final operations = [
      'Addition',
      'Subtraction',
      'Multiplication',
      'Division'
    ];

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
          // Modern header with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Learning Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E5CE6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Color(0xFF5E5CE6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(
                        color: Color(0xFF5E5CE6),
                        width: 3,
                      ),
                      insets: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    labelColor: const Color(0xFF5E5CE6),
                    unselectedLabelColor: const Color(0xFF1D1D1F),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Semantic'),
                      Tab(text: 'Verbal'),
                      Tab(text: 'Procedural'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildProfileTabOptimized(operations, 'Semantic'),
                      _buildProfileTabOptimized(operations, 'Verbal'),
                      _buildProfileTabOptimized(operations, 'Procedural'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Modern info card with gradient background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5E5CE6).withOpacity(0.1),
                  const Color(0xFF5E5CE6).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
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
                      const Text(
                        'Learning Profiles Explained',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5E5CE6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Semantic: Understanding quantity and number meaning\n'
                        '• Verbal: Processing word math problems\n'
                        '• Procedural: Following step-by-step calculation rules',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: const Color(0xFF1D1D1F).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTabOptimized(
      List<String> operations, String profileType) {
    final profileKey = '${profileType.toLowerCase()}Prediction';

    // Check if any operation has data for this profile type
    bool hasAnyOperationData = operations.any((operation) =>
        _operationData.containsKey(operation) &&
        _operationData[operation]!.containsKey(profileKey) &&
        _operationData[operation]![profileKey] != null);

    // If no operations have prediction data for this profile type, show empty state
    if (!hasAnyOperationData) {
      return _buildEmptyProfileTab(profileType);
    }

    // Build the list of all operations, showing data for those that have it
    // and a prompt to complete solo sessions for those that don't
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: operations.length,
      itemBuilder: (context, index) {
        final operation = operations[index];

        // Check if this operation has prediction data
        final hasPredictionData = _operationData.containsKey(operation) &&
            _operationData[operation]!.containsKey(profileKey) &&
            _operationData[operation]![profileKey] != null;

        // Get operation details
        final operationDetails = _getOperationDetails(operation);
        final operationColor = operationDetails['color'] as Color;
        final operationIcon = operationDetails['icon'] as IconData;

        if (hasPredictionData) {
          // If operation has prediction data, show performance
          final predictionValue =
              _operationData[operation]![profileKey] as double;
          final progressColor = _getProgressColor(predictionValue);

          return _buildPredictionItem(
            operation: operation,
            operationColor: operationColor,
            operationIcon: operationIcon,
            predictionValue: predictionValue,
            progressColor: progressColor,
          );
        } else {
          // If operation doesn't have prediction data, show prompt
          return _buildOperationPromptItem(
            operation: operation,
            operationColor: operationColor,
            operationIcon: operationIcon,
          );
        }
      },
    );
  }

  // Widget for operations that need solo sessions to be completed
  Widget _buildOperationPromptItem({
    required String operation,
    required Color operationColor,
    required IconData operationIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Optional: Navigate to solo sessions
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: operationColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(operationIcon, color: operationColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        operation,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete solo sessions to see performance',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF1D1D1F).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFF1D1D1F).withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern prediction item with improved design
  Widget _buildPredictionItem({
    required String operation,
    required Color operationColor,
    required IconData operationIcon,
    required double predictionValue,
    required Color progressColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Optional: Add interaction like showing detailed breakdown
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: operationColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(operationIcon, color: operationColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        operation,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${predictionValue.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Modern progress indicator with rounded edges
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: predictionValue / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: progressColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyProfileTab(String profileType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pending_actions,
            size: 36,
            color: const Color(0xFF5E5CE6).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No $profileType data available yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1D1F).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete solo sessions to see predictions',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF1D1D1F).withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper to get progress color
  Color _getProgressColor(double value) {
    if (value >= 75) return const Color(0xFF30D158); // Green
    if (value >= 50) return const Color(0xFFFF9F0A); // Orange
    return const Color(0xFFFF3B30); // Red
  }

  // Helper to get operation details
  Map<String, dynamic> _getOperationDetails(String operation) {
    return _mathOperations.firstWhere((op) => op['title'] == operation,
        orElse: () => {
              'title': operation,
              'color': const Color(0xFF5E5CE6),
              'icon': Icons.calculate,
            });
  }
}
