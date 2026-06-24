import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../extensions/theme_ext.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.blur = 12.0,
    this.opacity = 0.85,
    this.border = true,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: context.surfaceContainerLow.withValues(alpha: opacity),
            borderRadius: radius,
            border: border
                ? Border.all(
                    color: context.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
