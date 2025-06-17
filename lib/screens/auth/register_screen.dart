import 'package:flutter/material.dart';
import 'package:green_market/services/auth_service.dart';
import 'package:green_market/utils/constants.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isLoading = false;

  void _tryRegister() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_password != _confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('รหัสผ่านไม่ตรงกัน'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
      final userCredential = await _authService.signUpWithEmailPassword(
          _email, _password, context);

      if (userCredential != null) {
        // Navigation to MainScreen will be handled by StreamBuilder in main.dart
        // You might want to create a user document in Firestore here if not done in AuthService
        print('Registration successful: ${userCredential.user?.uid}');
      }
      // If registration fails, AuthService already shows a SnackBar
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (ctx) => const LoginScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สมัครสมาชิก Green Market',
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
                Icon(Icons.eco_outlined,
                    size: 80, color: AppColors.primaryGreen),
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
                const SizedBox(height: 12),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'ยืนยันรหัสผ่าน'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณายืนยันรหัสผ่าน';
                    }
                    // You can add more complex password matching here if needed,
                    // but the main check is done in _tryRegister
                    return null;
                  },
                  onSaved: (value) {
                    _confirmPassword = value!;
                  },
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  CircularProgressIndicator(color: AppColors.primaryTeal)
                else
                  ElevatedButton(
                    onPressed: _tryRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      textStyle: AppTextStyles.button,
                    ),
                    child: const Text('สมัครสมาชิก'),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    'มีบัญชีอยู่แล้ว? เข้าสู่ระบบที่นี่',
                    style: AppTextStyles.link
                        .copyWith(color: AppColors.primaryTeal),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
