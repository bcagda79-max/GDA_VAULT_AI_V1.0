// lib/features/add_document/add_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gda_vault_ai/core/constants/app_strings.dart';

/// A screen for adding new documents.
class AddDocumentScreen extends StatelessWidget {
  const AddDocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.addDocumentTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text(AppStrings.scanDocumentButton),
                onPressed: () {
                  context.push('/add/scanner');
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text(AppStrings.uploadDocumentButton),
                onPressed: () {
                  context.push(
                    '/add/select-category',
                    extra: {
                      'source': 'upload',
                      'pageCount': 1,
                      'fileName': 'new_upload.pdf',
                      'fileSize': 1024,
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
