import 'package:flutter/material.dart';

/// ModernButton
/// ปุ่ม UI ที่ทันสมัย รองรับ animation, accessibility, ripple, loading, icon ซ้าย/ขวา
/// - [label]: ข้อความบนปุ่ม
/// - [onPressed]: ฟังก์ชันเมื่อกดปุ่ม
/// - [isLoading]: แสดง loading indicator
/// - [isDisabled]: ปุ่มถูกปิดใช้งาน
/// - [iconLeft], [iconRight]: ไอคอนซ้าย/ขวา
/// - [semanticLabel]: สำหรับ accessibility
/// - [color], [height], [borderRadius], [elevation], [padding]: ปรับแต่ง UI
class ModernButton extends StatelessWidget {
  // TODO: [ภาษาไทย] เพิ่มการตั้งค่าฟอนต์ (Custom Fonts) ให้รองรับฟอนต์ไทยและฟอนต์เฉพาะกลุ่ม
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final bool isDisabled;
  final Widget? iconLeft;
  final Widget? iconRight;
  final TextStyle? textStyle;
  final String? semanticLabel;
  final double elevation;
  final EdgeInsetsGeometry? padding;

  const ModernButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.height = 48,
    this.borderRadius = 14,
    this.isLoading = false,
    this.isDisabled = false,
    this.iconLeft,
    this.iconRight,
    this.textStyle,
    this.semanticLabel,
    this.elevation = 4,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final effectiveTextStyle = textStyle ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 0.2,
        );
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: height,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withOpacity(0.18),
              blurRadius: elevation,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: (isDisabled || isLoading) ? null : onPressed,
            focusColor: effectiveColor.withOpacity(0.22),
            highlightColor: Colors.white.withOpacity(0.08),
            splashColor: Colors.white.withOpacity(0.16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: padding ??
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (iconLeft != null) ...[
                        iconLeft!,
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: effectiveTextStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (iconRight != null) ...[
                        const SizedBox(width: 8),
                        iconRight!,
                      ],
                    ],
                  ),
                ),
                if (isLoading)
                  Container(
                    color: effectiveColor.withOpacity(0.18),
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
