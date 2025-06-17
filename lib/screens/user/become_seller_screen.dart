// lib/screens/user/become_seller_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BecomeSellerScreen extends StatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  State<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends State<BecomeSellerScreen> {
  bool _isLoading = false;

  Future<void> _handleApplyToBeSeller() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('กรุณาเข้าสู่ระบบก่อนสมัครเป็นผู้ขาย'),
              backgroundColor: AppColors.errorRed),
        );
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.requestToBeSeller(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คำขอเป็นผู้ขายของคุณถูกส่งเรียบร้อยแล้ว!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        // Optionally, navigate away or disable the button
        // Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ร่วมเป็นผู้ขายกับ Green Market',
          style: AppTextStyles.title
              .copyWith(color: AppColors.white, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(Icons.storefront_outlined,
                size: 100, color: AppColors.primaryTeal),
            const SizedBox(height: 24),
            Text(
              'เริ่มต้นขายสินค้าเพื่อโลกที่ยั่งยืน',
              textAlign: TextAlign.center,
              style: AppTextStyles.title
                  .copyWith(color: AppColors.primaryTeal, fontSize: 22),
            ),
            const SizedBox(height: 16),
            Text(
              'เข้าร่วมชุมชนผู้ขาย Green Market และนำเสนอผลิตภัณฑ์ที่เป็นมิตรต่อสิ่งแวดล้อมของคุณให้กับผู้ซื้อที่ใส่ใจโลกของเรา',
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.modernGrey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleApplyToBeSeller,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: AppTextStyles.subtitle.copyWith(
                      color: AppColors.white, fontWeight: FontWeight.bold)),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 3.0,
                      ),
                    )
                  : Text('สมัครเป็นผู้ขายเลย!',
                      style: AppTextStyles.subtitle
                          .copyWith(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
