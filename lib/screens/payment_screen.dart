import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final Order order;
  const PaymentScreen({required this.order, super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;
  String? _result;

  void _pay() async {
    setState(() => _isProcessing = true);
    try {
      final result = await _paymentService.processPayment(widget.order, {});
      setState(() {
        _isProcessing = false;
        _result = result.success
            ? 'ชำระเงินสำเร็จ'
            : (result.errorMessage ?? 'ชำระเงินล้มเหลว');
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _result = 'เกิดข้อผิดพลาด: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงิน')),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('ยอดชำระ: ${widget.order.total} บาท'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pay,
                    child: const Text('ชำระเงิน'),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    Text(_result!),
                  ]
                ],
              ),
      ),
    );
  }
}
