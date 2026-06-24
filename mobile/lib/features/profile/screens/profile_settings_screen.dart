import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/extensions/theme_ext.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = ref.read(localStorageProvider);
    final name = storage.getUserName() ?? 'Your Name';
    final email = storage.getUserEmail() ?? 'Add an email in Edit Profile';
    final notificationsEnabled = storage.getNotificationPreference();
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: context.surface,
      body: CustomScrollView(
        slivers: [
          // ── Sticky header ─────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: context.surfaceDim.withValues(alpha: 0.85),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.onSurface),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRouter.home);
                }
              },
            ),
            title: Text(
              'Profile Settings',
              style: AppTypography.headlineMd.copyWith(fontWeight: FontWeight.w800),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Avatar section ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              color: context.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.surfaceContainerHigh, width: 4),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 64,
                              color: context.onSurfaceVariant,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: context.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: context.surface, width: 3),
                                ),
                                child: Icon(Icons.photo_camera, size: 16, color: context.onPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(name, style: AppTypography.headlineMd.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(email, style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant)),
                    ],
                  ),
                ),



                // ── Preferences group ───────────────────────────────
                _SettingsGroup(
                  title: 'PREFERENCES',
                  items: [
                    _SettingItem(
                      iconBg: AppColors.friends.withValues(alpha: 0.15),
                      iconColor: AppColors.friends,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: notificationsEnabled ? 'Push, email alerts on' : 'Off',
                      trailing: Switch.adaptive(
                        value: notificationsEnabled,
                        onChanged: (v) async {
                          await storage.saveNotificationPreference(v);
                          setState(() {});
                        },
                        activeTrackColor: context.primary,
                      ),
                      onTap: () async {
                        final v = !notificationsEnabled;
                        await storage.saveNotificationPreference(v);
                        setState(() {});
                      },
                    ),
                    _SettingItem(
                      iconBg: AppColors.family.withValues(alpha: 0.15),
                      iconColor: AppColors.family,
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      subtitle: 'Always on',
                      trailing: Switch.adaptive(
                        value: true,
                        onChanged: (v) async {
                          if (v) {
                            await ref.read(locationServiceProvider).requestPermission();
                          }
                          setState(() {});
                        },
                        activeTrackColor: context.primary,
                      ),
                    ),
                    _SettingItem(
                      iconBg: AppColors.solo.withValues(alpha: 0.15),
                      iconColor: AppColors.solo,
                      icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      title: 'Appearance',
                      subtitle: isDark ? 'Dark mode' : 'Light mode',
                      trailing: Switch.adaptive(
                        value: isDark,
                        onChanged: (v) {
                          ref.read(themeModeProvider.notifier).state =
                              v ? ThemeMode.dark : ThemeMode.light;
                          ref.read(localStorageProvider).saveDarkModePreference(v);
                        },
                        activeTrackColor: context.primary,
                      ),
                    ),
                  ],
                ),

                // ── Account group ───────────────────────────────────
                _SettingsGroup(
                  title: 'ACCOUNT',
                  items: [
                    _SettingItem(
                      iconBg: context.outlineVariant.withValues(alpha: 0.2),
                      iconColor: context.onSurfaceVariant,
                      icon: Icons.lock_outline,
                      title: 'Privacy & Security',
                      subtitle: 'Manage your data',
                      onTap: () {},
                    ),
                    _SettingItem(
                      iconBg: context.outlineVariant.withValues(alpha: 0.2),
                      iconColor: context.onSurfaceVariant,
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'FAQ, contact us',
                      onTap: () {},
                    ),
                    _SettingItem(
                      iconBg: context.errorContainer.withValues(alpha: 0.3),
                      iconColor: context.error,
                      icon: Icons.logout,
                      title: 'Sign Out',
                      onTap: () async {
                        await storage.saveUserName('');
                        await storage.saveUserEmail('');
                        await ref.read(secureStorageProvider).clearSession();
                        ref.read(apiClientProvider).setAuthToken(null);
                        ref.read(isAuthenticatedProvider.notifier).state = false;
                        AppRouter.startSignedIn = false;
                        if (context.mounted) context.go(AppRouter.signIn);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.items});
  final String title;
  final List<_SettingItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.md),
            child: Text(
              title,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: context.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: context.outlineVariant.withValues(alpha: 0.25)),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: List.generate(items.length, (i) {
                return Column(
                  children: [
                    items[i],
                    if (i < items.length - 1)
                      Divider(height: 1, color: context.outlineVariant, indent: 60),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.surfaceContainer,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Leading icon + text (tappable, fills remaining width)
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppTypography.bodyMd.copyWith(
                              color: context.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          trailing ?? Icon(Icons.chevron_right, color: context.onSurfaceVariant, size: 20),
        ],
      ),
    );
  }
}
