import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'env_service.dart';
import '../core/errors/failures.dart';

enum LanguageMode { immersion, guided, correction }

@lazySingleton
class OpenRouterService {
  final Dio _dio;
  final EnvService _envService;

  OpenRouterService(this._dio, this._envService);

  Stream<String> streamResponse(
    List<Map<String, dynamic>> messages,
    LanguageMode mode,
    String targetLanguage,
  ) async* {
    if (!_envService.hasValidApiKey) {
      throw NetworkFailure(
        'Please configure your OpenRouter API key in .env file',
      );
    }

    final systemPrompt = _buildSystemPrompt(mode, targetLanguage);
    final models = _envService.openRouterModels;

    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_envService.openRouterApiKey}',
            'HTTP-Referer': 'https://github.com/language-practice-app',
            'X-Title': 'Language Practice App',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'model': models.first,
          'models': models.skip(1).toList(),
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...messages,
          ],
          'stream': true,
          'temperature': 0.7,
          'max_tokens': 1000,
        },
      );

      final responseBody = response.data;
      if (responseBody == null) {
        throw NetworkFailure('Empty response from OpenRouter');
      }

      var pendingChunk = '';
      var fullResponse = '';

      await for (final chunk in responseBody.stream) {
        pendingChunk += utf8.decode(chunk, allowMalformed: true);
        final lines = pendingChunk.split('\n');
        pendingChunk = lines.removeLast();

        for (final line in lines) {
          final trimmedLine = line.trim();
          if (!trimmedLine.startsWith('data:')) {
            continue;
          }

          final data = trimmedLine.substring(5).trim();
          if (data.isEmpty) {
            continue;
          }
          if (data == '[DONE]') {
            return;
          }

          final payload = jsonDecode(data);
          if (payload is! Map<String, dynamic>) {
            continue;
          }

          final error = payload['error'];
          if (error != null) {
            throw NetworkFailure(_extractErrorMessage(error));
          }

          final choices = payload['choices'];
          if (choices is! List || choices.isEmpty) {
            continue;
          }

          final firstChoice = choices.first;
          if (firstChoice is! Map<String, dynamic>) {
            continue;
          }

          final delta = firstChoice['delta'];
          if (delta is! Map<String, dynamic>) {
            continue;
          }

          final content = delta['content']?.toString();
          if (content == null || content.isEmpty) {
            continue;
          }

          fullResponse += content;
          yield fullResponse;
        }
      }
    } on DioException catch (e) {
      throw NetworkFailure.fromDioError(e);
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is Map<String, dynamic>) {
      return error['message']?.toString() ?? 'OpenRouter request failed';
    }

    return error.toString();
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
