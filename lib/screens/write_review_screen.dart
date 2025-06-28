// lib/screens/write_review_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:green_market/models/review.dart';
import 'package:green_market/models/order_item.dart'; // Changed to use OrderItem
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WriteReviewScreen extends StatefulWidget {
  final String orderId;
  final OrderItem orderItem; // Changed from ProductInOrder to OrderItem

  const WriteReviewScreen({
    super.key,
    required this.orderId,
    required this.orderItem,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 3.0; // Default rating
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อส่งรีวิว')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final String userName = currentUser.displayName ??
        currentUser.email?.split('@')[0] ??
        'ผู้ใช้งานนิรนาม';

    try {
      await firebaseService.addReview({
        'productId': widget.orderItem.productId,
        'userId': currentUser.uid,
        'orderId': widget.orderId,
        'userName': userName,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ขอบคุณสำหรับรีวิวของคุณ!'),
              backgroundColor: AppColors.successGreen),
        );
        Navigator.of(context).pop(true); // Pop with true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการส่งรีวิว: $e'),
              backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เขียนรีวิวสำหรับ ${widget.orderItem.productName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: widget.orderItem.imageUrl.isNotEmpty
                    ? Image.network(widget.orderItem.imageUrl,
                        height: 150, fit: BoxFit.contain)
                    : Container(
                        height: 150,
                        width: 150,
                        color: AppColors.lightGrey,
                        child: const Icon(Icons.image_not_supported, size: 50)),
              ),
              const SizedBox(height: 16),
              Center(
                  child: Text(widget.orderItem.productName,
                      style: AppTextStyles.subtitle
                          .copyWith(color: AppColors.primaryDarkGreen))),
              const SizedBox(height: 24),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: AppColors.warningYellow),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'ความคิดเห็นของคุณ',
                  hintText: 'แบ่งปันประสบการณ์การใช้สินค้า...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาใส่ความคิดเห็น';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReview,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 3, color: Colors.white))
                      : const Text('ส่งรีวิว'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
