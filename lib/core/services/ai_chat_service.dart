import 'dart:convert';
import 'package:http/http.dart' as http;

class AiChatService {
  // CONFIG - Live n8n Webhook URL
  static const String _n8nChatUrl = 'https://gda-abbottabad.app.n8n.cloud/webhook-test/docvault-final-chat';

  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String sessionId,
    String? categoryId,
    String? subCategoryId,
    String? yearFrom,
    String? yearTo,
  }) async {
    final payload = {
      'message': message,
      'session_id': sessionId,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'year_from': yearFrom,
      'year_to': yearTo,
    }..removeWhere((key, value) => value == null);

    try {
      final response = await http
          .post(
            Uri.parse(_n8nChatUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Chat API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to AI server: $e');
    }
  }
}
