// lib/utils/validation_utils.dart

import 'dart:convert';
import 'dart:math';

/// Validation result container with detailed feedback
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final dynamic value;
  final Map<String, dynamic>? metadata;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.value,
    this.metadata,
  });

  /// Get the first error message
  String? get firstError => errors.isNotEmpty ? errors.first : null;

  /// Get the first warning message
  String? get firstWarning => warnings.isNotEmpty ? warnings.first : null;

  /// Check if result has any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Get all messages combined
  List<String> get allMessages => [...errors, ...warnings];

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}

/// Enhanced Validation Utilities with comprehensive security and performance features
/// Provides input validation, sanitization, and security checks
class ValidationUtils {
  // Security configuration
  static const int _maxInputLength = 10000;
  static const List<String> _allowedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];

  // Cache for validation results
  static final Map<String, bool> _validationCache = {};
  static const int _maxCacheSize = 1000;

  // ENHANCED SECURITY FUNCTIONS

  /// Advanced input sanitization with multiple layers
  static String sanitizeInput(String input, {bool preserveNewlines = false}) {
    if (input.isEmpty) return input;

    // Check length limit
    if (input.length > _maxInputLength) {
      input = input.substring(0, _maxInputLength);
    }

    String sanitized = input.trim();

    // Remove HTML tags and script elements
    sanitized = sanitized
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&[#\w]+;'), ''); // Remove HTML entities

    // Remove dangerous characters but preserve Thai characters
    sanitized = sanitized.replaceAll(
        RegExp(r'[<>&"\x27\x60\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    // Normalize whitespace
    if (preserveNewlines) {
      sanitized = sanitized.replaceAll(RegExp(r'[ \t]+'), ' ');
    } else {
      sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    }

    return sanitized;
  }

  /// Advanced security threat detection
  static bool containsInappropriateContent(String content) {
    final cacheKey = 'inappropriate_${content.hashCode}';
    if (_validationCache.containsKey(cacheKey)) {
      return _validationCache[cacheKey]!;
    }

    final maliciousPatterns = [
      // Script injection
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),

      // SQL injection
      RegExp(
          r'(union|select|insert|delete|update|drop|create|alter|exec|execute)\s+',
          caseSensitive: false),
      RegExp(r'(\;|\|\||&&)', caseSensitive: false),

      // Command injection
      RegExp(r'(\$\(|`|\|)', caseSensitive: false),

      // Path traversal
      RegExp(r'\.\./', caseSensitive: false),
      RegExp(r'\.\.\\\\', caseSensitive: false),

      // Protocol handlers
      RegExp(r'(file|ftp|data|mailto|tel):', caseSensitive: false),

      // Suspicious patterns
      RegExp(r'eval\s*\(', caseSensitive: false),
      RegExp(r'expression\s*\(', caseSensitive: false),
      RegExp(r'@import', caseSensitive: false),
    ];

    bool hasInappropriate = false;
    for (final pattern in maliciousPatterns) {
      if (pattern.hasMatch(content)) {
        hasInappropriate = true;
        break;
      }
    }

    // Cache result
    _cacheValidationResult(cacheKey, hasInappropriate);
    return hasInappropriate;
  }

  /// Enhanced profanity detection with Thai language support
  static bool containsProfanity(String content) {
    final cacheKey = 'profanity_${content.hashCode}';
    if (_validationCache.containsKey(cacheKey)) {
      return _validationCache[cacheKey]!;
    }

    // Basic profanity word list (add more as needed)
    final profanityWords = [
      'damn', 'hell', 'shit', 'fuck', 'bitch', 'ass',
      // Thai profanity words (using transliteration for safety)
      'ai', 'hia', 'kwai', 'sat', 'mon'
    ];

    final lowerContent = content.toLowerCase();
    bool hasProfanity =
        profanityWords.any((word) => lowerContent.contains(word));

    _cacheValidationResult(cacheKey, hasProfanity);
    return hasProfanity;
  }

  // ENHANCED VALIDATION FUNCTIONS

  /// Enhanced quantity validation with business rules
  static ValidationResult validateQuantity(
    dynamic quantity, {
    int minQuantity = 1,
    int maxQuantity = 999999,
    bool allowZero = false,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    final parsed =
        quantity is int ? quantity : int.tryParse(quantity.toString());

    if (parsed == null) {
      errors.add('จำนวนต้องเป็นตัวเลขเท่านั้น');
      return ValidationResult(isValid: false, errors: errors);
    }

    if (!allowZero && parsed <= 0) {
      errors.add('จำนวนต้องมากกว่า 0');
    } else if (allowZero && parsed < 0) {
      errors.add('จำนวนต้องมากกว่าหรือเท่ากับ 0');
    }

    if (parsed < minQuantity) {
      errors.add('จำนวนต้องมากกว่าหรือเท่ากับ $minQuantity');
    }

    if (parsed > maxQuantity) {
      errors.add('จำนวนต้องไม่เกิน $maxQuantity');
    }

    // Add warning for large quantities
    if (parsed > 100) {
      warnings.add('จำนวนสินค้าเยอะ กรุณาตรวจสอบความถูกต้อง');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      value: parsed,
    );
  }

  /// Enhanced eco score validation
  static ValidationResult validateEcoScore(dynamic score) {
    final errors = <String>[];
    final warnings = <String>[];

    final parsed = score is int ? score : int.tryParse(score.toString());

    if (parsed == null) {
      errors.add('คะแนนความยั่งยืนต้องเป็นตัวเลขเท่านั้น');
      return ValidationResult(isValid: false, errors: errors);
    }

    if (parsed < 0) {
      errors.add('คะแนนความยั่งยืนต้องมากกว่าหรือเท่ากับ 0');
    }

    if (parsed > 100) {
      errors.add('คะแนนความยั่งยืนต้องไม่เกิน 100');
    }

    // Add warnings based on score ranges
    if (parsed < 30) {
      warnings.add('คะแนนความยั่งยืนต่ำ ควรปรับปรุงการผลิต');
    } else if (parsed >= 80) {
      warnings.add('คะแนนความยั่งยืนสูง เยี่ยมมาก!');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      value: parsed,
    );
  }

  /// Enhanced price validation with currency support
  static ValidationResult validatePrice(
    String price, {
    double minPrice = 0.01,
    double maxPrice = 1000000.0,
    String currency = 'THB',
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Clean the price string
    final cleanPrice = price.replaceAll(RegExp(r'[,\s]'), '');

    if (cleanPrice.isEmpty) {
      errors.add('ราคาจำเป็นต้องกรอก');
      return ValidationResult(isValid: false, errors: errors);
    }

    final priceRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!priceRegex.hasMatch(cleanPrice)) {
      errors.add('รูปแบบราคาไม่ถูกต้อง (ใช้ทศนิยม 2 ตำแหน่งเท่านั้น)');
      return ValidationResult(isValid: false, errors: errors);
    }

    final numPrice = double.tryParse(cleanPrice);
    if (numPrice == null) {
      errors.add('ราคาต้องเป็นตัวเลขเท่านั้น');
      return ValidationResult(isValid: false, errors: errors);
    }

    if (numPrice < minPrice) {
      errors.add('ราคาต้องมากกว่าหรือเท่ากับ $minPrice บาท');
    }

    if (numPrice > maxPrice) {
      errors.add('ราคาต้องไม่เกิน $maxPrice บาท');
    }

    // Add warnings based on price ranges
    if (numPrice > 50000) {
      warnings.add('ราคาสูง กรุณาตรวจสอบความถูกต้อง');
    } else if (numPrice < 1) {
      warnings.add('ราคาต่ำมาก อาจมีข้อผิดพลาด');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      value: numPrice,
    );
  }

  /// Enhanced image URL validation with security checks
  static ValidationResult validateImageUrl(String url) {
    final errors = <String>[];
    final warnings = <String>[];

    if (url.trim().isEmpty) {
      errors.add('URL รูปภาพจำเป็นต้องกรอก');
      return ValidationResult(isValid: false, errors: errors);
    }

    try {
      final uri = Uri.parse(url);

      // Check scheme
      if (!uri.hasScheme) {
        errors.add('URL ต้องมี protocol (http หรือ https)');
      } else if (uri.scheme != 'http' && uri.scheme != 'https') {
        errors.add('รองรับเฉพาะ HTTP และ HTTPS เท่านั้น');
      }

      // Check authority
      if (!uri.hasAuthority) {
        errors.add('URL ไม่ถูกต้อง');
      }

      // Check file extension
      final lowerUrl = url.toLowerCase();
      final hasValidExtension =
          _allowedImageTypes.any((ext) => lowerUrl.contains('.$ext'));

      if (!hasValidExtension) {
        errors.add('รองรับเฉพาะไฟล์รูปภาพ: ${_allowedImageTypes.join(', ')}');
      }

      // Security checks
      if (containsInappropriateContent(url)) {
        errors.add('URL มีเนื้อหาที่ไม่เหมาะสม');
      }

      // Add warnings
      if (uri.scheme == 'http') {
        warnings.add('ควรใช้ HTTPS เพื่อความปลอดภัย');
      }

      if (url.length > 500) {
        warnings.add('URL ยาวเกินไป อาจทำให้โหลดช้า');
      }
    } catch (e) {
      errors.add('รูปแบบ URL ไม่ถูกต้อง');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      value: url,
    );
  }

  /// Enhanced Thai citizen ID validation
  static ValidationResult validateThaiCitizenId(String id) {
    final errors = <String>[];
    final warnings = <String>[];

    if (id.trim().isEmpty) {
      errors.add('เลขบัตรประชาชนจำเป็นต้องกรอก');
      return ValidationResult(isValid: false, errors: errors);
    }

    // Remove any non-digit characters
    final digits = id.replaceAll(RegExp(r'\D'), '');

    // Must be exactly 13 digits
    if (digits.length != 13) {
      errors.add('เลขบัตรประชาชนต้องมี 13 หลัก');
      return ValidationResult(isValid: false, errors: errors);
    }

    // Calculate checksum using Thai citizen ID algorithm
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(digits[i]) * (13 - i);
    }

    final checkDigit = (11 - (sum % 11)) % 10;
    final isValid = checkDigit == int.parse(digits[12]);

    if (!isValid) {
      errors.add('เลขบัตรประชาชนไม่ถูกต้อง');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      value: digits,
    );
  }

  /// Enhanced email validation with domain checking
  static ValidationResult validateEmail(String email) {
    final errors = <String>[];
    final warnings = <String>[];

    if (email.trim().isEmpty) {
      errors.add('อีเมลจำเป็นต้องกรอก');
      return ValidationResult(isValid: false, errors: errors);
    }

    final cleanEmail = email.trim().toLowerCase();

    // Basic format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(cleanEmail)) {
      errors.add('รูปแบบอีเมลไม่ถูกต้อง');
      return ValidationResult(isValid: false, errors: errors);
    }

    // Security checks
    if (containsInappropriateContent(cleanEmail)) {
      errors.add('อีเมลมีเนื้อหาที่ไม่เหมาะสม');
    }

    // Domain checks
    final domain = cleanEmail.split('@').last;
    final suspiciousDomains = ['tempmail', 'guerrillamail', '10minutemail'];

    if (suspiciousDomains.any((suspicious) => domain.contains(suspicious))) {
      warnings.add('อีเมลอาจเป็นอีเมลชั่วคราว');
    }

    // Common typos check
    final commonDomains = {
      'gmai.com': 'gmail.com',
      'gmial.com': 'gmail.com',
      'hotmial.com': 'hotmail.com',
      'yahooo.com': 'yahoo.com',
    };

    final suggestion = commonDomains[domain];
    if (suggestion != null) {
      warnings.add(
          'คุณหมายถึง ${cleanEmail.replaceAll(domain, suggestion)} หรือไม่?');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      value: cleanEmail,
    );
  }

  /// Enhanced Thai phone number validation
  static ValidationResult validateThaiPhoneNumber(String phone) {
    final errors = <String>[];
    final warnings = <String>[];

    if (phone.trim().isEmpty) {
      errors.add('หมายเลขโทรศัพท์จำเป็นต้องกรอก');
      return ValidationResult(isValid: false, errors: errors);
    }

    // Clean phone number
    final cleanPhone = phone.replaceAll(RegExp(r'[-.\s()]'), '');

    // Remove country code prefixes
    String normalizedPhone = cleanPhone;
    if (normalizedPhone.startsWith('+66')) {
      normalizedPhone = '0${normalizedPhone.substring(3)}';
    } else if (normalizedPhone.startsWith('66')) {
      normalizedPhone = '0${normalizedPhone.substring(2)}';
    }

    // Validate format
    final phoneRegex = RegExp(r'^0[689]\d{8}$');

    if (!phoneRegex.hasMatch(normalizedPhone)) {
      errors.add(
          'รูปแบบหมายเลขโทรศัพท์ไม่ถูกต้อง (ต้องขึ้นต้นด้วย 06, 08, หรือ 09)');
      return ValidationResult(isValid: false, errors: errors);
    }

    // Check for suspicious patterns
    if (RegExp(r'^0(\d)\1{8}$').hasMatch(normalizedPhone)) {
      warnings.add('หมายเลขโทรศัพท์อาจไม่ถูกต้อง (ตัวเลขซ้ำกัน)');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      value: normalizedPhone,
    );
  }

  /// Enhanced password validation with comprehensive security checks
  static ValidationResult validatePassword(String password) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];

    int score = 0;
    String strength = 'very_weak';

    if (password.isEmpty) {
      errors.add('รหัสผ่านจำเป็นต้องกรอก');
      return ValidationResult(isValid: false, errors: errors);
    }

    // Length checks
    if (password.length < 8) {
      errors.add('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
      suggestions.add('เพิ่มความยาวรหัสผ่านให้มากกว่า 8 ตัวอักษร');
    } else {
      score += 1;
      if (password.length >= 12) score += 1;
      if (password.length >= 16) score += 1;
    }

    // Character type checks
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUpper) {
      suggestions.add('เพิ่มตัวอักษรพิมพ์ใหญ่ (A-Z)');
    } else {
      score += 1;
    }

    if (!hasLower) {
      suggestions.add('เพิ่มตัวอักษรพิมพ์เล็ก (a-z)');
    } else {
      score += 1;
    }

    if (!hasNumber) {
      suggestions.add('เพิ่มตัวเลข (0-9)');
    } else {
      score += 1;
    }

    if (!hasSpecial) {
      suggestions.add('เพิ่มอักขระพิเศษ เช่น !@#\$%^&*');
    } else {
      score += 1;
    }

    // Security checks
    final commonPasswords = [
      'password',
      '123456',
      '123456789',
      'qwerty',
      'abc123',
      'password123',
      'admin',
      'letmein',
      'welcome',
      'monkey'
    ];

    if (commonPasswords.contains(password.toLowerCase())) {
      errors.add('รหัสผ่านง่ายเกินไป กรุณาเลือกรหัสผ่านที่ปลอดภัยกว่า');
    }

    // Check for repeated characters
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      warnings.add('รหัสผ่านมีตัวอักษรซ้ำกัน ควรหลีกเลี่ยง');
      score -= 1;
    }

    // Check for sequential characters
    if (RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde|def)')
        .hasMatch(password.toLowerCase())) {
      warnings.add('รหัสผ่านมีลำดับตัวอักษร ควรหลีกเลี่ยง');
      score -= 1;
    }

    // Determine strength
    if (score <= 2) {
      strength = 'very_weak';
    } else if (score <= 4) {
      strength = 'weak';
    } else if (score <= 6) {
      strength = 'medium';
    } else if (score <= 7) {
      strength = 'strong';
    } else {
      strength = 'very_strong';
    }

    final metadata = {
      'score': score,
      'strength': strength,
      'suggestions': suggestions,
      'hasUpper': hasUpper,
      'hasLower': hasLower,
      'hasNumber': hasNumber,
      'hasSpecial': hasSpecial,
    };

    return ValidationResult(
      isValid: errors.isEmpty && score >= 4, // Minimum score for valid password
      errors: errors,
      warnings: warnings,
      value: password,
      metadata: metadata,
    );
  }

  // HELPER METHODS

  /// Cache validation result with size limit
  static void _cacheValidationResult(String key, bool result) {
    if (_validationCache.length >= _maxCacheSize) {
      // Remove oldest entries (simple FIFO)
      final keysToRemove =
          _validationCache.keys.take(_maxCacheSize ~/ 4).toList();
      for (final keyToRemove in keysToRemove) {
        _validationCache.remove(keyToRemove);
      }
    }
    _validationCache[key] = result;
  }

  /// Clear validation cache
  static void clearCache() {
    _validationCache.clear();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _validationCache.length,
      'maxCacheSize': _maxCacheSize,
      'cacheUtilization': _validationCache.length / _maxCacheSize,
    };
  }

  // LEGACY METHODS FOR BACKWARD COMPATIBILITY

  /// Legacy isValidPrice method
  static bool isValidPrice(String price) {
    final result = validatePrice(price);
    return result.isValid;
  }

  /// Legacy isValidQuantity method
  static bool isValidQuantity(dynamic quantity) {
    final result = validateQuantity(quantity);
    return result.isValid;
  }

  /// Legacy isValidEcoScore method
  static bool isValidEcoScore(dynamic score) {
    final result = validateEcoScore(score);
    return result.isValid;
  }

  /// Legacy password validation that returns Map for compatibility
  static Map<String, dynamic> validatePasswordLegacy(String password) {
    final result = validatePassword(password);

    return {
      'isValid': result.isValid,
      'score': result.metadata?['score'] ?? 0,
      'strength': result.metadata?['strength'] ?? 'weak',
      'issues': result.errors,
      'suggestions': result.metadata?['suggestions'] ?? [],
    };
  }

  // ENHANCED VALIDATION METHODS (non-conflicting)

  /// Advanced file size validation
  static ValidationResult validateFileSize(
    int sizeInBytes, {
    int maxSize = 10 * 1024 * 1024, // 10MB default
    String fileType = 'file',
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    if (sizeInBytes <= 0) {
      errors.add('ไฟล์ไม่ถูกต้องหรือไม่มีข้อมูล');
      return ValidationResult(isValid: false, errors: errors);
    }

    if (sizeInBytes > maxSize) {
      final maxSizeMB = (maxSize / (1024 * 1024)).toStringAsFixed(1);
      errors.add('ขนาดไฟล์เกิน $maxSizeMB MB');
    }

    // Warning for large files
    final warningSize = maxSize * 0.8; // 80% of max size
    if (sizeInBytes > warningSize) {
      final sizeMB = (sizeInBytes / (1024 * 1024)).toStringAsFixed(1);
      warnings.add('ไฟล์มีขนาดใหญ่ ($sizeMB MB) อาจทำให้อัปโหลดช้า');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      value: sizeInBytes,
    );
  }

  /// Advanced Thai address validation
  static ValidationResult validateAddressAdvanced(String address) {
    final errors = <String>[];
    final warnings = <String>[];

    if (address.trim().isEmpty) {
      errors.add('ที่อยู่จำเป็นต้องกรอก');
      return ValidationResult(isValid: false, errors: errors);
    }

    final cleanAddress = sanitizeInput(address);

    if (cleanAddress.length < 10) {
      errors.add('ที่อยู่สั้นเกินไป ควรระบุรายละเอียดให้ครบถ้วน');
    }

    if (cleanAddress.length > 500) {
      errors.add('ที่อยู่ยาวเกินไป (สูงสุด 500 ตัวอักษร)');
    }

    // Check for required components (basic heuristic)
    final hasNumber = RegExp(r'\d+').hasMatch(cleanAddress);
    if (!hasNumber) {
      warnings.add('ที่อยู่ควรมีเลขที่บ้าน');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      value: cleanAddress,
    );
  }

  /// Batch validation helper
  static Map<String, ValidationResult> validateBatch(
      Map<String, dynamic> data, Map<String, Function> validators) {
    final results = <String, ValidationResult>{};

    for (final entry in validators.entries) {
      final fieldName = entry.key;
      final validator = entry.value;
      final value = data[fieldName];

      try {
        final result = validator(value);
        if (result is ValidationResult) {
          results[fieldName] = result;
        } else if (result is String?) {
          // Handle legacy string validation results
          results[fieldName] = ValidationResult(
            isValid: result == null,
            errors: result != null ? [result] : [],
            value: value,
          );
        } else {
          results[fieldName] = ValidationResult(
            isValid: false,
            errors: ['รูปแบบผลลัพธ์การตรวจสอบไม่ถูกต้อง'],
          );
        }
      } catch (e) {
        results[fieldName] = ValidationResult(
          isValid: false,
          errors: ['เกิดข้อผิดพลาดในการตรวจสอบ: $e'],
        );
      }
    }

    return results;
  }

  /// Check if all validations in batch are valid
  static bool isBatchValid(Map<String, ValidationResult> results) {
    return results.values.every((result) => result.isValid);
  }

  /// Get all errors from batch validation
  static List<String> getBatchErrors(Map<String, ValidationResult> results) {
    final allErrors = <String>[];
    for (final entry in results.entries) {
      final fieldName = entry.key;
      final result = entry.value;
      for (final error in result.errors) {
        allErrors.add('$fieldName: $error');
      }
    }
    return allErrors;
  }

  static bool isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          !uri.hasAuthority) {
        return false;
      }
      final lowerUrl = url.toLowerCase();
      return lowerUrl.contains('.jpg') ||
          lowerUrl.contains('.jpeg') ||
          lowerUrl.contains('.png') ||
          lowerUrl.contains('.gif') ||
          lowerUrl.contains('.webp');
    } catch (e) {
      return false;
    }
  }

  static bool isValidThaiCitizenId(String id) {
    // Remove any non-digit characters
    final digits = id.replaceAll(RegExp(r'\D'), '');

    // Must be exactly 13 digits
    if (digits.length != 13) return false;

    // Calculate checksum using Thai citizen ID algorithm
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(digits[i]) * (13 - i);
    }

    final checkDigit = (11 - (sum % 11)) % 10;
    return checkDigit == int.parse(digits[12]);
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  static bool isValidThaiPhoneNumber(String phone) {
    final phoneRegex = RegExp(
      r'^((\+66|66|0)[-.\s]?)?[689]\d{8}$',
    );
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[-.\s]'), ''));
  }

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  // Product validation
  static String? validateProductName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'กรุณาระบุชื่อสินค้า';
    }

    final sanitized = sanitizeInput(name);
    if (sanitized.length < 2) {
      return 'ชื่อสินค้าต้องมีอย่างน้อย 2 ตัวอักษร';
    }

    if (sanitized.length > 100) {
      return 'ชื่อสินค้าต้องไม่เกิน 100 ตัวอักษร';
    }

    if (ValidationUtils.containsInappropriateContent(sanitized)) {
      return 'ชื่อสินค้าประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  static String? validateProductDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'กรุณาระบุรายละเอียดสินค้า';
    }

    final sanitized = ValidationUtils.sanitizeInput(description);
    if (sanitized.length < 10) {
      return 'รายละเอียดสินค้าต้องมีอย่างน้อย 10 ตัวอักษร';
    }

    if (sanitized.length > 1000) {
      return 'รายละเอียดสินค้าต้องไม่เกิน 1000 ตัวอักษร';
    }

    if (ValidationUtils.containsInappropriateContent(sanitized)) {
      return 'รายละเอียดสินค้าประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  static String? validateProductPrice(String? price) {
    if (price == null || price.trim().isEmpty) {
      return 'กรุณาระบุราคาสินค้า';
    }

    if (!ValidationUtils.isValidPrice(price.trim())) {
      return 'ราคาสินค้าไม่ถูกต้อง (0.01 - 1,000,000 บาท)';
    }

    return null;
  }

  static String? validateProductStock(String? stock) {
    if (stock == null || stock.trim().isEmpty) {
      return 'กรุณาระบุจำนวนสต็อก';
    }

    final stockNum = int.tryParse(stock.trim());
    if (stockNum == null) {
      return 'จำนวนสต็อกต้องเป็นตัวเลข';
    }

    if (!ValidationUtils.isValidQuantity(stockNum)) {
      return 'จำนวนสต็อกต้องอยู่ระหว่าง 0 - 10,000';
    }

    return null;
  }

  static String? validatePasswordString(String? password) {
    if (password == null || password.isEmpty) {
      return 'กรุณาระบุรหัสผ่าน';
    }

    final validation = ValidationUtils.validatePasswordLegacy(password);
    if (!(validation['isValid'] as bool)) {
      final issues = validation['issues'] as List<String>;
      return issues.first;
    }

    return null;
  }

  static String? validateConfirmPassword(
      String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'กรุณายืนยันรหัสผ่าน';
    }

    if (password != confirmPassword) {
      return 'รหัสผ่านไม่ตรงกัน';
    }

    return null;
  }

  static String? validateDisplayName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'กรุณาระบุชื่อ';
    }

    final sanitized = ValidationUtils.sanitizeInput(name);
    if (sanitized.length < 2) {
      return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
    }

    if (sanitized.length > 50) {
      return 'ชื่อต้องไม่เกิน 50 ตัวอักษร';
    }

    if (ValidationUtils.containsInappropriateContent(sanitized)) {
      return 'ชื่อประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'กรุณาระบุหมายเลขโทรศัพท์';
    }

    if (!ValidationUtils.isValidThaiPhoneNumber(phone.trim())) {
      return 'รูปแบบหมายเลขโทรศัพท์ไม่ถูกต้อง';
    }

    return null;
  }

  // Shop validation
  static String? validateShopName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'กรุณาระบุชื่อร้าน';
    }

    final sanitized = ValidationUtils.sanitizeInput(name);
    if (sanitized.length < 3) {
      return 'ชื่อร้านต้องมีอย่างน้อย 3 ตัวอักษร';
    }

    if (sanitized.length > 80) {
      return 'ชื่อร้านต้องไม่เกิน 80 ตัวอักษร';
    }

    if (ValidationUtils.containsInappropriateContent(sanitized)) {
      return 'ชื่อร้านประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  static String? validateShopDescription(String? description) {
    if (description != null && description.trim().isNotEmpty) {
      final sanitized = ValidationUtils.sanitizeInput(description);
      if (sanitized.length > 500) {
        return 'คำอธิบายร้านต้องไม่เกิน 500 ตัวอักษร';
      }

      if (ValidationUtils.containsInappropriateContent(sanitized)) {
        return 'คำอธิบายร้านประกอบด้วยเนื้อหาไม่เหมาะสม';
      }
    }

    return null;
  }

  static String? validateWebsite(String? website) {
    if (website != null && website.trim().isNotEmpty) {
      if (!ValidationUtils.isValidUrl(website.trim())) {
        return 'รูปแบบ URL เว็บไซต์ไม่ถูกต้อง';
      }
    }

    return null;
  }

  // Review validation
  static String? validateReviewComment(String? comment) {
    if (comment == null || comment.trim().isEmpty) {
      return 'กรุณาเขียนความคิดเห็น';
    }

    final sanitized = ValidationUtils.sanitizeInput(comment);
    if (sanitized.length < 5) {
      return 'ความคิดเห็นต้องมีอย่างน้อย 5 ตัวอักษร';
    }

    if (sanitized.length > 500) {
      return 'ความคิดเห็นต้องไม่เกิน 500 ตัวอักษร';
    }

    if (ValidationUtils.containsInappropriateContent(sanitized)) {
      return 'ความคิดเห็นประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  static String? validateRating(double? rating) {
    if (rating == null) {
      return 'กรุณาให้คะแนน';
    }

    if (rating < 1 || rating > 5) {
      return 'คะแนนต้องอยู่ระหว่าง 1 - 5';
    }

    return null;
  }

  // Investment validation
  static String? validateInvestmentAmount(String? amount) {
    if (amount == null || amount.trim().isEmpty) {
      return 'กรุณาระบุจำนวนเงินลงทุน';
    }

    final amountNum = double.tryParse(amount.trim());
    if (amountNum == null) {
      return 'จำนวนเงินลงทุนต้องเป็นตัวเลข';
    }

    if (amountNum < 100) {
      return 'จำนวนเงินลงทุนขั้นต่ำ 100 บาท';
    }

    if (amountNum > 1000000) {
      return 'จำนวนเงินลงทุนสูงสุด 1,000,000 บาท';
    }

    return null;
  }

  // Activity validation
  static String? validateActivityTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'กรุณาระบุชื่อกิจกรรม';
    }

    final sanitized = ValidationUtils.sanitizeInput(title);
    if (sanitized.length < 5) {
      return 'ชื่อกิจกรรมต้องมีอย่างน้อย 5 ตัวอักษร';
    }

    if (sanitized.length > 100) {
      return 'ชื่อกิจกรรมต้องไม่เกิน 100 ตัวอักษร';
    }

    if (ValidationUtils.containsInappropriateContent(sanitized)) {
      return 'ชื่อกิจกรรมประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  static String? validateActivityDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'กรุณาระบุรายละเอียดกิจกรรม';
    }

    final sanitized = ValidationUtils.sanitizeInput(description);
    if (sanitized.length < 20) {
      return 'รายละเอียดกิจกรรมต้องมีอย่างน้อย 20 ตัวอักษร';
    }

    if (sanitized.length > 1500) {
      return 'รายละเอียดกิจกรรมต้องไม่เกิน 1500 ตัวอักษร';
    }

    if (ValidationUtils.containsInappropriateContent(sanitized)) {
      return 'รายละเอียดกิจกรรมประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  // Generic validation helpers
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณาระบุ$fieldName';
    }
    return null;
  }

  static String? validateLength(
      String? value, int minLength, int maxLength, String fieldName) {
    if (value == null) return null;

    final sanitized = ValidationUtils.sanitizeInput(value);
    if (sanitized.length < minLength) {
      return '$fieldNameต้องมีอย่างน้อย $minLength ตัวอักษร';
    }

    if (sanitized.length > maxLength) {
      return '$fieldNameต้องไม่เกิน $maxLength ตัวอักษร';
    }

    return null;
  }

  static String? validateNumericRange(
      String? value, double min, double max, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณาระบุ$fieldName';
    }

    final numValue = double.tryParse(value.trim());
    if (numValue == null) {
      return '$fieldNameต้องเป็นตัวเลข';
    }

    if (numValue < min || numValue > max) {
      return '$fieldNameต้องอยู่ระหว่าง $min - $max';
    }

    return null;
  }
}
