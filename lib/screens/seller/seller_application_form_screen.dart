import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/providers/user_provider.dart';

class SellerApplicationFormScreen extends StatefulWidget {
  const SellerApplicationFormScreen({super.key});

  @override
  State<SellerApplicationFormScreen> createState() => _SellerApplicationFormScreenState();
}

class _SellerApplicationFormScreenState extends State<SellerApplicationFormScreen> {
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
              const Text('ชื่อร้านค้า', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: const InputDecoration(hintText: 'กรอกชื่อร้าน'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกชื่อร้าน' : null,
                onSaved: (v) => _shopName = v ?? '',
              ),
              const SizedBox(height: 16),
              const Text('อีเมลติดต่อ', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: currentUser?.email ?? '',
                decoration: const InputDecoration(hintText: 'กรอกอีเมล'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกอีเมล' : null,
                onSaved: (v) => _contactEmail = v ?? '',
              ),
              const SizedBox(height: 16),
              const Text('เบอร์โทรศัพท์', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: const InputDecoration(hintText: 'กรอกเบอร์โทรศัพท์'),
                validator: (v) => v == null || v.isEmpty ? 'กรุณากรอกเบอร์โทรศัพท์' : null,
                onSaved: (v) => _phoneNumber = v ?? '',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    _formKey.currentState!.save();
                    setState(() => _isSubmitting = true);
                    try {