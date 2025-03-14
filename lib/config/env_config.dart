import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get mlServerIP {
    return (dotenv.env['MLIP']?.isEmpty ?? true)
        ? dotenv.env['DEFAULT_MLIP']!
        : dotenv.env['MLIP']!;
  }
}
