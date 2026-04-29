// lib/features/add_document/category_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:gda_vault_ai/core/constants/app_strings.dart';

/// A screen for selecting a category for a new document.
class CategorySelectorScreen extends StatelessWidget {
  final String source;
  final int pageCount;
  final String fileName;
  final int? fileSize;

  const CategorySelectorScreen({
    super.key,
    required this.source,
    required this.pageCount,
    required this.fileName,
    this.fileSize,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.selectCategoryTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Category selector for: $fileName'),
              Text('Source: $source | Pages: $pageCount'),
              if (fileSize != null) Text('Size: ${fileSize! / 1024} KB'),
            ],
          ),
        ),
      ),
    );
  }
}
