import 'dart:convert';
import 'package:http/http.dart' as http;

class AiChatService {
  // CONFIG - Live n8n Webhook URL
  static const String _n8nChatUrl =
      'https://bcagda.app.n8n.cloud/webhook/docvault-final-chat';

  // Session local cache for repeating the same question
  static final Map<String, Map<String, dynamic>> _sessionCache = {};

  static String _cacheKey(String message, String? categoryId, String? subCategoryId, String? yearFrom, String? yearTo) {
    return '${message.toLowerCase().trim()}_${categoryId}_${subCategoryId}_${yearFrom}_${yearTo}';
  }

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

    final key = _cacheKey(message, categoryId, subCategoryId, yearFrom, yearTo);
    if (_sessionCache.containsKey(key)) {
      final cachedResponse = Map<String, dynamic>.from(_sessionCache[key]!);
      cachedResponse['from_cache'] = true;
      return cachedResponse;
    }

    try {
      final response = await http
          .post(
            Uri.parse(_n8nChatUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        _sessionCache[key] = result;
        return result;
      } else {
        throw Exception('Chat API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to AI server: $e');
    }
  }
}
