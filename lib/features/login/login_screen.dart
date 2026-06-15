import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/providers/profile_provider.dart';
import 'package:gda_vault_ai/core/constants/app_colors.dart';
import 'package:gda_vault_ai/core/constants/app_text_styles.dart';
import 'package:gda_vault_ai/widgets/gda_input_field.dart';
import 'package:gda_vault_ai/widgets/gda_primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'admin@gda.gop.pk';
    _passwordController.text = '123456';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(dummyProfileProvider.notifier).state = null;
      }
    });

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));
    _entryController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final email = _emailController.text.replaceAll(' ', '').trim().toLowerCase();
      final isAdmin = email.contains('admin');

      ref.read(dummyProfileProvider.notifier).state = {
        'id': 'dummy-id-123',
        'email': email,
        'name': isAdmin ? 'GDA Admin' : 'GDA Officer',
        'designation': isAdmin ? 'System Administrator' : 'Technical Officer',
        'role': isAdmin ? 'admin' : 'user',
      };

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.lightBgPage, // Always strict enterprise light for auth bg
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            if (isDesktop) {
              return _buildDesktopLayout();
            }
            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _buildLeftSidebar(),
        ),
        Expanded(
          flex: 7,
          child: Container(
            color: AppTokens.lightBgPage,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildFormContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      color: AppTokens.lightBgPage,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  _buildMobileHeader(),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTokens.lightBgSurface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                      border: Border.all(color: AppTokens.lightBorderLight),
                      boxShadow: AppTokens.lightShadowMd,
                    ),
                    child: _buildFormContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      color: AppTokens.lightBgSidebar, // #1C2536
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2A3A52), width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/gda_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.business,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'GDA Vault AI',
            style: AppTextStyles.displayMd.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Enterprise Document Intelligence',
            style: AppTextStyles.bodyLg.copyWith(color: AppTokens.lightTextSidebar),
          ),
          const SizedBox(height: 32),
          Container(
            height: 1,
            width: 200,
            color: const Color(0xFF2A3A52),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Column(
              children: [
                _buildFeatureItem(Icons.search, 'Semantic Search', 'Find documents using natural language.'),
                _buildFeatureItem(Icons.psychology, 'AI Summarization', 'Instantly extract key insights.'),
                _buildFeatureItem(Icons.security, 'Government Grade', 'AES-256 encryption & role-based access.'),
                _buildFeatureItem(Icons.speed, 'High Performance', 'Optimized for large document repositories.'),
              ],
            ),
          ),
          Text(
            '© 2026 Galiyat Development Authority. All rights reserved.',
            style: AppTextStyles.caption.copyWith(color: AppTokens.lightTextSidebar),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Center(
              child: Icon(icon, size: 16, color: const Color(0xFF6B8FBF)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLg.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppTokens.lightTextSidebar)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTokens.lightBorderLight, width: 1),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/gda_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.business,
                size: 32,
                color: AppTokens.lightBrandPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'GDA Vault AI',
          style: AppTextStyles.displaySm.copyWith(color: AppTokens.lightTextPrimary),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome back',
            style: AppTextStyles.displaySm.copyWith(color: AppTokens.lightTextPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to access your enterprise dashboard.',
            style: AppTextStyles.bodyMd.copyWith(color: AppTokens.lightTextSecondary),
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null) _buildErrorBanner(),
          GdaInputField(
            hint: 'Email address',
            controller: _emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          GdaInputField(
            hint: 'Password',
            controller: _passwordController,
            prefixIcon: Icons.lock_outline,
            obscure: true,
            suffixToggle: true,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {},
                child: Text(
                  'Forgot password?',
                  style: AppTextStyles.labelMd.copyWith(color: AppTokens.lightBrandPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          GdaPrimaryButton(
            label: 'Sign In',
            isLoading: _isLoading,
            onTap: _handleLogin,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: AppTextStyles.bodyMd.copyWith(color: AppTokens.lightTextSecondary),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: Text(
                    'Sign Up',
                    style: AppTextStyles.labelLg.copyWith(color: AppTokens.lightBrandPrimary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: const Color(0xFFFECDCA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTokens.lightStatusError, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodySm.copyWith(color: AppTokens.lightStatusError),
            ),
          ),
        ],
      ),
    );
  }
}
