part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatInitialized extends ChatEvent {
  const ChatInitialized();
}

class MessageSent extends ChatEvent {
  final String text;

  const MessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

class RecordingStarted extends ChatEvent {
  const RecordingStarted();
}

class RecordingStopped extends ChatEvent {
  const RecordingStopped();
}

class RecordingStatusChanged extends ChatEvent {
  final bool isRecording;

  const RecordingStatusChanged({required this.isRecording});

  @override
  List<Object?> get props => [isRecording];
}

class TextRecognized extends ChatEvent {
  final String text;

  const TextRecognized({required this.text});

  @override
  List<Object?> get props => [text];
}

class MessageUpdated extends ChatEvent {
  final String messageId;
  final String content;

  const MessageUpdated({required this.messageId, required this.content});

  @override
  List<Object?> get props => [messageId, content];
}

class ResponseReceived extends ChatEvent {
  final String messageId;

  const ResponseReceived({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class ResponseFailed extends ChatEvent {
  final String messageId;
  final String error;

  const ResponseFailed({required this.messageId, required this.error});

  @override
  List<Object?> get props => [messageId, error];
}

class ClearChatRequested extends ChatEvent {
  const ClearChatRequested();
}

class ModeChanged extends ChatEvent {
  final LanguageMode mode;

  const ModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

class TargetLanguageChanged extends ChatEvent {
  final String languageCode;

  const TargetLanguageChanged(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

class AssistantVoiceChanged extends ChatEvent {
  final VoiceOption? voice;

  const AssistantVoiceChanged(this.voice);

  @override
  List<Object?> get props => [voice];
}

class ToggleMuteRequested extends ChatEvent {
  const ToggleMuteRequested();
}
