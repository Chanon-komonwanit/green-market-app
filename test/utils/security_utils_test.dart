import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/utils/security_utils.dart';

void main() {
  group('SecurityUtils', () {
    test('sanitizeInput removes HTML and dangerous chars', () {
      const input = '''<script>alert(1)</script> <b>Test</b> & " \\ \\'`''';
      final sanitized = SecurityUtils.sanitizeInput(input);
      expect(sanitized.contains('<'), false);
      expect(sanitized.contains('>'), false);
      expect(sanitized.contains('&'), false);
      expect(sanitized.contains('"'), false);
      expect(sanitized.contains("'"), false);
      expect(sanitized.contains('`'), false);
    });

    test('containsInappropriateContent detects bad words', () {
      expect(SecurityUtils.containsInappropriateContent('This is spam!'), true);
      expect(SecurityUtils.containsInappropriateContent('Normal text'), false);
    });

    test('isValidEmail returns true for valid email', () {
      expect(SecurityUtils.isValidEmail('test@email.com'), true);
      expect(SecurityUtils.isValidEmail('bad-email'), false);
    });

    test('isValidUrl returns true for valid url', () {
      expect(SecurityUtils.isValidUrl('https://google.com'), true);
      expect(SecurityUtils.isValidUrl('ftp://google.com'), false);
    });

    test('validatePassword checks strength', () {
      final weak = SecurityUtils.validatePassword('abc');
      expect(weak['isValid'], false);
      final strong = SecurityUtils.validatePassword('Abcdefg1!');
      expect(strong['isValid'], true);
    });
  });
}
