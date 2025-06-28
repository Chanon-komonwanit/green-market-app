// lib/screens/seller/seller_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/screens/seller/my_products_screen.dart';
import 'package:green_market/screens/seller/seller_orders_screen.dart';
import 'package:green_market/screens/seller/shop_settings_screen.dart'; // Corrected: Already correct
import 'package:green_market/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool _isLoading = true;
  Seller? _seller;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId != null) {
      _loadSellerProfile();
    }
  }

  Future<void> _loadSellerProfile() async {
    if (_currentUserId == null) return;
    setState(() => _isLoading = true);
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final sellerData =
          await firebaseService.getSellerFullDetails(_currentUserId!);
      if (mounted && sellerData != null) {
        setState(() {
          _seller = sellerData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดโปรไฟล์ร้านค้า: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์ร้านค้า'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _seller == null
              ? const Center(child: Text('ไม่พบข้อมูลร้านค้า'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(context, _seller!),
                      const SizedBox(height: 24),
                      _buildProfileOption(
                        context,
                        'จัดการสินค้าของฉัน',
                        Icons.inventory_2_outlined,
                        () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const MyProductsScreen(),
                          ));
                        },
                      ),
                      _buildProfileOption(
                        context,
                        'จัดการคำสั่งซื้อ',
                        Icons.receipt_long_outlined,
                        () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const SellerOrdersScreen(),
                          ));
                        },
                      ),
                      _buildProfileOption(
                        context,
                        'ตั้งค่าร้านค้า',
                        Icons.settings_outlined,
                        () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const ShopSettingsScreen(),
                          ));
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Seller seller) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage:
              seller.shopImageUrl != null && seller.shopImageUrl!.isNotEmpty
                  ? NetworkImage(seller.shopImageUrl!)
                  : null,
          child: seller.shopImageUrl == null || seller.shopImageUrl!.isEmpty
              ? const Icon(Icons.storefront, size: 50)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          seller.shopName,
          style: theme.textTheme.headlineSmall,
        ),
        Text(
          seller.shopDescription ?? 'ไม่มีคำอธิบายร้านค้า',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'เป็นผู้ขายตั้งแต่: ${DateFormat('dd MMMM yyyy', 'th_TH').format(seller.createdAt.toDate())}',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOption(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
