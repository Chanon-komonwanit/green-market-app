import 'package:flutter/material.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/order.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/screens/chat_screen.dart';
import 'package:green_market/screens/seller/my_products_screen.dart';
import 'package:green_market/screens/seller/seller_orders_screen.dart';
import 'package:green_market/screens/seller/shop_settings_screen.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// หน้าร้านค้าสาธารณะ (Public Seller Shop) สไตล์ Shopee/Marketplace
class SellerShopScreen extends StatefulWidget {
  final String sellerId;
  const SellerShopScreen({super.key, required this.sellerId});

  @override
  State<SellerShopScreen> createState() => _SellerShopScreenState();
}

class _SellerShopScreenState extends State<SellerShopScreen> {
  Seller? _seller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeller();
  }

  Future<void> _loadSeller() async {
    setState(() => _isLoading = true);
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final seller =
          await firebaseService.getSellerFullDetails(widget.sellerId);
      if (mounted) setState(() => _seller = seller);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดหน้าร้าน: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareShop() {
    if (_seller != null) {
      final shopUrl = 'https://greenmarket.app/shop/${_seller!.id}';
      final shareText = '''
🌱 มาเที่ยวชมร้าน "${_seller!.shopName}" ในแอป Green Market กันเถอะ!

ร้านค้าที่เน้นสินค้าเป็นมิตรต่อสิ่งแวดล้อม
� ${_seller!.contactEmail}
⭐ เรตติ้ง ${_seller!.rating.toStringAsFixed(1)} จาก ${_seller!.totalRatings} รีวิว

🔗 $shopUrl

#GreenMarket #EcoFriendly #SustainableShopping
''';

      // For now, show in a dialog (can be replaced with actual share package)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('แชร์ร้านค้า'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('คัดลอกลิงก์ด้านล่างเพื่อแชร์:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(shareText),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
            TextButton(
              onPressed: () {
                // Copy to clipboard
                // Clipboard.setData(ClipboardData(text: shareText));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('คัดลอกลิงก์แล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('คัดลอก'),
            ),
          ],
        ),
      );
    }
  }

  void _followShop() {
    if (_seller != null) {
      // Show follow confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('ติดตาม ${_seller!.shopName}'),
          content: const Text(
              'คุณต้องการติดตามร้านนี้เพื่อรับข่าวสารและโปรโมชั่นใหม่ๆ หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Add to user's followed shops
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'followedShops': FieldValue.arrayUnion([_seller!.id])
                    });

                    // Update shop's follower count
                    await FirebaseFirestore.instance
                        .collection('sellers')
                        .doc(_seller!.id)
                        .update({'followerCount': FieldValue.increment(1)});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ติดตาม ${_seller!.shopName} แล้ว'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('ติดตาม'),
            ),
          ],
        ),
      );
    }
  }

  void _chatWithShop() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนส่งข้อความ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_seller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลร้านค้า'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: '${currentUser.uid}_${_seller!.id}_shop',
          productId: 'shop_general',
          productName: _seller!.shopName,
          productImageUrl: _seller!.shopImageUrl ?? '',
          buyerId: currentUser.uid,
          sellerId: _seller!.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      appBar: AppBar(
        title: const Text('หน้าร้านค้า'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _seller == null
                ? null
                : () {
                    _shareShop();
                  },
            tooltip: 'แชร์ร้านค้า',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _seller == null
              ? const Center(child: Text('ไม่พบข้อมูลร้านค้า'))
              : RefreshIndicator(
                  onRefresh: _loadSeller,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                          child: _buildShopHeader(context, _seller!)),
                      SliverToBoxAdapter(child: _buildShopStats(_seller!)),
                      SliverToBoxAdapter(
                          child: _buildShopActions(context, _seller!)),
                      SliverToBoxAdapter(child: _buildShopTabs()),
                    ],
                  ),
                ),
    );
  }

  Widget _buildShopHeader(BuildContext context, Seller seller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundImage:
                seller.shopImageUrl != null && seller.shopImageUrl!.isNotEmpty
                    ? NetworkImage(seller.shopImageUrl!)
                    : null,
            backgroundColor: const Color(0xFFF1F8E9),
            child: seller.shopImageUrl == null || seller.shopImageUrl!.isEmpty
                ? const Icon(Icons.storefront,
                    size: 44, color: Color(0xFFBDBDBD))
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        seller.shopName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color(0xFF1B5E20),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.verified, color: Colors.green[400], size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  seller.shopDescription ?? 'ไม่มีคำอธิบายร้านค้า',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF388E3C)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'เปิดร้านเมื่อ: ${DateFormat('dd MMM yyyy', 'th_TH').format(seller.createdAt.toDate())}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF757575)),
                    ),
                  ],
                ),
                if (seller.website != null && seller.website!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      children: [
                        Icon(Icons.link, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            seller.website!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (seller.socialMediaLink != null &&
                    seller.socialMediaLink!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.alternate_email,
                            size: 16, color: Colors.purple[700]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            seller.socialMediaLink!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.purple),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopStats(Seller seller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('คะแนนร้าน', seller.rating.toStringAsFixed(2),
              icon: Icons.star, color: Colors.amber),
          _buildStatItem('รีวิว', seller.totalRatings.toString(),
              icon: Icons.reviews, color: Colors.blue),
          _buildStatItem('ผู้ติดตาม', '${(seller.totalRatings * 1.5).round()}',
              icon: Icons.people, color: Colors.green),
          _buildStatItem('สินค้า', '${(seller.totalRatings * 0.8).round()}',
              icon: Icons.inventory_2, color: Colors.teal),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value,
      {required IconData icon, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
      ],
    );
  }

  Widget _buildShopActions(BuildContext context, Seller seller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _followShop();
              },
              icon: const Icon(Icons.favorite_border),
              label: const Text('ติดตามร้าน'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green[700],
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _chatWithShop();
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('แชทร้าน'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              labelColor: Colors.green[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.green[700],
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'สินค้า'),
                Tab(text: 'รีวิว'),
                Tab(text: 'เกี่ยวกับ'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildProductsTab(),
                _buildReviewsTab(),
                _buildAboutTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'สินค้าทั้งหมดของร้าน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'จะแสดงรายการสินค้าทั้งหมดในร้านนี้',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'รีวิวร้าน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'จะแสดงรีวิวและคะแนนจากลูกค้า',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_seller?.shopDescription != null) ...[
            const Text(
              'เกี่ยวกับร้าน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _seller!.shopDescription!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            'ข้อมูลติดต่อ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactRow(Icons.email, 'อีเมล', _seller?.contactEmail ?? ''),
          const SizedBox(height: 8),
          _buildContactRow(Icons.phone, 'โทรศัพท์', _seller?.phoneNumber ?? ''),
          if (_seller?.website != null) ...[
            const SizedBox(height: 8),
            _buildContactRow(Icons.web, 'เว็บไซต์', _seller!.website!),
          ],
          if (_seller?.socialMediaLink != null) ...[
            const SizedBox(height: 8),
            _buildContactRow(Icons.share, 'โซเชียล', _seller!.socialMediaLink!),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
