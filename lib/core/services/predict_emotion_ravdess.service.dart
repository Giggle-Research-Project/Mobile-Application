import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      final mlIP = dotenv.env['MLIP'] ?? '127.0.0.1';
      final url = Uri.parse('http://$mlIP:8000/predict-emotion/');

      var request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('⭐ Voice Response: ${response.statusCode} - $responseData');

      if (response.statusCode == 200) {
        final emotionClass = _emotionMap[responseData.trim()] ?? 'neutral';

        if (mounted) {
          setState(() => currentEmotion = emotionClass);
          onEmotionDetected(emotionClass);
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
