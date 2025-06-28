// lib/screens/investment_project/my_investments_screen.dart
import 'package:flutter/material.dart';

class MyInvestmentsScreen extends StatelessWidget {
  const MyInvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การลงทุนของฉัน'),
      ),
      body: const Center(
        child: Text('หน้านี้จะแสดงรายการการลงทุนของคุณ'),
      ),
    );
  }
}
