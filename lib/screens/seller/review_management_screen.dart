import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// ระบบจัดการรีวิวและคะแนน - Review Management (Shopee/TikTok Style)
/// รองรับ: ดูรีวิว, ตอบกลับรีวิว, วิเคราะห์คะแนน, กรองตามดาว
class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _sellerId;

  List<ReviewData> _reviews = [];
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  // Filters
  int? _filterRating; // null = all, 1-5 = specific rating
  bool _showOnlyUnanswered = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (_sellerId != null) {
      _loadReviews();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      // Load all reviews for seller's products
      final productsSnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: _sellerId)
          .get();

      final productIds = productsSnapshot.docs.map((doc) => doc.id).toList();

      if (productIds.isEmpty) {
        setState(() {
          _reviews = [];
          _isLoading = false;
        });
        return;
      }

      // Load reviews (batch by product)
      List<ReviewData> allReviews = [];
      for (var productId in productIds) {
        final reviewsSnapshot = await _firestore
            .collection('reviews')
            .where('productId', isEqualTo: productId)
            .orderBy('createdAt', descending: true)
            .get();

        for (var doc in reviewsSnapshot.docs) {
          final data = doc.data();
          final product =
              productsSnapshot.docs.firstWhere((p) => p.id == productId).data();

          allReviews.add(ReviewData(
            id: doc.id,
            productId: productId,
            productName: product['name'] ?? '',
            productImage: (product['images'] as List?)?.firstOrNull,
            userId: data['userId'] ?? '',
            userName: data['userName'] ?? 'ลูกค้า',
            userPhoto: data['userPhoto'],
            rating: (data['rating'] as num?)?.toInt() ?? 5,
            comment: data['comment'] ?? '',
            images: List<String>.from(data['images'] ?? []),
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            sellerReply: data['sellerReply'],
            sellerReplyAt: data['sellerReplyAt'] != null
                ? (data['sellerReplyAt'] as Timestamp).toDate()
                : null,
          ));
        }
      }

      // Calculate stats
      final totalReviews = allReviews.length;
      final avgRating = totalReviews > 0
          ? allReviews.fold<double>(0, (sum, r) => sum + r.rating) /
              totalReviews
          : 0;
      final rating5 = allReviews.where((r) => r.rating == 5).length;
      final rating4 = allReviews.where((r) => r.rating == 4).length;
      final rating3 = allReviews.where((r) => r.rating == 3).length;
      final rating2 = allReviews.where((r) => r.rating == 2).length;
      final rating1 = allReviews.where((r) => r.rating == 1).length;
      final unanswered = allReviews.where((r) => r.sellerReply == null).length;

      setState(() {
        _reviews = allReviews;
        _stats = {
          'total': totalReviews,
          'avgRating': avgRating,
          'rating5': rating5,
          'rating4': rating4,
          'rating3': rating3,
          'rating2': rating2,
          'rating1': rating1,
          'unanswered': unanswered,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() => _isLoading = false);
    }
  }

  List<ReviewData> get _filteredReviews {
    var filtered = _reviews;

    if (_filterRating != null) {
      filtered = filtered.where((r) => r.rating == _filterRating).toList();
    }

    if (_showOnlyUnanswered) {
      filtered = filtered.where((r) => r.sellerReply == null).toList();
    }

    return filtered;
  }

  Future<void> _replyToReview(ReviewData review) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตอบกลับรีวิว'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.comment,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'พิมพ์คำตอบของคุณ...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('ส่งคำตอบ'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _firestore.collection('reviews').doc(review.id).update({
          'sellerReply': result,
          'sellerReplyAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          review.sellerReply = result;
          review.sellerReplyAt = DateTime.now();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ ส่งคำตอบเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการรีวิว'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviews,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ทั้งหมด', icon: Icon(Icons.list, size: 20)),
            Tab(text: 'รอตอบกลับ', icon: Icon(Icons.message, size: 20)),
            Tab(text: 'สถิติ', icon: Icon(Icons.analytics, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllReviewsTab(),
                _buildUnansweredTab(),
                _buildStatsTab(),
              ],
            ),
    );
  }

  // ==================== TAB 1: ทั้งหมด ====================
  Widget _buildAllReviewsTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _filteredReviews.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReviews,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildReviewCard(_filteredReviews[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('ทั้งหมด', null),
            const SizedBox(width: 8),
            _buildFilterChip('⭐ 5', 5),
            const SizedBox(width: 8),
            _buildFilterChip('⭐ 4', 4),
            const SizedBox(width: 8),
            _buildFilterChip('⭐ 3', 3),
            const SizedBox(width: 8),
            _buildFilterChip('⭐ 2', 2),
            const SizedBox(width: 8),
            _buildFilterChip('⭐ 1', 1),
            const SizedBox(width: 16),
            FilterChip(
              label: const Text('ยังไม่ได้ตอบกลับ'),
              selected: _showOnlyUnanswered,
              onSelected: (selected) {
                setState(() {
                  _showOnlyUnanswered = selected;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int? rating) {
    final count = rating == null
        ? _reviews.length
        : _reviews.where((r) => r.rating == rating).length;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _filterRating == rating
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _filterRating == rating ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: _filterRating == rating,
      onSelected: (selected) {
        setState(() {
          _filterRating = selected ? rating : null;
        });
      },
    );
  }

  Widget _buildReviewCard(ReviewData review) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info
            Row(
              children: [
                if (review.productImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      review.productImage!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    review.productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.userPhoto != null
                      ? NetworkImage(review.userPhoto!)
                      : null,
                  child: review.userPhoto == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('d MMM yyyy', 'th')
                                .format(review.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Comment
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14),
            ),

            // Review images
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        review.images[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],

            // Seller reply
            if (review.sellerReply != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text(
                          'คำตอบจากผู้ขาย',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (review.sellerReplyAt != null)
                          Text(
                            DateFormat('d MMM', 'th')
                                .format(review.sellerReplyAt!),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.sellerReply!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            // Reply button
            if (review.sellerReply == null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _replyToReview(review),
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text('ตอบกลับรีวิว'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== TAB 2: รอตอบกลับ ====================
  Widget _buildUnansweredTab() {
    final unansweredReviews =
        _reviews.where((r) => r.sellerReply == null).toList();

    if (unansweredReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 80, color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text(
              'ตอบกลับรีวิวครบแล้ว! 🎉',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ไม่มีรีวิวที่รอตอบกลับ',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: unansweredReviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildReviewCard(unansweredReviews[index]);
        },
      ),
    );
  }

  // ==================== TAB 3: สถิติ ====================
  Widget _buildStatsTab() {
    final avgRating = _stats['avgRating'] ?? 0.0;
    final total = _stats['total'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall rating
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < avgRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$total รีวิวทั้งหมด',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Rating breakdown
        const Text(
          '📊 สถิติคะแนน',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildRatingBar(5, _stats['rating5'] ?? 0, total),
        _buildRatingBar(4, _stats['rating4'] ?? 0, total),
        _buildRatingBar(3, _stats['rating3'] ?? 0, total),
        _buildRatingBar(2, _stats['rating2'] ?? 0, total),
        _buildRatingBar(1, _stats['rating1'] ?? 0, total),

        const SizedBox(height: 24),
        Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.pending_actions,
                    size: 40, color: Colors.orange.shade700),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_stats['unanswered'] ?? 0} รีวิว',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const Text('รอตอบกลับ'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(int rating, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Row(
            children: [
              Text('$rating'),
              const Icon(Icons.star, size: 16, color: Colors.amber),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  rating >= 4 ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '$count',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีรีวิว',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ==================== MODELS ====================
class ReviewData {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final String userId;
  final String userName;
  final String? userPhoto;
  final int rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;
  String? sellerReply;
  DateTime? sellerReplyAt;

  ReviewData({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.rating,
    required this.comment,
    this.images = const [],
    required this.createdAt,
    this.sellerReply,
    this.sellerReplyAt,
  });
}
