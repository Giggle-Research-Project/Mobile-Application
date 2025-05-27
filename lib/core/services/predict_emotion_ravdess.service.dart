import 'dart:io';
import 'dart:convert';
import 'package:giggle/core/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;

class PredictVoiceEmotionService {
  final Map<String, String> _emotionMap = {
    '0': 'neutral',
    '1': 'calm',
    '2': 'happy',
    '3': 'sad',
    '4': 'angry',
    '5': 'fearful',
    '6': 'disgust',
    '7': 'surprised'
  };

  Future<void> predictEmotion(
      File audioFile,
      Function(String) onEmotionDetected,
      bool mounted,
      Function setState,
      String currentEmotion) async {
    try {
      final url = Uri.parse(ApiEndpoints.predictVoiceEmotion);

      var request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('⭐ Voice Response: ${response.statusCode} - $responseData');

      if (response.statusCode == 200) {
        // Parse JSON response
        final jsonResponse = jsonDecode(responseData);
        final predictedEmotion = jsonResponse['predicted_emotion'] as String;

        if (mounted) {
          setState(() {
            currentEmotion = predictedEmotion;
          });
          onEmotionDetected(predictedEmotion);
        }
      }

      // Clean up the file after sending
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    } catch (e) {
      print('Error sending audio file: $e');
    }
  }
}
