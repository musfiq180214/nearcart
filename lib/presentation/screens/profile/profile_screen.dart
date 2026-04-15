import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(firebaseAuthUserProvider);
    final stats = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Text('Profile',
                  style: AppTextStyles.displayLarge
                      .copyWith(color: Colors.black87))
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.05),
              const SizedBox(height: AppSpacing.lg),

              // ── Avatar + name ──────────────────────────────────────────
              authAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (firebaseUser) {
                  final displayName =
                      firebaseUser?.displayName ?? 'NearCart User';
                  final email = firebaseUser?.email ?? '';
                  final initials = displayName.isNotEmpty
                      ? displayName
                      .trim()
                      .split(' ')
                      .map((w) => w[0])
                      .take(2)
                      .join()
                      .toUpperCase()
                      : '?';

                  return Column(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                    width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn().scale(),
                            const SizedBox(height: AppSpacing.md),
                            Text(displayName,
                                style: AppTextStyles.headingLarge
                                    .copyWith(color: Colors.black87))
                                .animate(delay: 100.ms)
                                .fadeIn(),
                            Text(email,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: Colors.black54))
                                .animate(delay: 140.ms)
                                .fadeIn(),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Stats ──────────────────────────────────────────────────
              Text('Your Activity',
                  style: AppTextStyles.headingMedium
                      .copyWith(color: Colors.black87)),
              const SizedBox(height: AppSpacing.sm),

              stats.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (s) => Row(
                  children: [
                    _StatTile(
                      label: 'Total',
                      value: '${s['totalLists'] ?? 0}',
                      icon: '📋',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatTile(
                      label: 'Active',
                      value: '${s['activeLists'] ?? 0}',
                      icon: '🛒',
                      accent: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatTile(
                      label: 'Done',
                      value: '${s['completedLists'] ?? 0}',
                      icon: '✅',
                      accent: AppColors.success,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Settings tiles ─────────────────────────────────────────
              Text('Settings',
                  style: AppTextStyles.headingMedium
                      .copyWith(color: Colors.black87)),
              const SizedBox(height: AppSpacing.sm),

              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () {},
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Sign out ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg)),
                        title: const Text('Sign Out'),
                        content: const Text(
                            'Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Sign Out',
                                style: TextStyle(color: Colors.red.shade600)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .signOut();
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  label: Text('Sign Out',
                      style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color? accent;

  const _StatTile(
      {required this.label,
        required this.value,
        required this.icon,
        this.accent});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: accent?.withOpacity(0.2) ?? Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: AppTextStyles.headingLarge.copyWith(
                    color: accent ?? Colors.black87, fontSize: 24)),
            Text(label,
                style:
                AppTextStyles.bodySmall.copyWith(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.black87)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.black38, size: 20),
          ],
        ),
      ),
    );
  }
}