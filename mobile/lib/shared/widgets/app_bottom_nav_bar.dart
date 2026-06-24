import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../extensions/theme_ext.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

static const _items = [
  _NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
  ),
  _NavItem(
  icon: Icons.explore_outlined,
  activeIcon: Icons.explore,
  label: 'Explore',
  ),
  _NavItem(
    icon: Icons.favorite_border,
    activeIcon: Icons.favorite,
    label: 'Saved',
  ),
  _NavItem(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
  ),
];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: context.surface.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(color: context.dividerColor),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final isActive = i == currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: isActive
                            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6)
                            : EdgeInsets.zero,
                        decoration: isActive
                            ? BoxDecoration(
                                color: context.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                              )
                            : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              color: isActive ? context.primary : context.onSurfaceVariant,
                              size: 22,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: AppTypography.labelSm.copyWith(
                                color: isActive ? context.primary : context.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
