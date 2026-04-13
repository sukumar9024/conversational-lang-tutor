class AppConstants {
  static const String appName = 'Language Practice';
  static const String appVersion = '1.0.0';
  
  // API Constants
  static const int apiTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;
  
  // Chat Constants
  static const int maxMessageLength = 1000;
  static const int maxConversationHistory = 50;
  
  // Voice Constants
  static const int maxRecordingDuration = 60; // 60 seconds
  
  // Supported Languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
  };
}