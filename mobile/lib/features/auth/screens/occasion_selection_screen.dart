import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../app/providers.dart';
import '../../../shared/models/occassion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/extensions/theme_ext.dart';

class OccasionSelectionScreen extends ConsumerStatefulWidget {
  const OccasionSelectionScreen({super.key});

  @override
  ConsumerState<OccasionSelectionScreen> createState() => _OccasionSelectionScreenState();
}

class _OccasionSelectionScreenState extends ConsumerState<OccasionSelectionScreen> {
  String? _selected;

  static const Map<String, Occasion> _occasionMap = {
    'date': Occasion.date,
    'friends': Occasion.friends,
    'family': Occasion.family,
    'solo': Occasion.solo,
  };

  static const _occasions = [
    _Occasion(
      key: 'date',
      label: 'Date',
      subtitle: 'Romantic spots for two',
      color: AppColors.dateNight,
      icon: Icons.favorite_outline,
    ),
    _Occasion(
      key: 'friends',
      label: 'Hangout with Friends',
      subtitle: 'Fun places to vibe together',
      color: AppColors.friends,
      icon: Icons.people_outline,
    ),
    _Occasion(
      key: 'family',
      label: 'Family Outing',
      subtitle: 'Kid-friendly and relaxed',
      color: AppColors.family,
      icon: Icons.home_outlined,
    ),
    _Occasion(
      key: 'solo',
      label: 'Solo Exploration',
      subtitle: 'Discover at your own pace',
      color: AppColors.solo,
      icon: Icons.person_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.near_me_outlined, color: context.primary, size: 22),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text("What's the occasion?", style: AppTypography.headlineLgMobile),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Pick your vibe and we'll find perfect places.",
                style: AppTypography.bodyLg.copyWith(color: context.onSurfaceVariant),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Occasion list ───────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  itemCount: _occasions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final occ = _occasions[i];
                    final isSelected = _selected == occ.key;
                    return _OccasionCard(
                      occasion: occ,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selected = occ.key),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Continue button ─────────────────────────────────────
              PrimaryButton(
                label: 'CONTINUE',
                onPressed: _selected == null
                    ? null
                    : () {
                        ref.read(selectedOccasionProvider.notifier).state =
                            _occasionMap[_selected!] ?? Occasion.date;
                        ref.read(localStorageProvider).saveFirstInstallFlag(false);
                        context.go(AppRouter.home);
                      },
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _Occasion {
  const _Occasion({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String key;
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
}

class _OccasionCard extends StatelessWidget {
  const _OccasionCard({
    required this.occasion,
    required this.isSelected,
    required this.onTap,
  });

  final _Occasion occasion;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? occasion.color.withValues(alpha: 0.12)
              : context.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isSelected ? occasion.color : context.outlineVariant.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: occasion.color.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: occasion.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(occasion.icon, color: occasion.color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    occasion.label,
                    style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    occasion.subtitle,
                    style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Checkmark
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: occasion.color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
