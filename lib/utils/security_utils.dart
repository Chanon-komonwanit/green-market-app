// lib/utils/security_utils.dart

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Class to track login attempts per email
class LoginAttemptInfo {
  int attempts = 0;
  DateTime? lastAttempt;
  DateTime? lockoutUntil;

  bool get isLockedOut {
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil!);
  }

  void recordFailedAttempt() {
    attempts++;
    lastAttempt = DateTime.now();

    if (attempts >= 5) {
      // Max 5 attempts
      lockoutUntil = DateTime.now().add(Duration(minutes: 30));
    }
  }

  void reset() {
    attempts = 0;
    lastAttempt = null;
    lockoutUntil = null;
  }
}

/// Security utilities for Green Market application
/// Provides validation, sanitization, and security checks
class SecurityUtils {
  static final Map<String, LoginAttemptInfo> _loginAttempts = {};

  /// Check if email is temporarily locked out due to failed login attempts
  static bool isEmailLockedOut(String email) {
    final info = _loginAttempts[email.toLowerCase()];
    return info?.isLockedOut ?? false;
  }

  /// Record a failed login attempt
  static void recordFailedLogin(String email) {
    final emailKey = email.toLowerCase();
    _loginAttempts[emailKey] ??= LoginAttemptInfo();
    _loginAttempts[emailKey]!.recordFailedAttempt();
  }

  /// Record a successful login (resets failed attempts)
  static void recordSuccessfulLogin(String email) {
    final emailKey = email.toLowerCase();
    _loginAttempts[emailKey]?.reset();
  }

  /// Get remaining lockout time in minutes
  static int getRemainingLockoutMinutes(String email) {
    final info = _loginAttempts[email.toLowerCase()];
    if (info?.lockoutUntil == null) return 0;

    final remaining = info!.lockoutUntil!.difference(DateTime.now()).inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// Validate email format with enhanced security checks
  static Map<String, dynamic> validateEmail(String email) {
    final result = {
      'isValid': false,
      'issues': <String>[],
      'securityScore': 0,
    };

    final trimmedEmail = email.trim().toLowerCase();

    // Basic format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmedEmail)) {
      (result['issues'] as List<String>).add('รูปแบบอีเมลไม่ถูกต้อง');
      return result;
    }

    // Check for suspicious patterns
    if (trimmedEmail.contains('..') ||
        trimmedEmail.startsWith('.') ||
        trimmedEmail.endsWith('.')) {
      (result['issues'] as List<String>).add('อีเมลมีรูปแบบที่น่าสงสัย');
      return result;
    }

    // Check for disposable email domains
    final disposableDomains = [
      '10minutemail.com',
      'tempmail.org',
      'guerrillamail.com',
      'mailinator.com',
      'yopmail.com',
      'throwaway.email'
    ];

    final domain = trimmedEmail.split('@').last;
    if (disposableDomains.contains(domain)) {
      (result['issues'] as List<String>).add('ไม่อนุญาตให้ใช้อีเมลชั่วคราว');
      return result;
    }

    result['isValid'] = true;
    result['securityScore'] = 100;
    return result;
  }

  /// Validate Thai phone number with enhanced patterns
  static Map<String, dynamic> validateThaiPhoneNumber(String phone) {
    final result = {
      'isValid': false,
      'issues': <String>[],
      'formattedNumber': '',
    };

    final cleanPhone = phone.replaceAll(RegExp(r'[-.\s()]+'), '');

    // Thai mobile patterns
    final mobilePatterns = [
      RegExp(r'^(\+66|66|0)([689]\d{8})$'), // Standard mobile
      RegExp(r'^(\+66|66|0)(2\d{7})$'), // Bangkok landline
      RegExp(r'^(\+66|66|0)([3-7]\d{7})$'), // Provincial landline
    ];

    bool isValid = false;
    String formattedNumber = '';

    for (final pattern in mobilePatterns) {
      final match = pattern.firstMatch(cleanPhone);
      if (match != null) {
        isValid = true;
        // Format as +66XXXXXXXXX
        final countryCode = '+66';
        final number = match.group(2)!;
        formattedNumber = '$countryCode$number';
        break;
      }
    }

    if (!isValid) {
      (result['issues'] as List<String>).add('รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง');
    } else {
      result['formattedNumber'] = formattedNumber;
    }

    result['isValid'] = isValid;
    return result;
  }

  /// Enhanced password validation with comprehensive security checks
  static Map<String, dynamic> validatePassword(String password) {
    final result = <String, dynamic>{
      'isValid': false,
      'score': 0,
      'strength': 'weak',
      'issues': <String>[],
      'suggestions': <String>[],
    };

    // Length check
    if (password.length < 8) {
      (result['issues'] as List<String>)
          .add('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
      (result['suggestions'] as List<String>)
          .add('เพิ่มความยาวรหัสผ่านให้มากกว่า 8 ตัวอักษร');
    } else {
      result['score'] = (result['score'] as int) + 1;
      if (password.length >= 12) {
        result['score'] =
            (result['score'] as int) + 1; // Bonus for longer passwords
      }
    }

    // Uppercase check
    if (!password.contains(RegExp(r'[A-Z]'))) {
      (result['issues'] as List<String>).add('ควรมีตัวอักษรพิมพ์ใหญ่');
      (result['suggestions'] as List<String>)
          .add('เพิ่มตัวอักษรพิมพ์ใหญ่ (A-Z)');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    // Lowercase check
    if (!password.contains(RegExp(r'[a-z]'))) {
      (result['issues'] as List<String>).add('ควรมีตัวอักษรพิมพ์เล็ก');
      (result['suggestions'] as List<String>)
          .add('เพิ่มตัวอักษรพิมพ์เล็ก (a-z)');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    // Number check
    if (!password.contains(RegExp(r'[0-9]'))) {
      (result['issues'] as List<String>).add('ควรมีตัวเลข');
      (result['suggestions'] as List<String>).add('เพิ่มตัวเลข (0-9)');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    // Special character check
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      (result['issues'] as List<String>).add('ควรมีอักขระพิเศษ');
      (result['suggestions'] as List<String>)
          .add('เพิ่มอักขระพิเศษ (!@#\$%^&*)');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    // Check for common weak patterns
    final weakPatterns = [
      RegExp(r'(.)\1{2,}'), // Repeated characters
      RegExp(r'(012|123|234|345|456|567|678|789|890)'), // Sequential numbers
      RegExp(
          r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)',
          caseSensitive: false), // Sequential letters
    ];

    bool hasWeakPattern = false;
    for (final pattern in weakPatterns) {
      if (pattern.hasMatch(password)) {
        hasWeakPattern = true;
        break;
      }
    }

    if (hasWeakPattern) {
      (result['issues'] as List<String>)
          .add('หลีกเลี่ยงการใช้ตัวอักษรหรือตัวเลขต่อเนื่องกัน');
      (result['suggestions'] as List<String>)
          .add('ใช้รหัสผ่านที่ซับซ้อนและไม่มีรูปแบบที่คาดเดาได้');
    }

    // Check for common passwords
    final commonPasswords = [
      'password',
      '12345678',
      'qwerty123',
      'admin123',
      'password123',
      'welcome123',
      'thailand',
      'bangkok'
    ];

    if (commonPasswords.contains(password.toLowerCase())) {
      (result['issues'] as List<String>)
          .add('รหัสผ่านนี้ใช้กันทั่วไปและไม่ปลอดภัย');
      (result['suggestions'] as List<String>)
          .add('เลือกรหัสผ่านที่ไม่เป็นที่รู้จักทั่วไป');
      result['score'] = 0; // Reset score for common passwords
    }

    // Determine strength and validity
    final score = result['score'] as int;
    if (score >= 5) {
      result['strength'] = 'strong';
      result['isValid'] = true;
    } else if (score >= 3) {
      result['strength'] = 'medium';
      result['isValid'] = true;
    } else {
      result['strength'] = 'weak';
    }

    return result;
  }

  /// Sanitize user input to prevent XSS and injection attacks
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(
            RegExp(r'[<>&"\x27\x60]'), '') // Remove dangerous characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Validate price format with reasonable limits
  static bool isValidPrice(String price) {
    final priceRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    final numPrice = double.tryParse(price);
    return priceRegex.hasMatch(price) &&
        numPrice != null &&
        numPrice > 0 &&
        numPrice <= 1000000;
  }

  /// Generate cryptographically secure random string
  static String generateSecureToken(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Validate URL format with security checks
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

  /// Rate limiting helper to prevent spam/abuse
  static final Map<String, DateTime> _rateLimitMap = {};

  static bool checkRateLimit(String identifier, Duration duration) {
    final now = DateTime.now();
    final lastRequest = _rateLimitMap[identifier];

    if (lastRequest == null || now.difference(lastRequest) > duration) {
      _rateLimitMap[identifier] = now;
      return true;
    }
    return false;
  }

  /// Hash password with salt for secure storage
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate random salt for password hashing
  static String generateSalt() {
    return generateSecureToken(32);
  }

  /// Verify password against hash
  static bool verifyPassword(String password, String hash, String salt) {
    final computedHash = hashPassword(password, salt);
    return computedHash == hash;
  }

  /// Check if string contains potentially dangerous content
  static bool containsMaliciousContent(String content) {
    final maliciousPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'sql.*?(union|select|insert|delete|update|drop)',
          caseSensitive: false),
    ];

    for (final pattern in maliciousPatterns) {
      if (pattern.hasMatch(content)) {
        return true;
      }
    }
    return false;
  }

  /// Validate product name for security and quality
  static Map<String, dynamic> validateProductName(String name) {
    final result = {
      'isValid': false,
      'issues': <String>[],
    };

    final sanitized = sanitizeInput(name);

    if (sanitized.length < 3) {
      (result['issues'] as List<String>)
          .add('ชื่อสินค้าต้องมีอย่างน้อย 3 ตัวอักษร');
    }

    if (sanitized.length > 100) {
      (result['issues'] as List<String>)
          .add('ชื่อสินค้าต้องไม่เกิน 100 ตัวอักษร');
    }

    if (containsMaliciousContent(sanitized)) {
      (result['issues'] as List<String>)
          .add('ชื่อสินค้ามีเนื้อหาที่ไม่เหมาะสม');
    }

    result['isValid'] = (result['issues'] as List<String>).isEmpty;
    return result;
  }

  /// Clean up old rate limit entries to prevent memory leaks
  static void cleanupRateLimitMap() {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(hours: 24));

    _rateLimitMap.removeWhere((key, value) => value.isBefore(cutoff));
  }

  /// Enhanced security audit log entry
  static Future<void> logSecurityEvent(String event, String details,
      {String? userId}) async {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = {
      'timestamp': timestamp,
      'event': event,
      'details': details,
      'userId': userId,
      'severity': _getEventSeverity(event),
    };

    // Console logging for development
    print(
        'SECURITY_AUDIT: $timestamp - $event - $details ${userId != null ? '(User: $userId)' : ''}');

    // Enhanced: Firebase logging for production monitoring
    try {
      // In production, send to Firebase for monitoring
      // await FirebaseFirestore.instance.collection('security_audit').add(logEntry);

      // For now, store locally or send to monitoring service
      _securityEventQueue.add(logEntry);

      // Process queue if it gets too large
      if (_securityEventQueue.length > 100) {
        await _flushSecurityEvents();
      }
    } catch (e) {
      print('WARNING: Failed to log security event: $e');
    }
  }

  static final List<Map<String, dynamic>> _securityEventQueue = [];

  /// Get severity level for security events
  static String _getEventSeverity(String event) {
    if (event.contains('FAILED_LOGIN') || event.contains('BRUTE_FORCE')) {
      return 'HIGH';
    } else if (event.contains('SUSPICIOUS') || event.contains('RATE_LIMIT')) {
      return 'MEDIUM';
    }
    return 'LOW';
  }

  /// Flush security events to monitoring system
  static Future<void> _flushSecurityEvents() async {
    if (_securityEventQueue.isEmpty) return;

    try {
      // In production: send batch to Firebase or monitoring service
      // await FirebaseFirestore.instance.collection('security_audit').add({
      //   'events': _securityEventQueue,
      //   'batch_timestamp': FieldValue.serverTimestamp(),
      // });

      print('SECURITY: Flushed ${_securityEventQueue.length} security events');
      _securityEventQueue.clear();
    } catch (e) {
      print('ERROR: Failed to flush security events: $e');
    }
  }

  /// Validate session token format
  static bool isValidSessionToken(String token) {
    return token.length >= 20 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(token);
  }

  /// Performance and memory management for security utils
  static void clearSecurityCaches() {
    _rateLimitMap.clear();
    // Clear any other static caches if needed
  }

  /// Additional validation methods for backwards compatibility
  static bool containsInappropriateContent(String content) {
    return containsMaliciousContent(content);
  }

  static bool isValidQuantity(String quantity) {
    final parsed = int.tryParse(quantity);
    return parsed != null && parsed >= 0 && parsed <= 999999;
  }

  static bool isValidEcoScore(String score) {
    final parsed = int.tryParse(score);
    return parsed != null && parsed >= 0 && parsed <= 100;
  }

  static bool isValidImageUrl(String url) {
    if (!isValidUrl(url)) return false;
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.jpeg') ||
        lowerUrl.contains('.png') ||
        lowerUrl.contains('.gif') ||
        lowerUrl.contains('.webp');
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

  /// Backwards compatibility wrappers
  static bool isValidEmail(String email) {
    final result = validateEmail(email);
    return result['isValid'] as bool;
  }

  static bool isValidThaiPhoneNumber(String phone) {
    final result = validateThaiPhoneNumber(phone);
    return result['isValid'] as bool;
  }
}
