import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../utils/security_utils.dart';
import '../utils/validation_utils.dart';

/// Enhanced Payment Service with security and scalability features
/// บริการชำระเงินขั้นสูงพร้อมระบบความปลอดภัยและขยายงานได้
class PaymentService {
  static const String _tag = 'PaymentService';

  // Payment status tracking
  final Map<String, PaymentTransaction> _activeTransactions = {};

  /// Process payment with enhanced security and validation
  Future<PaymentResult> processPayment(
      Order order, Map<String, dynamic> paymentData) async {
    final transactionId = _generateTransactionId();

    try {
      // Validate payment data
      final validationResult = _validatePaymentData(paymentData);
      if (!validationResult.isValid) {
        return PaymentResult(
          success: false,
          transactionId: transactionId,
          errorMessage: validationResult.errors.first,
        );
      }

      // Security checks
      final userId = paymentData['userId'] as String?;
      if (userId == null || userId.isEmpty || userId.length < 3) {
        return PaymentResult(
          success: false,
          transactionId: transactionId,
          errorMessage: 'Invalid user authentication',
        );
      }

      // Track transaction
      _activeTransactions[transactionId] = PaymentTransaction(
        id: transactionId,
        orderId: order.id,
        amount: order.totalAmount,
        status: PaymentStatus.processing,
        createdAt: DateTime.now(),
      );

      // Simulate payment processing with proper error handling
      final result =
          await _processPaymentInternal(order, paymentData, transactionId);

      // Update transaction status
      _activeTransactions[transactionId]?.status =
          result.success ? PaymentStatus.completed : PaymentStatus.failed;

      return result;
    } catch (e) {
      debugPrint('[$_tag] Payment processing error: $e');

      // Update failed transaction
      if (_activeTransactions.containsKey(transactionId)) {
        _activeTransactions[transactionId]?.status = PaymentStatus.failed;
      }

      return PaymentResult(
        success: false,
        transactionId: transactionId,
        errorMessage: 'Payment processing failed: ${e.toString()}',
      );
    }
  }

  /// Internal payment processing (ready for payment gateway integration)
  Future<PaymentResult> _processPaymentInternal(
    Order order,
    Map<String, dynamic> paymentData,
    String transactionId,
  ) async {
    try {
      // Payment method specific processing
      final paymentMethod = paymentData['method'] as String?;

      switch (paymentMethod) {
        case 'credit_card':
          return await _processCreditCardPayment(
              order, paymentData, transactionId);
        case 'bank_transfer':
          return await _processBankTransferPayment(
              order, paymentData, transactionId);
        case 'promptpay':
          return await _processPromptPayPayment(
              order, paymentData, transactionId);
        case 'wallet':
          return await _processWalletPayment(order, paymentData, transactionId);
        default:
          throw Exception('Unsupported payment method: $paymentMethod');
      }
    } on TimeoutException {
      return PaymentResult(
        success: false,
        transactionId: transactionId,
        errorMessage: 'Payment timeout. Please try again.',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        transactionId: transactionId,
        errorMessage: e.toString(),
      );
    }
  }

  /// Credit Card Payment Processing (Ready for Omise/Stripe integration)
  Future<PaymentResult> _processCreditCardPayment(
    Order order,
    Map<String, dynamic> paymentData,
    String transactionId,
  ) async {
    // Enhanced validation
    final errors = <String>[];
    _validateCreditCardData(paymentData, errors);
    if (errors.isNotEmpty) {
      return PaymentResult(
        success: false,
        transactionId: transactionId,
        errorMessage: errors.first,
      );
    }

    try {
      // Payment gateway integration ready structure
      // TODO: Replace with actual Omise/Stripe API call
      final gatewayResponse = await _callPaymentGateway({
        'amount': (order.totalAmount * 100).round(), // Convert to cents
        'currency': 'THB',
        'card_token': paymentData['cardToken'],
        'description': 'Green Market Order ${order.id}',
        'metadata': {
          'order_id': order.id,
          'user_id': order.userId,
          'transaction_id': transactionId,
        }
      });

      // Process gateway response
      if (gatewayResponse['status'] == 'successful') {
        return PaymentResult(
          success: true,
          transactionId: transactionId,
          paymentMethod: 'credit_card',
          gatewayTransactionId: gatewayResponse['id'],
          metadata: {
            'processingTime': DateTime.now().toIso8601String(),
            'gateway': 'production_ready',
            'cardBrand': gatewayResponse['card_brand'],
            'lastFourDigits': gatewayResponse['last_four_digits'],
          },
        );
      } else {
        return PaymentResult(
          success: false,
          transactionId: transactionId,
          errorMessage: gatewayResponse['failure_message'] ?? 'Payment failed',
        );
      }
    } catch (e) {
      debugPrint('[$_tag] Credit card payment error: $e');

      return PaymentResult(
        success: false,
        transactionId: transactionId,
        errorMessage: 'Payment processing temporarily unavailable',
      );
    }
  }

  /// Bank Transfer Payment Processing
  Future<PaymentResult> _processBankTransferPayment(
    Order order,
    Map<String, dynamic> paymentData,
    String transactionId,
  ) async {
    await Future.delayed(Duration(seconds: 1));

    return PaymentResult(
      success: true,
      transactionId: transactionId,
      paymentMethod: 'bank_transfer',
      metadata: {
        'bankCode': paymentData['bankCode'],
        'accountNumber': paymentData['accountNumber'],
      },
    );
  }

  /// PromptPay Payment Processing (Ready for SCB Easy integration)
  Future<PaymentResult> _processPromptPayPayment(
    Order order,
    Map<String, dynamic> paymentData,
    String transactionId,
  ) async {
    await Future.delayed(Duration(seconds: 1));

    return PaymentResult(
      success: true,
      transactionId: transactionId,
      paymentMethod: 'promptpay',
      metadata: {
        'promptPayId': paymentData['promptPayId'],
        'qrCode': _generatePromptPayQR(order),
      },
    );
  }

  /// Wallet Payment Processing
  Future<PaymentResult> _processWalletPayment(
    Order order,
    Map<String, dynamic> paymentData,
    String transactionId,
  ) async {
    await Future.delayed(Duration(seconds: 1));

    return PaymentResult(
      success: true,
      transactionId: transactionId,
      paymentMethod: 'wallet',
      metadata: {
        'walletId': paymentData['walletId'],
      },
    );
  }

  /// Validate payment data
  ValidationResult _validatePaymentData(Map<String, dynamic> paymentData) {
    final errors = <String>[];

    if (paymentData.isEmpty) {
      errors.add('Payment data is required');
    }

    final method = paymentData['method'] as String?;
    if (method == null || method.isEmpty) {
      errors.add('Payment method is required');
    }

    final userId = paymentData['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      errors.add('User ID is required');
    }

    // Method-specific validation
    if (method == 'credit_card') {
      _validateCreditCardData(paymentData, errors);
    } else if (method == 'bank_transfer') {
      _validateBankTransferData(paymentData, errors);
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: [],
      value: paymentData,
      metadata: {'validatedAt': DateTime.now().toIso8601String()},
    );
  }

  /// Validate credit card data
  void _validateCreditCardData(Map<String, dynamic> data, List<String> errors) {
    final cardNumber = data['cardNumber'] as String?;
    final expiryDate = data['expiryDate'] as String?;
    final cvv = data['cvv'] as String?;

    if (cardNumber == null || !ValidationUtils.isValidEmail(cardNumber)) {
      errors.add('Invalid card number');
    }

    if (expiryDate == null || expiryDate.length != 5) {
      errors.add('Invalid expiry date format (MM/YY)');
    }

    if (cvv == null || cvv.length < 3 || cvv.length > 4) {
      errors.add('Invalid CVV');
    }
  }

  /// Validate bank transfer data
  void _validateBankTransferData(
      Map<String, dynamic> data, List<String> errors) {
    final bankCode = data['bankCode'] as String?;
    final accountNumber = data['accountNumber'] as String?;

    if (bankCode == null || bankCode.isEmpty) {
      errors.add('Bank code is required');
    }

    if (accountNumber == null || accountNumber.length < 10) {
      errors.add('Invalid account number');
    }
  }

  /// Generate transaction ID
  String _generateTransactionId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'TXN_${timestamp}_${(timestamp % 10000).toString().padLeft(4, '0')}';
  }

  /// Generate PromptPay QR code data
  String _generatePromptPayQR(Order order) {
    // This would generate actual PromptPay QR code data
    // For now, return a placeholder
    return 'promptpay_qr_${order.id}_${order.totalAmount}';
  }

  /// Get transaction status
  PaymentTransaction? getTransaction(String transactionId) {
    return _activeTransactions[transactionId];
  }

  /// Get all active transactions
  List<PaymentTransaction> getActiveTransactions() {
    return _activeTransactions.values.toList();
  }

  /// Clear old transactions (cleanup)
  void clearOldTransactions() {
    final now = DateTime.now();
    _activeTransactions.removeWhere((id, transaction) {
      return now.difference(transaction.createdAt).inHours > 24;
    });
  }

  /// Simulated payment gateway call (replace with actual gateway)
  Future<Map<String, dynamic>> _callPaymentGateway(
      Map<String, dynamic> paymentData) async {
    // Simulate network call
    await Future.delayed(Duration(seconds: 2));

    // Simulate different responses for testing
    final amount = paymentData['amount'] as int;

    if (amount > 10000000) {
      // Amounts over 100,000 THB fail
      return {
        'status': 'failed',
        'failure_message': 'Transaction amount exceeds limit',
      };
    }

    // Simulate success
    return {
      'id': 'chrg_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'successful',
      'card_brand': 'visa',
      'last_four_digits': '4242',
      'amount': amount,
      'currency': paymentData['currency'],
    };
  }
}

/// Payment Result Model
class PaymentResult {
  final bool success;
  final String transactionId;
  final String? paymentMethod;
  final String? errorMessage;
  final String? gatewayTransactionId;
  final Map<String, dynamic>? metadata;

  PaymentResult({
    required this.success,
    required this.transactionId,
    this.paymentMethod,
    this.errorMessage,
    this.gatewayTransactionId,
    this.metadata,
  });
}

/// Payment Transaction Model
class PaymentTransaction {
  final String id;
  final String orderId;
  final double amount;
  PaymentStatus status;
  final DateTime createdAt;
  DateTime? completedAt;

  PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });
}

/// Payment Status Enum
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}
