import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import '../../../app/router/app_router.dart';
import '../../../app/providers.dart';
import '../../../app/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/extensions/theme_ext.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await ref.read(authServiceProvider).login(
            email: email,
            password: password,
          );
      ref.read(apiClientProvider).setAuthToken(token);
      await ref.read(secureStorageProvider).saveAuthToken(token);
      await ref.read(localStorageProvider).saveUserEmail(email);
      ref.read(isAuthenticatedProvider.notifier).state = true;

      if (mounted) {
        context.go(AppRouter.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Both of these just *launch* the OAuth flow (a browser tab opens for
  // the user to approve). Completion happens asynchronously when the
  // provider redirects back into the app — handled once, app-wide, by
  // the Supabase auth-state listener in main.dart, which exchanges the
  // resulting Supabase session for our backend token and navigates on.
  Future<void> _continueWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : AppConstants.supabaseRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start Google sign-in: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              const Text('Welcome back', style: AppTypography.headlineLgMobile),
              const SizedBox(height: AppSpacing.xs),
              RichText(
                text: TextSpan(
                  style: AppTypography.bodyLg.copyWith(color: context.onSurfaceVariant),
                  children: [
                    const TextSpan(text: 'Enter your phone number or email to sign in, or '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => context.push(AppRouter.createAccount),
                        child: Text(
                          'Create new account.',
                          style: AppTypography.bodyLg.copyWith(
                            color: context.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Email field ─────────────────────────────────────────
              const _FieldLabel(label: 'EMAIL ADDRESS'),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.bodyLg,
                decoration: const InputDecoration(
                  hintText: 'email@example.com',
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Password field ──────────────────────────────────────
              const _FieldLabel(label: 'PASSWORD'),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppTypography.bodyLg,
                decoration: InputDecoration(
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: context.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Forgot password
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'FORGOT PASSWORD?',
                    style: AppTypography.labelMd.copyWith(
                      color: context.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Sign in button ──────────────────────────────────────
              PrimaryButton(
                label: 'SIGN IN',
                onPressed: _signIn,
                isLoading: _isLoading,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: context.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'OR',
                      style: AppTypography.labelMd.copyWith(color: context.onSurfaceVariant),
                    ),
                  ),
                  Expanded(child: Divider(color: context.outlineVariant)),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Social buttons ──────────────────────────────────────
              const SizedBox(height: AppSpacing.sm),
              _SocialButton(
                color: AppColors.white,
                textColor: const Color(0xFF1F1F1F),
                label: 'CONNECT WITH GOOGLE',
                googleLogo: true,
                onTap: _continueWithGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelMd.copyWith(
        color: context.onSurfaceVariant,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.color,
    required this.label,
    required this.onTap,
    this.googleLogo = false,
    this.textColor = AppColors.white,
  }) : icon = null;

  final Color color;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool googleLogo;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (googleLogo)
              const _GoogleLogo()
            else if (icon != null)
              Icon(icon, color: textColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final segments = [
      (const Color(0xFF4285F4), 0.0, 90.0),
      (const Color(0xFF34A853), 90.0, 180.0),
      (const Color(0xFFFBBC05), 180.0, 270.0),
      (const Color(0xFFEA4335), 270.0, 360.0),
    ];

    for (final (color, startDeg, endDeg) in segments) {
      final paint = Paint()..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startDeg * 3.14159 / 180,
        (endDeg - startDeg) * 3.14159 / 180,
        true,
        paint,
      );
    }

    // White center
    canvas.drawCircle(center, radius * 0.6, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
