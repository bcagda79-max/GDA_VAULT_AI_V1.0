import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/services/supabase_service.dart';
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
      categories: _buildInitialCategories(),
      isLoading: false,
      categoriesSelected: false,
    );
  }

  // Load history from DB
  Future<void> loadRecentSessions() async {
    final sessions = await ChatHistoryService.instance.getAllSessions();
    state = state.copyWith(recentSessions: sessions);
  }

  List<ChatCategory> _buildInitialCategories() {
    return [
      ChatCategory(
        id: SupabaseConstants.idBoardOfAuthority,
        name: 'Board of Authority',
        shortName: 'BOARD',
        color: AppColors.catBoard,
        icon: Icons.gavel_rounded,
        isSelected: false,
        docCount: 0,
      ),
      ChatCategory(
        id: SupabaseConstants.idBoardAuthorityMinutes,
        name: 'Board Authority Minutes',
        shortName: 'MINUTES',
        color: AppColors.catBoard,
        icon: Icons.history_edu_rounded,
        parentId: SupabaseConstants.idBoardOfAuthority,
        isSelected: false,
        docCount: 0,
      ),
      ChatCategory(
        id: SupabaseConstants.idTrustMinutes,
        name: 'Trust Minutes Archive',
        shortName: 'TRUST',
        color: AppColors.catBoard,
        icon: Icons.handshake_rounded,
        parentId: SupabaseConstants.idBoardOfAuthority,
        isSelected: false,
        docCount: 0,
      ),
      ChatCategory(
        id: SupabaseConstants.idTownPlots,
        name: 'Town (Plot) Files',
        shortName: 'TOWNS',
        color: AppColors.catTown,
        icon: Icons.location_city_rounded,
        isSelected: false,
        docCount: 0,
      ),
      ChatCategory(
        id: SupabaseConstants.idAdministration,
        name: 'Administration',
        shortName: 'ADMIN',
        color: AppColors.catAdmin,
        icon: Icons.admin_panel_settings_rounded,
        isSelected: false,
        docCount: 0,
      ),
      ChatCategory(
        id: SupabaseConstants.idPrivateProperties,
        name: 'Private Properties',
        shortName: 'PRIVATE',
        color: AppColors.catPrivate,
        icon: Icons.home_work_rounded,
        isSelected: false,
        docCount: 0,
      ),
    ];
  }

  Future<void> syncCategories() async {
    try {
      final rows = await SupabaseService.instance.getAllCategories();
      if (rows.isEmpty) return;

      final updatedCategories = state.categories.map((cat) {
        final dbRow = rows.firstWhere(
          (row) => row['id'].toString() == cat.id,
          orElse: () => <String, dynamic>{},
        );

        int aggregatedChildren = 0;
        for (final row in rows) {
          if (row['parent_id']?.toString() == cat.id) {
            aggregatedChildren += (row['document_count'] as num?)?.toInt() ?? 0;
          }
        }

        if (cat.id == SupabaseConstants.idBoardOfAuthority &&
            aggregatedChildren > 0) {
          return ChatCategory(
            id: cat.id,
            name: cat.name,
            shortName: cat.shortName,
            color: cat.color,
            icon: cat.icon,
            parentId: cat.parentId,
            docCount: aggregatedChildren,
            isSelected: cat.isSelected,
          );
        }

        if (dbRow.isEmpty) {
          if (aggregatedChildren > 0) {
            return ChatCategory(
              id: cat.id,
              name: cat.name,
              shortName: cat.shortName,
              color: cat.color,
              icon: cat.icon,
              parentId: cat.parentId,
              docCount: aggregatedChildren,
              isSelected: cat.isSelected,
            );
          }
          return cat;
        }

        return ChatCategory(
          id: cat.id,
          name: cat.name,
          shortName: cat.shortName,
          color: cat.color,
          icon: cat.icon,
          parentId: cat.parentId,
          docCount: (dbRow['document_count'] as num?)?.toInt() ?? 0,
          isSelected: cat.isSelected,
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

  void _applyDefaultCategories(List<String> ids) {
    final limited = ids.take(2).toSet();
    final updatedCategories = state.categories.map((cat) {
      return ChatCategory(
        id: cat.id,
        name: cat.name,
        shortName: cat.shortName,
        color: cat.color,
        icon: cat.icon,
        parentId: cat.parentId,
        docCount: cat.docCount,
        isSelected: limited.contains(cat.id),
      );
    }).toList();

    state = state.copyWith(
      categories: updatedCategories,
      categoriesSelected: updatedCategories.any((c) => c.isSelected),
    );
  }

  void _applySelectedCategories(List<String> ids) {
    final selectedIds = ids.take(2).toSet();
    final updatedCategories = state.categories.map((cat) {
      return ChatCategory(
        id: cat.id,
        name: cat.name,
        shortName: cat.shortName,
        color: cat.color,
        icon: cat.icon,
        parentId: cat.parentId,
        docCount: cat.docCount,
        isSelected: selectedIds.contains(cat.id),
      );
    }).toList();

    state = state.copyWith(
      categories: updatedCategories,
      categoriesSelected: updatedCategories.any((c) => c.isSelected),
    );
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

  // Disabled Select All as we now limit to 2
  void selectAllCategories() {
    debugPrint('Select All is disabled due to 2-category limit');
  }

  // Clear all selections
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

  // Signal to open filter sheet
  void openFilterSheet() {
    state = state.copyWith(showFilterSheet: true);
    // Immediately reset so it doesn't trigger again on next state update
    Future.microtask(() {
      state = state.copyWith(showFilterSheet: false);
    });
  }

  // Update input text
  void updateInput(String text) {
    state = state.copyWith(inputText: text);
  }

  // Update year range for filtering
  void updateYearRange(String? from, String? to) {
    state = state.copyWith(
      yearFrom: from,
      clearYearFrom: from == null,
      yearTo: to,
      clearYearTo: to == null,
    );
  }

  // Start a fresh session
  void startNewChat() {
    state = state.copyWith(
      sessionId: _uuid.v4(),
      sessionTitle: null,
      messages: const [],
      isLoading: false,
      inputText: '',
      clearYearFrom: true,
      clearYearTo: true,
    );

    if (state.defaultCategoryIds.isNotEmpty) {
      _applyDefaultCategories(state.defaultCategoryIds);
    } else {
      clearAllCategories();
    }
  }

  // Load specific session
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

    // Extract year_from and year_to from session
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

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    await ChatHistoryService.instance.deleteSession(sessionId);
    await loadRecentSessions();
    if (state.sessionId == sessionId) {
      startNewChat();
    }
  }

  // Send message + get real AI response from n8n
  Future<void> sendMessage(String userText) async {
    if (!state.canSendMessage) return;

    // Use defaults if user hasn't selected years
    final effectiveYearFrom = state.yearFrom ?? '1996';
    final effectiveYearTo = state.yearTo ?? '2026';

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: userText.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Save/Update session first if it's the first message
    if (state.messages.isEmpty) {
      final title =
          userText.length > 30 ? "${userText.substring(0, 27)}..." : userText;

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
      );
    }

    // Save user message
    await ChatHistoryService.instance.saveMessage(state.sessionId, userMsg);

    // Add user message + typing indicator
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
      // Get selected category IDs
      final selected = state.selectedCategories;
      final mainId = selected.isNotEmpty ? selected.first.id : null;
      final subId = selected.length > 1 ? selected[1].id : null;

      // Call n8n service
      final response = await AiChatService.sendMessage(
        message: userText,
        sessionId: state.sessionId,
        categoryId: mainId,
        subCategoryId: subId,
        yearFrom: effectiveYearFrom,
        yearTo: effectiveYearTo,
      );

      final answer = response['answer']?.toString() ?? 'No response from AI.';
      final sourcesData = response['sources'] as List? ?? [];

      final citations = sourcesData.map((s) {
        final citation = SourceCitation.fromJson(s as Map<String, dynamic>);

        // Use currently selected category if n8n didn't provide one
        String catName = citation.categoryName;
        if (catName == 'General' && selected.isNotEmpty) {
          catName = selected.first.name;
        }

        // Map category color for UI consistency
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
