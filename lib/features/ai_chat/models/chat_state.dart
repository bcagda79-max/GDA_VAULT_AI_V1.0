import 'package:flutter/material.dart';

/// Message source citation
class SourceCitation {
  final String documentName;   // "Trust Minutes Vol. IV"
  final String yearLabel;      // "1972"
  final String categoryName;   // "Trust Minutes"
  final List<int> pageNumbers; // [23, 67]
  final Color categoryColor;

  const SourceCitation({
    required this.documentName,
    required this.yearLabel,
    required this.categoryName,
    required this.pageNumbers,
    required this.categoryColor,
  });
}

/// Single chat message
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<SourceCitation> citations; // empty for user messages
  final bool isTyping;  // true = show typing bubble

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.citations = const [],
    this.isTyping = false,
  });

  ChatMessage copyWith({
    String? content,
    bool? isTyping,
    List<SourceCitation>? citations,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
      citations: citations ?? this.citations,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

/// Selected category for chat context
class ChatCategory {
  final String id;
  final String name;
  final String shortName;  // "BOARD", "TRUST" etc
  final Color color;
  final IconData icon;
  final String? parentId;
  final int docCount;
  bool isSelected;

  ChatCategory({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.icon,
    this.parentId,
    this.docCount = 0,
    this.isSelected = false,
  });
}

/// Overall chat state
class ChatState {
  final List<ChatMessage> messages;
  final List<ChatCategory> categories;
  final bool isLoading;          // AI is "thinking"
  final bool categoriesSelected; // at least 1 category selected
  final String? errorMessage;
  final String inputText;

  const ChatState({
    this.messages = const [],
    this.categories = const [],
    this.isLoading = false,
    this.categoriesSelected = false,
    this.errorMessage,
    this.inputText = '',
  });

  bool get canSendMessage =>
    categoriesSelected && inputText.trim().isNotEmpty && !isLoading;

  List<ChatCategory> get selectedCategories =>
    categories.where((c) => c.isSelected).toList();

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatCategory>? categories,
    bool? isLoading,
    bool? categoriesSelected,
    String? errorMessage,
    String? inputText,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      categoriesSelected: categoriesSelected ?? this.categoriesSelected,
      errorMessage: errorMessage,
      inputText: inputText ?? this.inputText,
    );
  }
}
