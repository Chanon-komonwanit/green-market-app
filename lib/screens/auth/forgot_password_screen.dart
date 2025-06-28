// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/providers/auth_provider.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        showAppSnackBar(
          context,
          'ลิงก์สำหรับรีเซ็ตรหัสผ่านได้ถูกส่งไปยังอีเมลของคุณแล้ว',
          isSuccess: true,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'เกิดข้อผิดพลาด: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลืมรหัสผ่าน'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'กรอกอีเมลของคุณ',
                  style: AppTextStyles.headline,
                ),
                const SizedBox(height: 8),
                Text(
                  'เราจะส่งลิงก์สำหรับรีเซ็ตรหัสผ่านไปยังอีเมลของคุณ',
                  textAlign: TextAlign.center,
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.modernGrey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        !value.contains('@')) {
                      return 'กรุณากรอกอีเมลที่ถูกต้อง';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _sendResetLink,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('ส่งลิงก์รีเซ็ต'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
