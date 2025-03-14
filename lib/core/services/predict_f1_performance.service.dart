import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> predictF1Performance(
  int skillCorrect,
  RegExpMatch? skillTimeMatch,
  int parentCorrect,
  RegExpMatch? parentTimeMatch,
) async {
  try {
    final mlIP = dotenv.env['MLIP']?.isNotEmpty == true
        ? dotenv.env['MLIP']
        : dotenv.env['DEFAULT_MLIP'] ?? 'localhost';

    // Convert time strings to minutes
    final int childTimeMinutes = skillTimeMatch != null
        ? ((int.tryParse(skillTimeMatch.group(1) ?? '0') ?? 0) +
                (int.tryParse(skillTimeMatch.group(2) ?? '0') ?? 0) / 60)
            .toInt()
        : 0;

    final int parentTimeMinutes = parentTimeMatch != null
        ? ((int.tryParse(parentTimeMatch.group(1) ?? '0') ?? 0) +
                (int.tryParse(parentTimeMatch.group(2) ?? '0') ?? 0) / 60)
            .toInt()
        : 0;

    // Create the API endpoint URI
    final uri = Uri.parse("http://$mlIP:8000/predict-f1-performance/");

    // Create request body with CORRECT parameter names as per API specification
    final requestBody = jsonEncode({
      'child_marks': skillCorrect,
      'child_time': childTimeMinutes,
      'parent_marks': parentCorrect,
      'parent_time': parentTimeMinutes,
    });

    print('Sending request to: $uri');
    print('Request payload: $requestBody');

    // Send request with correct headers
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 10));

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final predictPerformance = responseData['predicted_performance'];

      if (predictPerformance is num) {
        return predictPerformance.toStringAsFixed(1);
      } else {
        return predictPerformance.toString();
      }
    } else {
      print('Error from ML server: ${response.statusCode} - ${response.body}');

      final double fallbackScore =
          _calculateFallbackScore(skillCorrect, parentCorrect);
      return fallbackScore.toStringAsFixed(1);
    }
  } catch (e, stackTrace) {
    print('Exception in predictF1Performance: $e');
    print('Stack trace: $stackTrace');

    try {
      final double fallbackScore =
          _calculateFallbackScore(skillCorrect, parentCorrect);
      return fallbackScore.toStringAsFixed(1);
    } catch (fallbackError) {
      print('Error calculating fallback score: $fallbackError');
      return "50.0";
    }
  }
}

double _calculateFallbackScore(int skillCorrect, int parentCorrect) {
  double weightedScore = (skillCorrect * 0.6) + (parentCorrect * 0.4);

  double maxPossibleMarks = 20.0;
  double scaledScore = (weightedScore / maxPossibleMarks) * 100;

  return scaledScore.clamp(0.0, 100.0);
}
