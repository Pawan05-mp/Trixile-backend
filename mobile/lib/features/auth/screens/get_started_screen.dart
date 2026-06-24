import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/extensions/theme_ext.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ───────────────── Hero Section ─────────────────
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: context.surface,
                  ),

                  // Logo
                  Positioned(
                    top: 16,
                    left: AppSpacing.marginMobile,
                    child: Text(
                      'Trixile',
                      style: AppTypography.headlineLgMobile.copyWith(
                        color: context.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  // Center Hero Icon
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            context.primary.withValues(alpha: 0.12),
                        border: Border.all(
                          color: context.primary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.travel_explore_rounded,
                        size: 72,
                        color: context.primary,
                      ),
                    ),
                  ),

                  // Bottom Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.7, 1.0],
                        colors: [
                          Colors.transparent,
                          const Color(0x40121416),
                          context.surface,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ───────────────── Success Banner ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.primary,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.radiusXl,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          context.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration,
                      color: context.onPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Account created successfully!',
                        style:
                            AppTypography.labelMd.copyWith(
                          color: context.onPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      color: context.onPrimary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ───────────────── Welcome Section ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.primary
                          .withValues(alpha: 0.12),
                      border: Border.all(
                        color: context.primary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: context.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WELCOME BACK,',
                        style:
                            AppTypography.caption.copyWith(
                          color:
                              context.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Text(
                        'Alex Rivera',
                        style: AppTypography.titleMd,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ───────────────── Setup Checklist ─────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Set up your travel profile',
                          style: AppTypography.titleMd,
                        ),
                        Text(
                          '1 of 2 done',
                          style:
                              AppTypography.labelMd.copyWith(
                            color: context.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      child: LinearProgressIndicator(
                        value: 0.5,
                        minHeight: 6,
                        backgroundColor:
                            context.surfaceContainerHighest,
                        color: context.primary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    _StepCard(
                      step: 1,
                      label: 'Create your account',
                      isDone: true,
                      isActive: false,
                      onTap: () {},
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    _StepCard(
                      step: 2,
                      label: 'Choose your occasions',
                      isDone: false,
                      isActive: true,
                      onTap: () => context.push(
                        AppRouter.occasionSelection,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.onTap,
  });

  final int step;
  final String label;
  final bool isDone;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? context.primary.withValues(alpha: 0.1)
              : context.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? context.primary : context.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? context.primary : Colors.transparent,
                border: Border.all(color: isDone ? context.primary : context.onSurfaceVariant),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 18, color: Colors.black)
                    : Text('$step', style: AppTypography.labelMd.copyWith(color: context.onSurfaceVariant)),
              ),
            ),
            const SizedBox(width: 14),
            Text(label, style: AppTypography.bodyLg),
          ],
        ),
      ),
    );
  }
}