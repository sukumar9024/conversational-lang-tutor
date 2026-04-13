part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatInitialized extends ChatEvent {}

class MessageSent extends ChatEvent {
  final String text;

  const MessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

class RecordingStarted extends ChatEvent {}

class RecordingStopped extends ChatEvent {}

class TextRecognized extends ChatEvent {
  final String text;

  const TextRecognized(this.text);

  @override
  List<Object?> get props => [text];
}

class MessageUpdated extends ChatEvent {
  final String messageId;
  final String content;

  const MessageUpdated({
    required this.messageId,
    required this.content,
  });

  @override
  List<Object?> get props => [messageId, content];
}

class ResponseReceived extends ChatEvent {
  final String messageId;

  const ResponseReceived(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class ClearChatRequested extends ChatEvent {}

class ModeChanged extends ChatEvent {
  final LanguageMode mode;

  const ModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

class ToggleMuteRequested extends ChatEvent {}