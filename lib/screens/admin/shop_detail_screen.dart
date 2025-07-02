// lib/screens/admin/shop_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/widgets/product_card.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ShopDetailScreen extends StatelessWidget {
  final Seller seller;

  const ShopDetailScreen({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(title: Text(seller.shopName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (seller.shopImageUrl != null && seller.shopImageUrl!.isNotEmpty)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(seller.shopImageUrl!),
                  backgroundColor:
                      Colors.grey[200], // Ensure shopImageUrl is not null
                  // Use a placeholder if shopImageUrl is null or empty
                  child: seller.shopImageUrl!.isNotEmpty
                      ? null
                      : const Icon(Icons.storefront, size: 50),
                ),
              )
            else
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.storefront, size: 50),
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    seller.shopName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge ร้านแนะนำ
                  if (seller.rating >= 4.8 && seller.totalRatings >= 10)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.thumb_up, size: 14, color: Colors.orange),
                          SizedBox(width: 2),
                          Text('ร้านแนะนำ',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.orange)),
                        ],
                      ),
                    ),
                  // Badge ร้านใหม่
                  if (DateTime.now()
                          .difference(seller.createdAt.toDate())
                          .inDays <=
                      30)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.fiber_new, size: 14, color: Colors.blue),
                          SizedBox(width: 2),
                          Text('ร้านใหม่',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.blue)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // คะแนนและสถิติร้าน
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    seller.rating.toStringAsFixed(1),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 2),
                  Text('(${seller.totalRatings} รีวิว)',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text('0 ผู้ติดตาม', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                seller.shopDescription ?? 'ไม่มีคำอธิบายร้านค้า',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 32),
            Text('ข้อมูลร้านค้า', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ชื่อร้าน: ${seller.shopName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      seller.shopDescription ?? '',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'อีเมลติดต่อ: ${seller.contactEmail}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'เบอร์โทรศัพท์: ${seller.contactPhone}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'เว็บไซต์: ${seller.website ?? 'N/A'}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'เป็นผู้ขายตั้งแต่: ${DateFormat('dd MMM yyyy').format(seller.createdAt.toDate())}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'สินค้าทั้งหมดของร้าน',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ส่วนสรุปคะแนนและรีวิว
            ShopReviewSummary(shopId: seller.id),
            const SizedBox(height: 16),
            // ส่วนรีวิวจากลูกค้า
            ShopReviewsList(shopId: seller.id, shopName: seller.shopName),
            const SizedBox(height: 16),
            StreamBuilder<List<Product>>(
              stream: firebaseService.getProductsBySeller(seller.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('ร้านนี้ยังไม่มีสินค้า'));
                }
                final products = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) => ProductCard(product: products[i]),
                );
              },
            ),
            const SizedBox(height: 32),
            ShopReviewSummary(shopId: seller.id),
            const SizedBox(height: 16),
            ShopReviewsList(shopId: seller.id, shopName: seller.shopName),
          ],
        ),
      ),
    );
  }
}

// กราฟคะแนนเฉลี่ย + กรองรีวิว Shopee-style สำหรับหน้าร้าน (top-level)
class ShopReviewSummary extends StatelessWidget {
  final String shopId;
  final Function(int?)? onStarFilter;
  const ShopReviewSummary({Key? key, required this.shopId, this.onStarFilter})
      : super(key: key);

  Future<Map<String, dynamic>> _getSummary() async {
    final query = await FirebaseFirestore.instance
        .collection('shop_reviews')
        .where('shopId', isEqualTo: shopId)
        .get();
    final reviews = query.docs.map((doc) => doc.data()).toList();
    if (reviews.isEmpty) {
      return {'avg': 0.0, 'total': 0, 'counts': List.filled(5, 0)};
    }
    double sum = 0;
    List<int> counts = List.filled(5, 0);
    for (var r in reviews) {
      final rating = (r['rating'] ?? 0).toInt();
      if (rating >= 1 && rating <= 5) counts[rating - 1]++;
      sum += (r['rating'] ?? 0).toDouble();
    }
    return {
      'avg': sum / reviews.length,
      'total': reviews.length,
      'counts': counts,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final avg = (snapshot.data!['avg'] as double);
        final total = snapshot.data!['total'] as int;
        final counts = snapshot.data!['counts'] as List<int>;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('คะแนนและรีวิว',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(avg.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.star,
                                color: Colors.amber, size: 24),
                          ],
                        ),
                        Text('$total รีวิว',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: List.generate(
                            5,
                            (i) => GestureDetector(
                                  onTap: onStarFilter != null
                                      ? () => onStarFilter!(5 - i)
                                      : null,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Text('${5 - i}',
                                            style:
                                                const TextStyle(fontSize: 11)),
                                        const Icon(Icons.star,
                                            color: Colors.amber, size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: total == 0
                                                ? 0
                                                : counts[4 - i] / total,
                                            minHeight: 6,
                                            backgroundColor: Colors.grey[200],
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(Colors.amber),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${counts[4 - i]}',
                                            style:
                                                const TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// รายการรีวิวร้านค้าสำหรับหน้าร้าน (top-level)
class ShopReviewsList extends StatefulWidget {
  final String shopId;
  final String shopName;
  const ShopReviewsList(
      {Key? key, required this.shopId, required this.shopName})
      : super(key: key);

  @override
  State<ShopReviewsList> createState() => _ShopReviewsListState();
}

class _ShopReviewsListState extends State<ShopReviewsList> {
  late Future<List<Map<String, dynamic>>> _futureReviews;
  int? _filterStar;
  bool _filterVerified = false;
  bool _filterHasImage = false;

  @override
  void initState() {
    super.initState();
    _futureReviews = _fetchShopReviews();
  }

  Future<List<Map<String, dynamic>>> _fetchShopReviews() async {
    final firestore = FirebaseFirestore.instance;
    final query = await firestore
        .collection('shop_reviews')
        .where('shopId', isEqualTo: widget.shopId)
        .orderBy('date', descending: true)
        .limit(10) // จำกัดแสดง 10 รีวิวล่าสุด
        .get();
    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'userName': data['userName'] ?? '',
        'rating': data['rating'],
        'comment': data['comment'],
        'date': (data['date'] is Timestamp)
            ? (data['date'] as Timestamp).toDate()
            : null,
        'reply': data['reply'],
        'verified': data['verified'] ?? false,
        'images': data['images'] ?? [],
      };
    }).toList();
  }

  void _refresh() {
    setState(() {
      _futureReviews = _fetchShopReviews();
    });
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> reviews) {
    return reviews.where((r) {
      if (_filterStar != null && r['rating'] != _filterStar) return false;
      if (_filterVerified && r['verified'] != true) return false;
      if (_filterHasImage &&
          (r['images'] == null || (r['images'] as List).isEmpty)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.reviews, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text('รีวิวจากลูกค้า',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              // ปุ่ม filter
              PopupMenuButton<int>(
                icon: const Icon(Icons.filter_alt,
                    color: Colors.orange, size: 20),
                tooltip: 'กรองรีวิว',
                onSelected: (star) => setState(
                    () => _filterStar = star == _filterStar ? null : star),
                itemBuilder: (context) => [
                  for (int i = 5; i >= 1; i--)
                    PopupMenuItem(
                      value: i,
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text('$i ดาว'),
                          if (_filterStar == i)
                            const Icon(Icons.check,
                                color: Colors.green, size: 16),
                        ],
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: Icon(
                    _filterVerified ? Icons.verified : Icons.verified_outlined,
                    color: Colors.green,
                    size: 20),
                tooltip: 'เฉพาะผู้ซื้อจริง',
                onPressed: () =>
                    setState(() => _filterVerified = !_filterVerified),
              ),
            ],
          ),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureReviews,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ));
            }
            final reviews = _applyFilters(snapshot.data ?? []);
            if (reviews.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Icon(Icons.reviews_outlined,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('ยังไม่มีรีวิวร้านค้านี้',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_comment),
                      label: const Text('เป็นคนแรกที่รีวิว'),
                      onPressed: () => _showAddReviewDialog(context),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
            return Column(
              children: [
                ...reviews
                    .take(3)
                    .map((review) => _buildReviewItem(review))
                    .toList(),
                if (reviews.length > 3)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton(
                      onPressed: () => _showAllReviewsDialog(context),
                      child: Text('ดูรีวิวทั้งหมด (${reviews.length})'),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_comment),
                      label: const Text('เขียนรีวิว'),
                      onPressed: () => _showAddReviewDialog(context),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                    radius: 16, child: Icon(Icons.person, size: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(review['userName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          ...List.generate(
                              5,
                              (i) => Icon(
                                    i < (review['rating'] ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 14,
                                  )),
                          if (review['verified'] == true)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('ผู้ซื้อจริง',
                                    style: TextStyle(
                                        fontSize: 9, color: Colors.green)),
                              ),
                            ),
                        ],
                      ),
                      if (review['date'] != null)
                        Text(
                          DateFormat('dd MMM yyyy')
                              .format(review['date'] as DateTime),
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review['comment'] ?? '', style: const TextStyle(fontSize: 13)),
            if (review['images'] != null &&
                (review['images'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: (review['images'] as List).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, idx) {
                      final imgUrl = (review['images'] as List)[idx];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          imgUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 20)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (review['reply'] != null &&
                review['reply'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront,
                          size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text('ตอบกลับจากร้าน: ${review['reply']}',
                              style: const TextStyle(
                                  color: Colors.blue, fontSize: 12))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: CustomerAddReviewForm(
            shopId: widget.shopId, onReviewAdded: _refresh),
      ),
    );
  }

  void _showAllReviewsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: AllShopReviewsDialog(
            shopId: widget.shopId, shopName: widget.shopName),
      ),
    );
  }
}

// ฟอร์มเพิ่มรีวิวสำหรับลูกค้า (top-level)
class CustomerAddReviewForm extends StatefulWidget {
  final String shopId;
  final VoidCallback onReviewAdded;
  const CustomerAddReviewForm(
      {Key? key, required this.shopId, required this.onReviewAdded})
      : super(key: key);

  @override
  State<CustomerAddReviewForm> createState() => _CustomerAddReviewFormState();
}

class _CustomerAddReviewFormState extends State<CustomerAddReviewForm> {
  final _commentController = TextEditingController();
  double _rating = 5;
  bool _loading = false;
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages =
              images.take(5).map((xfile) => File(xfile.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูป: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('รีวิวร้านค้า',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          const Text('ให้คะแนนร้านค้า',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: List.generate(
                5,
                (i) => IconButton(
                      icon: Icon(
                        i < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setState(() => _rating = i + 1.0),
                    )),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'แสดงความคิดเห็น',
              hintText: 'เขียนรีวิวเกี่ยวกับร้านค้านี้...',
              border: OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.add_photo_alternate),
                label: Text('เพิ่มรูปภาพ (${_selectedImages.length}/5)'),
                onPressed: _selectedImages.length < 5 ? _pickImages : null,
              ),
            ],
          ),
          if (_selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[idx],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedImages.removeAt(idx)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading || _commentController.text.trim().isEmpty
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) throw 'กรุณาเข้าสู่ระบบ';

                          // TODO: อัปโหลดรูปภาพไป Firebase Storage (ตอนนี้เป็น Demo)
                          List<String> imageUrls = [];

                          await FirebaseFirestore.instance
                              .collection('shop_reviews')
                              .add({
                            'shopId': widget.shopId,
                            'userId': user.uid,
                            'userName': user.displayName ?? 'ผู้ใช้',
                            'rating': _rating,
                            'comment': _commentController.text.trim(),
                            'date': Timestamp.now(),
                            'reply': '',
                            'verified': false, // TODO: ตรวจสอบการซื้อจริง
                            'images': imageUrls,
                          });

                          widget.onReviewAdded();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'เพิ่มรีวิวสำเร็จ ขอบคุณสำหรับความคิดเห็น!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                          );
                        } finally {
                          setState(() => _loading = false);
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('ส่งรีวิว'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Dialog แสดงรีวิวทั้งหมด (top-level)
class AllShopReviewsDialog extends StatefulWidget {
  final String shopId;
  final String shopName;
  const AllShopReviewsDialog(
      {Key? key, required this.shopId, required this.shopName})
      : super(key: key);

  @override
  State<AllShopReviewsDialog> createState() => _AllShopReviewsDialogState();
}

class _AllShopReviewsDialogState extends State<AllShopReviewsDialog> {
  late Future<List<Map<String, dynamic>>> _futureReviews;
  int? _filterStar;
  bool _filterVerified = false;

  @override
  void initState() {
    super.initState();
    _futureReviews = _fetchAllReviews();
  }

  Future<List<Map<String, dynamic>>> _fetchAllReviews() async {
    final firestore = FirebaseFirestore.instance;
    final query = await firestore
        .collection('shop_reviews')
        .where('shopId', isEqualTo: widget.shopId)
        .orderBy('date', descending: true)
        .get();
    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'userName': data['userName'] ?? '',
        'rating': data['rating'],
        'comment': data['comment'],
        'date': (data['date'] is Timestamp)
            ? (data['date'] as Timestamp).toDate()
            : null,
        'reply': data['reply'],
        'verified': data['verified'] ?? false,
        'images': data['images'] ?? [],
      };
    }).toList();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> reviews) {
    return reviews.where((r) {
      if (_filterStar != null && r['rating'] != _filterStar) return false;
      if (_filterVerified && r['verified'] != true) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 600,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.reviews, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('รีวิวร้าน ${widget.shopName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16))),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.filter_alt, color: Colors.orange),
                  tooltip: 'กรองรีวิว',
                  onSelected: (star) => setState(
                      () => _filterStar = star == _filterStar ? null : star),
                  itemBuilder: (context) => [
                    for (int i = 5; i >= 1; i--)
                      PopupMenuItem(
                        value: i,
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 2),
                            Text('$i ดาว'),
                            if (_filterStar == i)
                              const Icon(Icons.check,
                                  color: Colors.green, size: 16),
                          ],
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                      _filterVerified
                          ? Icons.verified
                          : Icons.verified_outlined,
                      color: Colors.green),
                  tooltip: 'เฉพาะผู้ซื้อจริง',
                  onPressed: () =>
                      setState(() => _filterVerified = !_filterVerified),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureReviews,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reviews = _applyFilters(snapshot.data ?? []);
                if (reviews.isEmpty) {
                  return const Center(
                      child: Text('ไม่พบรีวิวที่ตรงกับเงื่อนไข'));
                }
                return ListView.separated(
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _buildReviewItem(reviews[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 18, child: Icon(Icons.person)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(review['userName'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < (review['rating'] ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                )),
                        if (review['verified'] == true)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('ผู้ซื้อจริง',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.green)),
                            ),
                          ),
                      ],
                    ),
                    if (review['date'] != null)
                      Text(
                        DateFormat('dd MMM yyyy HH:mm')
                            .format(review['date'] as DateTime),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review['comment'] ?? ''),
          if (review['images'] != null && (review['images'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (review['images'] as List).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, idx) {
                    final imgUrl = (review['images'] as List)[idx];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imgUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (review['reply'] != null && review['reply'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Icon(Icons.storefront, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text('ตอบกลับจากร้าน: ${review['reply']}',
                            style: const TextStyle(color: Colors.blue))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
