import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../core/errors/failures.dart';

@lazySingleton
class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = await _speech.initialize();
    if (!_isInitialized) {
      throw VoiceServiceFailure('Speech recognition not available');
    }
  }

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  void startListening({
    required Function(String text) onResult,
    required VoidCallback onListeningStarted,
    required VoidCallback onListeningStopped,
  }) async {
    if (!_isInitialized) await init();

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw PermissionFailure('Microphone permission required');
    }

    _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      onSoundLevelChange: null,
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
    );

    onListeningStarted();
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;

  void dispose() {
    _speech.stop();
  }
}