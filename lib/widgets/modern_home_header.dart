import 'package:flutter/material.dart';

/// ส่วนหัวหน้า Home ดีไซน์ทันสมัย รองรับ title, subtitle, รูป, action, และ background gradient
class ModernHomeHeader extends StatelessWidget {
  // TODO: [ภาษาไทย] รองรับหลายภาษา (Multi-language Support) ในข้อความ header
  final String title;
  final String? subtitle;
  final Widget? leadingImage;
  final List<Widget>? actions;
  final Gradient? backgroundGradient;

  const ModernHomeHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingImage,
    this.actions,
    this.backgroundGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: backgroundGradient ??
            LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingImage != null) ...[
            leadingImage!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
