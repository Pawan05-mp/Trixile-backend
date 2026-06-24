import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/place.dart';
import '../../../app/providers.dart';
import '../../../shared/utils/navigation_launcher.dart';
import '../../../shared/extensions/theme_ext.dart';

class PlacePeekScreen extends ConsumerStatefulWidget {
  const PlacePeekScreen({super.key, required this.place});

  final Place place;

  @override
  ConsumerState<PlacePeekScreen> createState() => _PlacePeekScreenState();
}

class _PlacePeekScreenState extends ConsumerState<PlacePeekScreen> {
  late bool _isFavorited;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(localStorageProvider);
    _isFavorited = storage.isFavorite(widget.place.id);
    storage.addRecentRecommendation(widget.place.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: Stack(
        children: [
          // ── Top half – hero image ─────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.place.displayImageUrl != null
                    ? Image.network(widget.place.displayImageUrl!, fit: BoxFit.cover)
                    : Container(color: context.surfaceContainer),
                // Scrim
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.9, 1.0],
                      colors: [Colors.transparent, Colors.transparent, context.surface],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Overlay controls ──────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: AppSpacing.marginMobile,
            right: AppSpacing.marginMobile,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GlassCircleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                _GlassCircleButton(
                  icon: _isFavorited ? Icons.favorite : Icons.favorite_border,
                  iconColor: _isFavorited ? AppColors.dateNight : AppColors.white,
                  onTap: () async {
                    final goingToFavorite = !_isFavorited;
                    setState(() => _isFavorited = goingToFavorite);

                    // Keep a local cache so Saved Places still has
                    // something to show offline.
                    await ref.read(localStorageProvider).toggleFavorite(
                          widget.place.id,
                          widget.place.toJson(),
                        );

                    try {
                      final favoritesService = ref.read(favoritesServiceProvider);
                      if (goingToFavorite) {
                        await favoritesService.add(widget.place.id);
                      } else {
                        await favoritesService.remove(widget.place.id);
                      }
                      ref.invalidate(savedPlacesProvider);
                    } catch (_) {
                      // Backend unreachable / not signed in — local
                      // cache above still reflects the change.
                    }
                  },
                ),
              ],
            ),
          ),

          // ── Bottom content sheet ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.42,
            child: Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Name & rating row ─────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.place.name,
                                style: AppTypography.headlineLgMobile.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: context.primary, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.place.area,
                                    style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: AppColors.star, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                widget.place.starRating.toStringAsFixed(1),
                                style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Meta badges ────────────────────────────────
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        _MetaBadge(
                          icon: Icons.auto_awesome,
                          label: '${(widget.place.score * 100).clamp(0, 100).toStringAsFixed(0)}% Match',
                          color: context.primary,
                        ),
                        _TextBadge(
                          label: '${widget.place.budgetIndicator} · ${widget.place.categoryName ?? widget.place.dnaCategory}',
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Get Directions
                    GestureDetector(
                      onTap: () => openInGoogleMaps(context, widget.place),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions, color: context.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Get Directions',
                              style: AppTypography.labelMd.copyWith(
                                color: context.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Bento info grid ────────────────────────────
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.6,
                      children: [
                        _InfoTile(
                          icon: Icons.straighten,
                          label: 'Distance',
                          value: '${widget.place.distanceKm.toStringAsFixed(1)} km away',
                        ),
                        _InfoTile(
                          icon: Icons.people_outline,
                          label: 'Best For',
                          value: widget.place.occasion?.displayName ?? 'Anyone',
                        ),
                        _InfoTile(
                          icon: widget.place.indoor ? Icons.home_outlined : Icons.park_outlined,
                          label: 'Setting',
                          value: widget.place.indoor ? 'Indoor' : 'Outdoor',
                        ),
                        _InfoTile(
                          icon: Icons.local_offer_outlined,
                          label: 'Tags',
                          value: widget.place.tags.isNotEmpty ? widget.place.tags.take(2).join(', ') : '—',
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── About ──────────────────────────────────────
                    const Text('About', style: AppTypography.sectionHeader),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.place.description.isNotEmpty
                          ? widget.place.description
                          : 'No description available yet for this place.',
                      style: AppTypography.bodyLg.copyWith(
                        color: context.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    if (widget.place.reasons.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const Text('Why we picked this', style: AppTypography.sectionHeader),
                      const SizedBox(height: AppSpacing.sm),
                      ...widget.place.reasons.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle, size: 16, color: context.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  r,
                                  style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap, this.iconColor = AppColors.white});
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            color: Colors.black.withValues(alpha: 0.4),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelSm.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TextBadge extends StatelessWidget {
  const _TextBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        style: AppTypography.bodyMd.copyWith(
          color: context.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: context.primary, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
