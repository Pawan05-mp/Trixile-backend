import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../shared/extensions/theme_ext.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _navIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: context.surface,
            border: Border(
              bottom: BorderSide(color: context.outlineVariant, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: context.primary),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Notifications', style: AppTypography.titleLg.copyWith(color: context.primary)),
                  const Spacer(),
                  TextButton(
                    onPressed: null,
                    child: Text(
                      'Mark all as read',
                      style: AppTypography.labelMd.copyWith(
                        color: context.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual anchor
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse ring
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: context.primary.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    // Icon circle
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: context.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        Icons.notifications_off_outlined,
                        size: 44,
                        color: context.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Decorative image strip
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  width: 220,
                  height: 100,
                  color: context.surfaceContainerHigh,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500',
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.4),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              const Text(
                'No notifications yet',
                style: AppTypography.headlineLgMobile,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                "We'll let you know when there's an update on your trips, new hidden gems, or social activity.",
                style: AppTypography.bodyLg.copyWith(color: context.onSurfaceVariant, height: 1.6),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: 'Explore Places',
                onPressed: () => context.push(AppRouter.explore),
                fullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
