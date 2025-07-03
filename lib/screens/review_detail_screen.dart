import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/order_item.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/app_text_styles.dart' as text_styles;
import 'package:intl/intl.dart';

/// หน้าแสดงรีวิวที่ผู้ใช้เขียนไว้สำหรับสินค้าแต่ละรายการ
class ReviewDetailScreen extends StatefulWidget {
  final String orderId;
  final OrderItem orderItem;

  const ReviewDetailScreen({
    super.key,
    required this.orderId,
    required this.orderItem,
  });

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  Map<String, dynamic>? _review;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final reviewQuery = await FirebaseFirestore.instance
          .collection('reviews')
          .where('orderId', isEqualTo: widget.orderId)
          .where('productId', isEqualTo: widget.orderItem.productId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (reviewQuery.docs.isNotEmpty) {
        final reviewData = reviewQuery.docs.first.data();
        reviewData['id'] = reviewQuery.docs.first.id;
        setState(() => _review = reviewData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดรีวิว: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReview() async {
    if (_review == null) return;

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบรีวิว'),
        content: const Text(
            'คุณต้องการลบรีวิวนี้หรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('reviews')
            .doc(_review!['id'])
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบรีวิวแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(
              context, true); // Return true to indicate review was deleted
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบรีวิว: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รีวิวของคุณ'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryTeal,
        elevation: 1,
        actions: [
          if (_review != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteReview();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('ลบรีวิว'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _review == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('ไม่พบรีวิวสำหรับสินค้านี้',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Info
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: widget.orderItem.imageUrl.isNotEmpty
                                  ? Image.network(
                                      widget.orderItem.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.image, size: 60),
                                    )
                                  : const Icon(Icons.image, size: 60),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.orderItem.productName,
                                    style: text_styles.AppTextStyles.title
                                        .copyWith(fontSize: 16),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '฿${widget.orderItem.pricePerUnit.toStringAsFixed(2)} x ${widget.orderItem.quantity}',
                                    style:
                                        text_styles.AppTextStyles.body.copyWith(
                                      color: AppColors.primaryTeal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Review Content
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Review Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'รีวิวของคุณ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm', 'th_TH')
                                      .format(
                                          (_review!['createdAt'] as Timestamp)
                                              .toDate()),
                                  style: text_styles.AppTextStyles.caption
                                      .copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Rating Stars
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < (_review!['rating'] ?? 0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 24,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_review!['rating'] ?? 0}/5',
                                  style:
                                      text_styles.AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Review Comment
                            if (_review!['comment'] != null &&
                                _review!['comment'].toString().isNotEmpty) ...[
                              const Text(
                                'ความคิดเห็น',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Text(
                                  _review!['comment'].toString(),
                                  style:
                                      text_styles.AppTextStyles.body.copyWith(
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Text(
                                  'ไม่มีความคิดเห็น',
                                  style:
                                      text_styles.AppTextStyles.body.copyWith(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],

                            // Review Images (if any)
                            if (_review!['images'] != null &&
                                (_review!['images'] as List).isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'รูปภาพ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      (_review!['images'] as List).length,
                                  itemBuilder: (context, index) {
                                    final imageUrl =
                                        (_review!['images'] as List)[index];
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
