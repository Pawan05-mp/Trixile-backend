import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../extensions/theme_ext.dart';

/// A frosted-glass sticky app bar.
/// Wrap inside a [SliverPersistentHeader] or use as a normal [PreferredSizeWidget].
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.height = kToolbarHeight,
    this.showBorder = true,
  });

  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final double height;
  final bool showBorder;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
          decoration: BoxDecoration(
            color: context.surfaceContainerLow.withValues(alpha: 0.85),
            border: showBorder
                ? Border(
                    bottom: BorderSide(
                      color: context.dividerColor,
                    ),
                  )
                : null,
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (leading != null) leading!,
                if (title != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: title!),
                ] else
                  const Spacer(),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
