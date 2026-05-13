import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/core/services/chat_history_service.dart';

const double _defaultChatFontSize = 15.0;
const double _minChatFontSize = 12.0;
const double _maxChatFontSize = 25.0;
const _chatFontSizeSettingKey = 'chat_font_size';

final chatFontSizeProvider = NotifierProvider<ChatFontSizeNotifier, double>(
  ChatFontSizeNotifier.new,
);

class ChatFontSizeNotifier extends Notifier<double> {
  @override
  double build() {
    Future.microtask(_loadPersistedFontSize);
    return _defaultChatFontSize;
  }

  Future<void> _loadPersistedFontSize() async {
    final raw = await ChatHistoryService.instance.getAppSetting(
      _chatFontSizeSettingKey,
    );
    final parsed = double.tryParse(raw ?? '');
    if (parsed == null) return;

    state = parsed.clamp(_minChatFontSize, _maxChatFontSize).toDouble();
  }

  Future<void> setChatFontSize(double value) async {
    final normalized = value
        .clamp(_minChatFontSize, _maxChatFontSize)
        .toDouble();
    state = normalized;
    await ChatHistoryService.instance.saveAppSetting(
      _chatFontSizeSettingKey,
      normalized.toStringAsFixed(1),
    );
  }
}
