import 'package:flutter/material.dart';

class SourceCitation {
  final String categoryName;
  final String yearLabel;
  final int pageNumber;
  final String? displayPath;
  final String? fileName;
  final String? storagePath;
  final Color? categoryColor;

  const SourceCitation({
    required this.categoryName,
    required this.yearLabel,
    required this.pageNumber,
    this.displayPath,
    this.fileName,
    this.storagePath,
    this.categoryColor,
  });

  factory SourceCitation.fromJson(Map<String, dynamic> json) {
    final rawFileName =
        json['file_name']?.toString() ??
        json['filename']?.toString() ??
        json['source_name']?.toString() ??
        json['original_filename']?.toString();

    final rawPath =
        json['storage_path']?.toString() ??
        json['path']?.toString() ??
        json['display_path']?.toString() ??
        json['source']?.toString();

    return SourceCitation(
      categoryName:
          json['category_name']?.toString() ??
          json['category']?.toString() ??
          'General',
      yearLabel: json['year']?.toString() ?? '',
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 0,
      displayPath: rawPath,
      fileName: rawFileName,
      storagePath: rawPath,
    );
  }

  String get effectiveFileName {
    if (fileName != null && fileName!.isNotEmpty) return fileName!;

    if (storagePath != null && storagePath!.isNotEmpty) {
      final parts = storagePath!.split('/');
      if (parts.isNotEmpty) {
        final last = parts.last;

        if (last.contains('_')) {
          final afterUnderscore = last.substring(last.indexOf('_') + 1);
          if (afterUnderscore.isNotEmpty) return afterUnderscore;
        }
        return last;
      }
    }

    return categoryName;
  }
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<SourceCitation> citations;
  final bool isTyping;

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

class ChatCategory {
  final String id;
  final String name;
  final String shortName;
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

class ChatState {
  final String sessionId;
  final String? sessionTitle;
  final List<Map<String, dynamic>> recentSessions;
  final List<ChatMessage> messages;
  final List<ChatCategory> categories;
  final List<String> defaultCategoryIds;
  final bool isLoading;
  final bool categoriesSelected;
  final String? errorMessage;
  final String? yearFrom;
  final String? yearTo;
  final String? fileName;
  
  // Cascading Selection State
  final String? selectedMainCategoryId;
  final String? selectedSubCategoryId;
  final String? selectedDocumentId;
  final List<Map<String, dynamic>> categoryDocuments;

  final String inputText;
  final bool showFilterSheet;

  const ChatState({
    required this.sessionId,
    this.sessionTitle,
    this.recentSessions = const [],
    this.messages = const [],
    this.categories = const [],
    this.defaultCategoryIds = const [],
    this.isLoading = false,
    this.categoriesSelected = false,
    this.errorMessage,
    this.yearFrom,
    this.yearTo,
    this.fileName,
    this.selectedMainCategoryId,
    this.selectedSubCategoryId,
    this.selectedDocumentId,
    this.categoryDocuments = const [],
    this.inputText = '',
    this.showFilterSheet = false,
  });

  bool get canSendMessage =>
      selectedMainCategoryId != null && inputText.trim().isNotEmpty && !isLoading;

  List<ChatCategory> get selectedCategories {
    final list = <ChatCategory>[];
    if (selectedMainCategoryId != null) {
      final mainCat = categories.cast<ChatCategory?>().firstWhere((c) => c?.id == selectedMainCategoryId, orElse: () => null);
      if (mainCat != null) list.add(mainCat);
    }
    if (selectedSubCategoryId != null) {
      final subCat = categories.cast<ChatCategory?>().firstWhere((c) => c?.id == selectedSubCategoryId, orElse: () => null);
      if (subCat != null) list.add(subCat);
    }
    return list;
  }

  ChatState copyWith({
    String? sessionId,
    String? sessionTitle,
    List<Map<String, dynamic>>? recentSessions,
    List<ChatMessage>? messages,
    List<ChatCategory>? categories,
    List<String>? defaultCategoryIds,
    bool? isLoading,
    bool? categoriesSelected,
    String? errorMessage,
    String? yearFrom,
    bool clearYearFrom = false,
    String? yearTo,
    bool clearYearTo = false,
    String? fileName,
    bool clearFileName = false,
    String? selectedMainCategoryId,
    bool clearMainCategory = false,
    String? selectedSubCategoryId,
    bool clearSubCategory = false,
    String? selectedDocumentId,
    bool clearDocument = false,
    List<Map<String, dynamic>>? categoryDocuments,
    String? inputText,
    bool? showFilterSheet,
  }) {
    return ChatState(
      sessionId: sessionId ?? this.sessionId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      recentSessions: recentSessions ?? this.recentSessions,
      messages: messages ?? this.messages,
      categories: categories ?? this.categories,
      defaultCategoryIds: defaultCategoryIds ?? this.defaultCategoryIds,
      isLoading: isLoading ?? this.isLoading,
      categoriesSelected: categoriesSelected ?? this.categoriesSelected,
      errorMessage: errorMessage,
      yearFrom: clearYearFrom ? null : (yearFrom ?? this.yearFrom),
      yearTo: clearYearTo ? null : (yearTo ?? this.yearTo),
      fileName: clearFileName ? null : (fileName ?? this.fileName),
      selectedMainCategoryId: clearMainCategory ? null : (selectedMainCategoryId ?? this.selectedMainCategoryId),
      selectedSubCategoryId: clearSubCategory ? null : (selectedSubCategoryId ?? this.selectedSubCategoryId),
      selectedDocumentId: clearDocument ? null : (selectedDocumentId ?? this.selectedDocumentId),
      categoryDocuments: categoryDocuments ?? this.categoryDocuments,
      inputText: inputText ?? this.inputText,
      showFilterSheet: showFilterSheet ?? this.showFilterSheet,
    );
  }
}
