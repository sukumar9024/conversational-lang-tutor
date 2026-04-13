import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/colors.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isDarkMode;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? (isDarkMode
                    ? AppColors.userBubbleDark
                    : AppColors.userBubbleLight)
              : (isDarkMode
                    ? AppColors.assistantBubbleDark
                    : AppColors.assistantBubbleLight),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                  height: 1.4,
                ),
              ),
            if (message.content.isNotEmpty) const SizedBox(height: 4),
            if (message.status == MessageStatus.thinking)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Thinking...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
