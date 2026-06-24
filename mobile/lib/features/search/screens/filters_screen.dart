import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../app/providers.dart';
import '../../../shared/models/occassion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/extensions/theme_ext.dart';

class FiltersScreen extends ConsumerStatefulWidget {
  const FiltersScreen({super.key});

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  static const _budgetLevels = ['₹', '₹₹', '₹₹₹', '₹₹₹₹'];

  String _sortBy = 'popularity';
  late String _budget;
  late double _distance;

  // Occasion filters
  late final Set<String> _selectedOccasions;
  static const _occasionOptions = [
    ('Date Night', AppColors.dateNight, Occasion.date),
    ('Friends', AppColors.friends, Occasion.friends),
    ('Family', AppColors.family, Occasion.family),
    ('Solo', AppColors.solo, Occasion.solo),
  ];

  @override
  void initState() {
    super.initState();
    final budgetLevel = ref.read(budgetPreferenceProvider).clamp(1, 4);
    _budget = _budgetLevels[budgetLevel - 1];
    _distance = ref.read(maxDistanceProvider);
    final occasion = ref.read(selectedOccasionProvider);
    _selectedOccasions = {
      _occasionOptions.firstWhere((o) => o.$3 == occasion).$1,
    };
  }

  // Category filters
  final Set<String> _selectedCategories = {};
  static const _categoryOptions = [
    'Café', 'Fine Dining', 'Bar', 'Nature', 'Culture',
    'Shopping', 'Nightlife', 'Wellness', 'Street Food',
  ];

  void _reset() {
    setState(() {
      _sortBy = 'popularity';
      _budget = _budgetLevels[1];
      _distance = 10;
      _selectedOccasions
        ..clear()
        ..add(_occasionOptions.first.$1);
      _selectedCategories.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.outlineVariant, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Icon(Icons.close, color: context.onSurface),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Filters',
                        style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: Text(
                      'Reset',
                      style: AppTypography.labelMd.copyWith(
                        color: context.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort By
                  const _SectionTitle(title: 'Sort By'),
                  const SizedBox(height: AppSpacing.md),
                  ...[
                    ('popularity', 'Popularity'),
                    ('distance', 'Distance'),
                    ('rating', 'Rating'),
                    ('price', 'Price'),
                  ].map(
                    (s) => _RadioTile(
                      label: s.$2,
                      value: s.$1,
                      groupValue: _sortBy,
                      onChanged: (v) => setState(() => _sortBy = v!),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Budget
                  const _SectionTitle(title: 'Budget'),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: ['₹', '₹₹', '₹₹₹', '₹₹₹₹'].map((b) {
                      final isSelected = _budget == b;
                      return GestureDetector(
                        onTap: () => setState(() => _budget = b),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? context.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            border: Border.all(
                              color: isSelected ? context.primary : context.outlineVariant,
                            ),
                          ),
                          child: Text(
                            b,
                            style: AppTypography.labelMd.copyWith(
                              color: isSelected ? context.primary : context.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Distance slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle(title: 'Distance'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: context.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${_distance.round()} km',
                          style: AppTypography.labelMd.copyWith(
                            color: context.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: context.primary,
                      inactiveTrackColor: context.surfaceContainerHighest,
                      thumbColor: context.primary,
                      overlayColor: context.primary.withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _distance,
                      min: 1,
                      max: 25,
                      divisions: 24,
                      onChanged: (v) => setState(() => _distance = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['1km', '5km', '10km', '20km+'].map(
                      (l) => Text(l, style: AppTypography.caption.copyWith(letterSpacing: 0.8)),
                    ).toList(),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Occasion
                  const _SectionTitle(title: 'Occasion'),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _occasionOptions.map((o) {
                      final isSelected = _selectedOccasions.contains(o.$1);
                      return GestureDetector(
                        onTap: () => setState(() {
                          isSelected
                              ? _selectedOccasions.remove(o.$1)
                              : _selectedOccasions.add(o.$1);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? o.$2.withValues(alpha: 0.15) : context.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            border: Border.all(
                              color: isSelected ? o.$2 : context.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            o.$1,
                            style: AppTypography.labelMd.copyWith(
                              color: isSelected ? o.$2 : context.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Categories
                  const _SectionTitle(title: 'Category'),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _categoryOptions.map((cat) {
                      final isSelected = _selectedCategories.contains(cat);
                      return GestureDetector(
                        onTap: () => setState(() {
                          isSelected
                              ? _selectedCategories.remove(cat)
                              : _selectedCategories.add(cat);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? context.primaryContainer : context.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            border: Border.all(
                              color: isSelected ? context.primary : context.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: AppTypography.labelMd.copyWith(
                              color: isSelected ? context.primary : context.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 120), // padding for sticky button
                ],
              ),
            ),
          ),

          // ── Apply button ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.md,
              AppSpacing.marginMobile,
              MediaQuery.of(context).padding.bottom + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: context.surface,
              border: Border(top: BorderSide(color: context.outlineVariant, width: 0.5)),
            ),
            child: PrimaryButton(
              label: 'APPLY FILTERS',
              onPressed: () {
                final budgetLevel = _budgetLevels.indexOf(_budget) + 1;
                ref.read(budgetPreferenceProvider.notifier).state = budgetLevel;
                ref.read(maxDistanceProvider.notifier).state = _distance;
                ref.read(localStorageProvider).saveBudgetPreference(budgetLevel);
                ref.read(localStorageProvider).saveDistancePreference(_distance);

                if (_selectedOccasions.isNotEmpty) {
                  final picked = _occasionOptions.firstWhere(
                    (o) => o.$1 == _selectedOccasions.first,
                  );
                  ref.read(selectedOccasionProvider.notifier).state = picked.$3;
                }

                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTypography.sectionHeader);
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? context.primary.withValues(alpha: 0.5) : context.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w500)),
            // Use a simple animated circle instead of the deprecated Radio
            // widget whose groupValue/onChanged API was removed in Flutter 3.32.
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? context.primary : context.outlineVariant,
                  width: 2,
                ),
                color: isSelected ? context.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
