import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/place.dart';
import '../../../shared/models/occassion.dart';
import '../../../shared/widgets/occasion_pill.dart';
import '../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/extensions/theme_ext.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  static const _occasionColors = {
    Occasion.date: AppColors.dateNight,
    Occasion.friends: AppColors.friends,
    Occasion.family: AppColors.family,
    Occasion.solo: AppColors.solo,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOccasion = ref.watch(selectedOccasionProvider);
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final recent = ref.watch(recentRecommendationsProvider);

    return Scaffold(
      backgroundColor: context.surface,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore, color: context.primary),
            const SizedBox(width: 6),
            Text('Pondicherry', style: AppTypography.titleLg.copyWith(color: context.primary)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: context.primary),
            onPressed: () => context.push(AppRouter.notifications),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (i) => AppRouter.goToTab(context, i),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(recommendationsProvider),
        child: ListView(
          padding: const EdgeInsets.only(top: 80, bottom: 24),
          children: [
            // ── Search bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
              child: TextField(
                style: AppTypography.bodyLg,
                decoration: InputDecoration(
                  hintText: 'Search places...',
                  hintStyle: AppTypography.bodyLg.copyWith(color: context.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search, color: context.onSurfaceVariant, size: 20),
                  filled: true,
                  fillColor: context.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    borderSide: BorderSide(color: context.outlineVariant.withValues(alpha: 0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    borderSide: BorderSide(color: context.outlineVariant.withValues(alpha: 0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    borderSide: BorderSide(color: context.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Mood/Occasion pills ───────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemCount: Occasion.values.length,
                itemBuilder: (context, i) {
                  final occasion = Occasion.values[i];
                  return OccasionPill(
                    label: occasion.displayName,
                    color: _occasionColors[occasion]!,
                    isSelected: selectedOccasion == occasion,
                    onTap: () => ref.read(selectedOccasionProvider.notifier).state = occasion,
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Recommended section ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recommended for You', style: AppTypography.sectionHeader),
                  TextButton(
                    onPressed: () => context.push(AppRouter.explore),
                    child: Text(
                      'View all',
                      style: AppTypography.labelMd.copyWith(color: context.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            SizedBox(
              height: 300,
              child: recommendationsAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: context.primary)),
                error: (err, st) => Center(
                  child: Text(
                    'Couldn\'t load recommendations.\n$err',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
                  ),
                ),
                data: (places) {
                  if (places.isEmpty) {
                    return Center(
                      child: Text(
                        'No recommendations yet for ${selectedOccasion.displayName}.',
                        style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                    itemCount: places.length,
                    itemBuilder: (context, i) => _PlaceCard(
                      place: places[i],
                      onTap: () => AppRouter.goToPlace(context, places[i]),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Recently viewed section ─────────────────────────────────
            if (recent.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recently Viewed', style: AppTypography.sectionHeader),
                    TextButton(
                      onPressed: () => context.push(AppRouter.savedPlaces),
                      child: Text(
                        'See all',
                        style: AppTypography.labelMd.copyWith(color: context.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...recent.take(5).map((p) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile,
                      vertical: AppSpacing.xs,
                    ),
                    child: _NearbyCard(
                      place: p,
                      onTap: () => AppRouter.goToPlace(context, p),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: context.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: const Color(0x0DFFFFFF)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 176,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  place.displayImageUrl != null
                      ? Image.network(place.displayImageUrl!, fit: BoxFit.cover)
                      : Container(color: context.surfaceContainerHigh),
                  // Rating badge
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: AppColors.star, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            place.starRating.toStringAsFixed(1),
                            style: AppTypography.labelSm.copyWith(color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tag
                  Positioned(
                    bottom: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        place.categoryName ?? place.dnaCategory,
                        style: AppTypography.labelSm.copyWith(
                          color: context.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: AppTypography.titleMd),
                  const SizedBox(height: 4),
                  Text(
                    place.description,
                    style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(color: Color(0x0DFFFFFF)),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: context.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            '${place.distanceKm.toStringAsFixed(1)} km',
                            style: AppTypography.labelSm.copyWith(color: context.onSurfaceVariant),
                          ),
                        ],
                      ),
                      Text(
                        place.budgetIndicator,
                        style: AppTypography.labelMd.copyWith(
                          color: context.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: const Color(0x0DFFFFFF)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: place.displayImageUrl != null
                  ? Image.network(place.displayImageUrl!, fit: BoxFit.cover)
                  : Container(color: context.surfaceContainerHigh),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: AppTypography.titleMd),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: context.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          '${place.distanceKm.toStringAsFixed(1)} km',
                          style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.star),
                        const SizedBox(width: 2),
                        Text(place.starRating.toStringAsFixed(1), style: AppTypography.labelSm),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Icon(Icons.chevron_right, color: context.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
