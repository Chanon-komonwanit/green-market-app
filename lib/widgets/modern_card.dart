import 'package:flutter/material.dart';
import 'package:green_market/utils/constants.dart';

/// Card ดีไซน์ทันสมัย รองรับการปรับแต่งสี, elevation, borderRadius, child, และ onTap
class ModernCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double elevation;
  final double borderRadius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const ModernCard({
    super.key,
    required this.child,
    this.color,
    this.elevation = AppDimens.cardElevation,
    this.borderRadius = AppDimens.largeRadius,
    this.onTap,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).cardColor;
    return Container(
      margin: margin ??
          const EdgeInsets.symmetric(
              vertical: AppDimens.smallPadding, horizontal: 0),
      child: Material(
        color: effectiveColor,
        elevation: elevation,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppDimens.mediumPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}
