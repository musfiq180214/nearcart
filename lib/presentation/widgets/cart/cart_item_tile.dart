import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/shopping_list_model.dart';
import '../glassmorphic/glass_card.dart';

class CartItemTile extends StatelessWidget {
  final CartItemEmbedded item;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final int animIndex;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    this.onDelete,
    this.animIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.uuid),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 22),
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        opacity: item.isChecked ? 0.05 : 0.1,
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: 250.ms,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isChecked
                      ? AppColors.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: item.isChecked
                        ? AppColors.primary
                        : AppColors.glassBorder,
                    width: 2,
                  ),
                ),
                child: item.isChecked
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: AppColors.background)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Emoji
            if (item.iconEmoji != null) ...[
              Text(item.iconEmoji!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
            ],

            // Name & category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: item.isChecked
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (item.category != null)
                    Text(
                      item.category!,
                      style: AppTextStyles.bodySmall,
                    ),
                ],
              ),
            ),

            // Quantity & price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      '×${item.quantity}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (item.unit != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        item.unit!,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ],
                ),
                if (item.estimatedPrice != null)
                  Text(
                    '৳${(item.estimatedPrice! * item.quantity).toStringAsFixed(0)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animIndex * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms);
  }
}
