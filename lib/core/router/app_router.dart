import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/features/splash/splash_screen.dart';
import 'package:gda_vault_ai/features/dashboard/dashboard_screen.dart';
import 'package:gda_vault_ai/core/utils/responsive_helper.dart';
import 'package:gda_vault_ai/features/categories/categories_screen.dart';
import 'package:gda_vault_ai/features/categories/subcategory_screen.dart';
import 'package:gda_vault_ai/features/categories/year_list_screen.dart';
import 'package:gda_vault_ai/features/categories/pdf_viewer_screen.dart';
import 'package:gda_vault_ai/features/add_document/add_screen.dart';
import 'package:gda_vault_ai/features/add_document/scanner_screen.dart';
import 'package:gda_vault_ai/features/add_document/scan_review_screen.dart';
import 'package:gda_vault_ai/features/add_document/scan_pdf_preview_screen.dart';
import 'package:gda_vault_ai/features/add_document/category_selector_screen.dart';
import 'package:gda_vault_ai/features/dashboard/tabs/home_tab.dart';
import 'package:gda_vault_ai/features/dashboard/tabs/settings_tab.dart';
import 'package:gda_vault_ai/features/dashboard/recent_documents_screen.dart';
import 'package:gda_vault_ai/features/ai_chat/chat_screen.dart';
import 'package:gda_vault_ai/features/recent_scans/recent_scans_list_screen.dart';
import 'package:gda_vault_ai/features/offline/offline_documents_screen.dart';
import 'package:gda_vault_ai/features/offline/offline_browser_screen.dart';
import 'package:gda_vault_ai/models/document_model.dart';
import 'package:gda_vault_ai/features/login/login_screen.dart';
import 'package:gda_vault_ai/features/login/signup_screen.dart';
import 'package:gda_vault_ai/features/dashboard/access_denied_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/splash',
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/access-denied',
        name: 'access-denied',
        builder: (context, state) => const AccessDeniedScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return DashboardScreen(child: child);
        },
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
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ChatScreen(
                initialDocumentId: extra?['documentId'] as String?,
                initialCategoryId: extra?['categoryId'] as String?,
                initialSubCategoryId: extra?['subCategoryId'] as String?,
                initialYear: extra?['year'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/dashboard/settings',
            name: 'settings',
            builder: (context, state) => const SettingsTab(),
          ),
          GoRoute(
            path: '/dashboard/recent-documents',
            name: 'recent-documents',
            builder: (context, state) => const RecentDocumentsScreen(),
          ),

          GoRoute(
            path: '/dashboard/offline-documents',
            name: 'offline-documents',
            builder: (context, state) => const OfflineDocumentsScreen(),
            routes: [
              GoRoute(
                path: 'sub/:categoryId',
                name: 'offline-subcategories',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return OfflineBrowserScreen(
                    categoryId: state.pathParameters['categoryId']!,
                    categoryName: extra['categoryName'] as String,
                    categoryColor: extra['categoryColor'] as Color,
                    viewType: extra['viewType'] as OfflineBrowserViewType,
                    subCategoryName: extra['subCategoryName'] as String?,
                  );
                },
              ),
              GoRoute(
                path: 'files/:categoryId',
                name: 'offline-files-list',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return OfflineBrowserScreen(
                    categoryId: state.pathParameters['categoryId']!,
                    categoryName: extra['categoryName'] as String,
                    categoryColor: extra['categoryColor'] as Color,
                    viewType: extra['viewType'] as OfflineBrowserViewType,
                    subCategoryName: extra['subCategoryName'] as String?,
                    year: extra['year'] as int?,
                  );
                },
              ),
            ],
          ),

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
                    categoryColor: extra['categoryColor'] as Color,
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
                        subCategoryId: extra['subCategoryId'] as String?,
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
                            initialPage: extra['initialPage'] as int?,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/dashboard/add/scanner',
        name: 'scanner',
        builder: (context, state) {
          if (ResponsiveHelper.isDesktop(context)) {
            return const AddScreen();
          }
          return const ScannerScreen();
        },
      ),
      GoRoute(
        path: '/dashboard/add/review',
        name: 'review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ScanReviewScreen(
            pageCount: extra['pageCount'] as int? ?? 1,
            source: extra['source'] as String? ?? 'scanner',
            imagePaths: List<String>.from(extra['imagePaths'] as List? ?? []),
            existingPdfPath: extra['existingPdfPath'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/dashboard/add/pdf-preview',
        name: 'pdf-preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ScanPdfPreviewScreen(
            imagePaths: List<String>.from(extra['imagePaths'] as List? ?? []),
            fileName: extra['fileName'] as String? ?? 'GDA_Scan.pdf',
            source: extra['source'] as String? ?? 'scanner',
            pageCount: extra['pageCount'] as int? ?? 1,
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
            filePath: extra['filePath'] as String?,
            imagePaths: List<String>.from(
              extra['imagePaths'] as List? ?? const [],
            ),
          );
        },
      ),

      GoRoute(
        path: '/recent-scans',
        name: 'recent-scans',
        builder: (context, state) => const RecentScansListScreen(),
      ),

      GoRoute(
        path: '/chat',
        name: 'chat-fullscreen',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            initialDocumentId: extra?['documentId'] as String?,
            initialCategoryId: extra?['categoryId'] as String?,
            initialSubCategoryId: extra?['subCategoryId'] as String?,
            initialYear: extra?['year'] as String?,
          );
        },
      ),

      GoRoute(
        path: '/pdf-viewer',
        name: 'pdf-viewer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PdfViewerScreen(
            document: extra['document'] as DocumentModel,
            categoryColor: extra['categoryColor'] as Color,
            categoryName: extra['categoryName'] as String,
            initialPage: extra['initialPage'] as int?,
          );
        },
      ),
    ],
  );
}
