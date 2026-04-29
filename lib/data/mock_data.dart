// lib/data/mock_data.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/models/category_model.dart';
import 'package:gda_vault_ai/models/document_model.dart';
import 'package:gda_vault_ai/models/chat_message_model.dart';
import 'package:uuid/uuid.dart';

/// Provides mock data for the application.
class MockData {
  static final _uuid = Uuid();

  static const List<String> suggestedQuestions = [
    'When was the land trust formed?',
    'What does Resolution 47 say?',
    'Show Plot 47-A records',
    'Latest board resolutions 2024',
    'Admin orders about staff transfers',
    'Private property transfers in 2008',
  ];

  static final List<CategoryModel> categories = [
    CategoryModel(
      id: 'board-authority',
      name: 'Board of Authority',
      color: AppColors.catBoard,
      iconData: Icons.gavel_rounded,
      docCount: 248,
      yearRange: "1996 – ongoing",
      hasSubCategories: true,
      subCategories: [
        "Board of Authority Minutes 1996–2026",
        "Trust Minutes 1961–1996",
      ],
      shortLabel: "BOARD",
      sortOrder: 1,
    ),
    CategoryModel(
      id: 'town-plots',
      name: 'Town (Plots) Files',
      color: AppColors.catTown,
      iconData: Icons.location_city_rounded,
      docCount: 186,
      yearRange: "1970 – 2026",
      hasSubCategories: false,
      shortLabel: "TOWNS",
      sortOrder: 2,
    ),
    CategoryModel(
      id: 'administration',
      name: 'Administration Files',
      color: AppColors.catAdmin,
      iconData: Icons.admin_panel_settings_rounded,
      docCount: 327,
      yearRange: "1965 – 2026",
      hasSubCategories: false,
      shortLabel: "ADMIN",
      sortOrder: 3,
    ),
    CategoryModel(
      id: 'private-properties',
      name: 'Private Properties Files',
      color: AppColors.catPrivate,
      iconData: Icons.home_work_rounded,
      docCount: 152,
      yearRange: "1975 – 2026",
      hasSubCategories: false,
      shortLabel: "PRIVATE",
      sortOrder: 4,
    ),
    CategoryModel(
      id: 'trust-minutes',
      name: 'Trust Minutes (1961-1996)',
      color: AppColors.catTrust,
      iconData: Icons.handshake_rounded,
      docCount: 412,
      yearRange: "1961 – 1996",
      hasSubCategories: false,
      shortLabel: "TRUST",
      sortOrder: 5,
    ),
  ];

  static final List<DocumentModel> documents = [
    // Board of Authority Minutes (1996–2026)
    ...List.generate(30, (i) {
      final year = 1996 + i;
      return DocumentModel(
        id: _uuid.v4(),
        categoryId: 'board-minutes-1996-2026',
        yearLabel: year.toString(),
        yearStart: year,
        fileName: 'Board Minutes $year.pdf',
        filePath: '/mock/board_minutes_$year.pdf',
        pageCount: 80 + (i * 5),
        uploadedAt: DateTime(year, 12, 15),
      );
    }),
    DocumentModel(
      id: _uuid.v4(),
      categoryId: 'board-minutes-1996-2026',
      yearLabel: '2025-2026',
      yearStart: 2025,
      yearEnd: 2026,
      fileName: 'Board Resolutions 2025-2026.pdf',
      filePath: '/mock/board_resolutions_2025-2026.pdf',
      pageCount: 250,
      uploadedAt: DateTime(2026, 1, 20),
    ),
    DocumentModel(
      id: _uuid.v4(),
      categoryId: 'board-minutes-1996-2026',
      yearLabel: '2026-onwards',
      yearStart: 2026,
      fileName: 'Board Minutes 2026-onwards.pdf',
      filePath: '/mock/board_minutes_2026_onwards.pdf',
      pageCount: 50,
      uploadedAt: DateTime.now(),
      isOngoing: true,
    ),

    // Trust Minutes (1961–1996)
    ...[
      1961,
      1964,
      1967,
      1969,
      1972,
      1975,
      1978,
      1981,
      1983,
      1985,
      1987,
      1989,
      1991,
      1993,
      1994,
      1996,
    ].asMap().entries.map((entry) {
      final year = entry.value;
      final index = entry.key;
      final roman = [
        'I',
        'II',
        'III',
        'IV',
        'V',
        'VI',
        'VII',
        'VIII',
        'IX',
        'X',
        'XI',
        'XII',
        'XIII',
        'XIV',
        'XV',
        'XVI',
      ][index];
      return DocumentModel(
        id: _uuid.v4(),
        categoryId: 'trust-minutes-1961-1996',
        yearLabel: year.toString(),
        yearStart: year,
        fileName: 'Trust Minutes Vol.$roman $year.pdf',
        filePath: '/mock/trust_minutes_$year.pdf',
        pageCount: 100 + (index * 20),
        uploadedAt: DateTime(year, 10, 5),
      );
    }),

    // Town Plots
    ...[
      1970,
      1975,
      1978,
      1982,
      1985,
      1989,
      1992,
      1995,
      1998,
      2001,
      2004,
      2007,
      2010,
      2013,
      2016,
      2019,
      2022,
      2024,
      2025,
    ].map((year) {
      return DocumentModel(
        id: _uuid.v4(),
        categoryId: 'town-plots',
        yearLabel: year.toString(),
        yearStart: year,
        fileName: 'Plot Registry $year.pdf',
        filePath: '/mock/plot_registry_$year.pdf',
        pageCount: 120 + (year - 1970),
        uploadedAt: DateTime(year, 6, 1),
      );
    }),

    // Administration
    ...[
      1965,
      1970,
      1975,
      1980,
      1985,
      1988,
      1991,
      1994,
      1997,
      2000,
      2003,
      2006,
      2009,
      2012,
      2015,
      2018,
      2021,
      2022,
      2023,
      2024,
      2025,
      2026,
    ].map((year) {
      return DocumentModel(
        id: _uuid.v4(),
        categoryId: 'administration',
        yearLabel: year.toString(),
        yearStart: year,
        fileName: 'Admin Order $year.pdf',
        filePath: '/mock/admin_order_$year.pdf',
        pageCount: 90 + (year - 1965),
        uploadedAt: DateTime(year, 3, 10),
      );
    }),

    // Private Properties
    ...[
      1975,
      1980,
      1985,
      1988,
      1992,
      1996,
      2000,
      2004,
      2008,
      2012,
      2015,
      2018,
      2020,
      2022,
      2024,
      2025,
    ].map((year) {
      return DocumentModel(
        id: _uuid.v4(),
        categoryId: 'private-properties',
        yearLabel: year.toString(),
        yearStart: year,
        fileName: 'Property File $year.pdf',
        filePath: '/mock/property_file_$year.pdf',
        pageCount: 150 + (year - 1975),
        uploadedAt: DateTime(year, 8, 20),
      );
    }),
  ];

  static List<DocumentModel> getDocumentsForCategory(String categoryId) {
    return documents.where((d) => d.categoryId == categoryId).toList();
  }

  static List<String> getYearsForCategory(String categoryId) {
    return getDocumentsForCategory(
      categoryId,
    ).map((d) => d.yearLabel).toSet().toList();
  }

  static List<ChatMessage> get chatMessages {
    return [
      ChatMessage(
        id: _uuid.v4(),
        content: 'When was the Trust established?',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        id: _uuid.v4(),
        content:
            'The Galiyat Development Authority was established under the GDA Act 1996. Prior to that, development activities were managed by the Abbottabad Development Authority, with trust-related matters documented in the "Trust Minutes".',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        sourceCitations: ['Trust Minutes 1961–1996'],
      ),
      ChatMessage(
        id: _uuid.v4(),
        content: 'Find me the decision on plot 152 in the town planning files.',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      ChatMessage(
        id: _uuid.v4(),
        content:
            'Searching for "plot 152"... I found a reference in "Plot Registry 2004.pdf" on page 18 regarding a boundary adjustment.',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        sourceCitations: ['Plot Registry 2004.pdf — p.18'],
      ),
      ChatMessage(
        id: _uuid.v4(),
        content: 'Thank you!',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];
  }
}
