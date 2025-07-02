// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/theme_settings.dart';
import 'package:green_market/services/firebase_service.dart';

class ThemeProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  ThemeData _themeData = ThemeData.light(); // Default theme
  ThemeSettings _currentSettings = ThemeSettings.defaultSettings();

  ThemeProvider(this._firebaseService) {
    _loadThemeSettings();
  }

  ThemeData get themeData => _themeData;
  ThemeSettings get currentSettings =>
      _currentSettings; // Expose current settings

  Future<void> _loadThemeSettings() async {
    try {
      print('[ThemeProvider] Listening to Firestore theme settings...');
      _firebaseService.streamThemeSettingsDocument().listen((settingsData) {
        print('[ThemeProvider] Firestore stream update: $settingsData');
        if (settingsData != null) {
          _currentSettings = ThemeSettings.fromMap(settingsData);
          _themeData = _buildTheme(_currentSettings);
          print(
              '[ThemeProvider] Theme loaded from Firestore: $_currentSettings');
          notifyListeners();
        } else {
          // If no settings found, use default and potentially save them to Firestore
          _currentSettings = ThemeSettings.defaultSettings();
          _themeData = _buildTheme(_currentSettings);
          print(
              '[ThemeProvider] No theme settings found, using default and saving.');
          notifyListeners();
          _firebaseService.logger.i(
              'ThemeProvider: No theme settings found in Firestore, using default and saving.');
          _firebaseService
              .updateThemeSettingsDocument(_currentSettings.toMap());
        }
      });
    } catch (e, s) {
      print('[ThemeProvider] ERROR loading theme: $e');
      _firebaseService.logger.e('ThemeProvider: Error loading theme settings',
          error: e, stackTrace: s);
      // Fallback to default theme on error
      _currentSettings = ThemeSettings.defaultSettings();
      _themeData = _buildTheme(_currentSettings);
      notifyListeners();
    }
  }

  ThemeData _buildTheme(ThemeSettings settings) {
    print('[ThemeProvider] Building ThemeData with: $settings');
    return ThemeData(
      primaryColor: Color(settings.primaryColor),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(settings.primaryColor),
        primary: Color(settings.primaryColor),
        secondary: Color(settings.secondaryColor),
        tertiary: Color(settings.tertiaryColor),
      ).copyWith(
          surfaceContainerHighest:
              Color(settings.primaryColor).withAlpha((0.1 * 255).round())),
      fontFamily: settings.fontFamily,
      useMaterial3: true,
    );
  }

  Future<void> updateTheme(ThemeSettings newSettings) async {
    print('[ThemeProvider] updateTheme called: $newSettings');
    _currentSettings = newSettings;
    _themeData = _buildTheme(newSettings);
    notifyListeners();
    try {
      await _firebaseService.updateThemeSettingsDocument(newSettings.toMap());
      print('[ThemeProvider] Theme settings updated and saved to Firestore.');
      _firebaseService.logger
          .i('ThemeProvider: Theme settings updated and saved to Firestore.');
    } catch (e, s) {
      print('[ThemeProvider] ERROR saving theme: $e');
      _firebaseService.logger.e('ThemeProvider: Error saving theme settings',
          error: e, stackTrace: s);
      // Optionally, revert theme or show error to user
    }
  }
}
