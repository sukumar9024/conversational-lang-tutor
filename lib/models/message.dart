import 'package:equatable/equatable.dart';

enum MessageRole {
  user,
  assistant,
}

enum MessageStatus {
  sending,
  sent,
  error,
  thinking,
  speaking,
}

class Message extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final MessageStatus status;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageRole? role,
    MessageStatus? status,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [id, content, role, status, timestamp];
}