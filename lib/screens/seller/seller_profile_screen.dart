// lib/screens/seller/seller_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/seller.dart';
import 'package:green_market/screens/seller/my_products_screen.dart';
import 'package:green_market/screens/seller/seller_orders_screen.dart';
import 'package:green_market/screens/seller/shop_settings_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// กราฟคะแนนเฉลี่ย + กรองรีวิว Shopee-style (top-level)
class ReviewSummary extends StatelessWidget {
  final String shopId;
  const ReviewSummary({Key? key, required this.shopId}) : super(key: key);

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
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final avg = (snapshot.data!['avg'] as double).toStringAsFixed(2);
        final total = snapshot.data!['total'] as int;
        final counts = snapshot.data!['counts'] as List<int>;
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(avg,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: Colors.amber, size: 28),
                  ],
                ),
                Text('$total รีวิว', style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: List.generate(
                    5,
                    (i) => Row(
                          children: [
                            Text('${5 - i}',
                                style: const TextStyle(fontSize: 12)),
                            const Icon(Icons.star,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : counts[4 - i] / total,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.amber),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('${counts[4 - i]}',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        )),
              ),
            ),
          ],
        );
      },
    );
  }
}

// SellerShopScreen - หน้าร้านค้า (top-level)
class SellerShopScreen extends StatelessWidget {
  final String sellerId;
  const SellerShopScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('หน้าร้านค้า (Demo)')),
      body: Center(child: Text('Seller Shop Screen for $sellerId (Demo)')),
    );
  }
}

// Shopee-style รีวิวร้านค้า: Dialog หลัก (แสดง/เพิ่ม/ตอบกลับ) - top-level
class ShopReviewDialog extends StatefulWidget {
  final String shopId;
  final String shopName;
  const ShopReviewDialog(
      {Key? key, required this.shopId, required this.shopName})
      : super(key: key);

  @override
  State<ShopReviewDialog> createState() => _ShopReviewDialogState();
}

class _ShopReviewDialogState extends State<ShopReviewDialog> {
  late Future<List<Map<String, dynamic>>> _futureReviews;
  int? _filterStar; // 1-5
  bool _filterVerified = false;
  bool _filterHasImage = false;

  @override
  void initState() {
    super.initState();
    _futureReviews = _fetchShopReviews(widget.shopId);
  }

  // ดึงรีวิวร้านค้าจาก Firestore (collection: shop_reviews) พร้อม field สำหรับ filter และรูปภาพ
  Future<List<Map<String, dynamic>>> _fetchShopReviews(String shopId) async {
    final firestore = FirebaseFirestore.instance;
    final query = await firestore
        .collection('shop_reviews')
        .where('shopId', isEqualTo: shopId)
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

  void _refresh() {
    setState(() {
      _futureReviews = _fetchShopReviews(widget.shopId);
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
    return SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.reviews, color: Colors.blue),
                const SizedBox(width: 8),
                Text('รีวิวร้านค้า',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'รีเฟรช',
                  onPressed: _refresh,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // กราฟคะแนนเฉลี่ย + ปุ่ม filter Shopee-style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: ReviewSummary(shopId: widget.shopId)),
                // ปุ่ม filter
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
                  icon: Icon(
                      _filterHasImage ? Icons.image : Icons.image_outlined,
                      color: Colors.blue),
                  tooltip: 'เฉพาะรีวิวที่มีรูป',
                  onPressed: () =>
                      setState(() => _filterHasImage = !_filterHasImage),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                    child: Text('รีวิวร้าน "${widget.shopName}"',
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_comment),
                  label: const Text('เพิ่มรีวิว'),
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: EnhancedAddReviewForm(
                            shopId: widget.shopId, onReviewAdded: _refresh),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureReviews,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reviews = _applyFilters(snapshot.data ?? []);
                if (reviews.isEmpty) {
                  return const Center(child: Text('ยังไม่มีรีวิวร้านค้านี้'));
                }
                return ListView.separated(
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final review = reviews[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading:
                                const CircleAvatar(child: Icon(Icons.person)),
                            title: Row(
                              children: [
                                Text(review['userName'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                Text(review['rating']?.toString() ?? ''),
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
                                              fontSize: 10,
                                              color: Colors.green)),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review['comment'] ?? ''),
                                if (review['images'] != null &&
                                    (review['images'] as List).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: SizedBox(
                                      height: 60,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            (review['images'] as List).length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 6),
                                        itemBuilder: (context, idx) {
                                          final imgUrl =
                                              (review['images'] as List)[idx];
                                          return ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              imgUrl,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                          Icons.broken_image)),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Text(
                                review['date'] != null
                                    ? (review['date'] as DateTime)
                                        .toString()
                                        .substring(0, 10)
                                    : '',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          if (review['reply'] != null &&
                              review['reply'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 72, right: 16, bottom: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.reply,
                                        size: 16, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Expanded(
                                        child: Text(
                                            'ร้านค้า: ${review['reply']}',
                                            style: const TextStyle(
                                                color: Colors.blue))),
                                  ],
                                ),
                              ),
                            ),
                          if (review['reply'] == null ||
                              review['reply'].toString().isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 72, right: 16, bottom: 8),
                              child: ReplyForm(
                                reviewId: review['id'],
                                onReplied: _refresh,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ฟอร์มเพิ่มรีวิวร้านค้า Shopee-style - top-level
class EnhancedAddReviewForm extends StatefulWidget {
  final String shopId;
  final VoidCallback onReviewAdded;
  const EnhancedAddReviewForm(
      {Key? key, required this.shopId, required this.onReviewAdded})
      : super(key: key);

  @override
  State<EnhancedAddReviewForm> createState() => _EnhancedAddReviewFormState();
}

class _EnhancedAddReviewFormState extends State<EnhancedAddReviewForm> {
  final _commentController = TextEditingController();
  double _rating = 5;
  bool _loading = false;
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((img) => File(img.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('เพิ่มรีวิวร้านค้า',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              mainAxisAlignment: MainAxisAlignment.center,
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
            Text('คะแนน: ${_rating.toInt()}/5',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'แสดงความคิดเห็น',
                hintText: 'บอกเล่าประสบการณ์การซื้อสินค้าจากร้านนี้...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment),
              ),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('รูปภาพ (ไม่บังคับ)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_camera, size: 18),
                  label: const Text('เลือกรูป'),
                  onPressed: _pickImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Text('${_selectedImages.length} รูปที่เลือก',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 20),
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

                            // TODO: อัปโหลดรูปภาพไปยัง Firebase Storage และได้ URLs
                            List<String> imageUrls = [];
                            if (_selectedImages.isNotEmpty) {
                              // สำหรับ Demo ใช้ placeholder URLs
                              imageUrls = _selectedImages
                                  .map((img) =>
                                      'https://via.placeholder.com/150?text=Review+Image')
                                  .toList();
                            }

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
                              'verified': true, // Demo: ถือว่าเป็นผู้ซื้อจริง
                              'images': imageUrls,
                            });
                            widget.onReviewAdded();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('✅ เพิ่มรีวิวสำเร็จ!')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                            );
                          } finally {
                            setState(() => _loading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('ส่งรีวิว'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ฟอร์มตอบกลับ Shopee-style - top-level
class ReplyForm extends StatefulWidget {
  final String reviewId;
  final VoidCallback onReplied;
  const ReplyForm({Key? key, required this.reviewId, required this.onReplied})
      : super(key: key);

  @override
  State<ReplyForm> createState() => _ReplyFormState();
}

class _ReplyFormState extends State<ReplyForm> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'ตอบกลับรีวิวนี้...',
            border: OutlineInputBorder(),
          ),
          minLines: 1,
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _loading || _controller.text.trim().isEmpty
                ? null
                : () async {
                    setState(() => _loading = true);
                    try {
                      await FirebaseFirestore.instance
                          .collection('shop_reviews')
                          .doc(widget.reviewId)
                          .update({'reply': _controller.text.trim()});
                      widget.onReplied();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ตอบกลับรีวิวสำเร็จ')),
                      );
                      _controller.clear();
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
                : const Text('ส่ง'),
          ),
        ),
      ],
    );
  }
}

// SellerProfileScreen - หน้าโปรไฟล์ร้านค้าหลัก
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

  // Shopee-style Dashboard Tab (statistics, shop status, promotions, badges, etc.)
  Widget buildDashboardTab(BuildContext context) {
    final stats = [
      {
        'label': 'ยอดขาย',
        'value': '1,250',
        'icon': Icons.attach_money,
        'color': Colors.green
      },
      {
        'label': 'เข้าชม',
        'value': '8,900',
        'icon': Icons.visibility,
        'color': Colors.blue
      },
      {
        'label': 'ติดตาม',
        'value': '320',
        'icon': Icons.people,
        'color': Colors.orange
      },
      {
        'label': 'รีวิว',
        'value': '4.8',
        'icon': Icons.star,
        'color': Colors.amber
      },
    ];
    final seller = _seller;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats
                  .map((s) => Column(
                        children: [
                          Icon(s['icon'] as IconData,
                              color: s['color'] as Color, size: 28),
                          const SizedBox(height: 4),
                          Text(s['value'].toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(s['label'].toString(),
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_offer, color: Colors.green),
            title: const Text('โปรโมชันร้านค้า'),
            subtitle: const Text('สร้างและจัดการโปรโมชัน, คูปอง, สินค้าแนะนำ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('โปรโมชันร้านค้า'),
                  content: const Text(
                      'ฟีเจอร์นี้อยู่ระหว่างการพัฒนา (จะสามารถสร้าง/แก้ไขโปรโมชัน คูปอง สินค้าแนะนำ ฯลฯ ได้จริง)'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิด'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.amber),
            title: const Text('เหรียญ/ตราร้านค้า'),
            subtitle:
                const Text('ตราร้านค้า, ร้านแนะนำ, ร้านใหม่, ร้านยอดนิยม'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('เหรียญ/ตราร้านค้า'),
                  content: const Text(
                      'ฟีเจอร์นี้อยู่ระหว่างการพัฒนา (ระบบ Badge, ร้านแนะนำ, ร้านใหม่ ฯลฯ)'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิด'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.reviews, color: Colors.blue),
            title: const Text('รีวิวร้านค้า'),
            subtitle: const Text('ดู/เพิ่ม/ตอบกลับรีวิวร้านค้า'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              if (seller == null) return;
              await showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: ShopReviewDialog(
                      shopId: seller.id, shopName: seller.shopName),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์ร้านค้า'),
        actions: [
          if (_seller != null)
            IconButton(
              icon: const Icon(Icons.storefront_rounded),
              tooltip: 'ดูหน้าร้าน',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        SellerShopScreen(sellerId: _seller!.id),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _seller == null
              ? const Center(child: Text('ไม่พบข้อมูลร้านค้า'))
              : DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      _buildModernProfileHeader(context, _seller!),
                      const SizedBox(height: 8),
                      TabBar(
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        tabs: const [
                          Tab(text: 'แดชบอร์ด'),
                          Tab(text: 'สินค้า'),
                          Tab(text: 'ออเดอร์'),
                          Tab(text: 'ตั้งค่า'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            buildDashboardTab(context),
                            const MyProductsScreen(),
                            const SellerOrdersScreen(),
                            const ShopSettingsScreen(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildModernProfileHeader(BuildContext context, Seller seller) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isNewShop = now.difference(seller.createdAt.toDate()).inDays <= 30;
    final isRecommended = seller.rating >= 4.8 && seller.totalRatings >= 10;
    return Stack(
      children: [
        // Shopee-style cover/banner
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ),
        Positioned(
          left: 24,
          top: 80,
          child: GestureDetector(
            onTap: () => _showEditShopImageDialog(context, seller),
            child: Material(
              elevation: 6,
              shape: const CircleBorder(),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                backgroundImage: seller.shopImageUrl != null &&
                        seller.shopImageUrl!.isNotEmpty
                    ? NetworkImage(seller.shopImageUrl!)
                    : null,
                child: seller.shopImageUrl == null ||
                        seller.shopImageUrl!.isEmpty
                    ? const Icon(Icons.storefront, size: 48, color: Colors.grey)
                    : null,
              ),
            ),
          ),
        ),
        Positioned(
          left: 140,
          top: 100,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      seller.shopName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isRecommended)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.thumb_up, size: 14, color: Colors.orange),
                          SizedBox(width: 2),
                          Text('ร้านแนะนำ',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.orange)),
                        ],
                      ),
                    ),
                  if (isNewShop)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.fiber_new, size: 14, color: Colors.blue),
                          SizedBox(width: 2),
                          Text('ร้านใหม่',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.blue)),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'แก้ไขชื่อ/รายละเอียดร้าน',
                    onPressed: () => _showEditShopDetailDialog(context, seller),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 2),
                  Text(
                    seller.rating.toStringAsFixed(2),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text('(${seller.totalRatings} รีวิว)',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 8),
                  const Icon(Icons.people, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 2),
                  Text('0 ผู้ติดตาม', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                seller.shopDescription ?? 'ไม่มีคำอธิบายร้านค้า',
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (seller.website != null && seller.website!.isNotEmpty)
                    const Icon(Icons.language,
                        size: 16, color: Colors.blueGrey),
                  if (seller.website != null && seller.website!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: Text(seller.website!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.blue)),
                    ),
                  if (seller.socialMediaLink != null &&
                      seller.socialMediaLink!.isNotEmpty)
                    const Icon(Icons.alternate_email,
                        size: 16, color: Colors.blueGrey),
                  if (seller.socialMediaLink != null &&
                      seller.socialMediaLink!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(seller.socialMediaLink!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.blue)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'เป็นผู้ขายตั้งแต่: ${DateFormat('dd MMMM yyyy', 'th_TH').format(seller.createdAt.toDate())}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // Shopee-style quick actions
        Positioned(
          right: 16,
          top: 16,
          child: Row(
            children: [
              _buildQuickAction(
                context,
                icon: Icons.person_add_alt_1,
                label: 'ติดตาม',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _buildQuickAction(
                context,
                icon: Icons.chat_bubble_outline,
                label: 'แชท',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _buildQuickAction(
                context,
                icon: Icons.share,
                label: 'แชร์',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Dialog สำหรับแก้ไขรูปร้านค้า (Demo)
  void _showEditShopImageDialog(BuildContext context, Seller seller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เปลี่ยนรูปร้านค้า'),
        content: const Text('ฟีเจอร์นี้อยู่ระหว่างการพัฒนา (อัปโหลดรูปใหม่)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  // Dialog สำหรับแก้ไขรายละเอียดร้านค้า (Demo)
  void _showEditShopDetailDialog(BuildContext context, Seller seller) {
    // ตัวอย่างฟอร์มแก้ไขชื่อ/รายละเอียดร้านค้า (Demo)
    final nameController = TextEditingController(text: seller.shopName);
    final descController =
        TextEditingController(text: seller.shopDescription ?? '');
    final websiteController = TextEditingController(text: seller.website ?? '');
    final socialController =
        TextEditingController(text: seller.socialMediaLink ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขรายละเอียดร้านค้า'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'ชื่อร้าน'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'รายละเอียดร้าน'),
                maxLines: 2,
              ),
              TextField(
                controller: websiteController,
                decoration: const InputDecoration(labelText: 'เว็บไซต์'),
              ),
              TextField(
                controller: socialController,
                decoration:
                    const InputDecoration(labelText: 'โซเชียลมีเดีย/Line/FB'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: เชื่อมต่อ backend เพื่อบันทึกข้อมูลจริง
              setState(() {
                _seller = Seller(
                  id: seller.id,
                  shopName: nameController.text,
                  contactEmail: seller.contactEmail,
                  phoneNumber: seller.phoneNumber,
                  status: seller.status,
                  rating: seller.rating,
                  totalRatings: seller.totalRatings,
                  createdAt: seller.createdAt,
                  shopImageUrl: seller.shopImageUrl,
                  shopDescription: descController.text,
                  website: websiteController.text,
                  socialMediaLink: socialController.text,
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('บันทึกข้อมูลร้านค้า (Demo) สำเร็จ')),
              );
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Review Analytics Dashboard
class ReviewAnalyticsDashboard extends StatefulWidget {
  final String shopId;
  const ReviewAnalyticsDashboard({Key? key, required this.shopId})
      : super(key: key);

  @override
  State<ReviewAnalyticsDashboard> createState() =>
      _ReviewAnalyticsDashboardState();
}

class _ReviewAnalyticsDashboardState extends State<ReviewAnalyticsDashboard> {
  Map<String, dynamic>? _analytics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final reviews = await FirebaseFirestore.instance
          .collection('shop_reviews')
          .where('shopId', isEqualTo: widget.shopId)
          .get();

      final data = reviews.docs.map((doc) => doc.data()).toList();
      if (data.isEmpty) {
        setState(() {
          _analytics = {
            'total': 0,
            'avgRating': 0.0,
            'ratingCounts': List.filled(5, 0),
            'verifiedCount': 0,
            'withImagesCount': 0,
            'recentCount': 0,
            'replyRate': 0.0,
          };
          _loading = false;
        });
        return;
      }

      double totalRating = 0;
      List<int> ratingCounts = List.filled(5, 0);
      int verifiedCount = 0;
      int withImagesCount = 0;
      int recentCount = 0;
      int repliedCount = 0;

      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));

      for (var review in data) {
        final rating = (review['rating'] ?? 0).toInt();
        if (rating >= 1 && rating <= 5) {
          ratingCounts[rating - 1]++;
          totalRating += rating;
        }

        if (review['verified'] == true) verifiedCount++;
        if (review['images'] != null && (review['images'] as List).isNotEmpty)
          withImagesCount++;
        if (review['reply'] != null && review['reply'].toString().isNotEmpty)
          repliedCount++;

        final reviewDate = (review['date'] as Timestamp?)?.toDate();
        if (reviewDate != null && reviewDate.isAfter(last30Days)) recentCount++;
      }

      setState(() {
        _analytics = {
          'total': data.length,
          'avgRating': data.isEmpty ? 0.0 : totalRating / data.length,
          'ratingCounts': ratingCounts,
          'verifiedCount': verifiedCount,
          'withImagesCount': withImagesCount,
          'recentCount': recentCount,
          'replyRate': data.isEmpty ? 0.0 : (repliedCount / data.length) * 100,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_analytics == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('📊 สถิติรีวิวร้านค้า',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() => _loading = true);
                    _loadAnalytics();
                  },
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'รีวิวทั้งหมด',
                    '${_analytics!['total']}',
                    Icons.reviews,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'คะแนนเฉลี่ย',
                    '${(_analytics!['avgRating'] as double).toStringAsFixed(2)}',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'ผู้ซื้อจริง',
                    '${_analytics!['verifiedCount']}',
                    Icons.verified,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'มีรูปภาพ',
                    '${_analytics!['withImagesCount']}',
                    Icons.image,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '30 วันล่าสุด',
                    '${_analytics!['recentCount']}',
                    Icons.calendar_today,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'อัตราตอบกลับ',
                    '${(_analytics!['replyRate'] as double).toStringAsFixed(1)}%',
                    Icons.reply,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// Enhanced Notification System
class ReviewNotificationManager {
  static Future<void> showReviewNotification(
      BuildContext context, String type, String message) async {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case 'success':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'error':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.error;
        break;
      case 'warning':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      default:
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        icon = Icons.info;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: textColor))),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Review Moderation Dialog
class ReviewModerationDialog extends StatefulWidget {
  final Map<String, dynamic> review;
  final VoidCallback onAction;

  const ReviewModerationDialog(
      {Key? key, required this.review, required this.onAction})
      : super(key: key);

  @override
  State<ReviewModerationDialog> createState() => _ReviewModerationDialogState();
}

class _ReviewModerationDialogState extends State<ReviewModerationDialog> {
  bool _loading = false;

  Future<void> _reportReview() async {
    setState(() => _loading = true);
    try {
      // TODO: Implement review reporting system
      await Future.delayed(const Duration(seconds: 1)); // Demo delay
      ReviewNotificationManager.showReviewNotification(
          context, 'success', 'รายงานรีวิวเรียบร้อย');
      widget.onAction();
      Navigator.pop(context);
    } catch (e) {
      ReviewNotificationManager.showReviewNotification(
          context, 'error', 'เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.flag, color: Colors.red),
          SizedBox(width: 8),
          Text('จัดการรีวิว'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ผู้ใช้: ${widget.review['userName']}'),
          Text('คะแนน: ${widget.review['rating']} ดาว'),
          const SizedBox(height: 8),
          const Text('ความคิดเห็น:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(widget.review['comment'] ?? ''),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _reportReview,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('รายงาน', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
