import 'package:giggle/core/constants/app_constants.dart';

class ApiEndpoints {
  static final String stopStream = "http://$mlIP:8000/stop-stream";
  static final String predictHandwriting =
      "http://$mlIP:8000/predict-handwriting/";
}
