// lib/utils/validation_utils.dart

import 'security_utils.dart';

class ValidationUtils {
  // Product validation
  static String? validateProductName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'กรุณาระบุชื่อสินค้า';
    }

    final sanitized = SecurityUtils.sanitizeInput(name);
    if (sanitized.length < 2) {
      return 'ชื่อสินค้าต้องมีอย่างน้อย 2 ตัวอักษร';
    }

    if (sanitized.length > 100) {
      return 'ชื่อสินค้าต้องไม่เกิน 100 ตัวอักษร';
    }

    if (SecurityUtils.containsInappropriateContent(sanitized)) {
      return 'ชื่อสินค้าประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  static String? validateProductDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'กรุณาระบุรายละเอียดสินค้า';
    }

    final sanitized = SecurityUtils.sanitizeInput(description);
    if (sanitized.length < 10) {
      return 'รายละเอียดสินค้าต้องมีอย่างน้อย 10 ตัวอักษร';
    }

    if (sanitized.length > 1000) {
      return 'รายละเอียดสินค้าต้องไม่เกิน 1000 ตัวอักษร';
    }

    if (SecurityUtils.containsInappropriateContent(sanitized)) {
      return 'รายละเอียดสินค้าประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  static String? validateProductPrice(String? price) {
    if (price == null || price.trim().isEmpty) {
      return 'กรุณาระบุราคาสินค้า';
    }

    if (!SecurityUtils.isValidPrice(price.trim())) {
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

    if (!SecurityUtils.isValidQuantity(stockNum)) {
      return 'จำนวนสต็อกต้องอยู่ระหว่าง 0 - 10,000';
    }

    return null;
  }

  static String? validateEcoScore(String? score) {
    if (score == null || score.trim().isEmpty) {
      return 'กรุณาระบุคะแนนสิ่งแวดล้อม';
    }

    final scoreNum = int.tryParse(score.trim());
    if (scoreNum == null) {
      return 'คะแนนสิ่งแวดล้อมต้องเป็นตัวเลข';
    }

    if (!SecurityUtils.isValidEcoScore(scoreNum)) {
      return 'คะแนนสิ่งแวดล้อมต้องอยู่ระหว่าง 1 - 100';
    }

    return null;
  }

  // User validation
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'กรุณาระบุอีเมล';
    }

    if (!SecurityUtils.isValidEmail(email.trim())) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }

    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'กรุณาระบุรหัสผ่าน';
    }

    final validation = SecurityUtils.validatePassword(password);
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

    final sanitized = SecurityUtils.sanitizeInput(name);
    if (sanitized.length < 2) {
      return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
    }

    if (sanitized.length > 50) {
      return 'ชื่อต้องไม่เกิน 50 ตัวอักษร';
    }

    if (SecurityUtils.containsInappropriateContent(sanitized)) {
      return 'ชื่อประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'กรุณาระบุหมายเลขโทรศัพท์';
    }

    if (!SecurityUtils.isValidThaiPhoneNumber(phone.trim())) {
      return 'รูปแบบหมายเลขโทรศัพท์ไม่ถูกต้อง';
    }

    return null;
  }

  // Shop validation
  static String? validateShopName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'กรุณาระบุชื่อร้าน';
    }

    final sanitized = SecurityUtils.sanitizeInput(name);
    if (sanitized.length < 3) {
      return 'ชื่อร้านต้องมีอย่างน้อย 3 ตัวอักษร';
    }

    if (sanitized.length > 80) {
      return 'ชื่อร้านต้องไม่เกิน 80 ตัวอักษร';
    }

    if (SecurityUtils.containsInappropriateContent(sanitized)) {
      return 'ชื่อร้านประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  static String? validateShopDescription(String? description) {
    if (description != null && description.trim().isNotEmpty) {
      final sanitized = SecurityUtils.sanitizeInput(description);
      if (sanitized.length > 500) {
        return 'คำอธิบายร้านต้องไม่เกิน 500 ตัวอักษร';
      }

      if (SecurityUtils.containsInappropriateContent(sanitized)) {
        return 'คำอธิบายร้านประกอบด้วยเนื้อหาไม่เหมาะสม';
      }
    }

    return null;
  }

  static String? validateWebsite(String? website) {
    if (website != null && website.trim().isNotEmpty) {
      if (!SecurityUtils.isValidUrl(website.trim())) {
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

    final sanitized = SecurityUtils.sanitizeInput(comment);
    if (sanitized.length < 5) {
      return 'ความคิดเห็นต้องมีอย่างน้อย 5 ตัวอักษร';
    }

    if (sanitized.length > 500) {
      return 'ความคิดเห็นต้องไม่เกิน 500 ตัวอักษร';
    }

    if (SecurityUtils.containsInappropriateContent(sanitized)) {
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

    final sanitized = SecurityUtils.sanitizeInput(title);
    if (sanitized.length < 5) {
      return 'ชื่อกิจกรรมต้องมีอย่างน้อย 5 ตัวอักษร';
    }

    if (sanitized.length > 100) {
      return 'ชื่อกิจกรรมต้องไม่เกิน 100 ตัวอักษร';
    }

    if (SecurityUtils.containsInappropriateContent(sanitized)) {
      return 'ชื่อกิจกรรมประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  static String? validateActivityDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'กรุณาระบุรายละเอียดกิจกรรม';
    }

    final sanitized = SecurityUtils.sanitizeInput(description);
    if (sanitized.length < 20) {
      return 'รายละเอียดกิจกรรมต้องมีอย่างน้อย 20 ตัวอักษร';
    }

    if (sanitized.length > 1500) {
      return 'รายละเอียดกิจกรรมต้องไม่เกิน 1500 ตัวอักษร';
    }

    if (SecurityUtils.containsInappropriateContent(sanitized)) {
      return 'รายละเอียดกิจกรรมประกอบด้วยเนื้อหาไม่เหมาะสม';
    }

    return null;
  }

  // Image validation
  static String? validateImageUrl(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      if (!SecurityUtils.isValidImageUrl(url.trim())) {
        return 'รูปแบบ URL รูปภาพไม่ถูกต้อง';
      }
    }

    return null;
  }

  // Thai Citizen ID validation
  static String? validateThaiCitizenId(String? id) {
    if (id == null || id.trim().isEmpty) {
      return 'กรุณาระบุหมายเลขบัตรประชาชน';
    }

    if (!SecurityUtils.isValidThaiCitizenId(id.trim())) {
      return 'หมายเลขบัตรประชาชนไม่ถูกต้อง';
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

    final sanitized = SecurityUtils.sanitizeInput(value);
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
