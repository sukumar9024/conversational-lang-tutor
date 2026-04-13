import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isMuted = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (_isMuted) return;
    if (!_isInitialized) await init();
    await _tts.speak(text);
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

  void dispose() {
    _tts.stop();
  }
}