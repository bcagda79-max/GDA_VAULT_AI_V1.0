// lib/features/ai_chat/widgets/chat_bubble_fab.dart
import 'package:flutter/material.dart';

/// A floating action button shaped like a chat bubble.
class ChatBubbleFab extends StatelessWidget {
  const ChatBubbleFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Navigate to chat screen
      },
      child: const Icon(Icons.chat_bubble),
    );
  }
}
