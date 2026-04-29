// lib/features/add_document/scanner_screen.dart
import 'package:flutter/material.dart';

/// A placeholder screen for the document scanner.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: const Text('Scanner')),
        body: const Center(child: Text('Scanner functionality placeholder')),
      ),
    );
  }
}
