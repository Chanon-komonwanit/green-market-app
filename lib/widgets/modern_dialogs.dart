// lib/widgets/modern_dialogs.dart
import 'package:flutter/material.dart';
import 'package:green_market/utils/constants.dart';

/// Modern Confirmation Dialog แบบ iOS/Material Design
class ModernDialog {
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'ยืนยัน',
    String cancelText = 'ยกเลิก',
    Color? confirmColor,
    IconData? icon,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDangerous
                          ? AppColors.errorRed
                          : confirmColor ?? AppColors.primaryTeal)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDangerous
                      ? AppColors.errorRed
                      : confirmColor ?? AppColors.primaryTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.headline.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTextStyles.body.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: TextStyle(color: AppColors.graySecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous
                  ? AppColors.errorRed
                  : confirmColor ?? AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 2),
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        Future.delayed(duration, () {
          if (context.mounted) Navigator.pop(context);
        });

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTextStyles.headline.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    String? message,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.errorRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.headline.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: message != null
            ? Text(
                message,
                style: AppTextStyles.body.copyWith(height: 1.5),
              )
            : null,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  static Future<void> showLoading({
    required BuildContext context,
    String message = 'กำลังโหลด...',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modern Input Dialog
class ModernInputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String hintText;
  final String? initialValue;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String confirmText;
  final String cancelText;

  const ModernInputDialog({
    super.key,
    required this.title,
    this.message,
    required this.hintText,
    this.initialValue,
    this.maxLines = 1,
    this.keyboardType,
    this.confirmText = 'ยืนยัน',
    this.cancelText = 'ยกเลิก',
  });

  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? message,
    required String hintText,
    String? initialValue,
    int? maxLines,
    TextInputType? keyboardType,
    String confirmText = 'ยืนยัน',
    String cancelText = 'ยกเลิก',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => ModernInputDialog(
        title: title,
        message: message,
        hintText: hintText,
        initialValue: initialValue,
        maxLines: maxLines,
        keyboardType: keyboardType,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  @override
  State<ModernInputDialog> createState() => _ModernInputDialogState();
}

class _ModernInputDialogState extends State<ModernInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: AppTextStyles.headline.copyWith(fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(
              widget.message!,
              style: AppTextStyles.body.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.grayBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryTeal, width: 2),
              ),
              filled: true,
              fillColor: AppColors.surfaceGray,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            widget.cancelText,
            style: TextStyle(color: AppColors.graySecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final value = _controller.text.trim();
            Navigator.pop(context, value.isNotEmpty ? value : null);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}

/// Modern Choice Dialog
class ModernChoiceDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<ChoiceItem<T>> items,
    T? selected,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: AppTextStyles.headline.copyWith(fontSize: 18),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            final isSelected = selected == item.value;
            return ListTile(
              leading: item.icon != null
                  ? Icon(
                      item.icon,
                      color: isSelected
                          ? AppColors.primaryTeal
                          : AppColors.graySecondary,
                    )
                  : null,
              title: Text(
                item.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryTeal
                      : AppColors.grayPrimary,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primaryTeal)
                  : null,
              onTap: () => Navigator.pop(context, item.value),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ChoiceItem<T> {
  final String label;
  final T value;
  final IconData? icon;

  const ChoiceItem({
    required this.label,
    required this.value,
    this.icon,
  });
}
