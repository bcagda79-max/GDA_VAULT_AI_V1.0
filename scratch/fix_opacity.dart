
import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('Directory lib not found');
    return;
  }
  dir.listSync(recursive: true).forEach((file) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = file.readAsStringSync();
        final newContent = content.replaceAllMapped(
          RegExp(r'\.withOpacity\((.*?)\)'),
          (match) => '.withValues(alpha: ${match.group(1)})',
        );
        if (content != newContent) {
          file.writeAsStringSync(newContent);
          print('Updated: ${file.path}');
        }
      } catch (e) {
        print('Error processing ${file.path}: $e');
      }
    }
  });
}
