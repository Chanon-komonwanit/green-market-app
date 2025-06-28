import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:green_market/screens/admin/admin_product_detail_screen.dart';

class AdminPendingProductsScreen extends StatefulWidget {
  const AdminPendingProductsScreen({super.key});

  @override
  State<AdminPendingProductsScreen> createState() =>
      _AdminPendingProductsScreenState();
}

class _AdminPendingProductsScreenState
    extends State<AdminPendingProductsScreen> {
  // Callback to refresh the list after approval/rejection
  void _refreshList() {
    // This triggers a rebuild of the StreamBuilder by calling setState
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('สินค้าที่รอการอนุมัติ'),
      ),
      body: StreamBuilder<List<Product>>(
        stream: firebaseService.getPendingApprovalProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error fetching pending products: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'เกิดข้อผิดพลาดในการโหลดข้อมูล\nกรุณาตรวจสอบ Console เพื่อดูลิงก์สำหรับสร้าง Index ใน Firestore\nError: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'ไม่มีสินค้าที่รอการอนุมัติในขณะนี้',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductListItem(context, product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductListItem(BuildContext context, Product product) {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminProductDetailScreen(
                product: product,
                onApprovedOrRejected: _refreshList, // Pass the callback
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: _buildProductImage(product.imageUrls.isNotEmpty
                      ? product.imageUrls.first
                      : ''),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(product.price),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (product.createdAt != null)
                      Text(
                        'ส่งเมื่อ: ${dateFormat.format(product.createdAt!.toDate())}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    final bool isValidUrl =
        imageUrl.isNotEmpty && (imageUrl.startsWith('http'));

    if (isValidUrl) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
  }
}
