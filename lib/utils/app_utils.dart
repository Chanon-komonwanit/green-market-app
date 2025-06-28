// lib/utils/app_utils.dart
import 'package:flutter/material.dart';

void showAppSnackBar(BuildContext context, String message,
    {bool isSuccess = false, bool isError = false}) {
  Color backgroundColor = Colors.grey.shade800;
  if (isSuccess) {
    backgroundColor = Colors.green.shade700;
  } else if (isError) {
    backgroundColor = Colors.red.shade700;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating, // Make it float
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16), // Add margin
    ),
  );
}
