part of 'chat_bloc.dart';

const _noErrorUpdate = Object();
const _noActiveVoiceUpdate = Object();
const _noManualVoiceUpdate = Object();

class ChatState extends Equatable {
  final List<Message> messages;
  final bool isLoading;
  final bool isRecording;
  final String draftText;
  final String? error;
  final LanguageMode currentMode;
  final String targetLanguage;
  final bool isMuted;
  final bool isVoiceLoading;
  final List<VoiceOption> availableVoices;
  final VoiceOption? activeVoice;
  final VoiceOption? manualVoiceOverride;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.draftText = '',
    this.error,
    this.currentMode = LanguageMode.immersion,
    this.targetLanguage = 'es',
    this.isMuted = false,
    this.isVoiceLoading = false,
    this.availableVoices = const [],
    this.activeVoice,
    this.manualVoiceOverride,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isRecording,
    String? draftText,
    Object? error = _noErrorUpdate,
    bool clearError = false,
    LanguageMode? currentMode,
    String? targetLanguage,
    bool? isMuted,
    bool? isVoiceLoading,
    List<VoiceOption>? availableVoices,
    Object? activeVoice = _noActiveVoiceUpdate,
    Object? manualVoiceOverride = _noManualVoiceUpdate,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      draftText: draftText ?? this.draftText,
      error: clearError
          ? null
          : identical(error, _noErrorUpdate)
          ? this.error
          : error as String?,
      currentMode: currentMode ?? this.currentMode,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      isMuted: isMuted ?? this.isMuted,
      isVoiceLoading: isVoiceLoading ?? this.isVoiceLoading,
      availableVoices: availableVoices ?? this.availableVoices,
      activeVoice: identical(activeVoice, _noActiveVoiceUpdate)
          ? this.activeVoice
          : activeVoice as VoiceOption?,
      manualVoiceOverride: identical(manualVoiceOverride, _noManualVoiceUpdate)
          ? this.manualVoiceOverride
          : manualVoiceOverride as VoiceOption?,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    isLoading,
    isRecording,
    draftText,
    error,
    currentMode,
    targetLanguage,
    isMuted,
    isVoiceLoading,
    availableVoices,
    activeVoice,
    manualVoiceOverride,
  ];
}
