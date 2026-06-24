import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import '../../../app/router/app_router.dart';
import '../../../app/providers.dart';
import '../../../app/constants/app_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/extensions/theme_ext.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

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

  Future<void> _continueWithFacebook() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : AppConstants.supabaseRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start Facebook sign-in: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              // ── Back button ─────────────────────────────────────────
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: context.primary),
                padding: EdgeInsets.zero,
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Header ─────────────────────────────────────────────
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: context.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'NEW ERA OF EXPLORATION',
                  style: AppTypography.labelMd.copyWith(
                    color: context.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RichText(
                text: TextSpan(
                  style: AppTypography.headlineLgMobile,
                  children: [
                    const TextSpan(text: 'Join '),
                    TextSpan(
                      text: 'Trixile',
                      style: AppTypography.headlineLgMobile.copyWith(
                        color: context.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Start your journey of discovery.',
                style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Social signup ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _SocialChip(
                      label: 'Google',
                      icon: Icons.g_mobiledata,
                      onTap: _continueWithGoogle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: context.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'OR CONTINUE WITH EMAIL',
                      style: AppTypography.labelMd.copyWith(
                        color: context.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: context.outlineVariant)),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Form ────────────────────────────────────────────────
              _FormField(label: 'FULL NAME', child: TextField(
                controller: _nameController,
                style: AppTypography.bodyLg,
                decoration: const InputDecoration(hintText: 'Your full name'),
              )),
              const SizedBox(height: AppSpacing.md),

              _FormField(label: 'EMAIL', child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.bodyLg,
                decoration: const InputDecoration(hintText: 'email@example.com'),
              )),
              const SizedBox(height: AppSpacing.md),

              _FormField(label: 'PASSWORD', child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppTypography.bodyLg,
                decoration: InputDecoration(
                  hintText: 'Create a password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: context.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              )),

              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: 'CREATE ACCOUNT',
                isLoading: _isLoading,
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final email = _emailController.text.trim();
                  final password = _passwordController.text;
                  if (name.isEmpty || email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all fields.')),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);
                  try {
                    final authService = ref.read(authServiceProvider);
                    await authService.register(name: name, email: email, password: password);
                    final token = await authService.login(email: email, password: password);

                    ref.read(apiClientProvider).setAuthToken(token);
                    await ref.read(secureStorageProvider).saveAuthToken(token);
                    ref.read(isAuthenticatedProvider.notifier).state = true;

                    final storage = ref.read(localStorageProvider);
                    await storage.saveUserName(name);
                    await storage.saveUserEmail(email);

                    if (!mounted) return;
                    context.go(AppRouter.getStarted);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not create account: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => context.push(AppRouter.signIn),
                          child: Text(
                            'Sign in.',
                            style: AppTypography.bodyMd.copyWith(
                              color: context.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: context.onSurfaceVariant,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: context.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: context.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.labelMd),
          ],
        ),
      ),
    );
  }
}
