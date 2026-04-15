import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../widgets/map/store_card_widget.dart';
import '../store/add_store_screen.dart';
import '../cart/store_lists_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only shows the current user's stores
    final myStoresAsync = ref.watch(myStoresProvider);
    final allListsAsync = ref.watch(allListsProvider);
    final stats = ref.watch(statsProvider);

    // Current user display name for greeting
    final firebaseUser = ref.watch(firebaseAuthUserProvider).value;
    final firstName = (firebaseUser?.displayName ?? 'there').split(' ').first;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $firstName 👋',
                            style: AppTextStyles.displayLarge
                                .copyWith(color: Colors.black87),
                          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                          Text(
                            'Smart shopping, near you',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.black54),
                          ).animate(delay: 100.ms).fadeIn(),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddStoreScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                          border: Border.all(color: Colors.black12),
                        ),
                        child: const Icon(Icons.add_location_alt_rounded,
                            color: AppColors.primary, size: 24),
                      ),
                    ).animate(delay: 200.ms).fadeIn().scale(),
                  ],
                ),
              ),
            ),

            // ── Stats Row ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: stats.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (s) => Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      _StatCard(
                          label: 'My Stores',
                          value: '${myStoresAsync.value?.length ?? 0}',
                          icon: '🏪'),
                      const SizedBox(width: AppSpacing.sm),
                      _StatCard(
                          label: 'Active',
                          value: '${s['activeLists'] ?? 0}',
                          icon: '📋',
                          accent: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      _StatCard(
                          label: 'Done',
                          value: '${s['completedLists'] ?? 0}',
                          icon: '✅',
                          accent: AppColors.success),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── Active Lists ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('Active Lists',
                    style: AppTextStyles.headingLarge
                        .copyWith(color: Colors.black87)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

            allListsAsync.when(
              loading: () =>
              const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) =>
              const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (lists) {
                final active =
                lists.where((l) => !l.isCompleted).toList();
                if (active.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: _EmptyStateCard(
                        icon: '📋',
                        title: 'No active lists',
                        subtitle:
                        'Add a store and create a list to get started',
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) {
                      final list = active[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 6),
                        child: _ListItemCard(list: list),
                      )
                          .animate(
                          delay: Duration(milliseconds: i * 80))
                          .fadeIn()
                          .slideY(begin: 0.08);
                    },
                    childCount: active.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── My Stores ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('My Saved Stores',
                    style: AppTextStyles.headingLarge
                        .copyWith(color: Colors.black87)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

            myStoresAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
              ),
              error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $e'))),
              data: (stores) {
                if (stores.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: _EmptyStateCard(
                        icon: '📍',
                        title: 'No stores yet',
                        subtitle:
                        'Tap the + button to pin your favourite stores',
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 6),
                      child: StoreCard(
                        store: stores[i],
                        animationIndex: i,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StoreListsScreen(store: stores[i]),
                          ),
                        ),
                      ),
                    ),
                    childCount: stores.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color? accent;

  const _StatCard(
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
          border:
          Border.all(color: accent?.withOpacity(0.2) ?? Colors.black12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: AppSpacing.sm),
            Text(value,
                style: AppTextStyles.headingLarge.copyWith(
                    color: accent ?? Colors.black87, fontSize: 24)),
            Text(label,
                style:
                AppTextStyles.bodySmall.copyWith(color: Colors.black54)),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.95, 0.95)),
    );
  }
}

class _ListItemCard extends StatelessWidget {
  final dynamic list;
  const _ListItemCard({required this.list});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Text('🛒', style: TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(list.name,
                    style: AppTextStyles.headingMedium
                        .copyWith(color: Colors.black87)),
                Text(list.storeName,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.black54)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: list.progress,
                    backgroundColor: Colors.black12,
                    valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${list.checkedItems}/${list.totalItems}',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: Colors.black87)),
              Text(
                '৳${list.totalEstimatedCost.toStringAsFixed(0)}',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const _EmptyStateCard(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.black12),
      ),
      child: Center(
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.sm),
            Text(title,
                style: AppTextStyles.headingMedium
                    .copyWith(color: Colors.black87)),
            Text(subtitle,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: Colors.black54),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}