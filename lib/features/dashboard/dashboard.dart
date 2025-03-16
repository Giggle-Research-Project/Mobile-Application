import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:giggle/core/constants/app_constants.dart';
import 'package:giggle/core/widgets/custom_appbar.dart';
import 'package:giggle/features/dashboard/operation_detail_screen.dart';
import 'package:giggle/features/dashboard/semantic_analytics.dart';
import 'package:giggle/features/dashboard/services/performance_data_services.dart';
import 'package:giggle/features/dashboard/services/solo_performance_prediction.dart';

import 'widgets/index.dart';

class DashBoardScreen extends StatefulWidget {
  final Map<String, String>? difficultyLevels;
  const DashBoardScreen({Key? key, this.difficultyLevels}) : super(key: key);

  @override
  DashBoardScreenState createState() => DashBoardScreenState();
}

class DashBoardScreenState extends State<DashBoardScreen> {
  final _userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = true;
  late final PerformanceDataService _dataService;
  final List<Map<String, dynamic>> _mathOperations =
      AppConstants.mathOperations;

  // Data containers
  Map<String, Map<String, dynamic>> _operationData = {};
  Map<String, dynamic> _overallStats = _getInitialOverallStats();

  // Initial empty stats
  static Map<String, dynamic> _getInitialOverallStats() {
    return {
      'totalCompletedLessons': 0,
      'totalLessons': 0,
      'totalCorrectAnswers': 0,
      'totalQuestions': 0,
      'averageTime': 0.0,
      'startedOperations': 0,
      'completedOperations': 0,
      'mostAccurateOperation': '',
      'fastestOperation': '',
      'weakestOperation': '',
      'recommendedFocus': '',
    };
  }

  // Add this method to your DashBoardScreenState class
  Future<void> _saveOperationData() async {
    if (_userId == null || _operationData.isEmpty) return;

    try {
      await _dataService.saveOperationData(_operationData);
      print('[INFO] Successfully saved operation data to Firestore');
    } catch (e) {
      print('[ERROR] Error in _saveOperationData: $e');
      // Consider showing a snackbar to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save your data. Please try again later.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _dataService = PerformanceDataService(userId: _userId);
    _checkDataFreshness();
    _loadData();
    _loadPredictionsWithCache();
  }

  Future<void> _checkDataFreshness() async {
    final lastUpdate = await _dataService.getLastDataUpdateTimestamp();
    final now = DateTime.now();

    if (lastUpdate == null || now.difference(lastUpdate).inHours > 24) {
      await _fetchPerformanceData();
    } else {
      await _loadData();
    }
  }

  Future<void> _loadPredictionsWithCache() async {
    if (_userId == null) return;

    // Try to load cached predictions first
    final cachedPredictions = await _dataService.loadCachedPredictions();

    if (cachedPredictions != null) {
      setState(() {
        for (final operation in cachedPredictions.keys) {
          if (_operationData.containsKey(operation)) {
            _operationData[operation]!.addAll(cachedPredictions[operation]!);
          }
        }
      });

      _loadAllPredictions().then((_) {
        // Cache the new predictions
        final Map<String, Map<String, dynamic>> predictionsToCache = {};
        for (final operation in _operationData.keys) {
          predictionsToCache[operation] = {
            'semanticPrediction':
                _operationData[operation]!['semanticPrediction'],
            'verbalPrediction': _operationData[operation]!['verbalPrediction'],
            'proceduralPrediction':
                _operationData[operation]!['proceduralPrediction'],
          };
        }
        _dataService.cachePredictionResults(predictionsToCache);
      });
    } else {
      // No cache, load predictions normally
      await _loadAllPredictions();
    }
  }

// MARK: - Optimized Prediction Loading

  void _updatePredictionValues() {
    setState(() {
      _operationData.forEach((operation, data) {
        // Check if we have any prediction values
        final semanticPrediction = data['semanticPrediction'];
        final verbalPrediction = data['verbalPrediction'];
        final proceduralPrediction = data['proceduralPrediction'];

        if (semanticPrediction != null ||
            verbalPrediction != null ||
            proceduralPrediction != null) {
          double sum = 0;
          int count = 0;

          if (semanticPrediction != null) {
            sum += semanticPrediction as double;
            count++;
          }

          if (verbalPrediction != null) {
            sum += verbalPrediction as double;
            count++;
          }

          if (proceduralPrediction != null) {
            sum += proceduralPrediction as double;
            count++;
          }

          if (count > 0) {
            // Calculate average and update predictedPerformance
            _operationData[operation]!['predictedPerformance'] = sum / count;
          }
        }
      });
    });
  }

  Future<void> _loadAllPredictions() async {
    if (_userId == null) return;

    final operations = [
      'Addition',
      'Subtraction',
      'Multiplication',
      'Division'
    ];
    final profiles = ['Semantic', 'Verbal', 'Procedural'];

    try {
      setState(() => _isLoading = true);

      // Create a single batch request to load all predictions at once
      List<Future<Map<String, dynamic>>> predictionFutures = [];

      for (final operation in operations) {
        for (final profile in profiles) {
          predictionFutures.add(PredictionService.predictUserPerformance(
                  _userId, operation, '$profile Dyscalculia')
              .then((result) => {
                    'operation': operation,
                    'profile': profile.toLowerCase(),
                    'value': result['success'] == true
                        ? result['prediction'] as double
                        : null
                  })
              .catchError((e) {
            print(
                '[ERROR] Error predicting $profile performance for $operation: $e');
            return {
              'operation': operation,
              'profile': profile.toLowerCase(),
              'value': null
            };
          }));
        }
      }

      // Wait for all predictions to complete together
      final results = await Future.wait(predictionFutures);

      // After all predictions are loaded and setState is called:
      if (mounted) {
        setState(() {
          for (final result in results) {
            final operation = result['operation'] as String;
            final profile = result['profile'] as String;
            final value = result['value'] as double?;

            if (_operationData.containsKey(operation) && value != null) {
              _operationData[operation]!['${profile}Prediction'] = value;
            }
          }
          _isLoading = false;
        });

        // Add this line to update the predictedPerformance values
        _updatePredictionValues();

        // After updating predictions, save to Firestore
        _saveOperationData();
      }
    } catch (e) {
      print('[ERROR] Error loading all predictions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // MARK: - Data Loading Methods

  Future<void> _loadData() async {
    final cachedData = await _dataService.loadCachedData();

    if (cachedData != null) {
      _updateStateWithData(cachedData);
    } else {
      await _fetchPerformanceData();
    }
  }

  Future<void> _fetchPerformanceData() async {
    setState(() => _isLoading = true);

    try {
      final firestoreData = await _dataService.fetchFirestoreData();

      if (firestoreData != null) {
        _updateStateWithData(firestoreData);
        print('[INFO] Loaded data from Firestore');
      } else {
        final fetchedData = await _dataService.fetchPerformanceData();
        _updateStateWithData(fetchedData);

        await _saveOperationData();
      }
    } catch (e) {
      print('[ERROR] Error in fetchPerformanceData: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateStateWithData(Map<String, Map<String, dynamic>> data) {
    setState(() {
      _operationData = data;
      _overallStats = _dataService.calculateOverallStats(_operationData);
      _isLoading = false;
    });

    // Save updated data to Firestore
    _saveOperationData();
  }

  // MARK: - Helper Methods

  String _getCompletionStatus() {
    final startedOps = _overallStats['startedOperations'] as int;
    final completedOps = _overallStats['completedOperations'] as int;
    final totalOps = _mathOperations.length;

    if (startedOps == 0) return 'Not started';
    if (completedOps == totalOps) return 'Complete';
    if (completedOps > 0) return 'In progress';
    return 'Just started';
  }

  String _formatLastActivity(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    }
    return 'Just now';
  }

  // MARK: - UI Building Methods

  @override
  Widget build(BuildContext context) {
    print(_operationData);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: _isLoading
          ? DashboardSkeleton()
          : RefreshIndicator(
              color: const Color(0xFF5E5CE6),
              onRefresh: _fetchPerformanceData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const CustomAppBar(
                    title: 'Dashboard',
                    subtitle: 'Overview of your performance',
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverallProgressCard(),
                          const SizedBox(height: 20),
                          DashboardPredictionCard(_operationData),
                          const SizedBox(height: 20),
                          InsightsSection(overallStats: _overallStats),
                          const SizedBox(height: 20),
                          const AnalyticsDashboardSection(),
                          const SizedBox(height: 20),
                          const DashboardSectionTitle(
                            title: 'Operation Analysis',
                          ),
                          const SizedBox(height: 16),
                          _buildOperationCards(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallProgressCard() {
    // Calculate metrics
    final totalCompletedLessons = _overallStats['totalCompletedLessons'] as int;
    final totalLessons = _overallStats['totalLessons'] as int;
    final totalCorrectAnswers = _overallStats['totalCorrectAnswers'] as int;
    final totalQuestions = _overallStats['totalQuestions'] as int;
    final averageTime = _overallStats['averageTime'] as double;
    final completedOperations = _overallStats['completedOperations'] as int;
    final totalOperations = _mathOperations.length;

    // Format display values
    final overallAccuracy = totalQuestions > 0
        ? (totalCorrectAnswers / totalQuestions * 100).toStringAsFixed(1)
        : '0.0';
    final completionRate = totalLessons > 0
        ? (totalCompletedLessons / totalLessons * 100).toStringAsFixed(1)
        : '0.0';
    final operationCompletionRate =
        (completedOperations / totalOperations * 100).toStringAsFixed(1);

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              CompletionBadge(
                operationCompletionRate,
                completionRate: completionRate,
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DashboardStatItem(
                icon: Icons.check_circle,
                color: const Color(0xFF5E5CE6),
                value: '$completionRate%',
                label: 'Lesson\nCompletion',
              ),
              DashboardStatItem(
                icon: Icons.timer,
                color: const Color(0xFFFF9F0A),
                value: '${averageTime.toStringAsFixed(1)}s',
                label: 'Avg.\nResponse Time',
              ),
              DashboardStatItem(
                icon: Icons.analytics,
                color: const Color(0xFF30D158),
                value: '$overallAccuracy%',
                label: 'Accuracy\nRate',
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value:
                totalOperations > 0 ? completedOperations / totalOperations : 0,
            backgroundColor: const Color(0xFFF5F5F7),
            color: const Color(0xFF5E5CE6),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedOperations of $totalOperations operations completed',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF1D1D1F).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCards() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _mathOperations.length,
      itemBuilder: (context, index) => OperationCards(
        operation: _mathOperations[index],
        operationData: _operationData,
        navigateToOperationDetail: _navigateToOperationDetail,
        formatLastActivity: _formatLastActivity,
      ),
    );
  }

  void _navigateToOperationDetail(
      String title, Map<String, dynamic> data, Color color) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OperationDetailScreen(
          operationName: title,
          operationData: data,
          color: color,
        ),
      ),
    );
  }
}
