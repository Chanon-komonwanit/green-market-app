import 'package:flutter/material.dart';

class SellerApplicationFormScreen extends StatelessWidget {
  const SellerApplicationFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครเป็นผู้ขาย')),
      body: const Center(child: Text('Seller Application Form')),
    );
  }
}
