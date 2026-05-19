import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get groqApiKey => dotenv.env['GROQ_API_KEY']?.trim() ?? '';

  static String get groqModel =>
      dotenv.env['GROQ_MODEL']?.trim().isNotEmpty == true
          ? dotenv.env['GROQ_MODEL']!.trim()
          : 'llama-3.3-70b-versatile';

  static bool get hasGroqKey => groqApiKey.isNotEmpty;
}
