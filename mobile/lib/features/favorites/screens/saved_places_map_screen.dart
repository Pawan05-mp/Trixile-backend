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

class SavedPlacesMapScreen extends ConsumerStatefulWidget {
  const SavedPlacesMapScreen({super.key});

  @override
  ConsumerState<SavedPlacesMapScreen> createState() => _SavedPlacesMapScreenState();
}

class _SavedPlacesMapScreenState extends ConsumerState<SavedPlacesMapScreen> {
  Future<void> _removeFavorite(Place place) async {
    await ref.read(localStorageProvider).removeFavorite(place.id);
    try {
      await ref.read(favoritesServiceProvider).remove(place.id);
    } catch (_) {
      // Backend unreachable — local cache above still updated.
    }
    ref.invalidate(savedPlacesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(savedPlacesProvider);
    final favorites = favoritesAsync.valueOrNull ?? const <Place>[];
    return Scaffold(
      backgroundColor: context.surface,
      appBar: GlassAppBar(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore, color: context.primary),
            const SizedBox(width: 6),
            Text(
              'Trixile',
              style: AppTypography.headlineMd.copyWith(
                color: context.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: context.onSurfaceVariant),
            onPressed: () => context.push(AppRouter.notifications),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (i) => AppRouter.goToTab(context, i),
      ),
      body: Column(
        children: [
          // ── Map placeholder (top half) ────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Map image placeholder
                Positioned.fill(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800',
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.5),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),

                // Custom map markers (first few favorites)
                ...List.generate(
                  favorites.length > 3 ? 3 : favorites.length,
                  (i) {
                    const positions = [
                      {'top': 80.0, 'left': 120.0},
                      {'bottom': 100.0, 'right': 80.0},
                      {'top': 140.0, 'right': 140.0},
                    ];
                    final pos = positions[i];
                    return Positioned(
                      top: pos['top'],
                      left: pos['left'],
                      bottom: pos['bottom'],
                      right: pos['right'],
                      child: _MapMarker(name: favorites[i].name),
                    );
                  },
                ),

                // Map zoom controls
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _MapControlBtn(icon: Icons.add, onTap: () {}),
                      const SizedBox(height: 8),
                      _MapControlBtn(icon: Icons.remove, onTap: () {}),
                      const SizedBox(height: 8),
                      _MapControlBtn(
                        icon: Icons.my_location,
                        onTap: () {},
                        color: context.primary,
                        iconColor: context.onPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Saved places list (bottom half) ──────────────────────
          Expanded(
            flex: 6,
            child: Container(
              color: context.surfaceContainerLowest,
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saved Places', style: AppTypography.headlineMd),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sort, color: context.primary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Filter',
                                style: AppTypography.labelMd.copyWith(color: context.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Place cards list
                  Expanded(
                    child: favoritesAsync.isLoading
                        ? Center(child: CircularProgressIndicator(color: context.primary))
                        : favorites.isEmpty
                        ? Center(
                            child: Text(
                              'No saved places yet.\nTap the heart on a place to save it here.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
                            ),
                          )
                        : ListView.separated(
                            itemCount: favorites.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, i) => _SavedPlaceCard(
                              place: favorites[i],
                              onTap: () => AppRouter.goToPlace(context, favorites[i]),
                              onRemove: () => _removeFavorite(favorites[i]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
          ),
          child: Text(
            name,
            style: AppTypography.labelSm.copyWith(
              color: context.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(Icons.location_on, color: context.primary, size: 28),
      ],
    );
  }
}

class _MapControlBtn extends StatelessWidget {
  const _MapControlBtn({
    required this.icon,
    required this.onTap,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color ?? context.surfaceContainerHigh.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
        ),
        child: Icon(icon, color: iconColor ?? context.onSurface, size: 18),
      ),
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  const _SavedPlaceCard({required this.place, required this.onTap, required this.onRemove});
  final Place place;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: context.outlineVariant.withValues(alpha: 0.12)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            SizedBox(
              width: 100,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(place.categoryName ?? place.dnaCategory, style: AppTypography.labelSm),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.location_on_outlined, size: 12, color: context.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text('${place.distanceKm.toStringAsFixed(1)} km', style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.star),
                        const SizedBox(width: 2),
                        Text(place.starRating.toStringAsFixed(1), style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.favorite, color: AppColors.dateNight, size: 20),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Icon(Icons.chevron_right, color: context.onSurfaceVariant, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}