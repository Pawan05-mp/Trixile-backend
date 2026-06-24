import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/extensions/theme_ext.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _bioController = TextEditingController(
    text:
        'Digital nomad exploring the hidden gems of Pondicherry. Always looking for the best local coffee spots.',
  );

  @override
  void initState() {
    super.initState();
    final storage = ref.read(localStorageProvider);
    _nameController = TextEditingController(text: storage.getUserName() ?? '');
    _emailController = TextEditingController(text: storage.getUserEmail() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        backgroundColor: context.surface.withValues(alpha: 0.85),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile', style: AppTypography.titleLg),
        actions: [
          TextButton(
            onPressed: () async {
              final storage = ref.read(localStorageProvider);
              await storage.saveUserName(_nameController.text.trim());
              await storage.saveUserEmail(_emailController.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: AppTypography.labelMd.copyWith(
                color: context.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          children: [
            // ── Avatar ────────────────────────────────────────────
Center(
  child: Stack(
    children: [
      Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.primary.withValues(alpha: 0.12),
          border: Border.all(
            color: context.primary.withValues(alpha: 0.8),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: context.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.person_rounded,
          size: 56,
          color: context.primary,
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
              border: Border.all(
                color: context.surface,
                width: 2.5,
              ),
            ),
            child: Icon(
              Icons.edit_rounded,
              size: 18,
              color: context.onPrimary,
            ),
          ),
        ),
      ),
    ],
  ),
),
const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {},
              child: Text(
                'Change Photo',
                style: AppTypography.labelMd.copyWith(color: context.primary, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Input fields ──────────────────────────────────────
            _InputField(label: 'Full Name', controller: _nameController),
            const SizedBox(height: AppSpacing.lg),
            _InputField(label: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: AppSpacing.lg),
            _InputField(label: 'Bio', controller: _bioController, maxLines: 3, hint: 'Tell us about your travel style...'),

            const SizedBox(height: AppSpacing.xl),

            // ── Social links ──────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Social Links', style: AppTypography.sectionHeader),
            ),
            const SizedBox(height: AppSpacing.md),

            _SocialLinkTile(
              platform: 'Instagram',
              handle: '@arjun_travels',
              gradient: const [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6)],
              icon: Icons.photo_camera,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            _SocialLinkTile(
              platform: 'Twitter / X',
              handle: '@arjun_on_road',
              color: const Color(0xFF1DA1F2),
              icon: Icons.alternate_email,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            _SocialLinkTile(
              platform: 'Website',
              handle: 'Not connected',
              color: context.onSurfaceVariant,
              icon: Icons.language,
              action: 'Add',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
          child: Text(
            label,
            style: AppTypography.labelMd.copyWith(color: context.onSurfaceVariant),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTypography.bodyLg,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _SocialLinkTile extends StatelessWidget {
  const _SocialLinkTile({
    required this.platform,
    required this.handle,
    required this.icon,
    required this.onTap,
    this.color,
    this.gradient,
    this.action = 'Edit',
  });

  final String platform;
  final String handle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final List<Color>? gradient;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Platform icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient != null
                  ? LinearGradient(
                      colors: gradient!,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: gradient == null ? color?.withValues(alpha: 0.2) : null,
            ),
            child: Icon(icon, color: gradient != null ? AppColors.white : color, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(platform, style: AppTypography.labelMd),
                const SizedBox(height: 2),
                Text(
                  handle,
                  style: AppTypography.bodyMd.copyWith(color: context.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Action
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: context.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action, style: AppTypography.labelMd.copyWith(color: context.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
