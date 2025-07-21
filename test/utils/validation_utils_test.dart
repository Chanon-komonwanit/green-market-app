import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/utils/validation_utils.dart';

void main() {
  group('ValidationUtils', () {
    test('validateProductName returns error for short/empty/inappropriate', () {
      expect(ValidationUtils.validateProductName(''), isNotNull);
      expect(ValidationUtils.validateProductName('A'), isNotNull);
      expect(ValidationUtils.validateProductName('spam'), isNotNull);
      expect(ValidationUtils.validateProductName('Valid Name'), null);
    });

    test(
        'validateProductDescription returns error for short/empty/inappropriate',
        () {
      expect(ValidationUtils.validateProductDescription(''), isNotNull);
      expect(ValidationUtils.validateProductDescription('short'), isNotNull);
      expect(ValidationUtils.validateProductDescription('scam'), isNotNull);
      expect(
          ValidationUtils.validateProductDescription(
              'This is a valid product description.'),
          null);
    });

    test('validateProductPrice returns error for invalid price', () {
      expect(ValidationUtils.validateProductPrice(''), isNotNull);
      expect(ValidationUtils.validateProductPrice('abc'), isNotNull);
      expect(ValidationUtils.validateProductPrice('0'), isNotNull);
      expect(ValidationUtils.validateProductPrice('100.00'), null);
    });

    test('validateEcoScore returns error for out of range', () {
      expect(ValidationUtils.validateEcoScore(''), isNotNull);
      expect(ValidationUtils.validateEcoScore('0'), isNotNull);
      expect(ValidationUtils.validateEcoScore('101'), isNotNull);
      expect(ValidationUtils.validateEcoScore('50'), null);
    });

    test('validateProductStock returns error for out of range', () {
      expect(ValidationUtils.validateProductStock(''), isNotNull);
      expect(ValidationUtils.validateProductStock('-1'), isNotNull);
      expect(ValidationUtils.validateProductStock('10001'), isNotNull);
      expect(ValidationUtils.validateProductStock('100'), null);
    });

    test('validateEmail returns error for invalid email', () {
      expect(ValidationUtils.validateEmail(''), isNotNull);
      expect(ValidationUtils.validateEmail('bad-email'), isNotNull);
      expect(ValidationUtils.validateEmail('test@email.com'), null);
    });

    test('validatePassword returns error for weak password', () {
      expect(ValidationUtils.validatePassword('abc'), isNotNull);
      expect(ValidationUtils.validatePassword('Abcdefg1!'), null);
    });
  });
}
