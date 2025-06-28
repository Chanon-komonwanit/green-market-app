// lib/utils/ui_helpers.dart

import 'package:flutter/material.dart';

InputDecoration buildInputDecoration(BuildContext context, String labelText,
    {String? hint}) {
  final theme = Theme.of(context);
  return InputDecoration(
    labelText: labelText,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
    ),
    labelStyle: theme.textTheme.bodyLarge
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0, horizontal: 12.0), // Consistent padding
  );
}
