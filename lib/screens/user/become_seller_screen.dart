// lib/screens/user/become_seller_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';

class BecomeSellerScreen extends StatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  State<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends State<BecomeSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing user data
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser != null) {
      _contactEmailController.text = currentUser.email;
      _contactPhoneController.text = currentUser.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final userId = userProvider.currentUser?.id;

    if (userId == null) {
      showAppSnackBar(context, 'ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอินใหม่อีกครั้ง',
          isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      await firebaseService.requestToBeSeller({
        'userId': userId,
        'shopName': _shopNameController.text.trim(),
        'contactEmail': _contactEmailController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Refresh user data to get the new application status
      await userProvider.loadUserData(userId);

      if (mounted) {
        showAppSnackBar(
          context,
          'ส่งคำขอเป็นผู้ขายเรียบร้อยแล้ว โปรดรอการอนุมัติ',
          isSuccess: true,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
            isError: true);
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
        title: const Text('สมัครเป็นผู้ขาย'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'กรอกข้อมูลร้านค้าของคุณ',
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: 8),
              Text(
                'ทีมงานจะตรวจสอบข้อมูลและอนุมัติคำขอของคุณภายใน 2-3 วันทำการ',
                style: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อร้านค้า',
                  prefixIcon: Icon(Icons.storefront_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อร้านค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactEmailController,
                decoration: const InputDecoration(
                  labelText: 'อีเมลติดต่อ',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'กรุณากรอกอีเมลที่ถูกต้อง';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(
                  labelText: 'เบอร์โทรศัพท์ติดต่อ',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกเบอร์โทรศัพท์';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitApplication,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('ส่งคำขอ'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
