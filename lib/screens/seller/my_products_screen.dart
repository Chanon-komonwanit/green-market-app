// lib/screens/seller/my_products_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/screens/seller/edit_product_seller_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/screens/product_detail_screen.dart'; // For viewing product
// For editing product

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('สินค้าของฉัน',
              style: AppTextStyles.title.copyWith(color: AppColors.white)),
          backgroundColor: AppColors.primaryTeal,
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        body: const Center(child: Text('กรุณาเข้าสู่ระบบเพื่อดูสินค้าของคุณ')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('สินค้าของฉัน',
            style: AppTextStyles.title
                .copyWith(color: AppColors.white, fontSize: 20)),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: StreamBuilder<List<Product>>(
        stream: firebaseService.getProductsBySeller(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: AppTextStyles.body));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('คุณยังไม่มีสินค้าที่ลงขาย',
                    style: AppTextStyles.body));
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: product.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            product.imageUrls[0],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image,
                                    size: 60, color: AppColors.lightModernGrey),
                          ),
                        )
                      : const Icon(Icons.image_not_supported,
                          size: 60, color: AppColors.lightModernGrey),
                  title: Text(product.name,
                      style: AppTextStyles.bodyBold
                          .copyWith(color: AppColors.modernDarkGrey)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ราคา: ฿${product.price.toStringAsFixed(2)}',
                          style: AppTextStyles.body.copyWith(fontSize: 14)),
                      Text('Eco Score: ${product.ecoScore}%',
                          style: AppTextStyles.body.copyWith(fontSize: 14)),
                      Text(
                        'สถานะ: ${product.isApproved ? "อนุมัติแล้ว" : "รอการอนุมัติ"}',
                        style: AppTextStyles.caption.copyWith(
                          color: product.isApproved
                              ? AppColors.successGreen
                              : AppColors.warningYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.primaryTeal),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EditProductSellerScreen(product: product)));
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(product: product)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
