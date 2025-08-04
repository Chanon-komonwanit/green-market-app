import 'package:flutter/material.dart';
import 'package:green_market/utils/constants.dart';

/// Utilities for order status display, color, and mapping.
///
/// ตัวอย่างการใช้งาน:
///   Text(OrderStatusUtils.getDisplayString(status))
///   Color c = OrderStatusUtils.getStatusColor(status)
///   Widget badge = OrderStatusBadge(status: status)
///
/// รองรับสถานะ: pendingPayment, processing, shipped, delivered, cancelled, unknown
// lib/utils/order_status_utils.dart

class OrderStatusUtils {
  // Define all possible order statuses
  static const String pendingPayment = 'pending_payment';
  static const String processing = 'processing';
  static const String shipped = 'shipped';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  // List of statuses that a seller can update an order to
  static const List<String> sellerUpdatableStatuses = [
    processing,
    shipped,
    delivered,
    cancelled,
  ];

  // Get display string for a given status
  static String getDisplayString(String status) {
    switch (status) {
      case pendingPayment:
        return 'รอการชำระเงิน';
      case processing:
        return 'กำลังดำเนินการ';
      case shipped:
        return 'จัดส่งแล้ว';
      case delivered:
        return 'จัดส่งสำเร็จ';
      case cancelled:
        return 'ยกเลิกแล้ว';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  // Get display string for a given status (for buyers, might be slightly different)
  static String getBuyerDisplayString(String status) {
    switch (status) {
      case pendingPayment:
        return 'รอการชำระเงิน';
      case processing:
        return 'กำลังเตรียมสินค้า';
      case shipped:
        return 'สินค้ากำลังจัดส่ง';
      case delivered:
        return 'ได้รับสินค้าแล้ว';
      case cancelled:
        return 'คำสั่งซื้อถูกยกเลิก';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  static Color getStatusColor(String currentStatus) {
    switch (currentStatus) {
      case pendingPayment:
        return AppColors.warningAmber;
      case processing:
        return AppColors.infoBlue;
      case shipped:
        return AppColors.primaryTeal;
      case delivered:
        return AppColors.successGreen;
      case cancelled:
        return AppColors.errorRed;
      default:
        return AppColors.graySecondary;
    }
  }

  // You can add more utility methods here, e.g., to check if a status is final, etc.
}
