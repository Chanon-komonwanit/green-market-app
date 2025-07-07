// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/theme_settings.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  ThemeData _themeData = ThemeData.light(); // Default theme
  ThemeData _darkThemeData = ThemeData.dark(); // Dark theme
  ThemeSettings _currentSettings = ThemeSettings.defaultSettings();
  bool _isDarkMode = false;

  ThemeProvider(this._firebaseService) {
    _loadThemeSettings();
    _loadDarkModePreference();
  }

  ThemeData get themeData => _isDarkMode ? _darkThemeData : _themeData;
  ThemeData get lightTheme => _themeData;
  ThemeData get darkTheme => _darkThemeData;
  ThemeSettings get currentSettings => _currentSettings;
  bool get isDarkMode => _isDarkMode;

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

  // Load dark mode preference from SharedPreferences
  Future<void> _loadDarkModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      print('[ThemeProvider] Dark mode preference loaded: $_isDarkMode');
      notifyListeners();
    } catch (e) {
      print('[ThemeProvider] Error loading dark mode preference: $e');
      _isDarkMode = false;
    }
  }

  ThemeData _buildTheme(ThemeSettings settings) {
    print('[ThemeProvider] Building ThemeData with: $settings');

    // Build Light Theme
    final lightTheme = ThemeData(
      primaryColor: Color(settings.primaryColor),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(settings.primaryColor),
        primary: Color(settings.primaryColor),
        secondary: Color(settings.secondaryColor),
        tertiary: Color(settings.tertiaryColor),
        brightness: Brightness.light,
      ).copyWith(
          surfaceContainerHighest:
              Color(settings.primaryColor).withAlpha((0.1 * 255).round())),
      fontFamily: settings.fontFamily,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(settings.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.black54),
        headlineLarge: TextStyle(color: Colors.black87),
        headlineMedium: TextStyle(color: Colors.black87),
        headlineSmall: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: Colors.black87),
        titleMedium: TextStyle(color: Colors.black87),
        titleSmall: TextStyle(color: Colors.black87),
      ),
    );

    // Build Dark Theme
    final darkTheme = ThemeData(
      primaryColor: Color(settings.primaryColor),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(settings.primaryColor),
        primary: Color(settings.primaryColor),
        secondary: Color(settings.secondaryColor),
        tertiary: Color(settings.tertiaryColor),
        brightness: Brightness.dark,
      ).copyWith(
          surfaceContainerHighest:
              Color(settings.primaryColor).withAlpha((0.1 * 255).round())),
      fontFamily: settings.fontFamily,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Color(settings.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white54),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
      ),
    );

    _themeData = lightTheme;
    _darkThemeData = darkTheme;

    return _isDarkMode ? darkTheme : lightTheme;
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

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      print('[ThemeProvider] Dark mode toggled to: $_isDarkMode');
      notifyListeners();
    } catch (e) {
      print('[ThemeProvider] Error saving dark mode preference: $e');
    }
  }

  // Set dark mode
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      print('[ThemeProvider] Dark mode set to: $_isDarkMode');
      notifyListeners();
    } catch (e) {
      print('[ThemeProvider] Error saving dark mode preference: $e');
    }
  }
}
