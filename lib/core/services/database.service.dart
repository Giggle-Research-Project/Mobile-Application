import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giggle/core/utlis/logger.dart';

class DatabaseService {
  Future<void> updateVideoLessonProgress(
      String userId, String courseName, String dyscalculiaType) async {
    try {
      await FirebaseFirestore.instance
          .collection('functionActivities')
          .doc(userId)
          .collection(courseName)
          .doc(dyscalculiaType)
          .collection('video_lesson')
          .doc('progress')
          .set({'completed': true}, SetOptions(merge: true));

      Logger.info('Successfully updated progress in Cloud Firestore');
    } catch (e) {
      Logger.error('Error updating Cloud Firestore: $e');
    }
  }
}
