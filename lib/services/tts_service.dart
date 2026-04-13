import 'dart:convert';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/voice_option.dart';
import 'env_service.dart';

class TtsVoiceConfiguration {
  final List<VoiceOption> availableVoices;
  final VoiceOption? activeVoice;
  final VoiceOption? manualVoiceOverride;

  const TtsVoiceConfiguration({
    required this.availableVoices,
    required this.activeVoice,
    required this.manualVoiceOverride,
  });
}

@lazySingleton
class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();
  final EnvService _envService;

  static const _voiceOverridesPreferenceKey = 'tts.voiceOverrides.v1';

  bool _isInitialized = false;
  bool _isMuted = false;
  SharedPreferences? _preferences;
  List<VoiceOption> _availableVoices = const [];
  VoiceOption? _activeVoice;
  String _currentTargetLanguage = 'es';

  TextToSpeechService(this._envService);

  Future<void> init() async {
    if (_isInitialized) return;
    _preferences = await SharedPreferences.getInstance();
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _availableVoices = await _loadAvailableVoices();
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (_isMuted || text.trim().isEmpty) return;
    if (!_isInitialized) await init();
    await _ensureLanguageAndVoiceApplied();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<TtsVoiceConfiguration> configureVoiceForLanguage(
    String targetLanguage,
  ) async {
    if (!_isInitialized) {
      await init();
    }

    _currentTargetLanguage = targetLanguage;
    _availableVoices = await _loadAvailableVoices();

    final manualOverride = _resolveManualVoiceOverride(
      targetLanguage,
      _availableVoices,
    );
    var selectedVoice = manualOverride;

    selectedVoice ??=
        _resolvePreferredAssistantVoice(targetLanguage, _availableVoices) ??
        _findBestVoiceForLanguage(targetLanguage, _availableVoices);

    await _applyVoiceSelection(
      targetLanguage: targetLanguage,
      voice: selectedVoice,
    );
    _activeVoice = selectedVoice;

    return TtsVoiceConfiguration(
      availableVoices: _availableVoices,
      activeVoice: _activeVoice,
      manualVoiceOverride: manualOverride,
    );
  }

  Future<TtsVoiceConfiguration> setManualVoiceOverride({
    required String targetLanguage,
    required VoiceOption voice,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    final overrides = _readVoiceOverrides();
    overrides[targetLanguage] = voice.toJsonString();
    await _writeVoiceOverrides(overrides);

    return configureVoiceForLanguage(targetLanguage);
  }

  Future<TtsVoiceConfiguration> clearManualVoiceOverride({
    required String targetLanguage,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    final overrides = _readVoiceOverrides();
    overrides.remove(targetLanguage);
    await _writeVoiceOverrides(overrides);

    return configureVoiceForLanguage(targetLanguage);
  }

  Future<List<VoiceOption>> getAvailableVoices({bool refresh = false}) async {
    if (!_isInitialized) {
      await init();
    }

    if (refresh) {
      _availableVoices = await _loadAvailableVoices();
    }

    return _availableVoices;
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> pause() async {
    await _tts.pause();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stop();
    }
  }

  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;
  VoiceOption? get activeVoice => _activeVoice;

  void dispose() {
    _tts.stop();
  }

  Future<void> _ensureLanguageAndVoiceApplied() async {
    await _applyVoiceSelection(
      targetLanguage: _currentTargetLanguage,
      voice: _activeVoice,
    );
  }

  Future<List<VoiceOption>> _loadAvailableVoices() async {
    final rawVoices = await _tts.getVoices;
    if (rawVoices is! List) {
      return const [];
    }

    final voices = rawVoices
        .whereType<Map<dynamic, dynamic>>()
        .map(VoiceOption.fromMap)
        .where((voice) => voice.name.isNotEmpty || voice.identifier.isNotEmpty)
        .toList();

    final unique = <String, VoiceOption>{};
    for (final voice in voices) {
      unique[voice.id] = voice;
    }

    final dedupedVoices = unique.values.toList()
      ..sort((a, b) => a.displayLabel.compareTo(b.displayLabel));

    return dedupedVoices;
  }

  VoiceOption? _resolveManualVoiceOverride(
    String targetLanguage,
    List<VoiceOption> availableVoices,
  ) {
    final rawOverride = _readVoiceOverrides()[targetLanguage];
    if (rawOverride == null || rawOverride.isEmpty) {
      return null;
    }

    try {
      final storedVoice = VoiceOption.fromJson(rawOverride);
      return _findMatchingVoice(storedVoice, availableVoices);
    } catch (_) {
      return null;
    }
  }

  VoiceOption? _resolvePreferredAssistantVoice(
    String targetLanguage,
    List<VoiceOption> availableVoices,
  ) {
    final preferredIdentifier = _envService.preferredAssistantVoiceIdentifier;
    final preferredName = _envService.preferredAssistantVoiceName;
    final preferredLocale = _envService.preferredAssistantVoiceLocale;

    if (preferredIdentifier.isEmpty &&
        preferredName.isEmpty &&
        preferredLocale.isEmpty) {
      return null;
    }

    final preferredVoice = VoiceOption(
      identifier: preferredIdentifier,
      name: preferredName,
      locale: preferredLocale,
    );
    final matchingVoice = _findMatchingVoice(preferredVoice, availableVoices);
    if (matchingVoice == null) {
      return null;
    }

    if (preferredLocale.isNotEmpty &&
        !matchingVoice.supportsLanguage(targetLanguage)) {
      return null;
    }

    return matchingVoice;
  }

  VoiceOption? _findMatchingVoice(
    VoiceOption expectedVoice,
    List<VoiceOption> availableVoices,
  ) {
    if (expectedVoice.identifier.isNotEmpty) {
      for (final voice in availableVoices) {
        if (voice.identifier == expectedVoice.identifier) {
          return voice;
        }
      }
    }

    for (final voice in availableVoices) {
      if (voice.name == expectedVoice.name &&
          voice.locale == expectedVoice.locale) {
        return voice;
      }
    }

    return null;
  }

  VoiceOption? _findBestVoiceForLanguage(
    String targetLanguage,
    List<VoiceOption> availableVoices,
  ) {
    if (availableVoices.isEmpty) {
      return null;
    }

    final preferredLocale = _preferredLocaleForLanguage(targetLanguage);
    final matchingVoices = availableVoices
        .where((voice) => voice.supportsLanguage(targetLanguage))
        .toList();

    if (matchingVoices.isEmpty) {
      return null;
    }

    matchingVoices.sort((a, b) {
      final scoreA = _voiceScore(a, preferredLocale);
      final scoreB = _voiceScore(b, preferredLocale);
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }

      return a.displayLabel.compareTo(b.displayLabel);
    });

    return matchingVoices.first;
  }

  int _voiceScore(VoiceOption voice, String preferredLocale) {
    var score = 0;

    if (voice.normalizedLocale == preferredLocale) {
      score += 100;
    } else if (voice.normalizedLocale.startsWith(
      '${preferredLocale.split('-').first}-',
    )) {
      score += 50;
    }

    if (!voice.networkRequired) {
      score += 10;
    }

    score += (voice.quality ?? 0);
    score -= (voice.latency ?? 0);

    return score;
  }

  Future<void> _applyVoiceSelection({
    required String targetLanguage,
    required VoiceOption? voice,
  }) async {
    final locale = voice?.locale.isNotEmpty == true
        ? voice!.locale
        : _preferredLocaleForLanguage(targetLanguage);

    await _tts.setLanguage(locale);

    if (voice == null) {
      await _tts.clearVoice();
      return;
    }

    final payload = voice.toTtsPayload();
    if (payload.isEmpty) {
      await _tts.clearVoice();
      return;
    }

    await _tts.setVoice(payload);
  }

  Map<String, String> _readVoiceOverrides() {
    final rawValue = _preferences?.getString(_voiceOverridesPreferenceKey);
    if (rawValue == null || rawValue.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! Map<String, dynamic>) {
      return {};
    }

    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<void> _writeVoiceOverrides(Map<String, String> overrides) async {
    await _preferences?.setString(
      _voiceOverridesPreferenceKey,
      jsonEncode(overrides),
    );
  }

  String _preferredLocaleForLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'en-US';
      case 'es':
        return 'es-ES';
      case 'fr':
        return 'fr-FR';
      case 'de':
        return 'de-DE';
      case 'it':
        return 'it-IT';
      case 'pt':
        return 'pt-PT';
      case 'ru':
        return 'ru-RU';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'zh':
        return 'zh-CN';
      default:
        return languageCode;
    }
  }
}
