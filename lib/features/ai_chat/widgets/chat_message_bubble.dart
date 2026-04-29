import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/chat_state.dart';
import 'typing_indicator.dart';
import 'source_citation_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isTyping) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: const TypingIndicator().animate().fadeIn(duration: 300.ms),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.isUser) _buildUserMessage(context) else _buildAiMessage(context, isDark),
        ],
      ).animate().fadeIn(duration: 300.ms).slideY(
            begin: 0.05,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOut,
          ),
    );
  }

  Widget _buildUserMessage(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Time
        Padding(
          padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
          child: Text(
            _formatTime(message.timestamp),
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 9,
              color: AppColors.charcoal.withValues(alpha: 0.35),
            ),
          ),
        ),
        // Bubble
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navyDark, Color(0xFF1A3A6B)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDark.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message.content,
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 13,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiMessage(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF1A3A6B), AppColors.navyDark],
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.gold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI label
              Row(
                children: [
                  Text(
                    "GDA Vault AI",
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkText.withValues(alpha: 0.5) : AppColors.navyDark.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: 9,
                      color: AppColors.charcoal.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Message bubble
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: AppColors.divider, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyDark.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message.content,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 13,
                        color: isDark ? AppColors.darkText : AppColors.charcoal,
                        height: 1.6,
                      ),
                    ),
                    if (message.citations.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withValues(alpha: 0.3) : AppColors.navyDark.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded, size: 13, color: AppColors.gold),
                            const SizedBox(width: 6),
                            Text(
                              "Sources",
                              style: AppTextStyles.dmSans.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoal.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...message.citations.map((citation) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: SourceCitationCard(citation: citation),
                          )),
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
}
