import 'package:flutter/material.dart';

class EnhancedEditProfileScreen extends StatelessWidget {
  const EnhancedEditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขโปรไฟล์')),
      body: const Center(child: Text('Edit Profile')),
    );
  }
}
