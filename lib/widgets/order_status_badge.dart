import 'package:flutter/material.dart';
import 'package:green_market/utils/order_status_utils.dart';

/// World-class reusable status badge for order status
///
/// - ใช้สีและไอคอนตามสถานะจาก OrderStatusUtils
/// - รองรับ accessibility (screen reader)
/// - รองรับ dense mode และ custom textStyle
class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool dense;
  final TextStyle? textStyle;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.dense = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final color = OrderStatusUtils.getStatusColor(status);
    final display = OrderStatusUtils.getDisplayString(status);
    return Semantics(
      label: 'สถานะออเดอร์: $display',
      child: Container(
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color, width: 1.2),
          borderRadius: BorderRadius.circular(dense ? 10 : 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_statusIcon(status), color: color, size: dense ? 16 : 20),
            const SizedBox(width: 6),
            Text(
              display,
              style: textStyle ??
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: dense ? 13 : 15,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case OrderStatusUtils.pendingPayment:
        return Icons.access_time;
      case OrderStatusUtils.processing:
        return Icons.sync;
      case OrderStatusUtils.shipped:
        return Icons.local_shipping;
      case OrderStatusUtils.delivered:
        return Icons.check_circle_outline;
      case OrderStatusUtils.cancelled:
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }
}
