import 'package:flutter/material.dart';import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/shopping_list_model.dart';

class CartItemTile extends StatelessWidget {
  final CartItemModel item;
  final int animIndex;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const CartItemTile({
    super.key,
    required this.item,
    required this.animIndex,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.uuid),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: item.isChecked
                ? Colors.grey.shade50
                : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: item.isChecked
                  ? AppColors.success.withOpacity(0.3)
                  : Colors.grey.shade200, // Changed from glassBorder to visible grey
            ),
            boxShadow: [
              if (!item.isChecked)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              // ── Checkbox ─────────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: item.isChecked
                      ? AppColors.success
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isChecked
                        ? AppColors.success
                        : Colors.grey.shade400, // Visible border for the circle
                    width: 2,
                  ),
                ),
                child: item.isChecked
                    ? const Icon(Icons.check_rounded,
                    size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),

              // ── Emoji ─────────────────────────────────────────────────
              Text(item.iconEmoji ?? '🛒',
                  style: TextStyle(
                    fontSize: 22,
                    color: item.isChecked
                        ? Colors.black38
                        : null,
                  )),
              const SizedBox(width: AppSpacing.sm),

              // ── Name + meta ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.isChecked
                            ? Colors.grey // Muted color when checked
                            : Colors.black, // Strong black when unchecked
                        fontWeight: item.isChecked
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    if (item.unit != null ||
                        item.category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
                          if (item.category != null) item.category!,
                        ].join(' · '),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Price ─────────────────────────────────────────────────
              if (item.estimatedPrice != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳${(item.estimatedPrice! * item.quantity).toStringAsFixed(0)}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: item.isChecked
                            ? Colors.grey
                            : AppColors.primary,
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (item.quantity > 1)
                      Text(
                        '৳${item.estimatedPrice!.toStringAsFixed(0)} each',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animIndex * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }
}