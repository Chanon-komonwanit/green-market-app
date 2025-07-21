import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../models/product.dart';
import '../models/seller.dart';
import '../services/firebase_service.dart';
import '../widgets/product_card.dart';

class SellerShopScreen extends StatefulWidget {
  final String sellerId;
  const SellerShopScreen({super.key, required this.sellerId});

  @override
  State<SellerShopScreen> createState() => _SellerShopScreenState();
}

class _SellerShopScreenState extends State<SellerShopScreen> {
  // ...existing state variables, services, etc...
  String shopName = "Shop Name"; // Placeholder
  var _shopDetails; // Placeholder for shop details

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shopName,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontSize: 22, color: Colors.teal[900])),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.teal),
            onPressed: () {
              // ...existing code...
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_shopDetails != null) _buildShopHeaderTemplate(_shopDetails!),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: StreamBuilder<List<Promotion>>(
                  stream: FirebaseService().getPromotions(),
                  builder: (context, promoSnapshot) {
                    if (promoSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!promoSnapshot.hasData || promoSnapshot.data!.isEmpty) {
                      return const Text('ร้านค้านี้ยังไม่มีโปรโมชั่น');
                    }
                    final promotions = promoSnapshot.data!
                        .where((promo) => promo.sellerId == widget.sellerId)
                        .toList();
                    if (promotions.isEmpty) {
                      return const Text('ร้านค้านี้ยังไม่มีโปรโมชั่น');
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('โปรโมชั่น/ส่วนลด',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        ...promotions.map((promo) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: promo.imageUrl.isNotEmpty
                                    ? Image.network(promo.imageUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover)
                                    : null,
                                title: Text(promo.title),
                                subtitle: Text(promo.description),
                                trailing: promo.discountType == 'percentage'
                                    ? Chip(
                                        label:
                                            Text('ลด ${promo.discountValue}%'),
                                        backgroundColor: Colors.green[100])
                                    : Chip(
                                        label: Text(
                                            'ลด ${promo.discountValue} บาท'),
                                        backgroundColor: Colors.blue[100]),
                              ),
                            ))
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: FutureBuilder<List<Product>>(
                  future: FirebaseService()
                      .getFeaturedProductsBySeller(widget.sellerId),
                  builder: (context, featuredSnapshot) {
                    if (featuredSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!featuredSnapshot.hasData ||
                        featuredSnapshot.data!.isEmpty) {
                      return const Text('ยังไม่มีสินค้าแนะนำ');
                    }
                    final featuredProducts = featuredSnapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('สินค้าแนะนำ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(
                          height: 180,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: featuredProducts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final product = featuredProducts[index];
                              return ProductCard(product: product);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: FutureBuilder<Map<String, dynamic>>(
                  future:
                      FirebaseService().getShopReviewSummary(widget.sellerId),
                  builder: (context, reviewSnapshot) {
                    if (reviewSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!reviewSnapshot.hasData) {
                      return const Text('ยังไม่มีรีวิวร้านค้า');
                    }
                    final reviewSummary = reviewSnapshot.data!;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.reviews,
                            color: Colors.teal, size: 32),
                        title: Text(
                            'คะแนนรีวิว ${(reviewSummary['rating'] as double?)?.toStringAsFixed(1) ?? "-"}'),
                        subtitle:
                            Text('รีวิวทั้งหมด ${reviewSummary['count'] ?? 0}'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // ...existing code...
            ],
          ),
        ),
      ),
    );
  }
}

enum ShopTemplate {
  ecoFriendly,
  environmentSolution,
  smart,
  vintage,
  fun,
  minimal,
  modernLuxury,
  natureFresh,
  urbanMinimal,
  festival,
  techStartup,
}

final Map<ShopTemplate, String> shopTemplateNames = {
  ShopTemplate.ecoFriendly: 'รักษ์โลก',
  ShopTemplate.environmentSolution: 'ลดปัญหาสิ่งแวดล้อม',
  ShopTemplate.smart: 'สมาร์ท',
  ShopTemplate.vintage: 'วินเทจ',
  ShopTemplate.fun: 'สนุกสนาน',
  ShopTemplate.minimal: 'เรียบง่าย',
  ShopTemplate.modernLuxury: 'Modern Luxury',
  ShopTemplate.natureFresh: 'Nature Fresh',
  ShopTemplate.urbanMinimal: 'Urban Minimal',
  ShopTemplate.festival: 'Festival',
  ShopTemplate.techStartup: 'Tech Startup',
};

ShopTemplate _selectedShopTemplate = ShopTemplate.ecoFriendly;

Widget _buildShopHeaderTemplate(Seller shop) {
  switch (_selectedShopTemplate) {
    case ShopTemplate.ecoFriendly:
      return Container(
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [Colors.green[200]!, Colors.brown[100]!]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              backgroundImage:
                  shop.shopImageUrl != null && shop.shopImageUrl!.isNotEmpty
                      ? NetworkImage(shop.shopImageUrl!)
                      : null,
              child: (shop.shopImageUrl == null || shop.shopImageUrl!.isEmpty)
                  ? const Icon(Icons.eco, size: 38, color: Colors.green)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(shop.shopName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900])),
            if (shop.shopDescription != null &&
                shop.shopDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(shop.shopDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.brown[700])),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    case ShopTemplate.environmentSolution:
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue[200]!, Colors.white]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: const Icon(Icons.public, size: 38, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(shop.shopName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900])),
            if (shop.shopDescription != null &&
                shop.shopDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(shop.shopDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue[700])),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    case ShopTemplate.smart:
      return Container(
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [Colors.grey[300]!, Colors.blue[100]!]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child:
                  const Icon(Icons.lightbulb, size: 38, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Text(shop.shopName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey)),
            if (shop.shopDescription != null &&
                shop.shopDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(shop.shopDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700])),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    case ShopTemplate.vintage:
      return Container(
        decoration: BoxDecoration(
          color: Colors.brown[100],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.brown[200],
              child: const Icon(Icons.style, size: 38, color: Colors.brown),
            ),
            const SizedBox(height: 8),
            Text(shop.shopName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[900],
                    fontFamily: 'Serif')),
            if (shop.shopDescription != null &&
                shop.shopDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(shop.shopDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.brown[700], fontFamily: 'Serif')),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    case ShopTemplate.fun:
      return Container(
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [Colors.pink[100]!, Colors.yellow[100]!]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.yellow[200],
              child: const Icon(Icons.emoji_emotions,
                  size: 38, color: Colors.pink),
            ),
            const SizedBox(height: 8),
            Text(shop.shopName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[900])),
            if (shop.shopDescription != null &&
                shop.shopDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(shop.shopDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.yellow[800])),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    case ShopTemplate.minimal:
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.check_circle_outline,
                  size: 38, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(shop.shopName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            if (shop.shopDescription != null &&
                shop.shopDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(shop.shopDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600])),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    case ShopTemplate.modernLuxury:
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.black, Colors.amber[700]!]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.amber[700],
              child: const Icon(Icons.star, size: 38, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(shop.shopName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700])),
            if (shop.shopDescription != null &&
                shop.shopDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(shop.shopDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    case ShopTemplate.natureFresh:
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.lightBlue[100]!, Colors.green[100]!]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.green[200],
              child: const Icon(Icons.local_florist,
                  size: 38, color: Colors.lightBlue),
            ),
            const SizedBox(height: 8),
            Text(shop.shopName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900])),
            if (shop.shopDescription != null &&
                shop.shopDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(shop.shopDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.lightBlue[900])),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    case ShopTemplate.urbanMinimal:
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.apartment, size: 38, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(shop.shopName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            if (shop.shopDescription != null &&
                shop.shopDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(shop.shopDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[300])),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    case ShopTemplate.festival:
      return Container(
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [Colors.red[100]!, Colors.yellow[100]!]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.yellow[200],
              child: const Icon(Icons.celebration, size: 38, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(shop.shopName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900])),
            if (shop.shopDescription != null &&
                shop.shopDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(shop.shopDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.yellow[800])),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    case ShopTemplate.techStartup:
      return Container(
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [Colors.purple[200]!, Colors.blue[200]!]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.blue[200],
              child: const Icon(Icons.memory, size: 38, color: Colors.purple),
            ),
            const SizedBox(height: 8),
            Text(shop.shopName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[900])),
            if (shop.shopDescription != null &&
                shop.shopDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(shop.shopDescription!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue[900])),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
  }
}

// ...existing code...
