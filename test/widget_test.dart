import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_practice/models/message.dart';
import 'package:language_practice/widgets/chat_bubble.dart';

void main() {
  testWidgets('chat bubble shows assistant thinking state', (
    WidgetTester tester,
  ) async {
    final message = Message(
      id: 'assistant-1',
      content: '',
      role: MessageRole.assistant,
      timestamp: DateTime(2024),
      status: MessageStatus.thinking,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatBubble(message: message, isDarkMode: false)),
      ),
    );

    expect(find.text('Thinking...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
