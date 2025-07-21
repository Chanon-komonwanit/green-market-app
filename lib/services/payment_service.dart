import '../models/order.dart';

class PaymentService {
  Future<bool> processPayment(
      Order order, Map<String, dynamic> paymentData) async {
    // TODO: Integrate with payment gateway
    await Future.delayed(Duration(seconds: 2));
    return true;
  }
}
