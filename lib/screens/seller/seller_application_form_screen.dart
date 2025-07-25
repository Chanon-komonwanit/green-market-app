import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/providers/user_provider.dart';

class SellerApplicationFormScreen extends StatefulWidget {
  const SellerApplicationFormScreen({super.key});

  @override
  State<SellerApplicationFormScreen> createState() =>
      _SellerApplicationFormScreenState();
}

class _SellerApplicationFormScreenState
    extends State<SellerApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _shopName = '';
  String _contactEmail = '';
  String _phoneNumber = '';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครเปิดร้านค้า')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ชื่อร้านค้า',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: const InputDecoration(hintText: 'กรอกชื่อร้าน'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกชื่อร้าน' : null,
                onSaved: (v) => _shopName = v ?? '',
              ),
              const SizedBox(height: 16),
              const Text('อีเมลติดต่อ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: currentUser?.email ?? '',
                decoration: const InputDecoration(hintText: 'กรอกอีเมล'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกอีเมล' : null,
                onSaved: (v) => _contactEmail = v ?? '',
              ),
              const SizedBox(height: 16),
              const Text('เบอร์โทรศัพท์',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                decoration:
                    const InputDecoration(hintText: 'กรอกเบอร์โทรศัพท์'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกเบอร์โทรศัพท์' : null,
                onSaved: (v) => _phoneNumber = v ?? '',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          _formKey.currentState!.save();
                          setState(() => _isSubmitting = true);

                          try {
                            final firebaseService =
                                Provider.of<FirebaseService>(context,
                                    listen: false);
                            final userProvider = Provider.of<UserProvider>(
                                context,
                                listen: false);
                            final userId = userProvider.currentUser?.id;
                            if (userId == null) {
                              throw Exception('ไม่พบข้อมูลผู้ใช้');
                            }
                            await firebaseService.submitSellerApplication(
                              userId: userId,
                              shopName: _shopName,
                              contactEmail: _contactEmail,
                              phoneNumber: _phoneNumber,
                            );

                            if (mounted) {
                              setState(() => _isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'ส่งใบสมัครเรียบร้อยแล้ว! รอการอนุมัติจากทีมงาน'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('เกิดข้อผิดพลาด: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('กำลังส่งใบสมัคร...'),
                          ],
                        )
                      : const Text(
                          'ส่งใบสมัคร',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
