import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/utils/order_status_utils.dart';
import 'package:green_market/utils/constants.dart';

void main() {
  group('OrderStatusUtils.getStatusColor', () {
    test('returns correct color for each status', () {
      expect(OrderStatusUtils.getStatusColor(OrderStatusUtils.pendingPayment),
          AppColors.warningAmber);
      expect(OrderStatusUtils.getStatusColor(OrderStatusUtils.processing),
          AppColors.infoBlue);
      expect(OrderStatusUtils.getStatusColor(OrderStatusUtils.shipped),
          AppColors.primaryTeal);
      expect(OrderStatusUtils.getStatusColor(OrderStatusUtils.delivered),
          AppColors.successGreen);
      expect(OrderStatusUtils.getStatusColor(OrderStatusUtils.cancelled),
          AppColors.errorRed);
      expect(
          OrderStatusUtils.getStatusColor('unknown'), AppColors.graySecondary);
    });
  });
}
