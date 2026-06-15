import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/widgets/gda_user_avatar.dart';

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int currentIndex;
  final bool isDesktop;
  final double leftInset;

  const HomeAppBar({
    super.key,
    required this.currentIndex,
    this.leftInset = 0,
    this.isDesktop = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTopBar = isDark ? AppTokens.darkBgSurface : AppTokens.lightBgSurface;
    final borderLight = isDark ? const Color(0xFF272727) : AppTokens.lightBorderLight;
    final textPrimary = isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary;

    if (isDesktop) {
      return AppBar(
        backgroundColor: bgTopBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: leftInset,
        leading: const SizedBox.shrink(),
        title: Text(
          'DASHBOARD',
          style: AppTextStyles.labelSm.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 2.0,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 24.0),
            child: GdaUserAvatar(initials: 'GA', size: 34),
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: bgTopBar,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: borderLight, width: 1)),
      leading: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset(
          'assets/images/gda_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.business,
            size: 20,
            color: textPrimary,
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DASHBOARD',
            style: AppTextStyles.labelSm.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              letterSpacing: 2.0,
            ),
          ),
          Text(
            'GDA Vault Intelligence',
            style: AppTextStyles.labelSm.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF8899B0) : AppTokens.lightTextSecondary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: GdaUserAvatar(initials: 'GA', size: 32, fontSize: 12),
        ),
      ],
    );
  }
}
