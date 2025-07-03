// lib/utils/security_utils.dart

import 'dart:convert';
import 'dart:math';

class SecurityUtils {
  // Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  // Validate phone number (Thai format)
  static bool isValidThaiPhoneNumber(String phone) {
    final phoneRegex = RegExp(
      r'^((\+66|66|0)[-.\s]?)?[689]\d{8}$',
    );
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[-.\s]'), ''));
  }

  // Validate password strength
  static Map<String, dynamic> validatePassword(String password) {
    final result = <String, dynamic>{
      'isValid': false,
      'score': 0,
      'issues': <String>[],
      'suggestions': <String>[],
    };

    if (password.length < 8) {
      (result['issues'] as List<String>)
          .add('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
      (result['suggestions'] as List<String>)
          .add('เพิ่มความยาวรหัสผ่านให้มากกว่า 8 ตัวอักษร');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      (result['issues'] as List<String>).add('ควรมีตัวอักษรพิมพ์ใหญ่');
      (result['suggestions'] as List<String>)
          .add('เพิ่มตัวอักษรพิมพ์ใหญ่ (A-Z)');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      (result['issues'] as List<String>).add('ควรมีตัวอักษรพิมพ์เล็ก');
      (result['suggestions'] as List<String>)
          .add('เพิ่มตัวอักษรพิมพ์เล็ก (a-z)');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      (result['issues'] as List<String>).add('ควรมีตัวเลข');
      (result['suggestions'] as List<String>).add('เพิ่มตัวเลข (0-9)');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      (result['issues'] as List<String>).add('ควรมีอักขระพิเศษ');
      (result['suggestions'] as List<String>)
          .add('เพิ่มอักขระพิเศษ (!@#\$%^&*)');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    result['isValid'] = (result['score'] as int) >= 3;
    return result;
  }

  // Sanitize user input
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(
            RegExp(r'[<>&"\x27\x60]'), '') // Remove dangerous characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  // Validate price format
  static bool isValidPrice(String price) {
    final priceRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    final numPrice = double.tryParse(price);
    return priceRegex.hasMatch(price) &&
        numPrice != null &&
        numPrice > 0 &&
        numPrice <= 1000000;
  }

  // Generate secure random string
  static String generateSecureToken(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Validate URL format
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

  // Rate limiting helper
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

  // Clean old rate limit entries
  static void cleanRateLimitMap() {
    final now = DateTime.now();
    _rateLimitMap.removeWhere(
        (key, value) => now.difference(value) > const Duration(hours: 1));
  }

  // Validate Thai citizen ID (for seller verification)
  static bool isValidThaiCitizenId(String id) {
    if (id.length != 13) return false;

    final digits = id.split('').map((e) => int.tryParse(e)).toList();
    if (digits.any((element) => element == null)) return false;

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += digits[i]! * (13 - i);
    }

    final checkDigit = (11 - (sum % 11)) % 10;
    return checkDigit == digits[12];
  }

  // Hash sensitive data (for logging)
  static String hashSensitiveData(String data) {
    final bytes = utf8.encode(data);
    final hash = bytes.fold(0, (prev, element) => prev + element) % 10000;
    return '****${hash.toString().padLeft(4, '0')}';
  }

  // Validate eco score range
  static bool isValidEcoScore(int score) {
    return score >= 1 && score <= 100;
  }

  // Validate product quantity
  static bool isValidQuantity(int quantity) {
    return quantity >= 0 && quantity <= 10000;
  }

  // Check for suspicious activity patterns
  static bool detectSuspiciousActivity({
    required int loginAttempts,
    required Duration timeWindow,
    required List<String> recentIPs,
  }) {
    // Too many login attempts
    if (loginAttempts > 5) return true;

    // Multiple IPs in short time
    if (recentIPs.length > 3 && timeWindow.inMinutes < 30) return true;

    return false;
  }

  // Content moderation - detect inappropriate content
  static bool containsInappropriateContent(String content) {
    final inappropriateWords = [
      'spam', 'scam', 'fake', 'fraud', 'cheat',
      // Add more inappropriate words as needed
    ];

    final lowerContent = content.toLowerCase();
    return inappropriateWords.any((word) => lowerContent.contains(word));
  }

  // Validate image URL
  static bool isValidImageUrl(String url) {
    if (!isValidUrl(url)) return false;

    final supportedExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
    final lowerUrl = url.toLowerCase();

    return supportedExtensions.any((ext) => lowerUrl.contains(ext)) ||
        url.contains('firebase') || // Firebase Storage
        url.contains('cloudinary') || // Cloudinary
        url.contains('imgur'); // Imgur
  }
}
