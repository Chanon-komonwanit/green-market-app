import 'package:flutter/material.dart';
import '../services/flash_sale_service.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class FlashSaleScreen extends StatelessWidget {
  final _flashSaleService = FlashSaleService();

  FlashSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flash Sale')),
      body: StreamBuilder<List<Product>>(
        stream: _flashSaleService.getActiveFlashSales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีสินค้า Flash Sale'));
          }
          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: product.imageUrl != null
                    ? Image.network(product.imageUrl!,
                        width: 48, height: 48, fit: BoxFit.cover)
                    : const Icon(Icons.image),
                title: Text(product.name),
                subtitle: Text('${product.price} บาท'),
                trailing: _buildCountdown(product.flashSaleEndTime),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCountdown(DateTime? endTime) {
    if (endTime == null) return const SizedBox();
    final remaining = endTime.difference(DateTime.now());
    if (remaining.isNegative) return const Text('หมดเวลา');
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    return Text('เหลือ $hours:$minutes:$seconds');
  }
}
