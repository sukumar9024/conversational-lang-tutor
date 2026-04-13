part of 'chat_bloc.dart';

const _noErrorUpdate = Object();

class ChatState extends Equatable {
  final List<Message> messages;
  final bool isLoading;
  final bool isRecording;
  final String draftText;
  final String? error;
  final LanguageMode currentMode;
  final String targetLanguage;
  final bool isMuted;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.draftText = '',
    this.error,
    this.currentMode = LanguageMode.immersion,
    this.targetLanguage = 'es',
    this.isMuted = false,
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
  ];
}
