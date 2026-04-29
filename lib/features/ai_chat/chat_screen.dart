// lib/features/ai_chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_strings.dart';
import 'package:gda_vault_ai/data/mock_data.dart';

/// The main screen for the AI chat feature.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = MockData.chatMessages;
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.chatTitle)),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return ListTile(
                    title: Text(message.content),
                    subtitle: Text(message.isUser ? 'You' : 'AI Assistant'),
                    leading: message.isUser
                        ? const Icon(Icons.person)
                        : const Icon(Icons.computer),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: AppStrings.chatHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      // Mock send action
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
