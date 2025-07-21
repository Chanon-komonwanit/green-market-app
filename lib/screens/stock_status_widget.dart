import 'package:flutter/material.dart';
import '../services/stock_service.dart';

class StockStatusWidget extends StatelessWidget {
  final String productId;
  final StockService _stockService = StockService();

  StockStatusWidget({required this.productId, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _stockService.getStock(productId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('กำลังโหลดสต็อก...');
        }
        final stock = snapshot.data!;
        if (stock <= 0) {
          return const Text('สินค้าหมด', style: TextStyle(color: Colors.red));
        }
        return Text('คงเหลือ $stock ชิ้น',
            style: const TextStyle(color: Colors.green));
      },
    );
  }
}
