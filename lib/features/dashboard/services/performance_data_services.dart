import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giggle/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceDataService {
  final String? userId;
  final List<Map<String, dynamic>> mathOperations = AppConstants.mathOperations;
  final List<String> dyscalculiaTypes = AppConstants.dyscalculiaTypes;

  PerformanceDataService({this.userId});

  Future<Map<String, Map<String, dynamic>>> fetchPerformanceData() async {
    if (userId == null) return {};

    Map<String, Map<String, dynamic>> operationData = {};

    // Initialize operation data
    for (var operation in mathOperations) {
      final operationName = operation['title'];
      operationData[operationName] = {
        'completedLessons': 0,
        'totalLessons': 0,
        'averageTime': 0.0,
        'correctAnswers': 0,
        'totalQuestions': 0,
        'timeValues': <double>[],
        'started': false,
        'completed': false,
        'lastActivityDate': null,
        'difficultyScore': 0.0,
        'predictedPerformance': null,
        'mlData': {
          'test1_marks': 0,
          'test1_time': 1,
          'test2_marks': 0,
          'test2_time': 1,
          'test3_marks': 0,
          'test3_time': 1,
        },
      };
    }

    try {
      final List<Future> futures = [];

      for (var operation in mathOperations) {
        final operationName = operation['title'];
        bool operationStarted = false;
        bool allLessonsCompleted = true;

        for (var dyscalculiaType in dyscalculiaTypes) {
          // Video lesson query
          futures.add(FirebaseFirestore.instance
              .collection('functionActivities')
              .doc(userId)
              .collection(operationName)
              .doc(dyscalculiaType)
              .collection('video_lesson')
              .doc('progress')
              .get()
              .then((doc) {
            if (doc.exists) {
              operationData[operationName]!['totalLessons'] =
                  (operationData[operationName]!['totalLessons'] as int) + 1;

              if (doc.data()?['completed'] == true) {
                operationData[operationName]!['completedLessons'] =
                    (operationData[operationName]!['completedLessons'] as int) +
                        1;
              } else {
                allLessonsCompleted = false;
              }

              if (doc.data()?['lastAccessed'] != null) {
                final timestamp = doc.data()?['lastAccessed'] as Timestamp;
                final date = timestamp.toDate();

                if (operationData[operationName]!['lastActivityDate'] == null ||
                    date.isAfter(
                        operationData[operationName]!['lastActivityDate'])) {
                  operationData[operationName]!['lastActivityDate'] = date;
                }
              }

              operationStarted = true;
            }
          }));

          // Interactive session query
          futures.add(FirebaseFirestore.instance
              .collection('functionActivities')
              .doc(userId)
              .collection(operationName)
              .doc(dyscalculiaType)
              .collection('interactive_session')
              .doc('progress')
              .get()
              .then((doc) {
            if (doc.exists) {
              operationData[operationName]!['totalLessons'] =
                  (operationData[operationName]!['totalLessons'] as int) + 1;

              if (doc.data()?['completed'] == true) {
                operationData[operationName]!['completedLessons'] =
                    (operationData[operationName]!['completedLessons'] as int) +
                        1;
              } else {
                allLessonsCompleted = false;
              }

              if (doc.data()?['timeElapsed'] != null) {
                final timeElapsed =
                    (doc.data()?['timeElapsed'] as num).toDouble();
                operationData[operationName]!['timeValues'].add(timeElapsed);

                operationData[operationName]!['averageTime'] =
                    (operationData[operationName]!['averageTime'] as double) +
                        timeElapsed;
              }

              if (doc.data()?['lastAccessed'] != null) {
                final timestamp = doc.data()?['lastAccessed'] as Timestamp;
                final date =
                    timestamp.toDate(); // Convert Timestamp to DateTime

                if (operationData[operationName]!['lastActivityDate'] == null ||
                    date.isAfter(
                        operationData[operationName]!['lastActivityDate']
                            as DateTime)) {
                  operationData[operationName]!['lastActivityDate'] = date;
                }
              }

              operationStarted = true;
            }
          }));

          // Solo sessions for ML prediction data
          Map<String, dynamic> soloSessionsData = {
            'questionOne': {'isCorrect': false, 'timeElapsed': 0.0},
            'questionTwo': {'isCorrect': false, 'timeElapsed': 0.0},
            'questionThree': {'isCorrect': false, 'timeElapsed': 0.0},
          };

          // Fetch each question data separately
          for (String questionName in [
            'questionOne',
            'questionTwo',
            'questionThree'
          ]) {
            futures.add(FirebaseFirestore.instance
                .collection('functionActivities')
                .doc(userId)
                .collection(operationName)
                .doc(dyscalculiaType)
                .collection('solo_sessions')
                .doc('progress')
                .collection(questionName)
                .doc('status')
                .get()
                .then((doc) {
              if (doc.exists) {
                operationData[operationName]!['totalQuestions'] =
                    (operationData[operationName]!['totalQuestions'] as int) +
                        1;

                soloSessionsData[questionName]['isCorrect'] =
                    doc.data()?['isCorrect'] ?? false;

                final Map<String, dynamic>? docData = doc.data();
                final timeValue =
                    (docData != null && docData.containsKey('timeElapsed')
                        ? docData['timeElapsed']
                        : docData?['timeTaken']) as num?;

                if (timeValue != null) {
                  soloSessionsData[questionName]['timeElapsed'] =
                      timeValue.toDouble();

                  operationData[operationName]!['timeValues']
                      .add(timeValue.toDouble());
                  operationData[operationName]!['averageTime'] =
                      (operationData[operationName]!['averageTime'] as double) +
                          timeValue.toDouble();
                }

                if (doc.data()?['isCorrect'] == true) {
                  operationData[operationName]!['correctAnswers'] =
                      (operationData[operationName]!['correctAnswers'] as int) +
                          1;
                }

                if (doc.data()?['timestamp'] != null) {
                  final timestamp = doc.data()?['timestamp'] as Timestamp;
                  final date = timestamp.toDate();

                  if (operationData[operationName]!['lastActivityDate'] ==
                          null ||
                      date.isAfter(
                          operationData[operationName]!['lastActivityDate'])) {
                    operationData[operationName]!['lastActivityDate'] = date;
                  }
                }

                operationStarted = true;
              }
            }));
          }

          futures.add(Future(() {
            Map<String, dynamic> mlData =
                Map.from(operationData[operationName]!['mlData']);

            // Map questions to test indices
            var questionMap = {
              'questionOne': 'test1',
              'questionTwo': 'test2',
              'questionThree': 'test3',
            };

            soloSessionsData.forEach((question, data) {
              if (questionMap.containsKey(question)) {
                String testKey = questionMap[question]!;

                mlData['${testKey}_marks'] = data['isCorrect'] ? 100 : 0;

                if (data['timeElapsed'] > 0) {
                  double timeInMinutes = data['timeElapsed'] / 60.0;
                  if (timeInMinutes < 1.0) timeInMinutes = 1.0;
                  mlData['${testKey}_time'] = timeInMinutes.ceil();
                }
              }
            });

            operationData[operationName]!['mlData'] = mlData;
          }));
        }

        futures.add(Future(() {
          operationData[operationName]!['started'] = operationStarted;
          operationData[operationName]!['completed'] = operationStarted &&
              allLessonsCompleted &&
              operationData[operationName]!['totalLessons'] > 0;
        }));
      }

      await Future.wait(futures);

      for (var operation in mathOperations) {
        final operationName = operation['title'];
        final data = operationData[operationName]!;

        final int totalTimeEntries = data['timeValues'].length;
        if (totalTimeEntries > 0) {
          data['averageTime'] =
              (data['averageTime'] as double) / totalTimeEntries;
        }

        final accuracy = data['totalQuestions'] > 0
            ? (data['correctAnswers'] / data['totalQuestions'])
            : 0.0;

        final avgTime = data['averageTime'] as double;

        data['difficultyScore'] = data['started']
            ? (1.0 - accuracy) * 0.7 +
                (avgTime > 30 ? 1.0 : avgTime / 30.0) * 0.3
            : 0.5;
      }

      await cacheData(operationData);

      return operationData;
    } catch (e) {
      print('[ERROR] Error fetching performance data: $e');
      return operationData;
    }
  }

  Future<void> cacheData(
      Map<String, Map<String, dynamic>> operationData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'dashboardCacheTime', DateTime.now().toIso8601String());

      final Map<String, Map<String, dynamic>> serializableData = {};

      operationData.forEach((operationName, data) {
        serializableData[operationName] = Map<String, dynamic>.from(data);

        // Convert Timestamps to ISO string for serialization
        if (serializableData[operationName]!['lastActivityDate'] != null) {
          // Handle both Timestamp and DateTime objects
          if (serializableData[operationName]!['lastActivityDate']
              is Timestamp) {
            serializableData[operationName]!['lastActivityDate'] =
                (serializableData[operationName]!['lastActivityDate']
                        as Timestamp)
                    .toDate()
                    .toIso8601String();
          } else if (serializableData[operationName]!['lastActivityDate']
              is DateTime) {
            serializableData[operationName]!['lastActivityDate'] =
                (serializableData[operationName]!['lastActivityDate']
                        as DateTime)
                    .toIso8601String();
          }
        }
      });

      await prefs.setString('dashboardData', json.encode(serializableData));
    } catch (e) {
      print('[ERROR] Error caching data: $e');
    }
  }

  Future<Map<String, Map<String, dynamic>>?> loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimeString = prefs.getString('dashboardCacheTime');

      if (cacheTimeString != null) {
        final cacheTime = DateTime.parse(cacheTimeString);
        final now = DateTime.now();
        if (now.difference(cacheTime).inMinutes < 30) {
          final cachedData = prefs.getString('dashboardData');
          if (cachedData != null) {
            final decodedData = json.decode(cachedData);

            return Map<String, Map<String, dynamic>>.from(
              decodedData.map((key, value) {
                final Map<String, dynamic> operationMap =
                    Map<String, dynamic>.from(value);

                if (operationMap['lastActivityDate'] != null) {
                  operationMap['lastActivityDate'] = DateTime.parse(
                      operationMap['lastActivityDate'] as String);
                }

                return MapEntry(key, operationMap);
              }),
            );
          }
        }
      }
      return null;
    } catch (e) {
      print('[ERROR] Error loading cached data: $e');
      return null;
    }
  }

  Map<String, dynamic> calculateOverallStats(
      Map<String, Map<String, dynamic>> operationData) {
    Map<String, dynamic> overallStats = {
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

    double bestAccuracy = 0.0;
    double worstAccuracy = 1.0;
    double fastestTime = double.infinity;
    double highestDifficulty = 0.0;

    String mostAccurateOp = '';
    String fastestOp = '';
    String weakestOp = '';

    int timeCount = 0;

    operationData.forEach((operationName, data) {
      overallStats['totalCompletedLessons'] += data['completedLessons'] as int;
      overallStats['totalLessons'] += data['totalLessons'] as int;
      overallStats['totalCorrectAnswers'] += data['correctAnswers'] as int;
      overallStats['totalQuestions'] += data['totalQuestions'] as int;

      if (data['started'] == true) {
        overallStats['startedOperations'] =
            (overallStats['startedOperations'] as int) + 1;
      }

      if (data['completed'] == true) {
        overallStats['completedOperations'] =
            (overallStats['completedOperations'] as int) + 1;
      }

      // Calculate accuracy for this operation
      final accuracy = data['totalQuestions'] > 0
          ? (data['correctAnswers'] as int) / (data['totalQuestions'] as int)
          : 0.0;

      // Find most accurate operation
      if (data['totalQuestions'] > 0 && accuracy > bestAccuracy) {
        bestAccuracy = accuracy;
        mostAccurateOp = operationName;
      }

      // Find weakest operation (lowest accuracy among started operations)
      if (data['started'] == true &&
          data['totalQuestions'] > 0 &&
          accuracy < worstAccuracy) {
        worstAccuracy = accuracy;
        weakestOp = operationName;
      }

      // Find fastest operation
      if (data['timeValues'].isNotEmpty &&
          (data['averageTime'] as double) < fastestTime) {
        fastestTime = data['averageTime'] as double;
        fastestOp = operationName;
      }

      // Find highest difficulty operation for recommendation
      if (data['difficultyScore'] > highestDifficulty) {
        highestDifficulty = data['difficultyScore'] as double;
        overallStats['recommendedFocus'] = operationName;
      }

      // Add to average time calculation
      if (data['timeValues'].isNotEmpty) {
        overallStats['averageTime'] = (overallStats['averageTime'] as double) +
            (data['averageTime'] as double);
        timeCount++;
      }
    });

    // Finalize average time calculation
    if (timeCount > 0) {
      overallStats['averageTime'] =
          (overallStats['averageTime'] as double) / timeCount;
    }

    // Set identified operations
    overallStats['mostAccurateOperation'] = mostAccurateOp;
    overallStats['fastestOperation'] = fastestOp;
    overallStats['weakestOperation'] =
        weakestOp.isEmpty ? overallStats['recommendedFocus'] : weakestOp;

    return overallStats;
  }

  Future<Map<String, Map<String, dynamic>>?> loadCachedPredictions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'prediction_cache_${userId}';
      final timestampKey = '${key}_timestamp';

      // Check if we have cached data
      if (!prefs.containsKey(key) || !prefs.containsKey(timestampKey)) {
        return null;
      }

      // Check if cache is still valid (24 hours)
      final timestamp = DateTime.parse(prefs.getString(timestampKey)!);
      final now = DateTime.now();
      if (now.difference(timestamp).inHours > 24) {
        return null;
      }

      // Load and decode cache
      final jsonData = prefs.getString(key);
      if (jsonData == null) return null;

      final Map<String, dynamic> decoded = jsonDecode(jsonData);
      final Map<String, Map<String, dynamic>> result = {};

      decoded.forEach((key, value) {
        result[key] = Map<String, dynamic>.from(value);
      });

      return result;
    } catch (e) {
      print('[ERROR] Failed to load cached predictions: $e');
      return null;
    }
  }

// This will cache prediction results to avoid repeated calls
  Future<void> cachePredictionResults(
      Map<String, Map<String, dynamic>> predictionsData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'prediction_cache_${userId}';
      final jsonData = jsonEncode(predictionsData);
      await prefs.setString(key, jsonData);
      await prefs.setString(
          '${key}_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print('[ERROR] Failed to cache prediction results: $e');
    }
  }

  // Add this method to your PerformanceDataService class to process prediction data

  /// Processes and consolidates prediction data before saving to Firestore
  Map<String, Map<String, dynamic>> processOperationDataForSaving(
      Map<String, Map<String, dynamic>> operationData) {
    final processedData = Map<String, Map<String, dynamic>>.from(operationData);

    // Process each operation to ensure prediction data is properly set
    processedData.forEach((operation, data) {
      // Create a mutable copy of the data
      final updatedData = Map<String, dynamic>.from(data);

      // Calculate overall predicted performance if prediction values exist
      final semanticPrediction = updatedData['semanticPrediction'];
      final verbalPrediction = updatedData['verbalPrediction'];
      final proceduralPrediction = updatedData['proceduralPrediction'];

      // Only calculate if at least one prediction exists
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
          // Set the overall predicted performance as the average of available predictions
          updatedData['predictedPerformance'] = sum / count;
        }
      }

      // Update the processed data map
      processedData[operation] = updatedData;
    });

    return processedData;
  }

// Update your saveOperationData method to use the processed data
  Future<void> saveOperationData(
      Map<String, Map<String, dynamic>> operationData) async {
    if (userId == null) return;

    try {
      // Process the data to ensure prediction values are properly set
      final processedData = processOperationDataForSaving(operationData);

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final DocumentReference userRef =
          firestore.collection('operationData').doc(userId);

      // First, save the entire processed operation data as a document
      await userRef.set({
        'lastUpdated': FieldValue.serverTimestamp(),
        'operations': processedData,
      }, SetOptions(merge: true));

      // Then save each operation as a separate document in a subcollection
      final operationsCollection = userRef.collection('operations');
      final WriteBatch batch = firestore.batch();

      processedData.forEach((operation, data) {
        final operationDoc = operationsCollection.doc(operation);

        // Add timestamp to the data
        final dataWithTimestamp = Map<String, dynamic>.from(data);
        dataWithTimestamp['updatedAt'] = FieldValue.serverTimestamp();

        // Save detailed data about each operation
        batch.set(operationDoc, dataWithTimestamp, SetOptions(merge: true));
      });

      // Commit the batch
      await batch.commit();

      // After saving to Firestore, update local cache with processed data
      await cachePerformanceData(processedData);

      print(
          '[INFO] Successfully saved operation data to Firestore for user: $userId');
    } catch (e) {
      print('[ERROR] Error saving operation data to Firestore: $e');
      throw e;
    }
  }

// Add a method to get the last cached timestamp to decide when to refresh
  Future<DateTime?> getLastDataUpdateTimestamp() async {
    if (userId == null) return null;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('operationData')
          .doc(userId)
          .get();

      if (snapshot.exists && snapshot.data()!.containsKey('lastUpdated')) {
        return (snapshot.data()!['lastUpdated'] as Timestamp).toDate();
      }
      return null;
    } catch (e) {
      print('[ERROR] Error getting last update timestamp: $e');
      return null;
    }
  }

// Method to retrieve operation data from Firestore
  Future<Map<String, Map<String, dynamic>>?> fetchFirestoreData() async {
    if (userId == null) return null;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('operationData')
          .doc(userId)
          .get();

      if (snapshot.exists && snapshot.data()!.containsKey('operations')) {
        final Map<String, dynamic> data = snapshot.data()!['operations'];
        final nestedData = _convertToNestedMap(data);

        // Process the data to ensure prediction values are properly set
        return processOperationDataForSaving(nestedData);
      }
      return null;
    } catch (e) {
      print('[ERROR] Error fetching operation data from Firestore: $e');
      return null;
    }
  }

// Helper to convert Firestore data to the expected nested map format
  Map<String, Map<String, dynamic>> _convertToNestedMap(
      Map<String, dynamic> data) {
    final Map<String, Map<String, dynamic>> result = {};

    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = value;
      } else {
        // Handle unexpected data format
        result[key] = {'data': value};
      }
    });

    return result;
  }

  Future<void> cachePerformanceData(
      Map<String, Map<String, dynamic>> data) async {
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Create a serializable copy of the data
      final Map<String, Map<String, dynamic>> serializableData = {};

      data.forEach((key, value) {
        // Create a new map to hold the serializable version of this operation data
        final Map<String, dynamic> serializedOperation = {};

        // Convert each field
        value.forEach((fieldKey, fieldValue) {
          // Convert Timestamp objects to ISO strings
          if (fieldValue is Timestamp) {
            serializedOperation[fieldKey] =
                fieldValue.toDate().toIso8601String();
          }
          // Convert DateTime objects to ISO strings
          else if (fieldValue is DateTime) {
            serializedOperation[fieldKey] = fieldValue.toIso8601String();
          }
          // Handle nested maps
          else if (fieldValue is Map) {
            final nestedMap = Map<String, dynamic>.from(fieldValue);
            // Process nested Timestamps
            nestedMap.forEach((nestedKey, nestedValue) {
              if (nestedValue is Timestamp) {
                nestedMap[nestedKey] = nestedValue.toDate().toIso8601String();
              } else if (nestedValue is DateTime) {
                nestedMap[nestedKey] = nestedValue.toIso8601String();
              }
            });
            serializedOperation[fieldKey] = nestedMap;
          }
          // Handle other types that can be directly serialized
          else {
            serializedOperation[fieldKey] = fieldValue;
          }
        });

        serializableData[key] = serializedOperation;
      });

      // Convert to JSON and store
      final jsonData = json.encode(serializableData);
      await prefs.setString('performance_data_$userId', jsonData);
      await prefs.setString('performance_data_timestamp_$userId',
          DateTime.now().toIso8601String());

      print('[INFO] Performance data cached successfully for user: $userId');
    } catch (e) {
      print('[ERROR] Error caching performance data: $e');
    }
  }

// Add this method to check if the cached data is fresh enough to use
  Future<bool> isCachedDataFresh(
      {Duration maxAge = const Duration(hours: 24)}) async {
    if (userId == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString =
          prefs.getString('performance_data_timestamp_$userId');

      if (timestampString == null) return false;

      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final age = now.difference(timestamp);

      return age <= maxAge;
    } catch (e) {
      print('[ERROR] Error checking cache freshness: $e');
      return false;
    }
  }
}
