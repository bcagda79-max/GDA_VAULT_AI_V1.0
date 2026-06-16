import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/ai_chat_service.dart';
import '../../../core/services/chat_history_service.dart';

const _uuid = Uuid();

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    // Initial load
    Future.microtask(() {
      syncCategories();
      loadDefaultCategoryIds();
      loadRecentSessions();
    });

    return ChatState(
      sessionId: _uuid.v4(),
      messages: const [],
      categories: const [],
      isLoading: false,
      categoriesSelected: false,
    );
  }

  Future<void> loadRecentSessions() async {
    final sessions = await ChatHistoryService.instance.getAllSessions();
    state = state.copyWith(recentSessions: sessions);
  }

  Future<void> syncCategories() async {
    try {
      final rows = await ApiService.instance.getAllCategories();
      if (rows.isEmpty) return;

      final updatedCategories = rows.map((row) {
        return ChatCategory(
          id: row['id'].toString(),
          name: row['name']?.toString() ?? 'Unknown',
          shortName: row['slug']?.toString() ?? 'UNK',
          color: _parseColor(row['hex_color']),
          icon: _parseIcon(row['icon']),
          parentId: row['parent_id']?.toString(),
          docCount: (row['document_count'] as num?)?.toInt() ?? 0,
          isSelected: false,
        );
      }).toList();

      state = state.copyWith(categories: updatedCategories);
    } catch (e) {
      debugPrint('Error syncing chat categories: $e');
    }
  }

  Future<void> loadDefaultCategoryIds() async {
    final ids = await ChatHistoryService.instance.getDefaultCategoryIds();
    state = state.copyWith(defaultCategoryIds: ids);

    if (state.messages.isEmpty && ids.isNotEmpty) {
      _applyDefaultCategories(ids);
    }
  }

  Color _parseColor(dynamic hexStr) {
    if (hexStr == null) return AppTokens.lightBrandPrimary;
    final str = hexStr.toString().replaceAll('#', '');
    if (str.length == 6) return Color(int.parse('0xFF$str'));
    if (str.length == 8) return Color(int.parse('0x$str'));
    return AppTokens.lightBrandPrimary;
  }

  IconData _parseIcon(dynamic iconStr) {
    final str = iconStr?.toString().toLowerCase() ?? '';
    if (str.contains('admin')) return Icons.admin_panel_settings_rounded;
    if (str.contains('book')) return Icons.menu_book_rounded;
    if (str.contains('gavel')) return Icons.gavel_rounded;
    if (str.contains('location') || str.contains('plot')) return Icons.location_city_rounded;
    if (str.contains('file') || str.contains('doc')) return Icons.insert_drive_file_rounded;
    return Icons.folder_rounded;
  }

  void _applyDefaultCategories(List<String> ids) {
    // We don't need this anymore with cascading dropdowns, keep minimal
  }

  void _applySelectedCategories(List<String> ids) {
    // Keep minimal
  }

  void selectMainCategory(String? categoryId) {
    state = state.copyWith(
      selectedMainCategoryId: categoryId,
      clearMainCategory: categoryId == null,
      selectedSubCategoryId: null,
      clearSubCategory: true,
      selectedDocumentId: null,
      clearDocument: true,
      categoryDocuments: const [],
      fileName: null,
      clearFileName: true,
      yearFrom: null,
      clearYearFrom: true,
      yearTo: null,
      clearYearTo: true,
    );

    // If no subcategories exist for this main category, fetch docs directly
    if (categoryId != null) {
      final subCategories = state.categories.where((c) => c.parentId == categoryId).toList();
      if (subCategories.isEmpty) {
        _fetchDocumentsForSelection(categoryId, null);
      }
    }
  }

  void selectSubCategory(String? subCategoryId) {
    state = state.copyWith(
      selectedSubCategoryId: subCategoryId,
      clearSubCategory: subCategoryId == null,
      selectedDocumentId: null,
      clearDocument: true,
      categoryDocuments: const [],
      fileName: null,
      clearFileName: true,
      yearFrom: null,
      clearYearFrom: true,
      yearTo: null,
      clearYearTo: true,
    );
    
    if (subCategoryId != null && state.selectedMainCategoryId != null) {
      _fetchDocumentsForSelection(state.selectedMainCategoryId!, subCategoryId);
    } else if (subCategoryId == null && state.selectedMainCategoryId != null) {
      // Re-fetch parent docs if cleared
      final subCategories = state.categories.where((c) => c.parentId == state.selectedMainCategoryId).toList();
      if (subCategories.isEmpty) {
        _fetchDocumentsForSelection(state.selectedMainCategoryId!, null);
      }
    }
  }

  void selectDocument(String? documentId) {
    state = state.copyWith(
      selectedDocumentId: documentId,
      clearDocument: documentId == null,
    );
    // When a document is specifically selected, also update the fileName for the AI backend filter
    if (documentId != null) {
      final doc = state.categoryDocuments.firstWhere((d) => d['id'].toString() == documentId, orElse: () => {});
      if (doc.isNotEmpty && doc['file_name'] != null) {
        updateFileName(doc['file_name'].toString());
      }
    } else {
      updateFileName(null);
    }
  }

  Future<void> _fetchDocumentsForSelection(String categoryId, String? subCategoryId) async {
    try {
      final docs = await ApiService.instance.getDocumentsByCategory(categoryId, subCategoryId: subCategoryId);
      state = state.copyWith(categoryDocuments: docs);
    } catch (e) {
      debugPrint("Error fetching documents for selection: $e");
      state = state.copyWith(categoryDocuments: const []);
    }
  }

  Future<void> updateDefaultCategoryIds(List<String> ids) async {
    final unique = ids.take(2).toList();
    await ChatHistoryService.instance.saveDefaultCategoryIds(unique);
    state = state.copyWith(defaultCategoryIds: unique);

    if (state.messages.isEmpty) {
      _applyDefaultCategories(unique);
    }
  }

  // Smart Selection for PDF View context
  void selectSpecificCategory(String? categoryId, String? subCategoryId) {
    final targetId = subCategoryId ?? categoryId;
    if (targetId == null) return;

    final updatedCategories = state.categories.map((cat) {
      return ChatCategory(
        id: cat.id,
        name: cat.name,
        shortName: cat.shortName,
        color: cat.color,
        icon: cat.icon,
        parentId: cat.parentId,
        docCount: cat.docCount,
        isSelected: cat.id == targetId || cat.id == categoryId,
      );
    }).toList();

    state = state.copyWith(
      categories: updatedCategories,
      categoriesSelected: updatedCategories.any((c) => c.isSelected),
    );
  }

  // Toggle category selection (Limited to max 2)
  void toggleCategory(String categoryId) {
    final currentSelected = state.selectedCategories;
    final isAlreadySelected = currentSelected.any((c) => c.id == categoryId);

    if (!isAlreadySelected && currentSelected.length >= 2) {
      // Limit reached, do not select more
      debugPrint('Maximum 2 categories allowed for selection');
      return;
    }

    final updatedCategories = state.categories.map((cat) {
      if (cat.id == categoryId) {
        return ChatCategory(
          id: cat.id,
          name: cat.name,
          shortName: cat.shortName,
          color: cat.color,
          icon: cat.icon,
          parentId: cat.parentId,
          docCount: cat.docCount,
          isSelected: !cat.isSelected,
        );
      }
      return cat;
    }).toList();

    final anySelected = updatedCategories.any((c) => c.isSelected);

    state = state.copyWith(
      categories: updatedCategories,
      categoriesSelected: anySelected,
    );
  }

  void selectAllCategories() {
    debugPrint('Select All is disabled due to 2-category limit');
  }

  void clearAllCategories() {
    final updatedCategories = state.categories.map((cat) {
      return ChatCategory(
        id: cat.id,
        name: cat.name,
        shortName: cat.shortName,
        color: cat.color,
        icon: cat.icon,
        parentId: cat.parentId,
        docCount: cat.docCount,
        isSelected: false,
      );
    }).toList();

    state = state.copyWith(
      categories: updatedCategories,
      categoriesSelected: false,
    );
  }

  void openFilterSheet() {
    state = state.copyWith(showFilterSheet: true);

    Future.microtask(() {
      state = state.copyWith(showFilterSheet: false);
    });
  }

  void updateInput(String text) {
    state = state.copyWith(inputText: text);
  }

  void updateYearRange(String? from, String? to) {
    state = state.copyWith(
      yearFrom: from,
      clearYearFrom: from == null,
      yearTo: to,
      clearYearTo: to == null,
      clearFileName: true, // Mutually exclusive with fileName
    );
  }

  void updateFileName(String? name) {
    state = state.copyWith(
      fileName: name?.isEmpty == true ? null : name,
      clearFileName: name == null || name.isEmpty,
      clearYearFrom: true, // Mutually exclusive with year
      clearYearTo: true,
    );
  }

  void startNewChat() {
    state = state.copyWith(
      sessionId: _uuid.v4(),
      sessionTitle: null,
      messages: const [],
      isLoading: false,
      inputText: '',
      clearYearFrom: true,
      clearYearTo: true,
      clearFileName: true,
    );

    if (state.defaultCategoryIds.isNotEmpty) {
      _applyDefaultCategories(state.defaultCategoryIds);
    } else {
      clearAllCategories();
    }
  }

  Future<void> loadSession(String sessionId) async {
    final sessions = state.recentSessions;
    final currentSession = sessions.firstWhere((s) => s['id'] == sessionId);
    final messages = await ChatHistoryService.instance.getMessagesForSession(
      sessionId,
    );

    final rawCategoryIds = currentSession['category_ids']?.toString();
    List<String> categoryIds = const [];
    if (rawCategoryIds != null && rawCategoryIds.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCategoryIds);
        if (decoded is List) {
          categoryIds = decoded.map((item) => item.toString()).toList();
        }
      } catch (_) {
        categoryIds = const [];
      }
    }

    if (categoryIds.isEmpty && state.defaultCategoryIds.isNotEmpty) {
      categoryIds = state.defaultCategoryIds;
    }

    final yearFrom = currentSession['year_from']?.toString();
    final yearTo = currentSession['year_to']?.toString();

    state = state.copyWith(
      sessionId: sessionId,
      sessionTitle: currentSession['title'],
      messages: messages,
      isLoading: false,
      inputText: '',
      yearFrom: yearFrom,
      yearTo: yearTo,
    );

    if (categoryIds.isNotEmpty) {
      _applySelectedCategories(categoryIds);
    } else {
      clearAllCategories();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await ChatHistoryService.instance.deleteSession(sessionId);
    await loadRecentSessions();
    if (state.sessionId == sessionId) {
      startNewChat();
    }
  }

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty || !state.categoriesSelected || state.isLoading)
      return;

    final currentYear = DateTime.now().year;
    final maxYear = currentYear > 2026 ? currentYear.toString() : '2026';

    final effectiveYearFrom = state.yearFrom ?? '1996';
    final effectiveYearTo = state.yearTo ?? maxYear;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: userText.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    if (state.messages.isEmpty) {
      final title = userText.length > 30
          ? "${userText.substring(0, 27)}..."
          : userText;

      await ChatHistoryService.instance.saveSession(
        id: state.sessionId,
        title: title,
        lastMessage: userText,
        categoryIds: state.selectedCategories.map((c) => c.id).toList(),
        yearFrom: effectiveYearFrom,
        yearTo: effectiveYearTo,
      );
      state = state.copyWith(
        sessionTitle: title,
        yearFrom: effectiveYearFrom,
        yearTo: effectiveYearTo,
        fileName: state.fileName,
      );
    }

    await ChatHistoryService.instance.saveMessage(state.sessionId, userMsg);

    final typingMsg = ChatMessage(
      id: 'typing-${_uuid.v4()}',
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, typingMsg],
      isLoading: true,
      inputText: '',
    );

    try {
      final selected = state.selectedCategories;
      final mainId = selected.isNotEmpty ? selected.first.id : null;
      final subId = selected.length > 1 ? selected[1].id : null;

      final response = await AiChatService.sendMessage(
        message: userText,
        sessionId: state.sessionId,
        categoryId: mainId,
        subCategoryId: subId,
        yearFrom: state.fileName == null ? effectiveYearFrom : null,
        yearTo: state.fileName == null ? effectiveYearTo : null,
        fileName: state.fileName,
      );

      final answer = response['answer']?.toString() ?? 'No response from AI.';
      final sourcesData = response['sources'] as List? ?? [];

      final citations = sourcesData.map((s) {
        final citation = SourceCitation.fromJson(s as Map<String, dynamic>);

        String catName = citation.categoryName;
        if (catName == 'General' && selected.isNotEmpty) {
          catName = selected.first.name;
        }

        final cat = state.categories.firstWhere(
          (c) => c.name.toLowerCase().contains(catName.toLowerCase()),
          orElse: () =>
              selected.isNotEmpty ? selected.first : state.categories.first,
        );

        return SourceCitation(
          categoryName: catName,
          yearLabel: citation.yearLabel,
          pageNumber: citation.pageNumber,
          displayPath: citation.displayPath,
          fileName: citation.fileName,
          storagePath: citation.storagePath,
          categoryColor: cat.color,
        );
      }).toList();

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        content: answer,
        isUser: false,
        timestamp: DateTime.now(),
        citations: citations,
      );

      // Save AI message
      await ChatHistoryService.instance.saveMessage(state.sessionId, aiMsg);
      await loadRecentSessions(); // Refresh list

      // Remove typing indicator, add AI response
      final updatedMessages = state.messages.where((m) => !m.isTyping).toList();

      state = state.copyWith(
        messages: [...updatedMessages, aiMsg],
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Chat error: $e');

      // Remove typing, add error message
      final updatedMessages = state.messages.where((m) => !m.isTyping).toList();

      state = state.copyWith(
        messages: [
          ...updatedMessages,
          ChatMessage(
            id: _uuid.v4(),
            content:
                'I encountered an error connecting to the AI server. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
      );
    }
  }

  // Clear chat history
  void clearChat() {
    state = state.copyWith(messages: const []);
  }

  Future<void> deleteAllChats() async {
    await ChatHistoryService.instance.deleteAllChats();
    await loadRecentSessions();
    startNewChat();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

