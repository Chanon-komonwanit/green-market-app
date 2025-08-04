// lib/providers/app_config_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:green_market/models/dynamic_app_config.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/enhanced_error_handler.dart';

/// AppConfigProvider จัดการการตั้งค่าแอปพลิเคชันแบบไดนามิก
/// รวมถึงธีม สี ฟอนต์ ข้อความ และการตั้งค่าต่างๆ
/// พร้อมระบบการจัดการข้อผิดพลาดและการป้องกันความปลอดภัยขั้นสูง
class AppConfigProvider extends ChangeNotifier {
  DynamicAppConfig _config = DynamicAppConfig.defaultConfig();
  bool _isLoading = false;
  String? _error;
  final FirebaseService _firebaseService;
  final EnhancedErrorHandler _errorHandler = EnhancedErrorHandler();

  // Enhanced Security & Performance Features
  int _consecutiveFailures = 0;
  static const int maxConsecutiveFailures = 3;
  bool _isNetworkAvailable = true;
  DateTime? _lastRefresh;
  Timer? _autoRefreshTimer;

  // Operation tracking for better reliability
  final Set<String> _pendingOperations = {};
  static const Duration _operationTimeout = Duration(seconds: 30);
  static const Duration _cacheTimeout = Duration(minutes: 15);
  static const Duration _autoRefreshInterval = Duration(hours: 1);

  AppConfigProvider(this._firebaseService) {
    _loadConfig();
    _startAutoRefresh();
  }

  DynamicAppConfig get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isHealthy =>
      !hasError && _consecutiveFailures < maxConsecutiveFailures;
  bool get canPerformOperations => isHealthy && _isNetworkAvailable;
  bool get isCacheExpired =>
      _lastRefresh == null ||
      DateTime.now().difference(_lastRefresh!).compareTo(_cacheTimeout) > 0;

  /// Enhanced error handling with retry logic and security measures
  void _setError(String? error) {
    if (error != null) {
      _consecutiveFailures++;

      // Use the appropriate error handler method
      _errorHandler.handlePlatformError(
        Exception(error),
        StackTrace.current,
      );

      // Implement circuit breaker pattern
      if (_consecutiveFailures >= maxConsecutiveFailures) {
        _isNetworkAvailable = false;
        _scheduleRecovery();
      }
    } else {
      _consecutiveFailures = 0;
      _isNetworkAvailable = true;
    }

    _error = error;
    notifyListeners();
  }

  /// Enhanced loading state management
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Schedule recovery attempt for circuit breaker pattern
  void _scheduleRecovery() {
    Timer(const Duration(minutes: 5), () {
      _consecutiveFailures = 0;
      _isNetworkAvailable = true;
      _setError(null);
    });
  }

  /// Start auto-refresh timer for enhanced data freshness
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
      if (!_isLoading && canPerformOperations && isCacheExpired) {
        reloadConfig();
      }
    });
  }

  /// Enhanced operation wrapper with timeout and validation
  Future<T?> _performOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Duration? timeout,
  }) async {
    if (!canPerformOperations) {
      throw Exception(
          'Operations temporarily disabled due to consecutive failures');
    }

    if (_pendingOperations.contains(operationName)) {
      throw Exception('Operation $operationName is already in progress');
    }

    _pendingOperations.add(operationName);
    try {
      return await operation().timeout(timeout ?? _operationTimeout);
    } catch (e) {
      _setError('$operationName failed: $e');
      return null;
    } finally {
      _pendingOperations.remove(operationName);
    }
  }

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

  /// Enhanced config loading with comprehensive error handling and validation
  Future<void> _loadConfig() async {
    await _performOperation('loadConfig', () async {
      _setLoading(true);
      _setError(null);

      try {
        final configData = await _firebaseService.getDynamicAppConfig();
        if (configData != null) {
          try {
            _config = DynamicAppConfig.fromMap(configData);
            _lastRefresh = DateTime.now();
            print('App config loaded successfully');
          } catch (parseError) {
            _setError('Error parsing app config: $parseError');
            _config = DynamicAppConfig.defaultConfig();
          }
        } else {
          print('No app config found, using default');
          _config = DynamicAppConfig.defaultConfig();
        }
      } catch (e) {
        _setError('Error loading app config: $e');
        // Use default config on any error
        _config = DynamicAppConfig.defaultConfig();
      }
    });

    _setLoading(false);
  }

  /// Enhanced config update with validation
  Future<void> updateConfig(DynamicAppConfig newConfig) async {
    if (newConfig == _config) {
      return; // No changes to update
    }

    await _performOperation('updateConfig', () async {
      _setLoading(true);
      _setError(null);

      await _firebaseService.updateDynamicAppConfig(newConfig);
      _config = newConfig;
      _lastRefresh = DateTime.now();
    });

    _setLoading(false);
  }

  /// Enhanced reload config with cache management
  Future<void> reloadConfig() async {
    if (_isLoading) {
      return; // Prevent multiple reload calls
    }

    await _loadConfig();
  }

  // Enhanced helper methods for text content with validation
  String getText(String key, {String? defaultValue}) {
    if (key.trim().isEmpty) return defaultValue ?? '';
    return _config.staticTexts[key] ?? defaultValue ?? key;
  }

  String getErrorMessage(String key, {String? defaultValue}) {
    if (key.trim().isEmpty) return defaultValue ?? '';
    return _config.errorMessages[key] ?? defaultValue ?? key;
  }

  String getSuccessMessage(String key, {String? defaultValue}) {
    if (key.trim().isEmpty) return defaultValue ?? '';
    return _config.successMessages[key] ?? defaultValue ?? key;
  }

  String getLabel(String key, {String? defaultValue}) {
    if (key.trim().isEmpty) return defaultValue ?? '';
    return _config.labels[key] ?? defaultValue ?? key;
  }

  String getPlaceholder(String key, {String? defaultValue}) {
    if (key.trim().isEmpty) return defaultValue ?? '';
    return _config.placeholders[key] ?? defaultValue ?? key;
  }

  String getButtonText(String key, {String? defaultValue}) {
    if (key.trim().isEmpty) return defaultValue ?? '';
    return _config.buttonTexts[key] ?? defaultValue ?? key;
  }

  String getImageUrl(String key, {String? defaultValue}) {
    if (key.trim().isEmpty) return defaultValue ?? '';
    return _config.images[key] ?? defaultValue ?? '';
  }

  String getIconUrl(String key, {String? defaultValue}) {
    if (key.trim().isEmpty) return defaultValue ?? '';
    return _config.icons[key] ?? defaultValue ?? '';
  }

  // Enhanced font and locale update methods
  Future<void> updateFontFamily(String fontFamily) async {
    if (fontFamily.trim().isEmpty) {
      _setError('Font family cannot be empty');
      return;
    }

    final newConfig = _config.copyWith(primaryFontFamily: fontFamily);
    await updateConfig(newConfig);
  }

  Future<void> updateLocale(String locale) async {
    if (locale.trim().isEmpty) {
      _setError('Locale cannot be empty');
      return;
    }

    final newConfig = _config.copyWith(locale: locale);
    await updateConfig(newConfig);
  }

  // Enhanced real-time color update methods with validation
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

  /// Additional utility methods for enhanced functionality

  /// Clear error message with enhanced logic
  void clearError() {
    _setError(null);
    if (!_isNetworkAvailable && _consecutiveFailures < maxConsecutiveFailures) {
      _isNetworkAvailable = true;
    }
  }

  /// Check if a specific feature is enabled
  bool isFeatureEnabled(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'darkmode':
        return enableDarkMode;
      case 'notifications':
        return enableNotifications;
      case 'chat':
        return enableChat;
      case 'investments':
        return enableInvestments;
      case 'sustainableactivities':
        return enableSustainableActivities;
      case 'reviews':
        return enableReviews;
      case 'promotions':
        return enablePromotions;
      case 'multilanguage':
        return enableMultiLanguage;
      default:
        return false;
    }
  }

  /// Get config as JSON for debugging
  Map<String, dynamic> get configAsJson => _config.toMap();

  /// Reset config to default
  Future<void> resetToDefault() async {
    final defaultConfig = DynamicAppConfig.defaultConfig();
    await updateConfig(defaultConfig);
  }

  /// Enhanced dispose method
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _pendingOperations.clear();
    super.dispose();
  }
}
