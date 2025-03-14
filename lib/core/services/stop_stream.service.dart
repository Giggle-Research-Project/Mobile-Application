import 'dart:async';
import 'package:giggle/core/constants/api_endpoints.dart';
import 'package:giggle/core/utlis/logger.dart';
import 'package:http/http.dart' as http;

Future<void> stopStream() async {
  try {
    final uri = Uri.parse(ApiEndpoints.stopStream);
    await http.get(uri).timeout(const Duration(seconds: 2));
  } catch (e) {
    Logger.error('Error notifying ML server: $e');
  }
}
