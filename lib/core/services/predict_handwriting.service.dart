import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> predictHandwriting(
    File imageFile, String squareIdentifier) async {
  try {
    final mlIP = dotenv.env['MLIP']?.isEmpty ?? true
        ? dotenv.env['DEFAULT_MLIP']
        : dotenv.env['MLIP'];

    final uri = Uri.parse('http://$mlIP:8000/predict-handwriting/');
    var request = http.MultipartRequest('POST', uri);

    var fileStream = http.ByteStream(imageFile.openRead());
    var length = await imageFile.length();

    var multipartFile = http.MultipartFile('file', fileStream, length,
        filename: '${squareIdentifier}.png');

    request.files.add(multipartFile);

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('Response for $squareIdentifier: ${response.body}');

    if (response.statusCode == 200) {
      try {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('predicted_class')) {
          return responseData['predicted_class'].toString();
        }
      } catch (e) {
        print('Error parsing prediction response: $e');
      }
    }

    return '';
  } catch (e) {
    print('Error sending to ML server: $e');
    return '';
  }
}
