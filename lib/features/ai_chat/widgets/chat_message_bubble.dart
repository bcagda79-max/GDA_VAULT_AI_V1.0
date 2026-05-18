import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_state.dart';
import '../providers/chat_font_size_provider.dart';
import 'typing_indicator.dart';
import 'source_citation_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatFontSize = ref.watch(chatFontSizeProvider);

    if (message.isTyping) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: const TypingIndicator().animate().fadeIn(duration: 300.ms),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child:
          Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (message.isUser)
                    _buildUserMessage(context, chatFontSize)
                  else
                    _buildAiMessage(context, isDark, chatFontSize),
                ],
              )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(
                begin: 0.05,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOut,
              ),
    );
  }

  Widget _buildUserMessage(BuildContext context, double chatFontSize) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            _formatTime(message.timestamp),
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 10,
              color: (isDark ? Colors.white : AppColors.charcoal).withValues(
                alpha: 0.3,
              ),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2B5876),
                  Color(0xFF4E4376),
                ], // Premium deep blue gradient
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2B5876).withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SelectableText(
              message.content,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: chatFontSize,
                color: Colors.white,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.navyMid, AppColors.navyDark],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAiMessage(
    BuildContext context,
    bool isDark,
    double chatFontSize,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Image.asset(
                'assets/images/gda_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI label + Time
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "GDA VAULT AI",
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatTime(message.timestamp),
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 10,
                        color: (isDark ? Colors.white : AppColors.charcoal)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              // Message content (Clean direct text, no card)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: message.content,
                      selectable: true,
                      shrinkWrap: true,
                      styleSheet: _buildMarkdownStyleSheet(
                        isDark: isDark,
                        chatFontSize: chatFontSize,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _CopyButton(
                        textToCopy: message.content,
                        isDark: isDark,
                      ),
                    ),
                    if (message.citations.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      // Styled Header for Citations
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              size: 14,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "REFERENCED SOURCES",
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color:
                                  (isDark ? Colors.white : AppColors.charcoal)
                                      .withValues(alpha: 0.5),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.divider.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Citations List (Full width)
                      ...message.citations.map(
                        (citation) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: SourceCitationCard(citation: citation),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet({
    required bool isDark,
    required double chatFontSize,
  }) {
    final baseColor = isDark ? AppColors.darkText : AppColors.charcoal;
    final headingBase = chatFontSize + 2;

    return MarkdownStyleSheet(
      p: AppTextStyles.dmSans.copyWith(
        fontSize: chatFontSize,
        color: baseColor,
        height: 1.58,
        letterSpacing: 0.08,
      ),
      strong: AppTextStyles.dmSans.copyWith(
        fontSize: chatFontSize,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.58,
        letterSpacing: 0.08,
      ),
      em: AppTextStyles.dmSans.copyWith(
        fontSize: chatFontSize,
        color: baseColor,
        height: 1.58,
      ),
      code: AppTextStyles.dmSans.copyWith(
        fontSize: chatFontSize - 1,
        color: baseColor,
        height: 1.45,
      ),
      h1: AppTextStyles.playfairDisplay.copyWith(
        fontSize: headingBase + 4,
        fontWeight: FontWeight.w800,
        color: baseColor,
        height: 1.2,
      ),
      h2: AppTextStyles.playfairDisplay.copyWith(
        fontSize: headingBase + 2,
        fontWeight: FontWeight.w800,
        color: baseColor,
        height: 1.25,
      ),
      h3: AppTextStyles.dmSans.copyWith(
        fontSize: headingBase + 1,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.3,
      ),
      h4: AppTextStyles.dmSans.copyWith(
        fontSize: headingBase,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.3,
      ),
      h5: AppTextStyles.dmSans.copyWith(
        fontSize: chatFontSize,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.3,
      ),
      h6: AppTextStyles.dmSans.copyWith(
        fontSize: chatFontSize,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.3,
      ),
      tableHead: AppTextStyles.dmSans.copyWith(
        fontSize: chatFontSize - 2,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppColors.navyDark,
        height: 1.3,
      ),
      tableBody: AppTextStyles.dmSans.copyWith(
        fontSize: chatFontSize - 2,
        color: baseColor,
        height: 1.38,
      ),
      tableBorder: TableBorder.all(
        color: AppColors.gold.withValues(alpha: 0.32),
        width: 0.5,
      ),
      tableColumnWidth: const IntrinsicColumnWidth(),
      tableScrollbarThumbVisibility: true,
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
    );
  }
}

enum _CopyState { idle, loading, copied }

class _CopyButton extends StatefulWidget {
  final String textToCopy;
  final bool isDark;

  const _CopyButton({required this.textToCopy, required this.isDark});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  _CopyState _state = _CopyState.idle;

  Future<void> _handleCopy() async {
    if (_state != _CopyState.idle) return;

    setState(() => _state = _CopyState.loading);

    await Clipboard.setData(ClipboardData(text: widget.textToCopy));

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() => _state = _CopyState.copied);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _state = _CopyState.idle);
  }

  @override
  Widget build(BuildContext context) {
    final color = (widget.isDark ? Colors.white : AppColors.charcoal)
        .withValues(alpha: 0.5);

    return InkWell(
      onTap: _handleCopy,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: _state == _CopyState.loading
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    )
                  : Icon(
                      _state == _CopyState.copied
                          ? Icons.check_rounded
                          : Icons.copy_rounded,
                      size: 14,
                      color: color,
                    ),
            ),
            const SizedBox(width: 6),
            Text(
              _state == _CopyState.copied ? "Copied" : "Copy",
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
