import 'package:flutter/material.dart';
import 'constants.dart';

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTeal,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryTeal,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.modernGrey,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTeal,
  );

  static const TextStyle price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryGreen,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.modernGrey,
  );
}
