part of 'chat_bloc.dart';

class ChatState extends Equatable {
  final List<Message> messages;
  final bool isLoading;
  final bool isRecording;
  final String draftText;
  final String? error;
  final LanguageMode currentMode;
  final bool isMuted;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.draftText = '',
    this.error,
    this.currentMode = LanguageMode.immersion,
    this.isMuted = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isRecording,
    String? draftText,
    String? error,
    LanguageMode? currentMode,
    bool? isMuted,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      draftText: draftText ?? this.draftText,
      error: error,
      currentMode: currentMode ?? this.currentMode,
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
        isMuted,
      ];
}