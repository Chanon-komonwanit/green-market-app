import 'package:flutter/material.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/screens/seller/my_products_screen.dart';
import 'package:green_market/screens/seller/seller_orders_screen.dart';
import 'package:green_market/screens/seller/shop_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

/// หน้าร้านค้าสาธารณะ (Public Seller Shop) สไตล์ Shopee/Marketplace
class SellerShopScreen extends StatefulWidget {
  final String sellerId;
  const SellerShopScreen({Key? key, required this.sellerId}) : super(key: key);

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
                    // TODO: Share shop link
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
                      // TODO: Add product list, reviews, promotions, etc.
                      SliverToBoxAdapter(child: _buildShopTabs(context)),
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
            child: seller.shopImageUrl == null || seller.shopImageUrl!.isEmpty
                ? const Icon(Icons.storefront,
                    size: 44, color: Color(0xFFBDBDBD))
                : null,
            backgroundColor: const Color(0xFFF1F8E9),
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
    // TODO: Replace with real stats from backend
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('คะแนนร้าน', seller.rating.toStringAsFixed(2),
              icon: Icons.star, color: Colors.amber),
          _buildStatItem('รีวิว', seller.totalRatings.toString(),
              icon: Icons.reviews, color: Colors.blue),
          _buildStatItem('ผู้ติดตาม', '123',
              icon: Icons.people, color: Colors.green),
          _buildStatItem('สินค้า', '0',
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
                // TODO: Follow shop
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
                // TODO: Chat with shop
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

  Widget _buildShopTabs(BuildContext context) {
    // TODO: Implement tabbed view for: สินค้าทั้งหมด, รีวิวร้าน, เกี่ยวกับร้าน, โปรโมชั่น ฯลฯ
    return Padding(
      padding: const EdgeInsets.only(top: 18.0),
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TabBar(
                labelColor: Color(0xFF2E7D32),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF2E7D32),
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'หน้าร้าน', icon: Icon(Icons.storefront)),
                  Tab(text: 'สินค้า', icon: Icon(Icons.inventory_2)),
                  Tab(text: 'รีวิว', icon: Icon(Icons.reviews)),
                  Tab(text: 'เกี่ยวกับร้าน', icon: Icon(Icons.info_outline)),
                ],
              ),
            ),
            SizedBox(
              height: 500, // TODO: Make dynamic
              child: const TabBarView(
                children: [
                  Center(
                      child: Text(
                          'หน้าร้าน (แบนเนอร์, โปรโมชั่น, สินค้าแนะนำ ฯลฯ)')),
                  Center(
                      child:
                          Text('สินค้าทั้งหมดของร้าน')), // TODO: Product list
                  Center(child: Text('รีวิวร้าน')), // TODO: Reviews
                  Center(child: Text('ข้อมูลเกี่ยวกับร้าน')), // TODO: About
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
