import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../app/router/app_router.dart';
import '../../../app/providers.dart';
import '../../../shared/models/place.dart';
import '../../../shared/models/map_place.dart';
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
  static const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _userAgent = 'com.trixile.app';
  static const _defaultCenter = LatLng(11.9416, 79.8083);

  final MapController _mapController = MapController();
  String? _selectedPlaceId;
  double _currentZoom = 14;
  bool _mapInitialized = false;

  @override
  void didUpdateWidget(covariant SavedPlacesMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fitMapToPlaces();
  }

  void _fitMapToPlaces() {
    final favoritesAsync = ref.read(savedPlacesProvider);
    final favorites = favoritesAsync.valueOrNull ?? const <Place>[];
    if (favorites.isEmpty) return;
    final latLngs = favorites.map((p) => LatLng(p.latitude, p.longitude)).toList();
    if (latLngs.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(latLngs);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
  }

  void _zoomBy(double delta) {
    final z = (_currentZoom + delta).clamp(3.0, 19.0);
    _mapController.move(_mapController.camera.center, z);
    setState(() => _currentZoom = z);
  }

  void _recenter() {
    _mapController.move(_defaultCenter, 14);
    setState(() => _currentZoom = 14);
  }

  Future<void> _removeFavorite(Place place) async {
    await ref.read(localStorageProvider).removeFavorite(place.id);
    try {
      await ref.read(favoritesServiceProvider).remove(place.id);
    } catch (_) {}
    ref.invalidate(savedPlacesProvider);
  }

  MapPlace _toMapPlace(Place p) {
    final color = switch (p.categoryName?.toLowerCase() ?? p.dnaCategory.toLowerCase()) {
      'beach' => '#3B82F6',
      'cafe' => '#FFB800',
      'park' => '#10B981',
      'landmark' => '#A855F7',
      _ => '#76D11B',
    };
    return MapPlace(
      id: p.id,
      name: p.name,
      category: p.categoryName ?? p.dnaCategory,
      lat: p.latitude,
      lng: p.longitude,
      rating: p.starRating,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(savedPlacesProvider);
    final favorites = favoritesAsync.valueOrNull ?? const <Place>[];
    final mapPlaces = favorites.map(_toMapPlace).toList();

    final selected = mapPlaces.where((p) => p.id == _selectedPlaceId);
    final selectedPlace = selected.isEmpty ? null : selected.first;

    // Fit map to places once data is ready
    if (!_mapInitialized && favoritesAsync.hasValue && favorites.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapInitialized = true;
        _fitMapToPlaces();
      });
    }

    return Scaffold(
      backgroundColor: context.surface,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore, color: context.primary),
            const SizedBox(width: 6),
            Text('Trixile', style: AppTypography.headlineMd.copyWith(
              color: context.primary, fontWeight: FontWeight.w800,
            )),
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
      body: Stack(
        children: [
          // ── Real OSM map ──────────────────────────────────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: _currentZoom,
                minZoom: 3,
                maxZoom: 19,
                onTap: (tapPosition, point) {
                  setState(() => _selectedPlaceId = null);
                },
                onPositionChanged: (camera, hasGesture) {
                  if ((camera.zoom - _currentZoom).abs() > 0.01) {
                    setState(() => _currentZoom = camera.zoom);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrl,
                  userAgentPackageName: _userAgent,
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    for (final place in mapPlaces)
                      Marker(
                        point: LatLng(place.lat, place.lng),
                        width: 44,
                        height: 56,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlaceId =
                              _selectedPlaceId == place.id ? null : place.id),
                          child: _PinMarker(
                            color: _hexToColor(place.color),
                            icon: _iconFor(place.category),
                            selected: place.id == _selectedPlaceId,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── OSM attribution overlay ───────────────────────────
          const Positioned(
            right: 8,
            bottom: 8,
            child: _OsmAttribution(),
          ),

          // top gradient for legibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.surface.withValues(alpha: 0.85),
                      context.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // right-side controls
          Positioned(
            right: 16,
            bottom: selectedPlace != null ? 240 : 120,
            child: _buildMapControls(context),
          ),

          if (selectedPlace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildPlaceCard(context, selectedPlace),
            ),

          // ── Saved places list (bottom half) ──────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.55,
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
              child: Column(
                children: [
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
                              Text('Filter', style: AppTypography.labelMd.copyWith(color: context.primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
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

  IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'beach':
        return Icons.beach_access_rounded;
      case 'cafe':
        return Icons.local_cafe_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'landmark':
        return Icons.account_balance_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Widget _buildMapControls(BuildContext context) {
    Widget btn(IconData icon, VoidCallback onTap) {
      return Material(
        color: context.surfaceContainerLowest.withValues(alpha: 0.95),
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: context.shadowColor,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icon, size: 20, color: context.onSurface),
          ),
        ),
      );
    }

    return Column(
      children: [
        btn(Icons.add_rounded, () => _zoomBy(1)),
        const SizedBox(height: 8),
        btn(Icons.remove_rounded, () => _zoomBy(-1)),
        const SizedBox(height: 12),
        btn(Icons.my_location_rounded, _recenter),
      ],
    );
  }

  Widget _buildPlaceCard(BuildContext context, MapPlace place) {
    final color = _hexToColor(place.color);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_iconFor(place.category), color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name,
                    style: TextStyle(
                        color: context.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.star, size: 15),
                    const SizedBox(width: 3),
                    Text('${place.rating}',
                        style: TextStyle(
                            color: context.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text('${place.lat.toStringAsFixed(4)}, ${place.lng.toStringAsFixed(4)}',
                        style: TextStyle(
                            color: context.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => setState(() => _selectedPlaceId = null),
              icon: const Icon(Icons.directions_rounded, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pin marker (teardrop) ──────────────────────────────────────────────────
class _PinMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool selected;
  const _PinMarker({required this.color, required this.icon, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.18 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: selected ? 16 : 8,
                  spreadRadius: selected ? 2 : 0,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          CustomPaint(
            size: const Size(8, 8),
            painter: _TrianglePainter(color: color),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => false;
}

// ── Required OSM attribution ───────────────────────────────────────────────
class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return RichAttributionWidget(
      alignment: AttributionAlignment.bottomRight,
      attributions: [
        TextSourceAttribution(
          '© OpenStreetMap contributors',
          onTap: () {},
        ),
      ],
    );
  }
}

// ─── Saved place card ─────────────────────────────────────────────────────
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
              width: 100, height: 88,
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
                    Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.titleMd),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Text(place.categoryName ?? place.dnaCategory, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelSm),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.location_on_outlined, size: 12, color: context.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text('${place.distanceKm.toStringAsFixed(1)} km', overflow: TextOverflow.ellipsis, style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant, fontSize: 12)),
                        ),
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
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
            ),
          ],
        ),
      ),
    );
  }
}
