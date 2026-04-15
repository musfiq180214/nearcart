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
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──────────────────────────────────────────────
                Text('Add Item', style: AppTextStyles.headingLarge.copyWith(color: Colors.black)),
                const SizedBox(height: AppSpacing.md),

                // ── Emoji picker ───────────────────────────────────────
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: emojis.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setBS(() => selectedEmoji = emojis[i]),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedEmoji == emojis[i]
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: selectedEmoji == emojis[i]
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(emojis[i], style: const TextStyle(fontSize: 20)),
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
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Item name',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Qty / Unit / Price ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyLarge.copyWith(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Qty',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        style: AppTextStyles.bodyLarge.copyWith(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Unit',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyLarge.copyWith(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: '৳ Price',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Category chips ─────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cats.map((c) => GestureDetector(
                    onTap: () => setBS(() => selectedCat = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedCat == c ? AppColors.primary : Colors.grey[200],
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(c,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: selectedCat == c ? Colors.white : Colors.black87,
                          )),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Add button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final item = CartItemModel(
                        uuid: const Uuid().v4(),
                        name: name,
                        quantity: int.tryParse(qtyCtrl.text) ?? 1,
                        unit: unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
                        estimatedPrice: double.tryParse(priceCtrl.text),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add to List',
                      style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
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
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_list == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('List not found')),
      );
    }

    final list = _list!;
    final unchecked = list.items.where((i) => !i.isChecked).toList();
    final checked = list.items.where((i) => i.isChecked).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(list.name, style: AppTextStyles.headingMedium.copyWith(color: Colors.black)),
            Text(list.storeName, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${list.checkedItems}/${list.totalItems} items',
                                style: AppTextStyles.headingLarge.copyWith(color: Colors.black),
                              ),
                              Text(
                                'Est. ৳${list.totalEstimatedCost.toStringAsFixed(0)}',
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(list.progress * 100).toInt()}%',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: list.isCompleted ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: list.progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          list.isCompleted ? AppColors.success : AppColors.primary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Items list ─────────────────────────────────────────────
            Expanded(
              child: list.items.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: AppSpacing.md),
                    Text('List is empty', style: AppTextStyles.headingLarge.copyWith(color: Colors.black)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Tap + to add your first item', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                  ],
                ),
              )
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  if (unchecked.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text('To Get', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey[700])),
                    ),
                    ...unchecked.asMap().entries.map(
                          (e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CartItemTile(
                          item: e.value,
                          animIndex: e.key,
                          onToggle: () => _toggleItem(e.value.uuid),
                          onDelete: () => _removeItem(e.value.uuid),
                        ),
                      ),
                    ),
                  ],
                  if (checked.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text('In Cart', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey[700])),
                    ),
                    ...checked.asMap().entries.map(
                          (e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Opacity(
                          opacity: 0.6,
                          child: CartItemTile(
                            item: e.value,
                            animIndex: e.key,
                            onToggle: () => _toggleItem(e.value.uuid),
                            onDelete: () => _removeItem(e.value.uuid),
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}