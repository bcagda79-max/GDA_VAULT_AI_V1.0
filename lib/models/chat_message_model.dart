// lib/models/chat_message_model.dart

/// Represents a message in the AI chat.
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? sourceCitations; // "Trust Minutes 1972 — p.23"

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.sourceCitations,
  });
}
