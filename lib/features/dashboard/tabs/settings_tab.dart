// lib/features/dashboard/tabs/settings_tab.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/features/ai_chat/providers/chat_provider.dart';
import 'package:gda_vault_ai/features/ai_chat/providers/chat_font_size_provider.dart';
import 'package:gda_vault_ai/features/ai_chat/models/chat_state.dart';
import 'package:gda_vault_ai/features/ai_chat/widgets/default_category_selector_sheet.dart';
import 'package:gda_vault_ai/providers/theme_provider.dart';
import 'package:gda_vault_ai/features/dashboard/providers/dashboard_stats_provider.dart';
import 'package:gda_vault_ai/core/utils/responsive_app_bar.dart';

/// The settings tab, allowing user to configure the app.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(
      themeProvider.select((mode) => mode == ThemeMode.dark),
    );
    final statsAsync = ref.watch(dashboardStatsProvider);
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.paper,
      body: Column(
        children: [
          _buildSectionHeader(context, isDark),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      statsAsync.when(
                        data: (stats) => _buildStorageCard(isDark, stats),
                        loading: () =>
                            _buildStorageCard(isDark, null, isLoading: true),
                        error: (_, _) => _buildStorageCard(isDark, null),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Text(
                          'Preferences',
                          style: AppTextStyles.dmSans.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: (isDark ? Colors.white : AppColors.navyDark)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      _buildSettingsList(context, ref, isDark, chatState),
                      const SizedBox(height: 40),
                      _buildFooter(isDark),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, bool isDark) {
    final isDesktop = ResponsiveAppBar.isDesktop(context);
    return Container(
      width: double.infinity,
      padding: isDesktop
          ? ResponsiveAppBar.desktopPadding
          : const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF161E35), const Color(0xFF0A0F1E)]
              : [AppColors.navyDark, AppColors.navyMid],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: isDesktop
              ? ResponsiveAppBar.desktopPadding
              : const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Setting",
                        style: AppTextStyles.playfairDisplay.copyWith(
                          fontSize: isDesktop ? 20 : 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: isDesktop ? 0.8 : 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStorageCard(
    bool isDark,
    Map<String, dynamic>? stats, {
    bool isLoading = false,
  }) {
    final double totalSizeGb =
        (stats?['total_size_gb'] as num?)?.toDouble() ?? 0.0;
    const double maxStorageGb = 100.0;
    final double percentage = (totalSizeGb / maxStorageGb).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: isDark ? 0.2 : 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: isDark ? 0.05 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_done_rounded,
                color: AppColors.gold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "GDA Cloud Storage",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                isLoading ? "..." : "${totalSizeGb.toStringAsFixed(1)} GB",
                style: AppTextStyles.dmSans.copyWith(
                  // Simplified font
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.gold : AppColors.navyDark,
                ),
              ),
              Text(
                " / ${maxStorageGb.toInt()} GB used",
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 12,
                  color: (isDark ? Colors.white : AppColors.navyDark)
                      .withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLoading
                      ? "..."
                      : "${(percentage * 100).toStringAsFixed(0)}%",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: isLoading ? null : percentage,
              backgroundColor: isDark
                  ? AppColors.darkBg
                  : AppColors.slate.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
  }

  Widget _buildSettingsList(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    ChatState chatState,
  ) {
    final defaultCategoryNames = chatState.categories
        .where(
          (cat) =>
              cat.parentId == null &&
              chatState.defaultCategoryIds.contains(cat.id),
        )
        .map((cat) => cat.name)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.text_fields_rounded,
            iconBgColor: AppColors.gold.withValues(alpha: 0.1),
            iconColor: AppColors.gold,
            title: "Chat Font Size",
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${ref.watch(chatFontSizeProvider).toStringAsFixed(1)} px',
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              ],
            ),
            onTap: () => _showChatFontSizeDialog(context, ref, isDark),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.dark_mode_outlined,
            iconBgColor: AppColors.gold.withValues(alpha: 0.1),
            iconColor: AppColors.gold,
            title: "Dark Mode Appearance",
            trailing: CupertinoSwitch(
              value: isDark,
              onChanged: (value) =>
                  ref.read(themeProvider.notifier).toggleTheme(),
              activeTrackColor: AppColors.gold,
            ),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.auto_awesome_rounded,
            iconBgColor: AppColors.navyLight.withValues(alpha: 0.1),
            iconColor: AppColors.navyLight,
            title: "Default Chat Categories",
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  defaultCategoryNames.isEmpty
                      ? "Configure"
                      : defaultCategoryNames.join(', '),
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyLight,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              ],
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => DraggableScrollableSheet(
                  initialChildSize: 0.75,
                  minChildSize: 0.5,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (_, scrollController) =>
                      const DefaultCategorySelectorSheet(),
                ),
              );
            },
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.translate_rounded,
            iconBgColor: AppColors.catAdmin.withValues(alpha: 0.1),
            iconColor: AppColors.catAdmin,
            title: "Language preference",
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "English",
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              ],
            ),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.help_outline_rounded,
            iconBgColor: isDark ? AppColors.darkSurface : AppColors.paper,
            iconColor: (isDark ? Colors.white : AppColors.navyDark).withValues(
              alpha: 0.6,
            ),
            title: "Help & Documentation",
            trailing: const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 18,
            ),
            onTap: () => _showAboutDialog(context, isDark),
          ),
          _SettingsListItem(
            isDark: isDark,
            icon: Icons.delete_sweep_rounded,
            iconBgColor: AppColors.catPrivate.withValues(alpha: 0.1),
            iconColor: AppColors.catPrivate,
            title: "Delete All Chats",
            trailing: const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 18,
            ),
            hasDivider: false,
            onTap: () => _showDeleteAllChatsDialog(context, ref),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  void _showChatFontSizeDialog(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (_) => ChatFontSizeDialog(
        initialSize: ref.read(chatFontSizeProvider),
        isDark: isDark,
        onSave: (size) =>
            ref.read(chatFontSizeProvider.notifier).setChatFontSize(size),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Text(
          "GDA Vault AI",
          style: AppTextStyles.dmSans.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: (isDark ? Colors.white : AppColors.navyDark).withValues(
              alpha: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Galiyat Development Authority · Abbottabad",
          style: AppTextStyles.dmSans.copyWith(
            fontSize: 10,
            color: (isDark ? Colors.white : AppColors.navyDark).withValues(
              alpha: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/gda_logo.png', width: 80, height: 80),
              const SizedBox(height: 20),
              Text(
                "GDA Vault AI",
                style: AppTextStyles.playfairDisplay.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "GDA Vault AI is an intelligent, secure document management system designed exclusively for the Galiyat Development Authority. It provides seamless categorization, local caching, and AI-powered insights for instant access to critical departmental archives.",
                textAlign: TextAlign.center,
                style: AppTextStyles.dmSans.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: (isDark ? Colors.white : AppColors.charcoal)
                      .withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "Close",
                    style: AppTextStyles.dmSans.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAllChatsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Delete all chats?",
            style: AppTextStyles.playfairDisplay.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "This will permanently remove every locally saved chat session and message from this device.",
            style: AppTextStyles.dmSans.copyWith(fontSize: 14),
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                "Delete All",
                style: TextStyle(
                  color: AppColors.catPrivate,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(chatProvider.notifier).deleteAllChats();
              },
            ),
          ],
        );
      },
    );
  }
}

class _SettingsListItem extends StatelessWidget {
  const _SettingsListItem({
    required this.isDark,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
    this.hasDivider = true,
  });

  final bool isDark;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: hasDivider
                ? Border(
                    bottom: BorderSide(
                      color: AppColors.divider.withValues(
                        alpha: isDark ? 0.05 : 0.1,
                      ),
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.dmSans.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.navyDark,
                  ),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatFontSizeDialog extends StatefulWidget {
  final double initialSize;
  final bool isDark;
  final Future<void> Function(double size) onSave;

  const ChatFontSizeDialog({
    super.key,
    required this.initialSize,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<ChatFontSizeDialog> createState() => _ChatFontSizeDialogState();
}

class _ChatFontSizeDialogState extends State<ChatFontSizeDialog> {
  late double _tempSize;

  @override
  void initState() {
    super.initState();
    _tempSize = widget.initialSize.clamp(12.0, 25.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.text_fields_rounded,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Chat Font Size',
              textAlign: TextAlign.center,
              style: AppTextStyles.playfairDisplay.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adjust how AI responses and your chat messages look.',
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans.copyWith(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? Colors.white70
                    : AppColors.charcoal.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.paper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.divider,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Sample AI chat text preview',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.dmSans.copyWith(
                      fontSize: _tempSize,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.charcoal,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '12 px',
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : AppColors.charcoal.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        '${_tempSize.toStringAsFixed(1)} px',
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                      Text(
                        '25 px',
                        style: AppTextStyles.dmSans.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : AppColors.charcoal.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.gold,
                      inactiveTrackColor: AppColors.gold.withValues(
                        alpha: 0.15,
                      ),
                      thumbColor: AppColors.gold,
                      overlayColor: AppColors.gold.withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _tempSize,
                      min: 12,
                      max: 25,
                      divisions: 26,
                      onChanged: (value) {
                        setState(() => _tempSize = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.white70
                          : AppColors.navyDark,
                      side: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await widget.onSave(_tempSize);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
