import 'package:flutter/material.dart';
import 'package:green_market/services/auth_service.dart';
import 'package:green_market/utils/constants.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _tryLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      final userCredential = await _authService.signInWithEmailPassword(
          _email, _password, context);
      if (userCredential != null) {
        // Navigation to MainScreen will be handled by StreamBuilder in main.dart
        print('Login successful: ${userCredential.user?.uid}');
      }
      // If login fails, AuthService already shows a SnackBar
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (ctx) => const RegisterScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เข้าสู่ระบบ Green Market',
            style: AppTextStyles.title.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Placeholder for Logo
                const Icon(
                  Icons
                      .eco_outlined, // Icon ต้นกล้า (ใช้ eco_outlined แทน sprout_outlined)
                  size: 80,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'อีเมล'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'กรุณากรอกอีเมลที่ถูกต้อง';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _email = value!;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _password = value!;
                  },
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  CircularProgressIndicator(color: AppColors.primaryTeal)
                else
                  ElevatedButton(
                    onPressed: _tryLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      textStyle: AppTextStyles.button,
                    ),
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _navigateToRegister,
                  child: Text(
                    'ยังไม่มีบัญชี? สมัครสมาชิกที่นี่',
                    style: AppTextStyles.link
                        .copyWith(color: AppColors.primaryTeal),
                  ),
                ),
                // TODO: Add "Forgot Password?" button
                // TODO: Add social login buttons (Google, Facebook, etc.)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
