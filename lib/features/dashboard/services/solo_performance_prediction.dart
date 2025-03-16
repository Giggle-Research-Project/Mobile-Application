import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giggle/core/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;

class PredictionService {
  static Future<Map<String, dynamic>> predictUserPerformance(
      String userId, String courseName, String dyscalculiaType) async {
    try {
      // Check if all three questions have been completed
      final bool isCompleted =
          await checkAllQuestionsCompleted(userId, courseName, dyscalculiaType);

      if (!isCompleted) {
        // Return a map indicating prediction wasn't performed
        return {
          'success': false,
          'message': 'User has not completed all questions in the solo session'
        };
      }

      // Get the progress data from Firestore
      final questionOneDoc = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(userId)
          .collection(courseName)
          .doc(dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection('questionOne')
          .doc('status')
          .get();

      final questionTwoDoc = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(userId)
          .collection(courseName)
          .doc(dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection('questionTwo')
          .doc('status')
          .get();

      final questionThreeDoc = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(userId)
          .collection(courseName)
          .doc(dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection('questionThree')
          .doc('status')
          .get();

      // Extract data with null safety
      final test1Marks =
          questionOneDoc.exists && questionOneDoc.data()?['isCorrect'] == true
              ? 100
              : 0;
      final test1Time = questionOneDoc.exists
          ? (questionOneDoc.data()?['timeElapsed'] ?? 0)
          : 0;

      final test2Marks =
          questionTwoDoc.exists && questionTwoDoc.data()?['isCorrect'] == true
              ? 100
              : 0;
      final test2Time = questionTwoDoc.exists
          ? (questionTwoDoc.data()?['timeElapsed'] ?? 0)
          : 0;

      final test3Marks = questionThreeDoc.exists &&
              questionThreeDoc.data()?['isCorrect'] == true
          ? 100
          : 0;
      final test3Time = questionThreeDoc.exists
          ? (questionThreeDoc.data()?['timeElapsed'] ?? 0)
          : 0;

      // Create request body for API
      final requestBody = {
        "test1_marks": test1Marks,
        "test1_time": test1Time,
        "test2_marks": test2Marks,
        "test2_time": test2Time,
        "test3_marks": test3Marks,
        "test3_time": test3Time
      };

      print('Sending prediction request with data: $requestBody');

      // Call the prediction API
      final response = await http.post(
        Uri.parse(ApiEndpoints.predictOverallPerformance),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('Prediction result: $result');
        final prediction = result['predicted_performance'].toDouble();

        return {
          'success': true,
          'prediction': prediction,
          'category': getPerformanceCategory(prediction),
          'color': getPerformanceColor(prediction),
          'formattedValue': formatPrediction(prediction)
        };
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to predict performance: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error predicting performance: $e');
      return {'success': false, 'message': 'Failed to predict performance: $e'};
    }
  }

  /// Check if user has completed all three questions in a solo session
  static Future<bool> checkAllQuestionsCompleted(
      String userId, String courseName, String dyscalculiaType) async {
    try {
      // Check questionOne
      final questionOneDoc = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(userId)
          .collection(courseName)
          .doc(dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection('questionOne')
          .doc('status')
          .get();

      // Check questionTwo
      final questionTwoDoc = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(userId)
          .collection(courseName)
          .doc(dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection('questionTwo')
          .doc('status')
          .get();

      // Check questionThree
      final questionThreeDoc = await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(userId)
          .collection(courseName)
          .doc(dyscalculiaType)
          .collection('solo_sessions')
          .doc('progress')
          .collection('questionThree')
          .doc('status')
          .get();

      // Check if all documents exist and have attempted status
      final q1Completed =
          questionOneDoc.exists && questionOneDoc.data() != null;
      final q2Completed =
          questionTwoDoc.exists && questionTwoDoc.data() != null;
      final q3Completed =
          questionThreeDoc.exists && questionThreeDoc.data() != null;

      return q1Completed && q2Completed && q3Completed;
    } catch (e) {
      print('Error checking question completion: $e');
      return false;
    }
  }

  /// Formats the prediction result for display
  static String formatPrediction(double prediction) {
    return prediction.toStringAsFixed(1);
  }

  /// Determines performance category based on prediction value
  static String getPerformanceCategory(double prediction) {
    if (prediction >= 80) {
      return 'Excellent';
    } else if (prediction >= 70) {
      return 'Good';
    } else if (prediction >= 60) {
      return 'Fair';
    } else {
      return 'Needs Improvement';
    }
  }

  /// Gets color associated with the performance category
  static String getPerformanceColor(double prediction) {
    if (prediction >= 80) {
      return '#4CAF50'; // Green
    } else if (prediction >= 70) {
      return '#8BC34A'; // Light Green
    } else if (prediction >= 60) {
      return '#FFC107'; // Amber
    } else {
      return '#F44336'; // Red
    }
  }
}
