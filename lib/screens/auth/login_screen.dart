// d:/Development/green_market/lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:green_market/providers/auth_provider.dart';
import 'package:green_market/screens/auth/forgot_password_screen.dart';
import 'package:green_market/screens/auth/registration_screen.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Navigation is handled by the auth state listener in main.dart
    } on FirebaseAuthException catch (e) {
      String message = 'เกิดข้อผิดพลาด กรุณาตรวจสอบข้อมูลการเข้าสู่ระบบ';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      } else if (e.code == 'user-disabled') {
        message = 'บัญชีผู้ใช้นี้ถูกระงับการใช้งาน';
      }
      if (mounted) {
        showAppSnackBar(context, message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'เข้าสู่ระบบไม่สำเร็จ: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signInWithGoogle();
      // Navigation is handled by the auth state listener in main.dart
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
            context, 'เข้าสู่ระบบด้วย Google ไม่สำเร็จ: ${e.toString()}',
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.eco_outlined,
                    size: 80, color: AppColors.primaryGreen),
                const SizedBox(height: 16),
                Text('ยินดีต้อนรับสู่ Green Market',
                    style: AppTextStyles.headline),
                const SizedBox(height: 8),
                Text('เข้าสู่ระบบเพื่อใช้งาน',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.modernGrey)),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'รหัสผ่าน',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().length < 6) {
                      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ));
                    },
                    child: const Text('ลืมรหัสผ่าน?'),
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('เข้าสู่ระบบ'),
                      ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const RegistrationScreen(),
                    ));
                  },
                  child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('หรือ'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata), // Placeholder
                  label: const Text('เข้าสู่ระบบด้วย Google'),
                  onPressed: _isLoading ? null : _googleSignIn,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
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
