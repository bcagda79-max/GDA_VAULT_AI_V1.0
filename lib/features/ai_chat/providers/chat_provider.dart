import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_state.dart';
import '../../../core/constants/app_colors.dart';

const _uuid = Uuid();

class ChatNotifier extends Notifier<ChatState> {
  
  @override
  ChatState build() {
    return ChatState(
      messages: const [],
      categories: _buildInitialCategories(),
      isLoading: false,
      categoriesSelected: false,
    );
  }

  List<ChatCategory> _buildInitialCategories() {
    return [
      ChatCategory(
        id: 'board-authority',
        name: 'Board of Authority',
        shortName: 'BOARD',
        color: AppColors.catBoard,
        icon: Icons.gavel_rounded,
        isSelected: false,
      ),
      ChatCategory(
        id: 'board-minutes',
        name: 'Board of Authority Minutes 1996-2026',
        shortName: 'MINUTES',
        color: AppColors.catBoard,
        icon: Icons.history_edu_rounded,
        parentId: 'board-authority',
        isSelected: false,
      ),
      ChatCategory(
        id: 'trust-minutes-sub',
        name: 'Trust Minutes 1961-1996',
        shortName: 'TRUST',
        color: AppColors.catBoard,
        icon: Icons.handshake_rounded,
        parentId: 'board-authority',
        isSelected: false,
      ),
      ChatCategory(
        id: 'town-plots',
        name: 'Town (Plot) Files',
        shortName: 'TOWNS',
        color: AppColors.catTown,
        icon: Icons.location_city_rounded,
        isSelected: false,
      ),
      ChatCategory(
        id: 'administration',
        name: 'Administration',
        shortName: 'ADMIN',
        color: AppColors.catAdmin,
        icon: Icons.admin_panel_settings_rounded,
        isSelected: false,
      ),
      ChatCategory(
        id: 'private-properties',
        name: 'Private Properties',
        shortName: 'PRIVATE',
        color: AppColors.catPrivate,
        icon: Icons.home_work_rounded,
        isSelected: false,
      ),
      ChatCategory(
        id: 'trust-minutes',
        name: 'Trust Minutes Archive',
        shortName: 'TRUST',
        color: AppColors.catTrust,
        icon: Icons.handshake_rounded,
        isSelected: false,
      ),
    ];
  }

  // Toggle category selection
  void toggleCategory(String categoryId) {
    final updatedCategories = state.categories.map((cat) {
      if (cat.id == categoryId) {
        return ChatCategory(
          id: cat.id,
          name: cat.name,
          shortName: cat.shortName,
          color: cat.color,
          icon: cat.icon,
          parentId: cat.parentId,
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

  // Select all categories
  void selectAllCategories() {
    final updatedCategories = state.categories.map((cat) {
      return ChatCategory(
        id: cat.id,
        name: cat.name,
        shortName: cat.shortName,
        color: cat.color,
        icon: cat.icon,
        parentId: cat.parentId,
        isSelected: true,
      );
    }).toList();

    state = state.copyWith(
      categories: updatedCategories,
      categoriesSelected: true,
    );
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
        isSelected: false,
      );
    }).toList();

    state = state.copyWith(
      categories: updatedCategories,
      categoriesSelected: false,
    );
  }

  // Update input text
  void updateInput(String text) {
    state = state.copyWith(inputText: text);
  }

  // Send message + get mock AI response
  Future<void> sendMessage(String userText) async {
    if (!state.canSendMessage) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: userText.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

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

    // Simulate AI thinking delay (1.5 - 2.5 seconds)
    final delay = 1500 + (DateTime.now().millisecond % 1000);
    await Future.delayed(Duration(milliseconds: delay));

    // Get mock response based on selected categories + query
    final mockResponse = _getMockResponse(
      userText,
      state.selectedCategories,
    );

    // Remove typing indicator, add AI response
    final updatedMessages = state.messages
      .where((m) => !m.isTyping)
      .toList();

    final aiMsg = ChatMessage(
      id: _uuid.v4(),
      content: mockResponse.content,
      isUser: false,
      timestamp: DateTime.now(),
      citations: mockResponse.citations,
    );

    state = state.copyWith(
      messages: [...updatedMessages, aiMsg],
      isLoading: false,
    );
  }

  // Clear chat history
  void clearChat() {
    state = state.copyWith(messages: const []);
  }

  // Mock response generator
  ({String content, List<SourceCitation> citations}) _getMockResponse(
    String query,
    List<ChatCategory> selectedCats,
  ) {
    final q = query.toLowerCase();
    final catNames = selectedCats.map((c) => c.shortName).join(', ');

    // Board / Minutes related
    if (q.contains('resolution') || q.contains('board') ||
        q.contains('minutes') || q.contains('decision')) {
      return (
        content: 'Based on the Board of Authority records, '
          'Resolution 47 was passed on 14 March 1972 regarding land '
          'allocation in the Galiyat region. The resolution established '
          'a five-member board of trustees to oversee development '
          'activities. Subsequent resolutions in 1996 expanded the '
          'authority\'s jurisdiction to include urban planning and '
          'plot registration under the new GDA framework.',
        citations: [
          SourceCitation(
            documentName: 'Board Minutes Vol. IV',
            yearLabel: '1972',
            categoryName: 'Board of Authority',
            pageNumbers: const [23, 67],
            categoryColor: AppColors.catBoard,
          ),
          SourceCitation(
            documentName: 'Board Resolutions 1996',
            yearLabel: '1996',
            categoryName: 'Board of Authority',
            pageNumbers: const [12],
            categoryColor: AppColors.catBoard,
          ),
        ],
      );
    }

    // Trust related
    if (q.contains('trust') || q.contains('land') ||
        q.contains('formed') || q.contains('constitution')) {
      return (
        content: 'The Galiyat land trust was formally constituted on '
          '14 March 1972 under Resolution 47, as recorded in Trust '
          'Minutes Volume IV. It superseded the 1968 ad-hoc arrangement '
          'and established a structured framework for land management '
          'in the Galiyat region. The trust operated continuously until '
          '1996 when authority structure was reorganised.',
        citations: [
          SourceCitation(
            documentName: 'Trust Minutes Vol. IV',
            yearLabel: '1972',
            categoryName: 'Trust Minutes',
            pageNumbers: const [23, 24, 67],
            categoryColor: AppColors.catTrust,
          ),
        ],
      );
    }

    // Plot / Town related
    if (q.contains('plot') || q.contains('town') ||
        q.contains('registry') || q.contains('property')) {
      return (
        content: 'Plot registry records from 1983 to 2024 are available '
          'in the Town Files archive. Plot 47-A in Nathiagali was '
          'registered in 1983 with a total area of 4 kanals. Ownership '
          'transfer documents are filed under the 2008 registry update. '
          'Current plot status can be verified in the 2024 Plot Registry.',
        citations: [
          SourceCitation(
            documentName: 'Plot Registry 1983',
            yearLabel: '1983',
            categoryName: 'Town (Plot) Files',
            pageNumbers: const [32],
            categoryColor: AppColors.catTown,
          ),
          SourceCitation(
            documentName: 'Plot Registry 2024',
            yearLabel: '2024',
            categoryName: 'Town (Plot) Files',
            pageNumbers: const [8, 9],
            categoryColor: AppColors.catTown,
          ),
        ],
      );
    }

    // Admin related
    if (q.contains('admin') || q.contains('order') ||
        q.contains('notification') || q.contains('circular')) {
      return (
        content: 'Administrative Order 12/2021 issued on 15 June 2021 '
          'outlines the revised standard operating procedures for '
          'document processing and archival. The order mandates digital '
          'backup of all records dated after 2015. Previous circular '
          'from 2018 regarding staff transfers is also available in '
          'the Administration Files.',
        citations: [
          SourceCitation(
            documentName: 'Admin Order 12/2021',
            yearLabel: '2021',
            categoryName: 'Administration',
            pageNumbers: const [4, 5, 11],
            categoryColor: AppColors.catAdmin,
          ),
        ],
      );
    }

    // Private properties
    if (q.contains('private') || q.contains('karim') ||
        q.contains('ownership') || q.contains('transfer')) {
      return (
        content: 'Private property records are maintained from 1975 '
          'onwards. The Karim property file (2008) documents ownership '
          'transfer and boundary demarcation for a 2-kanal residential '
          'plot in Changla Gali. All private property files require '
          'authorised officer access for full document viewing.',
        citations: [
          SourceCitation(
            documentName: 'Property File — Karim',
            yearLabel: '2008',
            categoryName: 'Private Properties',
            pageNumbers: const [12, 13, 62],
            categoryColor: AppColors.catPrivate,
          ),
        ],
      );
    }

    // Generic response
    return (
      content: 'I have searched through the selected categories '
        '($catNames) and found relevant information. The GDA archive '
        'contains records spanning from 1961 to 2026 across ${selectedCats.length} '
        'selected categories. Please refine your query with specific '
        'keywords such as year, document type, resolution number, or '
        'plot number for more precise results.',
      citations: const [],
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
