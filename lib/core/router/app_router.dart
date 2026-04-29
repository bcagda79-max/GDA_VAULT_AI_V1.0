// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/features/splash/splash_screen.dart';
import 'package:gda_vault_ai/features/dashboard/dashboard_screen.dart';
import 'package:gda_vault_ai/features/categories/categories_screen.dart';
import 'package:gda_vault_ai/features/categories/subcategory_screen.dart';
import 'package:gda_vault_ai/features/categories/year_list_screen.dart';
import 'package:gda_vault_ai/features/categories/pdf_viewer_screen.dart';
import 'package:gda_vault_ai/features/add_document/add_screen.dart';
import 'package:gda_vault_ai/features/add_document/scanner_screen.dart';
import 'package:gda_vault_ai/features/add_document/camera_scanner_screen.dart';
import 'package:gda_vault_ai/features/add_document/scan_review_screen.dart';
import 'package:gda_vault_ai/features/add_document/category_selector_screen.dart';
import 'package:gda_vault_ai/features/dashboard/tabs/home_tab.dart';
import 'package:gda_vault_ai/features/dashboard/tabs/chat_tab.dart';
import 'package:gda_vault_ai/features/dashboard/tabs/settings_tab.dart';
import 'package:gda_vault_ai/features/ai_chat/chat_screen.dart';
import 'package:gda_vault_ai/models/document_model.dart';

/// Manages the routing logic for the application.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Dashboard as ShellRoute for persistent bottom nav
      ShellRoute(
        builder: (context, state, child) => DashboardScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const HomeTab(),
          ),
          GoRoute(
            path: '/dashboard/add',
            name: 'add',
            builder: (context, state) => const AddScreen(),
          ),
          GoRoute(
            path: '/dashboard/chat',
            name: 'chatTab',
            builder: (context, state) => const ChatTab(),
          ),
          GoRoute(
            path: '/dashboard/settings',
            name: 'settings',
            builder: (context, state) => const SettingsTab(),
          ),
        ],
      ),

      // Categories flow — OUTSIDE shell (full screen, has own back)
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoriesScreen(),
        routes: [
          GoRoute(
            path: 'sub/:categoryId',
            name: 'subcategory',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return SubcategoryScreen(
                categoryId: state.pathParameters['categoryId']!,
                categoryName: extra['categoryName'] as String,
              );
            },
            routes: [
              GoRoute(
                path: 'years',
                name: 'years',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return YearListScreen(
                    categoryId: state.pathParameters['categoryId']!,
                    categoryName: extra['categoryName'] as String,
                    categoryColor: extra['categoryColor'] as Color,
                    yearFrom: extra['yearFrom'] as int,
                    yearTo: extra['yearTo'] as int?,
                    subCategoryName: extra['subCategoryName'] as String?,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'pdf',
                    name: 'pdf',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>;
                      return PdfViewerScreen(
                        document: extra['document'] as DocumentModel,
                        categoryColor: extra['categoryColor'] as Color,
                        categoryName: extra['categoryName'] as String,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Add document flow (Full Screen)
      GoRoute(
        path: '/dashboard/add/scanner',
        name: 'scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/dashboard/add/camera-scanner',
        name: 'camera-scanner',
        builder: (context, state) => const CameraScannerScreen(),
      ),
      GoRoute(
        path: '/dashboard/add/review',
        name: 'review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final imagePaths =
              (extra['imagePaths'] as List<dynamic>?)?.cast<String>() ??
              const <String>[];
          return ScanReviewScreen(
            pageCount: extra['pageCount'] as int,
            source: extra['source'] as String,
            imagePaths: imagePaths,
          );
        },
      ),
      GoRoute(
        path: '/dashboard/add/select-category',
        name: 'select-category',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CategorySelectorScreen(
            source: extra['source'] as String,
            pageCount: extra['pageCount'] as int? ?? 1,
            fileName: extra['fileName'] as String,
            fileSize: extra['fileSize'] as int?,
          );
        },
      ),
      // Chat screen as full screen if accessed directly from home FAB
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
    ],
  );
}
