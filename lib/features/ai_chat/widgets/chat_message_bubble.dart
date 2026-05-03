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
      child:
          Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (message.isUser)
                    _buildUserMessage(context)
                  else
                    _buildAiMessage(context, isDark),
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

  Widget _buildUserMessage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(
            _formatTime(message.timestamp),
            style: AppTextStyles.dmSans.copyWith(
              fontSize: 9,
              color: AppColors.charcoal.withValues(alpha: 0.3),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navyDark, AppColors.navyMid],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDark.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.navyMid : AppColors.navyDark,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 15,
            color: Colors.white,
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.navyMid : AppColors.navyDark,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/gda_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Colors.white,
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
                padding: const EdgeInsets.only(left: 2, bottom: 6),
                child: Row(
                  children: [
                    Text(
                      "GDA VAULT AI",
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(message.timestamp),
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 9,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppColors.charcoal.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              // Message bubble
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.divider.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message.content,
                      style: AppTextStyles.dmSans.copyWith(
                        fontSize: 14,
                        color: isDark ? AppColors.darkText : AppColors.charcoal,
                        height: 1.6,
                        letterSpacing: 0.1,
                      ),
                    ),
                    if (message.citations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      // Divider
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.divider.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_stories_rounded,
                            size: 14,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "REFERENCED SOURCES",
                            style: AppTextStyles.dmSans.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : AppColors.charcoal.withValues(alpha: 0.4),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...message.citations.map(
                        (citation) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
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
}
