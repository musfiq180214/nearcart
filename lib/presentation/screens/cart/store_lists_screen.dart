import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../../data/models/store_model.dart';
import '../../../data/models/shopping_list_model.dart';
import '../../../data/repositories/shopping_list_firestore_repo.dart';
import '../../widgets/glassmorphic/glass_card.dart';
import 'shopping_list_screen.dart';

class StoreListsScreen extends ConsumerStatefulWidget {
  final StoreModel store;
  const StoreListsScreen({super.key, required this.store});

  @override
  ConsumerState<StoreListsScreen> createState() => _StoreListsScreenState();
}

class _StoreListsScreenState extends ConsumerState<StoreListsScreen> {
  Future<void> _createList() async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Shopping List', style: AppTextStyles.headingLarge),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                    hintText: 'e.g. Weekly Groceries'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.glassWhite,
                          borderRadius:
                          BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Center(
                            child: Text('Cancel',
                                style: AppTextStyles.bodyLarge)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(ctx, nameCtrl.text.trim()),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: AppColors.primaryGradient),
                          borderRadius:
                          BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Text(
                            'Create',
                            style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.background),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Grab the current userId — required for user-scoped lists
      final uid = ref.read(currentUidProvider);
      if (uid == null) return;

      final repo = ref.read(shoppingListRepositoryProvider);
      final list = repo.createShoppingList(
        uuid: const Uuid().v4(),
        userId: uid, // ← pass userId
        name: result,
        storeUuid: widget.store.uuid,
        storeName: widget.store.name,
      );
      await repo.createList(list);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync =
    ref.watch(listsForStoreProvider(widget.store.uuid));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(10),
                      borderRadius: AppRadius.md,
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.store.name,
                              style: AppTextStyles.displayMedium),
                          Text(
                            '${widget.store.iconEmoji ?? '🏬'} ${widget.store.category}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    GlowGlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      onTap: _createList,
                      child: Row(
                        children: [
                          const Icon(Icons.add_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text('New List',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Lists ────────────────────────────────────────────────
              Expanded(
                child: listsAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                  error: (e, _) =>
                      Center(child: Text('Error: $e')),
                  data: (lists) {
                    if (lists.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🛒',
                                style: TextStyle(fontSize: 64)),
                            const SizedBox(height: AppSpacing.md),
                            Text('No lists yet',
                                style: AppTextStyles.headingLarge),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Create your first shopping list\nfor ${widget.store.name}',
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: lists.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) =>
                          _ListCard(list: lists[i], index: i),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListCard extends ConsumerWidget {
  final ShoppingListModel list;
  final int index;

  const _ListCard({required this.list, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = list.progress;

    return GlassCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShoppingListScreen(listUuid: list.uuid),
        ),
      ),
      borderColor: list.isCompleted
          ? AppColors.success.withOpacity(0.4)
          : AppColors.glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(list.name, style: AppTextStyles.headingMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${list.checkedItems}/${list.totalItems} items · ৳${list.totalEstimatedCost.toStringAsFixed(0)} est.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (list.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Text('✓ Done',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.success)),
                )
              else
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted),
            ],
          ),
          if (list.totalItems > 0) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.glassWhite,
                valueColor: AlwaysStoppedAnimation(
                  list.isCompleted
                      ? AppColors.success
                      : AppColors.primary,
                ),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}