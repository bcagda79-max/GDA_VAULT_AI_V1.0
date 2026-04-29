// lib/features/add_document/scan_review_screen.dart
import 'package:flutter/material.dart';

class ScanReviewScreen extends StatelessWidget {
  final int pageCount;
  final String source;

  const ScanReviewScreen({
    super.key,
    required this.pageCount,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: const Text('Review Scan')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Reviewing $pageCount pages from $source'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
