import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class EnvService {
  Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  String get openRouterApiKey => dotenv.get('OPENROUTER_API_KEY', fallback: '');
  String get openRouterBaseUrl => dotenv.get('OPENROUTER_BASE_URL', fallback: 'https://openrouter.ai/api/v1');
  String get openRouterModel => dotenv.get('OPENROUTER_MODEL', fallback: 'anthropic/claude-3.5-sonnet');
  
  bool get isDebug => dotenv.get('APP_DEBUG', fallback: 'false') == 'true';
  String get logLevel => dotenv.get('APP_LOG_LEVEL', fallback: 'info');

  bool get hasValidApiKey => openRouterApiKey.isNotEmpty && !openRouterApiKey.contains('your_api_key');
}