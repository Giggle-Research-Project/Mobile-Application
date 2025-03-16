import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Core Data Models
class EmotionData {
  final double confidence;
  final int firstDetected;
  final int lastDetected;
  final int lastDuration;
  final int occurrences;
  final int totalDuration;

  EmotionData({
    required this.confidence,
    required this.firstDetected,
    required this.lastDetected,
    required this.lastDuration,
    required this.occurrences,
    required this.totalDuration,
  });

  factory EmotionData.fromMap(Map<dynamic, dynamic> map) {
    return EmotionData(
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      firstDetected: map['firstDetected'] as int? ?? 0,
      lastDetected: map['lastDetected'] as int? ?? 0,
      lastDuration: map['lastDuration'] as int? ?? 0,
      occurrences: map['occurrences'] as int? ?? 0,
      totalDuration: map['totalDuration'] as int? ?? 0,
    );
  }
}

class ConcentrationData {
  final int firstDetected;
  final int lastDetected;
  final int occurrences;
  final int totalDuration;

  ConcentrationData({
    required this.firstDetected,
    required this.lastDetected,
    required this.occurrences,
    required this.totalDuration,
  });

  factory ConcentrationData.fromMap(Map<dynamic, dynamic> map) {
    return ConcentrationData(
      firstDetected: map['firstDetected'] as int? ?? 0,
      lastDetected: map['lastDetected'] as int? ?? 0,
      occurrences: map['occurrences'] as int? ?? 0,
      totalDuration: map['totalDuration'] as int? ?? 0,
    );
  }
}

class ConcentrationStatus {
  final double currentScore;
  final String currentStatus;
  final int lastUpdated;

  ConcentrationStatus({
    required this.currentScore,
    required this.currentStatus,
    required this.lastUpdated,
  });

  factory ConcentrationStatus.fromMap(Map<dynamic, dynamic> map) {
    return ConcentrationStatus(
      currentScore: (map['currentScore'] as num?)?.toDouble() ?? 0.0,
      currentStatus: map['currentStatus'] as String? ?? '',
      lastUpdated: map['lastUpdated'] as int? ?? 0,
    );
  }
}

class EmotionStatus {
  final double confidence;
  final String currentEmotion;
  final int lastUpdated;

  EmotionStatus({
    required this.confidence,
    required this.currentEmotion,
    required this.lastUpdated,
  });

  factory EmotionStatus.fromMap(Map<dynamic, dynamic> map) {
    return EmotionStatus(
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      currentEmotion: map['currentEmotion'] as String? ?? '',
      lastUpdated: map['lastUpdated'] as int? ?? 0,
    );
  }
}

class SessionSummary {
  final double averageConcentration;
  final String date;
  final int endTime;
  final String sessionDate;
  final int startTime;
  final int totalDuration;

  SessionSummary({
    required this.averageConcentration,
    required this.date,
    required this.endTime,
    required this.sessionDate,
    required this.startTime,
    required this.totalDuration,
  });

  factory SessionSummary.fromMap(Map<dynamic, dynamic> map) {
    return SessionSummary(
      averageConcentration:
          (map['averageConcentration'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] as String? ?? '',
      endTime: map['endTime'] as int? ?? 0,
      sessionDate: map['sessionDate'] as String? ?? '',
      startTime: map['startTime'] as int? ?? 0,
      totalDuration: map['totalDuration'] as int? ?? 0,
    );
  }
}

// Semantic Dyscalculia Data Model
class SemanticDyscalculiaData {
  final Map<String, ConcentrationData> concentrationByStatus;
  final ConcentrationStatus concentrationStatus;
  final Map<String, EmotionData> emotion;
  final EmotionStatus emotionStatus;
  final SessionSummary sessionSummary;

  SemanticDyscalculiaData({
    required this.concentrationByStatus,
    required this.concentrationStatus,
    required this.emotion,
    required this.emotionStatus,
    required this.sessionSummary,
  });

  factory SemanticDyscalculiaData.fromMap(Map<dynamic, dynamic> map) {
    // Parse concentrationByStatus
    final concentrationByStatusMap = <String, ConcentrationData>{};
    final concentrationByStatusRaw =
        map['concentrationByStatus'] as Map<dynamic, dynamic>? ?? {};
    concentrationByStatusRaw.forEach((key, value) {
      concentrationByStatusMap[key.toString()] =
          ConcentrationData.fromMap(value as Map<dynamic, dynamic>);
    });

    // Parse emotion data
    final emotionMap = <String, EmotionData>{};
    final emotionRaw = map['emotion'] as Map<dynamic, dynamic>? ?? {};
    emotionRaw.forEach((key, value) {
      emotionMap[key.toString()] =
          EmotionData.fromMap(value as Map<dynamic, dynamic>);
    });

    return SemanticDyscalculiaData(
      concentrationByStatus: concentrationByStatusMap,
      concentrationStatus: ConcentrationStatus.fromMap(
          map['concentrationStatus'] as Map<dynamic, dynamic>? ?? {}),
      emotion: emotionMap,
      emotionStatus: EmotionStatus.fromMap(
          map['emotionStatus'] as Map<dynamic, dynamic>? ?? {}),
      sessionSummary: SessionSummary.fromMap(
          map['sessionSummary'] as Map<dynamic, dynamic>? ?? {}),
    );
  }
}

// Learning Analytics Service
class LearningAnalyticsService {
  final DatabaseReference _databaseRef;

  // Singleton pattern
  static final LearningAnalyticsService _instance =
      LearningAnalyticsService._internal();

  factory LearningAnalyticsService() {
    return _instance;
  }

  LearningAnalyticsService._internal()
      : _databaseRef = FirebaseDatabase.instance.ref('learningAnalytics');

  // Get semantic dyscalculia data for a specific user and math operation
  Future<SemanticDyscalculiaData?> getSemanticDyscalculiaData(
      String userId, String mathOperation) async {
    final path = '$userId/$mathOperation/Semantic Dyscalculia';
    final snapshot = await _databaseRef.child(path).get();

    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }

    return SemanticDyscalculiaData.fromMap(
        snapshot.value as Map<dynamic, dynamic>);
  }

  // Stream semantic dyscalculia data for a specific user and math operation
  Stream<SemanticDyscalculiaData?> streamSemanticDyscalculiaData(
      String userId, String mathOperation) {
    final path = '$userId/$mathOperation/Semantic Dyscalculia';
    return _databaseRef.child(path).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }

      return SemanticDyscalculiaData.fromMap(
          event.snapshot.value as Map<dynamic, dynamic>);
    });
  }
}

// Analytics Service for Semantic Dyscalculia
class SemanticDyscalculiaAnalyticsService {
  final LearningAnalyticsService _analyticsService = LearningAnalyticsService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  // Cache data
  Map<String, dynamic> _cachedAnalytics = {};
  DateTime? _lastFetchTime;
  final int _cacheDurationMinutes = 5;

  // Standard math operations
  final List<String> _mathOperations = [
    'Addition',
    'Subtraction',
    'Multiplication',
    'Division'
  ];

  // Get dyscalculia analytics for the current user
  Future<Map<String, dynamic>> getDyscalculiaAnalytics() async {
    // Check if we have valid cached data
    if (_isCacheValid()) {
      return _cachedAnalytics;
    }

    if (_userId == null) {
      return {};
    }

    try {
      final Map<String, dynamic> dyscalculiaData = {};

      // Fetch data for each math operation
      for (final operation in _mathOperations) {
        final semanticData = await _analyticsService.getSemanticDyscalculiaData(
            _userId!, operation);

        if (semanticData != null) {
          dyscalculiaData[operation] = {
            'concentration':
                _processConcentrationData(semanticData.concentrationByStatus),
            'emotion': _processEmotionData(semanticData.emotion),
            'averageConcentration':
                semanticData.sessionSummary.averageConcentration,
            'sessionDuration': semanticData.sessionSummary.totalDuration,
            'lastSessionDate': semanticData.sessionSummary.sessionDate,
          };
        }
      }

      // Calculate overall scores
      dyscalculiaData['overall'] = _calculateOverallScores(dyscalculiaData);

      // Cache the data
      _cachedAnalytics = dyscalculiaData;
      _lastFetchTime = DateTime.now();

      return dyscalculiaData;
    } catch (e) {
      print('[ERROR] Error fetching semantic dyscalculia data: $e');
      return {};
    }
  }

  // Check if cache is valid
  bool _isCacheValid() {
    return _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes <
            _cacheDurationMinutes &&
        _cachedAnalytics.isNotEmpty;
  }

  // Process concentration data
  Map<String, dynamic> _processConcentrationData(
      Map<String, ConcentrationData> concentrationByStatus) {
    // Calculate total duration
    int totalDuration = 0;
    concentrationByStatus.forEach((_, data) {
      totalDuration += data.totalDuration;
    });

    // Initialize result
    final Map<String, dynamic> result = {
      'totalDuration': totalDuration,
      'statusBreakdown': <String, double>{},
      'mostFrequentStatus': '',
      'maxFrequency': 0.0,
    };

    String mostFrequentStatus = '';
    double maxPercentage = 0.0;

    // Calculate percentages
    concentrationByStatus.forEach((status, data) {
      final percentage =
          totalDuration > 0 ? (data.totalDuration / totalDuration) * 100 : 0.0;
      result['statusBreakdown'][status] = percentage;

      if (percentage > maxPercentage) {
        maxPercentage = percentage;
        mostFrequentStatus = status;
      }
    });

    result['mostFrequentStatus'] = mostFrequentStatus;
    result['maxFrequency'] = maxPercentage;

    return result;
  }

  // Process emotion data
  Map<String, dynamic> _processEmotionData(
      Map<String, EmotionData> emotionData) {
    // Calculate total duration
    int totalDuration = 0;
    emotionData.forEach((_, data) {
      totalDuration += data.totalDuration;
    });

    // Initialize result
    final Map<String, dynamic> result = {
      'totalDuration': totalDuration,
      'emotionBreakdown': <String, double>{},
      'primaryEmotion': '',
      'primaryEmotionPercentage': 0.0,
      'averageConfidence': 0.0,
    };

    String primaryEmotion = '';
    double maxPercentage = 0.0;
    double totalConfidence = 0.0;
    int emotionCount = 0;

    // Calculate percentages
    emotionData.forEach((emotion, data) {
      final percentage =
          totalDuration > 0 ? (data.totalDuration / totalDuration) * 100 : 0.0;
      result['emotionBreakdown'][emotion] = percentage;

      if (percentage > maxPercentage) {
        maxPercentage = percentage;
        primaryEmotion = emotion;
      }

      totalConfidence += data.confidence;
      emotionCount++;
    });

    result['primaryEmotion'] = primaryEmotion;
    result['primaryEmotionPercentage'] = maxPercentage;
    result['averageConfidence'] =
        emotionCount > 0 ? totalConfidence / emotionCount : 0.0;

    return result;
  }

  // Calculate overall scores
  Map<String, dynamic> _calculateOverallScores(
      Map<String, dynamic> dyscalculiaData) {
    double totalConcentration = 0.0;
    int operationsWithData = 0;
    Map<String, double> allEmotions = {};
    Map<String, double> allConcentrationStatuses = {};

    dyscalculiaData.forEach((operation, data) {
      if (operation != 'overall' && data != null) {
        // Track average concentration
        if (data.containsKey('averageConcentration')) {
          totalConcentration += data['averageConcentration'];
          operationsWithData++;
        }

        // Track emotions across operations
        if (data.containsKey('emotion') &&
            data['emotion'].containsKey('emotionBreakdown')) {
          final emotions =
              data['emotion']['emotionBreakdown'] as Map<String, double>;
          emotions.forEach((emotion, percentage) {
            allEmotions[emotion] = (allEmotions[emotion] ?? 0.0) + percentage;
          });
        }

        // Track concentration statuses across operations
        if (data.containsKey('concentration') &&
            data['concentration'].containsKey('statusBreakdown')) {
          final statuses =
              data['concentration']['statusBreakdown'] as Map<String, double>;
          statuses.forEach((status, percentage) {
            allConcentrationStatuses[status] =
                (allConcentrationStatuses[status] ?? 0.0) + percentage;
          });
        }
      }
    });

    // Calculate averages
    final averageConcentration =
        operationsWithData > 0 ? totalConcentration / operationsWithData : 0.0;

    // Find dominant emotion and status
    final dominantEmotion =
        _findDominantMetric(allEmotions, operationsWithData);
    final dominantStatus =
        _findDominantMetric(allConcentrationStatuses, operationsWithData);

    return {
      'averageConcentration': averageConcentration,
      'dominantEmotion': dominantEmotion['name'],
      'dominantEmotionPercentage': dominantEmotion['value'],
      'dominantConcentrationStatus': dominantStatus['name'],
      'dominantStatusPercentage': dominantStatus['value'],
      'operationsWithData': operationsWithData,
    };
  }

  // Helper to find dominant metric
  Map<String, dynamic> _findDominantMetric(
      Map<String, double> metrics, int divisor) {
    String dominantName = '';
    double maxValue = 0.0;

    metrics.forEach((name, total) {
      final average = divisor > 0 ? total / divisor : 0.0;
      if (average > maxValue) {
        maxValue = average;
        dominantName = name;
      }
    });

    return {'name': dominantName, 'value': maxValue};
  }

  // Get learning insights based on analytics
  Map<String, dynamic> getLearningInsights(
      Map<String, dynamic> dyscalculiaData) {
    final insights = <String, dynamic>{};
    final overall = dyscalculiaData['overall'];
    if (overall == null) return insights;

    // Concentration insight
    final concentrationScore = overall['averageConcentration'];
    insights['concentration'] = {
      'score': concentrationScore,
      'insight': _getConcentrationInsight(concentrationScore)
    };

    // Emotion insight
    final dominantEmotion = overall['dominantEmotion'];
    final emotionAnalysis = _getEmotionInsight(dominantEmotion);
    insights['emotion'] = {
      'dominantEmotion': dominantEmotion,
      'insight': emotionAnalysis['insight'],
      'recommendation': emotionAnalysis['recommendation'],
    };

    // Operation-specific insights
    insights['operations'] = _generateOperationInsights(dyscalculiaData);

    // Find operation that needs most attention
    insights['recommendedFocus'] =
        _findRecommendedFocus(insights['operations']);

    return insights;
  }

  // Get concentration insight based on score
  String _getConcentrationInsight(double score) {
    if (score > 80) return 'Excellent concentration across math operations';
    if (score > 60) return 'Good concentration, but room for improvement';
    if (score > 40) return 'Moderate concentration levels detected';
    return 'Concentration difficulties noted';
  }

  // Get emotion insight and recommendation
  Map<String, String> _getEmotionInsight(String emotion) {
    final lowerEmotion = emotion.toLowerCase();

    if (['happy', 'joy'].contains(lowerEmotion)) {
      return {
        'insight': 'Positive engagement with math activities',
        'recommendation': 'Maintain this positive learning environment'
      };
    } else if (lowerEmotion == 'neutral') {
      return {
        'insight': 'Neutral emotional response to math activities',
        'recommendation':
            'Consider adding more engaging elements to increase positive emotions'
      };
    } else if (lowerEmotion == 'confused') {
      return {
        'insight': 'Confusion detected during math activities',
        'recommendation':
            'Consider revisiting basic concepts and providing clearer explanations'
      };
    } else if (['frustrated', 'angry'].contains(lowerEmotion)) {
      return {
        'insight': 'Frustration detected during math activities',
        'recommendation':
            'Break down problems into smaller steps and provide more encouragement'
      };
    } else if (['worried', 'anxious'].contains(lowerEmotion)) {
      return {
        'insight': 'Math anxiety detected',
        'recommendation':
            'Use anxiety-reduction techniques and positive reinforcement'
      };
    }

    return {
      'insight': 'Mixed emotional responses to math activities',
      'recommendation':
          'Monitor emotional responses to identify specific triggers'
    };
  }

  // Generate operation-specific insights
  Map<String, Map<String, dynamic>> _generateOperationInsights(
      Map<String, dynamic> data) {
    final operationInsights = <String, Map<String, dynamic>>{};

    _mathOperations.forEach((operation) {
      if (data.containsKey(operation) && data[operation] != null) {
        final opData = data[operation];
        final concentration = opData['averageConcentration'] ?? 0.0;
        final emotion = opData['emotion']['primaryEmotion'] ?? '';

        String status = 'Needs attention';
        if (concentration > 70) {
          status = 'Strong';
        } else if (concentration > 50) {
          status = 'Moderate';
        }

        operationInsights[operation] = {
          'status': status,
          'concentration': concentration,
          'primaryEmotion': emotion,
        };
      }
    });

    return operationInsights;
  }

  // Find operation that needs most attention
  String _findRecommendedFocus(
      Map<String, Map<String, dynamic>> operationInsights) {
    String recommendedFocus = '';
    double lowestConcentration = 100.0;

    operationInsights.forEach((operation, data) {
      final concentration = data['concentration'] as double;
      if (concentration < lowestConcentration && concentration > 0) {
        lowestConcentration = concentration;
        recommendedFocus = operation;
      }
    });

    return recommendedFocus;
  }
}
