import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../../data/models/store_model.dart';
import '../../../data/models/shopping_list_model.dart';
import '../../widgets/glassmorphic/glass_card.dart'; // Keeping for compatibility, but replacing usage
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Shopping List',
                  style: AppTextStyles.headingLarge.copyWith(color: Colors.black)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.black),
                decoration: InputDecoration(
                    hintText: 'e.g. Weekly Groceries',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    )),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                            child: Text('Cancel',
                                style: AppTextStyles.bodyLarge.copyWith(color: Colors.black))),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, nameCtrl.text.trim()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Text(
                            'Create',
                            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
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
      final uid = ref.read(currentUidProvider);
      if (uid == null) return;

      final repo = ref.read(shoppingListRepositoryProvider);
      final list = repo.createShoppingList(
        uuid: const Uuid().v4(),
        userId: uid,
        name: result,
        storeUuid: widget.store.uuid,
        storeName: widget.store.name,
      );
      await repo.createList(list);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(listsForStoreProvider(widget.store.uuid));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          size: 18, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.store.name,
                            style: AppTextStyles.displayMedium.copyWith(color: Colors.black)),
                        Text(
                          '${widget.store.iconEmoji ?? '🏬'} ${widget.store.category}',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _createList,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text('New List',
                              style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Lists ────────────────────────────────────────────────
            Expanded(
              child: listsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (lists) {
                  if (lists.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🛒', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: AppSpacing.md),
                          Text('No lists yet',
                              style: AppTextStyles.headingLarge.copyWith(color: Colors.black)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Create your first shopping list\nfor ${widget.store.name}',
                            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: lists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => _ListCard(list: lists[i], index: i),
                  );
                },
              ),
            ),
          ],
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

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShoppingListScreen(listUuid: list.uuid),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: list.isCompleted
                ? AppColors.success.withOpacity(0.3)
                : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(list.name,
                          style: AppTextStyles.headingMedium.copyWith(color: Colors.black)),
                      const SizedBox(height: 4),
                      Text(
                        '${list.checkedItems}/${list.totalItems} items · ৳${list.totalEstimatedCost.toStringAsFixed(0)} est.',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (list.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text('✓ Done',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
              ],
            ),
            if (list.totalItems > 0) ...[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation(
                    list.isCompleted ? AppColors.success : AppColors.primary,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0);
  }
}