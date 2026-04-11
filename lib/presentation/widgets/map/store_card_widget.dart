import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/store_model.dart';
import '../glassmorphic/glass_card.dart';

class StoreCard extends StatelessWidget {
  final StoreModel store;
  final VoidCallback? onTap;
  final VoidCallback? onAddList;
  final int? listCount;
  final double? distanceKm;
  final bool isSelected;
  final int animationIndex;

  const StoreCard({
    super.key,
    required this.store,
    this.onTap,
    this.onAddList,
    this.listCount,
    this.distanceKm,
    this.isSelected = false,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(store.markerColor);

    return GlassCard(
      onTap: onTap,
      borderColor: isSelected ? color.withOpacity(0.6) : AppColors.glassBorder,
      shadows: isSelected ? AppShadows.primary : AppShadows.card,
      child: Row(
        children: [
          // Icon container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                store.iconEmoji ?? _categoryEmoji(store.category),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.name, style: AppTextStyles.headingMedium),
                const SizedBox(height: 2),
                Text(
                  store.address,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _chip(
                      _categoryLabel(store.category),
                      color.withOpacity(0.15),
                      color,
                    ),
                    if (distanceKm != null) ...[
                      const SizedBox(width: 6),
                      _chip(
                        '${distanceKm!.toStringAsFixed(1)} km',
                        AppColors.glassWhite,
                        AppColors.textSecondary,
                      ),
                    ],
                    if (listCount != null && listCount! > 0) ...[
                      const SizedBox(width: 6),
                      _chip(
                        '$listCount list${listCount! > 1 ? 's' : ''}',
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Action
          Column(
            children: [
              if (onAddList != null)
                GestureDetector(
                  onTap: onAddList,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: animationIndex * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String _categoryEmoji(String cat) {
    switch (cat.toLowerCase()) {
      case 'grocery': return '🛒';
      case 'pharmacy': return '💊';
      case 'electronics': return '📱';
      case 'bakery': return '🥖';
      case 'butcher': return '🥩';
      case 'market': return '🏪';
      case 'clothing': return '👕';
      case 'hardware': return '🔧';
      default: return '🏬';
    }
  }

  String _categoryLabel(String cat) {
    return cat[0].toUpperCase() + cat.substring(1);
  }
}
