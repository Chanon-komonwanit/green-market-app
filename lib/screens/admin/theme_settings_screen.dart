// lib/screens/admin/theme_settings_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:green_market/providers/theme_provider.dart';
import 'package:green_market/models/theme_settings.dart'; // Import ThemeSettings model
import 'package:provider/provider.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  late Color _currentPrimaryColor;
  late Color _currentSecondaryColor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize colors from the provider once after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        setState(() {
          _currentPrimaryColor = themeProvider.themeData.colorScheme.primary;
          _currentSecondaryColor =
              themeProvider.themeData.colorScheme.secondary;
          _isLoading = false;
        });
      }
    });
  }

  void _pickColor(BuildContext context, bool isPrimary) {
    // Use the local state as the initial color for the picker
    Color initialColor =
        isPrimary ? _currentPrimaryColor : _currentSecondaryColor;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        Color pickedColor = initialColor;
        return AlertDialog(
          title: Text('เลือก${isPrimary ? "สีหลัก" : "สีรอง"}'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (color) => pickedColor = color,
            ),
          ),
          actions: <Widget>[
            TextButton(
                child: const Text('ยกเลิก'),
                onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              child: const Text('เลือก'),
              onPressed: () {
                setState(() {
                  // Update local state for immediate UI feedback in this screen
                  if (isPrimary) {
                    _currentPrimaryColor = pickedColor;
                  } else {
                    _currentSecondaryColor = pickedColor;
                  }
                });
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveThemeSettings() async {
    setState(() => _isLoading = true);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    try {
      // Create a new ThemeSettings object with updated colors, preserving other settings
      final newSettings = ThemeSettings(
        // Corrected: Already correct
        // Corrected: Already correct // Corrected: Already correct
        primaryColor: _currentPrimaryColor // Corrected: Already correct
            .value, // Convert Color to int (already correct)
        secondaryColor: _currentSecondaryColor
            .value, // Convert Color to int (already correct)
        tertiaryColor: themeProvider
            .currentSettings.tertiaryColor, // Preserve existing tertiary color
        useDarkTheme: themeProvider.currentSettings
            .useDarkTheme, // Preserve existing dark theme setting
      );
      await themeProvider.updateTheme(newSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('บันทึกการตั้งค่าธีมสำเร็จ!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกธีม: $e')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('การตั้งค่าธีมหลัก',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 20),
                ListTile(
                  title: Text('สีหลัก (Primary Color)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  trailing: CircleAvatar(backgroundColor: _currentPrimaryColor),
                  onTap: _isLoading ? null : () => _pickColor(context, true),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('สีรอง (Secondary Color)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  trailing:
                      CircleAvatar(backgroundColor: _currentSecondaryColor),
                  onTap: _isLoading ? null : () => _pickColor(context, false),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveThemeSettings,
                      child: const Text('บันทึกการตั้งค่าธีม')),
                ),
              ],
            ),
          );
  }
}
