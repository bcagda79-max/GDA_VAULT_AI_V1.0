import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  final replacements = {
    '0xFF161B27': '0xFF141414',
    '0xFF1E2535': '0xFF1C1C1C',
    '0xFF0D1117': '0xFF0A0A0A',
    '0xFF0D1B2E': '0xFF0A0A0A',
    '0xFF21293A': '0xFF272727',
    '0xFF2D3748': '0xFF333333',
    '0xFF1A2236': '0xFF111111',
    '0xFF243044': '0xFF111111',
    // '0xFF1B2E4B': '...', // Except in AppBar/Banner only. We will handle 1B2E4B manually if needed.
  };

  for (final file in files) {
    if (file.path.contains('app_colors.dart')) continue; // already updated
    if (file.path.contains('auth_colors.dart')) continue; // already updated

    String content = file.readAsStringSync();
    bool changed = false;

    for (final entry in replacements.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        changed = true;
      }
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated: ${file.path}');
    }
  }
}
