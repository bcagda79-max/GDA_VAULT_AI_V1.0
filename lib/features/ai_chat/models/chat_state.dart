import 'package:flutter/material.dart';

/// Message source citation (matches n8n SourcePage)
class SourceCitation {
  final String categoryName;   // e.g. "Board of Authority"
  final String yearLabel;      // e.g. "1972"
  final int pageNumber;        // e.g. 23
  final String? displayPath;   // Optional path for PDF mapping
  final Color? categoryColor;  // Optional UI color

  const SourceCitation({
    required this.categoryName,
    required this.yearLabel,
    required this.pageNumber,
    this.displayPath,
    this.categoryColor,
  });

  factory SourceCitation.fromJson(Map<String, dynamic> json) {
    return SourceCitation(
      categoryName: json['category_name']?.toString() ?? '',
      yearLabel: json['year']?.toString() ?? '',
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 0,
      displayPath: json['display_path']?.toString(),
    );
  }
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
  final String sessionId;
  final String? sessionTitle;
  final List<Map<String, dynamic>> recentSessions;
  final List<ChatMessage> messages;
  final List<ChatCategory> categories;
  final bool isLoading;          // AI is "thinking"
  final bool categoriesSelected; // at least 1 category selected
  final String? errorMessage;
  final String? yearFrom;
  final String? yearTo;
  final String inputText;

  const ChatState({
    required this.sessionId,
    this.sessionTitle,
    this.recentSessions = const [],
    this.messages = const [],
    this.categories = const [],
    this.isLoading = false,
    this.categoriesSelected = false,
    this.errorMessage,
    this.yearFrom,
    this.yearTo,
    this.inputText = '',
  });

  bool get canSendMessage =>
    categoriesSelected && inputText.trim().isNotEmpty && !isLoading;

  List<ChatCategory> get selectedCategories =>
    categories.where((c) => c.isSelected).toList();

  ChatState copyWith({
    String? sessionId,
    String? sessionTitle,
    List<Map<String, dynamic>>? recentSessions,
    List<ChatMessage>? messages,
    List<ChatCategory>? categories,
    bool? isLoading,
    bool? categoriesSelected,
    String? errorMessage,
    String? yearFrom,
    String? yearTo,
    String? inputText,
  }) {
    return ChatState(
      sessionId: sessionId ?? this.sessionId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      recentSessions: recentSessions ?? this.recentSessions,
      messages: messages ?? this.messages,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      categoriesSelected: categoriesSelected ?? this.categoriesSelected,
      errorMessage: errorMessage,
      yearFrom: yearFrom ?? this.yearFrom,
      yearTo: yearTo ?? this.yearTo,
      inputText: inputText ?? this.inputText,
    );
  }
}
