// lib/utils/order_utils.dart
import 'package:flutter/material.dart';
import 'package:green_market/utils/constants.dart';

String getOrderStatusText(String status) {
  switch (status) {
    case 'pending_payment':
      return 'รอการชำระเงิน';
    case 'awaiting_confirmation': // Added from OrderDetailScreen
      return 'รอตรวจสอบการชำระเงิน';
    case 'pending_delivery':
      return 'รอการจัดส่ง';
    case 'processing':
      return 'กำลังเตรียมจัดส่ง';
    case 'shipped':
      return 'จัดส่งแล้ว';
    case 'delivered':
      return 'จัดส่งสำเร็จ';
    case 'cancelled':
      return 'ยกเลิกแล้ว';
    default:
      return status.replaceAll('_', ' ').toUpperCase();
  }
}

Color getOrderStatusColor(String status) {
  switch (status) {
    case 'pending_payment':
      return Colors.orangeAccent;
    case 'pending_delivery':
    case 'processing':
      return Colors.blueAccent;
    case 'shipped':
      return AppColors.accentGreen;
    case 'delivered':
      return AppColors.primaryGreen;
    case 'cancelled':
      return AppColors.errorRed;
    default:
      return AppColors.darkGrey;
  }
}
