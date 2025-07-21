import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/services/promotion_service.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/models/promotion.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// เพิ่ม enum และ map สำหรับ Shop Template
enum ShopTemplate {
  ecoFriendly,
  environmentSolution,
  smart,
}

const Map<ShopTemplate, String> shopTemplateNames = {
  ShopTemplate.ecoFriendly: 'Eco-Friendly',
  ShopTemplate.environmentSolution: 'Environment Solution',
  ShopTemplate.smart: 'Smart',
};

const Map<ShopTemplate, LinearGradient> shopTemplateGradients = {
  ShopTemplate.ecoFriendly:
      LinearGradient(colors: [Colors.green, Colors.brown]),
  ShopTemplate.environmentSolution:
      LinearGradient(colors: [Colors.blue, Colors.green]),
  ShopTemplate.smart: LinearGradient(colors: [Colors.grey, Colors.blueGrey]),
};

class CategoryForShop {
  final String name;
  final IconData icon;
  CategoryForShop(this.name, this.icon);
}

final List<CategoryForShop> categories = [
  CategoryForShop('ผักผลไม้', Icons.eco),
  CategoryForShop('อาหารแปรรูป', Icons.fastfood),
  CategoryForShop('เครื่องดื่ม', Icons.local_drink),
  CategoryForShop('ของใช้', Icons.shopping_bag),
  CategoryForShop('อื่นๆ', Icons.category),
];

class ShopPublicViewScreen extends StatefulWidget {
  final String sellerId;
  const ShopPublicViewScreen({super.key, required this.sellerId});

  @override
  State<ShopPublicViewScreen> createState() => _ShopPublicViewScreenState();
}

class _ShopPublicViewScreenState extends State<ShopPublicViewScreen> {
  ShopTemplate? _selectedTemplate;
  bool _isOwner = false;

  // --- Coupon Claim Logic ---
  Future<int> _getUserClaimedCouponCount(
      String userId, String promotionId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('coupon_claims')
        .where('userId', isEqualTo: userId)
        .where('promotionId', isEqualTo: promotionId)
        .get();
    return snapshot.docs.length;
  }

  Future<bool> _claimCoupon(String userId, Promotion promo) async {
    final claimsRef = FirebaseFirestore.instance.collection('coupon_claims');
    final promoRef =
        FirebaseFirestore.instance.collection('promotions').doc(promo.id);
    // Check if user already claimed (optional: limit per user)
    final alreadyClaimed = await _getUserClaimedCouponCount(userId, promo.id);
    if (promo.usageLimitPerUser != null &&
        alreadyClaimed >= (promo.usageLimitPerUser ?? 1)) {
      return false;
    }
    // Transaction: add claim, increment couponUsed
    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.set(claimsRef.doc(), {
        'userId': userId,
        'promotionId': promo.id,
        'claimedAt': FieldValue.serverTimestamp(),
      });
      tx.update(promoRef, {
        'couponUsed': FieldValue.increment(1),
      });
    });
    return true;
  }

  // --- Filter Dialog ---
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedCategory = _selectedCategory;
        return AlertDialog(
          title: const Text('กรองสินค้า'),
          content: DropdownButton<String>(
            value: selectedCategory,
            items: ['ทั้งหมด', ...categories.map((c) => c.name)]
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedCategory = val!;
              });
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  ShopTemplate _getShopTemplate(String? templateStr) {
    if (templateStr == null) return ShopTemplate.ecoFriendly;
    return ShopTemplate.values.firstWhere(
      (t) => t.toString().split('.').last == templateStr,
      orElse: () => ShopTemplate.ecoFriendly,
    );
  }

  Future<void> _updateShopTemplate(String templateStr) async {
    await FirebaseFirestore.instance
        .collection('sellers')
        .doc(widget.sellerId)
        .update({'shopTemplate': templateStr});
  }

  String _selectedCategory = 'ทั้งหมด';
  String _selectedSort = 'ล่าสุด';

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final appUser = Provider.of<AppUser?>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร้านค้าสาธารณะ'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<Seller?>(
        future: firebaseService.getSellerFullDetails(widget.sellerId),
        builder: (context, shopSnapshot) {
          if (shopSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!shopSnapshot.hasData || shopSnapshot.data == null) {
            return const Center(child: Text('ไม่พบข้อมูลร้านค้า'));
          }
          final shop = shopSnapshot.data!;
          final shopTemplate = _getShopTemplate(shop.shopTemplate);
          _selectedTemplate ??= shopTemplate;
          // เช็คสิทธิ์เจ้าของร้านจริง
          if (appUser != null && appUser.id == shop.id) {
            _isOwner = true;
          } else {
            _isOwner = false;
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Banner
                    Container(
                      width: double.infinity,
                      height: 120,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: AssetImage('assets/banner_sample.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text('Flash Sale! ลดสูงสุด 50%',
                              style: TextStyle(
                                  color: Colors.red[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                        ),
                      ),
                    ),
                    // หมวดหมู่สินค้า
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          return ChoiceChip(
                            label: Text(cat.name),
                            avatar: Icon(cat.icon, size: 18),
                            selected: _selectedCategory == cat.name,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = cat.name;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    // filter/sort
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton<String>(
                          value: _selectedSort,
                          items: ['ล่าสุด', 'ขายดี', 'ราคาต่ำ', 'ราคาสูง']
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSort = val!;
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter'),
                          onPressed: _showFilterDialog,
                        ),
                      ],
                    ),
                    // ส่วนหัวร้านเปลี่ยนตาม template
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: shopTemplateGradients[_selectedTemplate],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          if (_isOwner)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: DropdownButton<ShopTemplate>(
                                value: _selectedTemplate,
                                items: ShopTemplate.values.map((template) {
                                  return DropdownMenuItem<ShopTemplate>(
                                    value: template,
                                    child: Text(shopTemplateNames[template]!),
                                  );
                                }).toList(),
                                onChanged: (newTemplate) async {
                                  if (newTemplate != null) {
                                    setState(() {
                                      _selectedTemplate = newTemplate;
                                    });
                                    await _updateShopTemplate(
                                        newTemplate.toString().split('.').last);
                                  }
                                },
                              ),
                            ),
                          if (shop.shopCoverUrl != null &&
                              shop.shopCoverUrl!.isNotEmpty)
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(shop.shopCoverUrl!),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.white,
                              backgroundImage: shop.shopImageUrl != null &&
                                      shop.shopImageUrl!.isNotEmpty
                                  ? NetworkImage(shop.shopImageUrl!)
                                  : null,
                              child: (shop.shopImageUrl == null ||
                                      shop.shopImageUrl!.isEmpty)
                                  ? const Icon(Icons.storefront,
                                      size: 38, color: Colors.teal)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(shop.shopName,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(shopTemplateNames[_selectedTemplate]!,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white)),
                          if (shop.shopDescription != null &&
                              shop.shopDescription!.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(shop.shopDescription!,
                                  textAlign: TextAlign.center),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // โซนโปรโมชั่น/ส่วนลด
                    // โซนโปรโมชั่น/ส่วนลด (ใช้ข้อมูลจริง)
                    StreamBuilder<List<Promotion>>(
                      stream: PromotionService()
                          .getPromotionsBySeller(widget.sellerId),
                      builder: (context, promoSnapshot) {
                        if (promoSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!promoSnapshot.hasData ||
                            promoSnapshot.data!.isEmpty) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.yellow[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('ร้านค้านี้ยังไม่มีโปรโมชั่น'),
                          );
                        }
                        final promotions = promoSnapshot.data!;
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.yellow[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('โปรโมชั่น/ส่วนลด',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              ...promotions.map(
                                (promo) => Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        leading: promo.imageUrl.isNotEmpty
                                            ? Image.network(promo.imageUrl,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover)
                                            : null,
                                        title: Text(promo.title),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(promo.description),
                                            if (promo.couponCondition != null &&
                                                promo.couponCondition!
                                                    .isNotEmpty)
                                              Text(
                                                  'เงื่อนไข: ${promo.couponCondition!}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.orange)),
                                            if (promo.couponQuantity != null)
                                              Text(
                                                  'คงเหลือ: ${(promo.couponQuantity! - (promo.couponUsed ?? 0)).clamp(0, promo.couponQuantity!)}',
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                          ],
                                        ),
                                        trailing: promo.discountType ==
                                                'percentage'
                                            ? Chip(
                                                label: Text(
                                                    'ลด ${promo.discountValue}%'),
                                                backgroundColor:
                                                    Colors.green[100])
                                            : Chip(
                                                label: Text(
                                                    'ลด ${promo.discountValue} บาท'),
                                                backgroundColor:
                                                    Colors.blue[100]),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 4),
                                        child: Builder(
                                          builder: (context) {
                                            final appUser =
                                                Provider.of<AppUser?>(context,
                                                    listen: false);
                                            return FutureBuilder<int>(
                                              future: appUser == null
                                                  ? Future.value(0)
                                                  : _getUserClaimedCouponCount(
                                                      appUser.id, promo.id),
                                              builder: (context, snapshot) {
                                                final userClaimedCount =
                                                    snapshot.data ?? 0;
                                                final canClaim = promo
                                                            .couponQuantity !=
                                                        null &&
                                                    (promo.couponQuantity! -
                                                            (promo.couponUsed ??
                                                                0)) >
                                                        0 &&
                                                    (promo.usageLimitPerUser ==
                                                            null ||
                                                        userClaimedCount <
                                                            promo
                                                                .usageLimitPerUser!);
                                                return ElevatedButton.icon(
                                                  icon: const Icon(
                                                      Icons.card_giftcard),
                                                  label: Text(canClaim
                                                      ? 'รับคูปอง'
                                                      : 'คูปองหมด'),
                                                  onPressed: canClaim &&
                                                          appUser != null
                                                      ? () async {
                                                          final success =
                                                              await _claimCoupon(
                                                                  appUser.id,
                                                                  promo);
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(success
                                                                  ? 'รับคูปองสำเร็จ!'
                                                                  : 'คุณรับคูปองนี้ครบจำนวนที่กำหนดแล้ว'),
                                                            ),
                                                          );
                                                          setState(
                                                              () {}); // Refresh UI
                                                        }
                                                      : null,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: canClaim
                                                        ? Colors.orange
                                                        : Colors.grey,
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // โซนสินค้าแนะนำ
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('สินค้าแนะนำ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text(
                              'ตัวอย่าง: สินค้าเด่นของร้าน | สินค้าขายดี | สินค้าใหม่ล่าสุด'),
                          // TODO: เชื่อมต่อข้อมูลสินค้าแนะนำจริงจาก Firebase
                        ],
                      ),
                    ),
                    const Divider(),
                    Text('สินค้าทั้งหมดของร้าน',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // สินค้าใหม่/ขายดี/แนะนำ (mockup)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Text('สินค้าใหม่',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    // สินค้าใหม่
                    FutureBuilder<List<Product>>(
                      future: firebaseService
                          .getNewProductsBySeller(widget.sellerId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                              height: 160,
                              child:
                                  Center(child: CircularProgressIndicator()));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8),
                            child: Text('ยังไม่มีสินค้าใหม่'),
                          );
                        }
                        final products = snapshot.data!;
                        return SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: products.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) =>
                                ProductCard(product: products[index]),
                          ),
                        );
                      },
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Text('สินค้าขายดี',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    // สินค้าขายดี
                    FutureBuilder<List<Product>>(
                      future: firebaseService
                          .getBestSellerProductsBySeller(widget.sellerId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                              height: 160,
                              child:
                                  Center(child: CircularProgressIndicator()));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8),
                            child: Text('ยังไม่มีสินค้าขายดี'),
                          );
                        }
                        final products = snapshot.data!;
                        return SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: products.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) =>
                                ProductCard(product: products[index]),
                          ),
                        );
                      },
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Text('สินค้าแนะนำ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    // สินค้าแนะนำ (Firebase เชื่อมต่อแล้ว)
                    FutureBuilder<List<Product>>(
                      future: firebaseService
                          .getFeaturedProductsBySeller(widget.sellerId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 160,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8),
                            child: Text('ยังไม่มีสินค้าแนะนำ'),
                          );
                        }
                        final products = snapshot.data!;
                        return SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: products.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) =>
                                ProductCard(product: products[index]),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              FutureBuilder<List<Product>>(
                future: firebaseService
                    .getApprovedProductsBySeller(widget.sellerId),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (!productSnapshot.hasData ||
                      productSnapshot.data!.isEmpty) {
                    return const SliverToBoxAdapter(
                        child: Center(
                            child:
                                Text('ร้านนี้ยังไม่มีสินค้าที่อนุมัติแล้ว')));
                  }
                  final products = productSnapshot.data!;
                  return SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            ProductCard(product: products[index]),
                        childCount: products.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
