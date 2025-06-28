// lib/providers/app_config_provider.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/dynamic_app_config.dart';
import 'package:green_market/services/firebase_service.dart';

class AppConfigProvider extends ChangeNotifier {
  DynamicAppConfig _config = DynamicAppConfig.defaultConfig();
  bool _isLoading = false;
  final FirebaseService _firebaseService;

  AppConfigProvider(this._firebaseService) {
    _loadConfig();
  }

  DynamicAppConfig get config => _config;
  bool get isLoading => _isLoading;

  // Quick access getters
  String get appName => _config.appName;
  String get appTagline => _config.appTagline;
  String get logoUrl => _config.logoUrl;
  String get heroTitle => _config.heroTitle;
  String get heroSubtitle => _config.heroSubtitle;
  String get heroImageUrl => _config.heroImageUrl;

  Color get primaryColor => _config.primaryColor;
  Color get secondaryColor => _config.secondaryColor;
  Color get accentColor => _config.accentColor;
  Color get backgroundColor => _config.backgroundColor;
  Color get surfaceColor => _config.surfaceColor;
  Color get errorColor => _config.errorColor;
  Color get successColor => _config.successColor;
  Color get warningColor => _config.warningColor;
  Color get infoColor => _config.infoColor;

  String get primaryFontFamily => _config.primaryFontFamily;
  String get secondaryFontFamily => _config.secondaryFontFamily;
  double get baseFontSize => _config.baseFontSize;
  double get titleFontSize => _config.titleFontSize;
  double get headingFontSize => _config.headingFontSize;
  double get captionFontSize => _config.captionFontSize;

  double get borderRadius => _config.borderRadius;
  double get cardElevation => _config.cardElevation;
  double get buttonHeight => _config.buttonHeight;
  double get inputHeight => _config.inputHeight;
  double get spacing => _config.spacing;
  double get padding => _config.padding;

  bool get enableDarkMode => _config.enableDarkMode;
  bool get enableNotifications => _config.enableNotifications;
  bool get enableChat => _config.enableChat;
  bool get enableInvestments => _config.enableInvestments;
  bool get enableSustainableActivities => _config.enableSustainableActivities;
  bool get enableReviews => _config.enableReviews;
  bool get enablePromotions => _config.enablePromotions;
  bool get enableMultiLanguage => _config.enableMultiLanguage;

  double get defaultShippingFee => _config.defaultShippingFee;
  double get minimumOrderAmount => _config.minimumOrderAmount;
  int get maxCartItems => _config.maxCartItems;
  int get productApprovalDays => _config.productApprovalDays;
  double get platformCommissionRate => _config.platformCommissionRate;

  String get supportEmail => _config.supportEmail;
  String get supportPhone => _config.supportPhone;
  String get companyAddress => _config.companyAddress;
  String get facebookUrl => _config.facebookUrl;
  String get lineUrl => _config.lineUrl;
  String get instagramUrl => _config.instagramUrl;
  String get twitterUrl => _config.twitterUrl;

  Future<void> _loadConfig() async {
    _isLoading = true;
    notifyListeners();

    try {
      final configData = await _firebaseService.getDynamicAppConfig();
      if (configData != null) {
        try {
          _config = DynamicAppConfig.fromMap(configData);
          print('App config loaded successfully');
        } catch (parseError) {
          print('Error parsing app config, using default: $parseError');
          _config = DynamicAppConfig.defaultConfig();
        }
      } else {
        print('No app config found, using default');
        _config = DynamicAppConfig.defaultConfig();
      }
    } catch (e) {
      print('Error loading app config, using default: $e');
      // Use default config on any error
      _config = DynamicAppConfig.defaultConfig();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateConfig(DynamicAppConfig newConfig) async {
    try {
      await _firebaseService.updateDynamicAppConfig(newConfig);
      _config = newConfig;
      notifyListeners();
    } catch (e) {
      print('Error updating app config: $e');
      rethrow;
    }
  }

  Future<void> reloadConfig() async {
    await _loadConfig();
  }

  // Helper methods for text content
  String getText(String key, {String? defaultValue}) {
    return _config.staticTexts[key] ?? defaultValue ?? key;
  }

  String getErrorMessage(String key, {String? defaultValue}) {
    return _config.errorMessages[key] ?? defaultValue ?? key;
  }

  String getSuccessMessage(String key, {String? defaultValue}) {
    return _config.successMessages[key] ?? defaultValue ?? key;
  }

  String getLabel(String key, {String? defaultValue}) {
    return _config.labels[key] ?? defaultValue ?? key;
  }

  String getPlaceholder(String key, {String? defaultValue}) {
    return _config.placeholders[key] ?? defaultValue ?? key;
  }

  String getButtonText(String key, {String? defaultValue}) {
    return _config.buttonTexts[key] ?? defaultValue ?? key;
  }

  String getImageUrl(String key, {String? defaultValue}) {
    return _config.images[key] ?? defaultValue ?? '';
  }

  String getIconUrl(String key, {String? defaultValue}) {
    return _config.icons[key] ?? defaultValue ?? '';
  }

  // Real-time color update methods
  Future<void> updatePrimaryColor(Color color) async {
    final newConfig = _config.copyWith(primaryColorValue: color.value);
    await updateConfig(newConfig);
  }

  Future<void> updateSecondaryColor(Color color) async {
    final newConfig = _config.copyWith(secondaryColorValue: color.value);
    await updateConfig(newConfig);
  }

  Future<void> updateAccentColor(Color color) async {
    final newConfig = _config.copyWith(accentColorValue: color.value);
    await updateConfig(newConfig);
  }

  Future<void> updateBackgroundColor(Color color) async {
    final newConfig = _config.copyWith(backgroundColorValue: color.value);
    await updateConfig(newConfig);
  }

  Future<void> updateSurfaceColor(Color color) async {
    final newConfig = _config.copyWith(surfaceColorValue: color.value);
    await updateConfig(newConfig);
  }

  // Real-time text update methods
  Future<void> updateAppName(String name) async {
    final newConfig = _config.copyWith(appName: name);
    await updateConfig(newConfig);
  }

  Future<void> updateAppTagline(String tagline) async {
    final newConfig = _config.copyWith(appTagline: tagline);
    await updateConfig(newConfig);
  }

  Future<void> updateHeroTitle(String title) async {
    final newConfig = _config.copyWith(heroTitle: title);
    await updateConfig(newConfig);
  }

  Future<void> updateHeroSubtitle(String subtitle) async {
    final newConfig = _config.copyWith(heroSubtitle: subtitle);
    await updateConfig(newConfig);
  }

  // Real-time image update methods
  Future<void> updateLogoUrl(String url) async {
    final newConfig = _config.copyWith(logoUrl: url);
    await updateConfig(newConfig);
  }

  Future<void> updateHeroImageUrl(String url) async {
    final newConfig = _config.copyWith(heroImageUrl: url);
    await updateConfig(newConfig);
  }

  // Dynamic theme data based on config
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: primaryFontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
      ),
      cardTheme: CardThemeData(
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding * 0.75,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: baseFontSize,
          fontFamily: primaryFontFamily,
        ),
        bodyMedium: TextStyle(
          fontSize: baseFontSize - 2,
          fontFamily: primaryFontFamily,
        ),
        titleLarge: TextStyle(
          fontSize: titleFontSize,
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontSize: headingFontSize,
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.bold,
        ),
        bodySmall: TextStyle(
          fontSize: captionFontSize,
          fontFamily: primaryFontFamily,
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: primaryFontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        secondary: secondaryColor,
        error: errorColor,
      ),
      cardTheme: CardThemeData(
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding * 0.75,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: baseFontSize,
          fontFamily: primaryFontFamily,
        ),
        bodyMedium: TextStyle(
          fontSize: baseFontSize - 2,
          fontFamily: primaryFontFamily,
        ),
        titleLarge: TextStyle(
          fontSize: titleFontSize,
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontSize: headingFontSize,
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.bold,
        ),
        bodySmall: TextStyle(
          fontSize: captionFontSize,
          fontFamily: primaryFontFamily,
        ),
      ),
    );
  }
}
