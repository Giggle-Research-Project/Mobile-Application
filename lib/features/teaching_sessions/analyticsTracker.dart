import 'package:firebase_database/firebase_database.dart';

class LearningAnalyticsTracker {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference _userRef;

  // Track the current states and their start times
  String _currentEmotion = '';
  double _currentConcentrationScore = 0.0;
  double _currentVoiceConfidence = 0.0;

  // Timestamps for tracking duration of each state
  int _emotionStartTime = 0;
  int _concentrationStartTime = 0;
  int _voiceConfidenceStartTime = 0;

  // Concentration states
  static const String HIGH_FOCUS = "Highly Focused";
  static const String MODERATE_FOCUS = "Moderately Focused";
  static const String DISTRACTED = "Distracted";

  LearningAnalyticsTracker({
    required String userId,
    required String courseName,
    required String dyscalculiaType,
  }) {
    // Initialize the database reference for this specific user and course
    _userRef = _database
        .ref()
        .child('learningAnalytics')
        .child(userId)
        .child(courseName)
        .child(dyscalculiaType);

    print(
        '📊 Learning Analytics Tracker initialized for user: $userId, course: $courseName, type: $dyscalculiaType');

    // Initialize session
    startSession();
  }

  // Update concentration data with detailed tracking
  void updateConcentration(double score) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Round score to nearest 0.1 for grouping similar scores
    final roundedScore = (score * 10).round() / 10;
    final scoreKey = roundedScore.toString();

    // Determine concentration status category
    String status = DISTRACTED;
    if (score >= 0.8) {
      status = HIGH_FOCUS;
    } else if (score >= 0.5) {
      status = MODERATE_FOCUS;
    }

    // Determine previous status for the current concentration score
    String previousStatus = DISTRACTED;
    if (_currentConcentrationScore >= 0.8) {
      previousStatus = HIGH_FOCUS;
    } else if (_currentConcentrationScore >= 0.5) {
      previousStatus = MODERATE_FOCUS;
    }

    print(
        '🔍 Updating concentration from $_currentConcentrationScore to $roundedScore (status: $status)');

    // If this is a different concentration level, update previous duration
    if (_currentConcentrationScore > 0 &&
        _currentConcentrationScore != roundedScore) {
      _saveConcentrationDuration(_currentConcentrationScore.toString(), now);

      // If status category has changed, update the previous status duration
      if (previousStatus != status) {
        _savePreviousConcentrationStatusDuration(previousStatus, now);
      }
    }

    // Update current concentration and start time
    if (_currentConcentrationScore != roundedScore) {
      _currentConcentrationScore = roundedScore;
      _concentrationStartTime = now;

      print('⏱️ Starting timer for concentration level: $roundedScore at $now');

      // Ensure concentration node structure exists
      _ensureConcentrationNodeExists(scoreKey, now);

      // Also track by status category
      _trackConcentrationByStatus(status, now);
    } else {
      // Just update the timestamp if concentration level hasn't changed
      _userRef
          .child('concentration')
          .child(scoreKey)
          .update({'lastDetected': now});

      // Update status node
      _userRef
          .child('concentrationByStatus')
          .child(status)
          .update({'lastDetected': now});
    }

    // Update concentrationStatus for easier querying
    _userRef.child('concentrationStatus').update(
        {'currentStatus': status, 'currentScore': score, 'lastUpdated': now});

    print(
        '🧠 Updated concentration score: $score (rounded to $roundedScore, status: $status)');
  }

  // Track concentration by status category (Highly Focused, Moderately Focused, Distracted)
  void _trackConcentrationByStatus(String status, int timestamp) {
    _userRef
        .child('concentrationByStatus')
        .child(status)
        .once()
        .then((snapshot) {
      if (!snapshot.snapshot.exists) {
        _userRef.child('concentrationByStatus').child(status).set({
          'firstDetected': timestamp,
          'totalDuration': 0,
          'occurrences': 1,
          'lastDetected': timestamp
        });
      } else {
        _userRef.child('concentrationByStatus').child(status).update({
          'lastDetected': timestamp,
          'occurrences': ServerValue.increment(1)
        });
      }
    });
  }

  // Helper method to save the duration for the previous concentration status
  void _savePreviousConcentrationStatusDuration(
      String previousStatus, int now) {
    if (_concentrationStartTime > 0) {
      // Convert milliseconds to seconds
      final durationMs = now - _concentrationStartTime;
      final duration = (durationMs / 1000).round();

      print(
          '⏱️ Saving duration for concentration status $previousStatus: $duration seconds');

      _userRef.child('concentrationByStatus').child(previousStatus).update({
        'totalDuration': ServerValue.increment(duration),
        'lastDuration': duration,
        'lastDetected': now
      });
    }
  }

  // Helper method to ensure the concentration node exists
  void _ensureConcentrationNodeExists(String scoreKey, int timestamp) {
    _userRef.child('concentration').once().then((snapshot) {
      // If concentration node doesn't exist at all, create it
      if (!snapshot.snapshot.exists) {
        print('📂 Creating initial concentration structure');
        _userRef.child('concentration').set({});
      }

      // Now check if this specific score level exists
      _userRef
          .child('concentration')
          .child(scoreKey)
          .once()
          .then((scoreSnapshot) {
        if (!scoreSnapshot.snapshot.exists) {
          print('📝 Creating new concentration level node: $scoreKey');
          _userRef.child('concentration').child(scoreKey).set({
            'firstDetected': timestamp,
            'totalDuration': 0,
            'occurrences': 1,
            'lastDetected': timestamp
          });
        } else {
          print('📈 Updating existing concentration level: $scoreKey');
          // Increment occurrences without resetting totalDuration
          _userRef.child('concentration').child(scoreKey).update({
            'lastDetected': timestamp,
            'occurrences': ServerValue.increment(1)
          });
        }
      });
    });
  }

  // Helper method to save concentration duration
  void _saveConcentrationDuration(String scoreKey, int now) {
    // Convert milliseconds to seconds
    final durationMs = now - _concentrationStartTime;
    final duration = (durationMs / 1000).round();

    print('⏱️ Saving duration for concentration level $scoreKey: $duration');

    _userRef.child('concentration').once().then((snapshot) {
      if (snapshot.snapshot.exists) {
        _userRef.child('concentration').child(scoreKey).update({
          'totalDuration': ServerValue.increment(duration),
          'lastDuration': duration,
          'lastDetected': now
        });

        print(
            '💾 Updated duration for concentration level $scoreKey: +$duration, total will be updated in Firebase');
      } else {
        print('⚠️ Concentration node doesn\'t exist, creating it');
        _userRef.child('concentration').set({});
        _userRef.child('concentration').child(scoreKey).set({
          'firstDetected': _concentrationStartTime,
          'totalDuration': duration,
          'lastDuration': duration,
          'occurrences': 1,
          'lastDetected': now
        });
      }
    });
  }

  // Update emotion data with tracking duration
  void updateEmotion(String emotion, double confidence) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // If this is a new emotion, update the previous emotion's duration
    if (_currentEmotion.isNotEmpty && _currentEmotion != emotion) {
      _saveEmotionDuration(_currentEmotion, now);
    }

    // Update current emotion and start time
    if (_currentEmotion != emotion) {
      _currentEmotion = emotion;
      _emotionStartTime = now;

      // Create a new node for this emotion if it's the first occurrence
      _userRef.child('emotion').child(emotion).once().then((snapshot) {
        if (!snapshot.snapshot.exists) {
          _userRef.child('emotion').child(emotion).set({
            'firstDetected': now,
            'totalDuration': 0,
            'confidence': confidence,
            'occurrences': 1
          });
        } else {
          // Increment occurrences
          _userRef.child('emotion').child(emotion).update({
            'lastDetected': now,
            'confidence': confidence,
            'occurrences': ServerValue.increment(1)
          });
        }
      });
    } else {
      // Just update the confidence if emotion hasn't changed
      _userRef
          .child('emotion')
          .child(emotion)
          .update({'confidence': confidence, 'lastDetected': now});
    }

    // Update current emotion status
    _userRef.child('emotionStatus').update({
      'currentEmotion': emotion,
      'confidence': confidence,
      'lastUpdated': now
    });

    print('😊 Updated emotion: $emotion with confidence: $confidence');
  }

  // Helper method to save emotion duration
  void _saveEmotionDuration(String emotion, int now) {
    // Convert milliseconds to seconds
    final durationMs = now - _emotionStartTime;
    final duration = (durationMs / 1000).round();

    _userRef.child('emotion').child(emotion).update({
      'totalDuration': ServerValue.increment(duration),
      'lastDuration': duration,
      'lastDetected': now
    });

    print('⏱️ Emotion $emotion lasted for $duration');
  }

  // Update voice confidence data
  void updateVoiceConfidence(double confidence) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Round confidence to nearest 0.1 for grouping similar values
    final roundedConfidence = (confidence * 10).round() / 10;
    final confidenceKey = roundedConfidence.toString();

    // If this is a different voice confidence level, update previous duration
    if (_currentVoiceConfidence > 0 &&
        _currentVoiceConfidence != roundedConfidence) {
      _saveVoiceConfidenceDuration(_currentVoiceConfidence.toString(), now);
    }

    // Update current voice confidence and start time
    if (_currentVoiceConfidence != roundedConfidence) {
      _currentVoiceConfidence = roundedConfidence;
      _voiceConfidenceStartTime = now;

      // Create a new voice confidence level node if it's the first occurrence
      _userRef
          .child('voiceConfidence')
          .child(confidenceKey)
          .once()
          .then((snapshot) {
        if (!snapshot.snapshot.exists) {
          _userRef.child('voiceConfidence').child(confidenceKey).set({
            'firstDetected': now,
            'totalDuration': 0,
            'occurrences': 1,
            'lastDetected': now
          });
        } else {
          // Increment occurrences
          _userRef.child('voiceConfidence').child(confidenceKey).update(
              {'lastDetected': now, 'occurrences': ServerValue.increment(1)});
        }
      });
    } else {
      // Just update the timestamp if voice confidence level hasn't changed
      _userRef
          .child('voiceConfidence')
          .child(confidenceKey)
          .update({'lastDetected': now});
    }

    // Update current voice confidence status
    _userRef
        .child('voiceConfidenceStatus')
        .update({'currentScore': confidence, 'lastUpdated': now});

    print(
        '🎤 Updated voice confidence: $confidence (rounded to $roundedConfidence)');
  }

  // Helper method to save voice confidence duration
  void _saveVoiceConfidenceDuration(String confidenceKey, int now) {
    // Convert milliseconds to seconds
    final durationMs = now - _voiceConfidenceStartTime;
    final duration = (durationMs / 1000).round();

    _userRef.child('voiceConfidence').child(confidenceKey).update({
      'totalDuration': ServerValue.increment(duration),
      'lastDuration': duration,
      'lastDetected': now
    });

    print('⏱️ Voice confidence level $confidenceKey lasted for $duration');
  }

  // Call this method when the session ends to save final durations
  Future<void> finalizeSession() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Save durations for the current states
    if (_currentEmotion.isNotEmpty) {
      _saveEmotionDuration(_currentEmotion, now);
    }

    if (_currentConcentrationScore > 0) {
      _saveConcentrationDuration(_currentConcentrationScore.toString(), now);

      // Save the duration for the current concentration status
      String currentStatus = DISTRACTED;
      if (_currentConcentrationScore >= 0.8) {
        currentStatus = HIGH_FOCUS;
      } else if (_currentConcentrationScore >= 0.5) {
        currentStatus = MODERATE_FOCUS;
      }
      _savePreviousConcentrationStatusDuration(currentStatus, now);
    }

    if (_currentVoiceConfidence > 0) {
      _saveVoiceConfidenceDuration(_currentVoiceConfidence.toString(), now);
    }

    // Calculate the average concentration score from all the recorded values
    // First, we'll get all the concentration scores and their durations
    final concentrationSnapshot = await _userRef.child('concentration').get();
    if (concentrationSnapshot.exists) {
      Map<dynamic, dynamic> concentrationData =
          concentrationSnapshot.value as Map<dynamic, dynamic>;

      double totalWeightedScore = 0.0;
      int totalDuration = 0;

      concentrationData.forEach((key, value) {
        if (value is Map && value.containsKey('totalDuration')) {
          double score = double.tryParse(key.toString()) ?? 0.0;
          int duration = value['totalDuration'] as int;

          totalWeightedScore += score * duration;
          totalDuration += duration;
        }
      });

      double averageScore =
          totalDuration > 0 ? totalWeightedScore / totalDuration : 0.0;

      // Get session start time
      final sessionStartSnapshot =
          await _userRef.child('sessionSummary').child('startTime').get();
      final sessionStartTime =
          sessionStartSnapshot.exists ? sessionStartSnapshot.value as int : now;

      // Calculate total session duration in seconds
      final totalSessionDurationMs = now - sessionStartTime;
      final totalSessionDuration = (totalSessionDurationMs / 1000).round();

      // Save session summary
      _userRef.child('sessionSummary').update({
        'endTime': now,
        'totalDuration': totalSessionDuration,
        'averageConcentration': averageScore,
        'sessionDate':
            DateTime.now().toString().split(' ')[0] // YYYY-MM-DD format
      });

      // Add analytics insight
      String concentrationInsight = "Low concentration";
      if (averageScore >= 0.8) {
        concentrationInsight = "Excellent concentration";
      } else if (averageScore >= 0.5) {
        concentrationInsight = "Good concentration";
      } else if (averageScore >= 0.3) {
        concentrationInsight = "Moderate concentration";
      }

      _userRef.child('sessionSummary').child('insights').update({
        'concentrationQuality': concentrationInsight,
        'sessionLengthMinutes': totalSessionDuration / 60, // Convert to minutes
        'timestamp': now
      });
    } else {
      // No concentration data exists, use default values
      final startTimeSnapshot =
          await _userRef.child('sessionSummary').child('startTime').get();
      final startTime =
          startTimeSnapshot.exists ? startTimeSnapshot.value as int : now;
      final durationMs = now - startTime;
      final duration = (durationMs / 1000).round();

      _userRef.child('sessionSummary').update({
        'endTime': now,
        'totalDuration': duration,
        'averageConcentration': 0.0,
        'sessionDate':
            DateTime.now().toString().split(' ')[0] // YYYY-MM-DD format
      });
    }

    print('📝 Learning analytics session finalized');
  }

  // Initialize a new session
  void startSession() {
    final now = DateTime.now().millisecondsSinceEpoch;

    _userRef.child('sessionSummary').update({
      'startTime': now,
      'date': DateTime.now().toString().split(' ')[0] // YYYY-MM-DD format
    });

    // Reset state tracking variables
    _currentEmotion = '';
    _currentConcentrationScore = 0.0;
    _currentVoiceConfidence = 0.0;
    _emotionStartTime = 0;
    _concentrationStartTime = 0;
    _voiceConfidenceStartTime = 0;

    print('🚀 New learning analytics session started');
  }
}
