// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/community_post.dart';

class PostDetailScreen extends StatelessWidget {
  final CommunityPost post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดโพสต์'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'หน้ารายละเอียดโพสต์\nจะพัฒนาต่อไป',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
