import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

import '../../../core/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius = AppRadius.lg,
    this.blur = 20,
    this.opacity = 0.1,
    this.borderColor,
    this.shadows,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        width: width,
        height: height,
        blur: blur,
        color: Colors.white.withOpacity(opacity),
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            boxShadow: shadows ?? AppShadows.glass,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glowing accent glass card — used for primary actions
class GlowGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color glowColor;
  final VoidCallback? onTap;

  const GlowGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.glowColor = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: -5,
            ),
          ],
        ),
        child: GlassContainer(
          blur: 25,
          color: glowColor.withOpacity(0.1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              glowColor.withOpacity(0.2),
              glowColor.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: glowColor.withOpacity(0.4),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet glass panel
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double maxHeight;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.maxHeight = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: maxHeight,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return GlassContainer(
          blur: 30,
          color: Colors.white.withOpacity(0.07),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.12),
              AppColors.backgroundSecondary.withOpacity(0.95),
            ],
          ),
          border: const Border(
            top: BorderSide(color: AppColors.glassBorder, width: 1),
            left: BorderSide(color: AppColors.glassBorder, width: 0.5),
            right: BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
