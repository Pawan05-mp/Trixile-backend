import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../app/providers.dart';
import '../../../shared/models/place.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../shared/extensions/theme_ext.dart';

class ExploreDiscoveryScreen extends ConsumerStatefulWidget {
  const ExploreDiscoveryScreen({super.key});

  @override
  ConsumerState<ExploreDiscoveryScreen> createState() => _ExploreDiscoveryScreenState();
}

class _ExploreDiscoveryScreenState extends ConsumerState<ExploreDiscoveryScreen> {
  static const _categories = ['All', 'Cafés', 'Dining', 'Nature', 'Culture', 'Nightlife'];
  int _catIndex = 0;

  List<Place> _filtered(List<Place> places) {
    if (_catIndex == 0) return places;
    final cat = _categories[_catIndex].toLowerCase();
    return places.where((p) {
      final haystack = '${p.categoryName ?? ''} ${p.dnaCategory} ${p.tags.join(' ')}'.toLowerCase();
      return haystack.contains(cat.substring(0, cat.length > 4 ? 4 : cat.length));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recommendationsAsync = ref.watch(recommendationsProvider);
    return Scaffold(
      backgroundColor: context.surface,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.near_me, color: context.primary),
            const SizedBox(width: 6),
            Text('Explore', style: AppTypography.headlineLgMobile.copyWith(color: context.primary)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: context.onSurface),
            onPressed: () => context.push(AppRouter.filters),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onTap: (i) => AppRouter.goToTab(context, i),
      ),
      body: ListView(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 12, bottom: 24),
        children: [
          // ── Search bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: context.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: context.outlineVariant.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      'Where would you like to go?',
                      style: AppTypography.bodyLg.copyWith(
                        color: context.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRouter.search),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.tune, color: context.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Category chips ────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemCount: _categories.length,
              itemBuilder: (context, i) => _CategoryChip(
                label: _categories[i],
                isSelected: _catIndex == i,
                onTap: () => setState(() => _catIndex = i),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Nearby + Top rated sections ───────────────────────────
          recommendationsAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: context.primary)),
            ),
            error: (err, st) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile, vertical: 40),
              child: Text(
                'Couldn\'t load places.\n$err',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
              ),
            ),
            data: (allPlaces) {
              final places = _filtered(allPlaces);
              if (places.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile, vertical: 40),
                  child: Text(
                    'No places found for "${_categories[_catIndex]}".',
                    style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
                  ),
                );
              }

              final nearby = [...places]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
              final topRated = [...places]..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nearby', style: AppTypography.sectionHeader),
                        TextButton(
                          onPressed: () => context.push(AppRouter.savedPlaces),
                          child: Text('See all', style: AppTypography.labelMd.copyWith(color: context.primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                      itemCount: nearby.length,
                      itemBuilder: (context, i) => _ExploreCard(
                        place: nearby[i],
                        onTap: () => AppRouter.goToPlace(context, nearby[i]),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                    child: Text('Top Rated in Pondicherry', style: AppTypography.sectionHeader),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...topRated.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.marginMobile,
                          vertical: AppSpacing.xs,
                        ),
                        child: _HorizontalPlaceCard(place: p, onTap: () => AppRouter.goToPlace(context, p)),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.primary : context.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: isSelected ? null : Border.all(color: context.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: isSelected ? context.onPrimary : context.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.place, required this.onTap});
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
          border: Border.all(color: context.outlineVariant.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  place.displayImageUrl != null
                      ? Image.network(place.displayImageUrl!, fit: BoxFit.cover)
                      : Container(color: context.surfaceContainerHigh),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.surfaceContainerHighest.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: context.primary, size: 14),
                          const SizedBox(width: 2),
                          Text(place.starRating.toStringAsFixed(1), style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.sectionHeader),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: context.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text('${place.distanceKm.toStringAsFixed(1)} km away', style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant)),
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

class _HorizontalPlaceCard extends StatelessWidget {
  const _HorizontalPlaceCard({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: context.outlineVariant.withValues(alpha: 0.08)),
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
                    Row(children: [
                      Icon(Icons.location_on_outlined, size: 14, color: context.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text('${place.distanceKm.toStringAsFixed(1)} km away', style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant)),
                    ]),
                  ],
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: AppColors.star, size: 14),
                      const SizedBox(width: 2),
                      Text(place.starRating.toStringAsFixed(1), style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
