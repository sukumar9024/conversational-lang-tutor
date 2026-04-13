import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'env_service.dart';
import '../core/errors/failures.dart';

enum LanguageMode {
  immersion,
  guided,
  correction,
}

@lazySingleton
class OpenRouterService {
  final Dio _dio;
  final EnvService _envService;

  OpenRouterService(this._dio, this._envService);

  Stream<String> streamResponse(List<Map<String, dynamic>> messages, LanguageMode mode, String targetLanguage) async* {
    if (!_envService.hasValidApiKey) {
      throw NetworkFailure('Please configure your OpenRouter API key in .env file');
    }

    final systemPrompt = _buildSystemPrompt(mode, targetLanguage);

    try {
      final response = await _dio.post(
        '${_envService.openRouterBaseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_envService.openRouterApiKey}',
            'HTTP-Referer': 'https://github.com/language-practice-app',
            'X-Title': 'Language Practice App',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'model': _envService.openRouterModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...messages,
          ],
          'stream': true,
          'temperature': 0.7,
          'max_tokens': 1000,
        },
      );

      final stream = response.data.stream;
      String buffer = '';

      await for (final chunk in stream) {
        final lines = utf8.decode(chunk).split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;

            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'] as String?;
              if (content != null) {
                buffer += content;
                yield buffer;
              }
            } catch (_) {}
          }
        }
      }
    } on DioException catch (e) {
      throw NetworkFailure.fromDioError(e);
    }
  }

  String _buildSystemPrompt(LanguageMode mode, String targetLanguage) {
    switch (mode) {
      case LanguageMode.immersion:
        return '''
You are a language practice assistant.
Speak ONLY in $targetLanguage.
Keep responses concise, natural, conversational.
Use simple vocabulary suitable for language learners.
Respond as a friendly conversation partner.
Do not switch to any other language.
''';

      case LanguageMode.guided:
        return '''
You are a language learning tutor.
For every user message respond EXACTLY in this 3 part structure:

1. What I understood: (in English, what the user meant)
2. Answer in English: (your natural answer in English)
3. Answer in user's language: (translate that answer into exactly the same language the user wrote their message in)

Keep everything short, simple, friendly.
Be encouraging and supportive.
You must always show all 3 sections exactly as specified.
''';

      case LanguageMode.correction:
        return '''
You are a language tutor correcting the user's sentences.
First respond with a friendly greeting.
If the user has no mistakes: tell them it was perfect.
If they have mistakes:
- Point out the corrections gently
- Show the improved natural version
- Then respond naturally in conversation

Always be encouraging, positive and supportive.
Keep it brief.
''';
    }
  }
}