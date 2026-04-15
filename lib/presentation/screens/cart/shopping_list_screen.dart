import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../../data/models/shopping_list_model.dart';
import '../../widgets/glassmorphic/glass_card.dart';
import '../../widgets/cart/cart_item_tile.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  final String listUuid;
  const ShoppingListScreen({super.key, required this.listUuid});

  @override
  ConsumerState<ShoppingListScreen> createState() =>
      _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  ShoppingListModel? _list;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ref
        .read(shoppingListRepositoryProvider)
        .getListByUuid(widget.listUuid);
    if (mounted) {
      setState(() {
        _list = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleItem(String itemUuid) async {
    if (_list == null) return;
    final updated = await ref
        .read(shoppingListRepositoryProvider)
        .toggleItemChecked(_list!, itemUuid);
    if (mounted) setState(() => _list = updated);
  }

  Future<void> _removeItem(String itemUuid) async {
    if (_list == null) return;
    final updated = await ref
        .read(shoppingListRepositoryProvider)
        .removeItemFromList(_list!, itemUuid);
    if (mounted) setState(() => _list = updated);
  }

  Future<void> _addItem() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    String selectedEmoji = '🛒';
    String selectedCat = 'General';

    final emojis = [
      '🛒', '🥦', '🥛', '🍎', '🍗', '🧴', '🍞', '🧃', '🥚', '🧀',
      '🧅', '🫙', '🥩', '🍌', '🫐', '🌽', '🧈', '🥫', '☕', '🧹',
    ];
    final cats = [
      'General', 'Produce', 'Dairy', 'Meat',
      'Bakery', 'Drinks', 'Snacks', 'Hygiene',
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: GlassCard(
            borderRadius: AppRadius.xl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──────────────────────────────────────────────
                Text('Add Item', style: AppTextStyles.headingLarge),
                const SizedBox(height: AppSpacing.md),

                // ── Emoji picker ───────────────────────────────────────
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: emojis.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () =>
                          setBS(() => selectedEmoji = emojis[i]),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedEmoji == emojis[i]
                              ? AppColors.primary.withOpacity(0.2)
                              : AppColors.glassWhite,
                          borderRadius:
                          BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: selectedEmoji == emojis[i]
                                ? AppColors.primary
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(emojis[i],
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Item name ──────────────────────────────────────────
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: AppTextStyles.bodyLarge,
                  decoration:
                  const InputDecoration(hintText: 'Item name'),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Qty / Unit / Price ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyLarge,
                        decoration:
                        const InputDecoration(hintText: 'Qty'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        style: AppTextStyles.bodyLarge,
                        decoration: const InputDecoration(
                            hintText: 'Unit (kg, pcs…)'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyLarge,
                        decoration:
                        const InputDecoration(hintText: '৳ Price'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Category chips ─────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cats
                      .map((c) => GestureDetector(
                    onTap: () =>
                        setBS(() => selectedCat = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedCat == c
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.glassWhite,
                        borderRadius: BorderRadius.circular(
                            AppRadius.full),
                        border: Border.all(
                          color: selectedCat == c
                              ? AppColors.primary
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Text(c,
                          style: AppTextStyles.bodySmall
                              .copyWith(
                            color: selectedCat == c
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          )),
                    ),
                  ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Add button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final item = CartItemModel(
                        uuid: const Uuid().v4(),
                        name: name,
                        quantity: int.tryParse(qtyCtrl.text) ?? 1,
                        unit: unitCtrl.text.trim().isEmpty
                            ? null
                            : unitCtrl.text.trim(),
                        estimatedPrice:
                        double.tryParse(priceCtrl.text),
                        category: selectedCat,
                        iconEmoji: selectedEmoji,
                        isChecked: false,
                      );
                      Navigator.pop(ctx);
                      if (_list != null) {
                        final updated = await ref
                            .read(shoppingListRepositoryProvider)
                            .addItemToList(_list!, item);
                        if (mounted) setState(() => _list = updated);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: AppColors.primaryGradient),
                        borderRadius:
                        BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          'Add to List',
                          style: AppTextStyles.headingMedium
                              .copyWith(color: AppColors.background),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body:
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_list == null) {
      return const Scaffold(
          body: Center(child: Text('List not found')));
    }

    final list = _list!;
    final unchecked = list.items.where((i) => !i.isChecked).toList();
    final checked = list.items.where((i) => i.isChecked).toList();

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
            children: [
              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(10),
                      borderRadius: AppRadius.md,
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          size: 18),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(list.name,
                              style: AppTextStyles.displayMedium),
                          Text(list.storeName,
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress card ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                child: GlowGlassCard(
                  glowColor: list.isCompleted
                      ? AppColors.success
                      : AppColors.primary,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${list.checkedItems}/${list.totalItems} items',
                                  style: AppTextStyles.headingLarge,
                                ),
                                Text(
                                  'Est. ৳${list.totalEstimatedCost.toStringAsFixed(0)}',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(list.progress * 100).toInt()}%',
                            style: AppTextStyles.displayLarge.copyWith(
                              color: list.isCompleted
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: list.progress,
                          backgroundColor: AppColors.glassWhite,
                          valueColor: AlwaysStoppedAnimation(
                            list.isCompleted
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Items list ─────────────────────────────────────────────
              Expanded(
                child: list.items.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📋',
                          style: TextStyle(fontSize: 56)),
                      const SizedBox(height: AppSpacing.md),
                      Text('List is empty',
                          style: AppTextStyles.headingLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Tap + to add your first item',
                          style: AppTextStyles.bodyMedium),
                    ],
                  ),
                )
                    : ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  children: [
                    if (unchecked.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                        child: Text('To Get',
                            style: AppTextStyles.labelMedium),
                      ),
                      ...unchecked.asMap().entries.map(
                            (e) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm),
                          child: CartItemTile(
                            item: e.value,
                            animIndex: e.key,
                            onToggle: () =>
                                _toggleItem(e.value.uuid),
                            onDelete: () =>
                                _removeItem(e.value.uuid),
                          ),
                        ),
                      ),
                    ],
                    if (checked.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                        child: Text('In Cart',
                            style: AppTextStyles.labelMedium),
                      ),
                      ...checked.asMap().entries.map(
                            (e) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm),
                          child: CartItemTile(
                            item: e.value,
                            animIndex: e.key,
                            onToggle: () =>
                                _toggleItem(e.value.uuid),
                            onDelete: () =>
                                _removeItem(e.value.uuid),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
      ),
    );
  }
}