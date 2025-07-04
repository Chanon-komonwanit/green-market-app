// lib/screens/create_community_post_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/community_post.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';

class CreateCommunityPostScreen extends StatefulWidget {
  const CreateCommunityPostScreen({super.key});

  @override
  State<CreateCommunityPostScreen> createState() =>
      _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState extends State<CreateCommunityPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

  final List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างโพสต์ใหม่'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: Text(
              'โพสต์',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Header
                  _buildUserHeader(),

                  const SizedBox(height: 16),

                  // Content Input
                  _buildContentInput(),

                  const SizedBox(height: 16),

                  // Tags Input
                  _buildTagsInput(),

                  const SizedBox(height: 16),

                  // Media Selection Buttons
                  _buildMediaButtons(),

                  const SizedBox(height: 16),

                  // Selected Images Preview
                  if (_selectedImages.isNotEmpty) _buildImagesPreview(),

                  // Selected Video Preview
                  if (_selectedVideo != null) _buildVideoPreview(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserHeader() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        return Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null
                  ? Icon(Icons.person, color: Colors.grey[600])
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'ผู้ใช้ไม่ระบุชื่อ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'แชร์กับชุมชนสีเขียว',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildContentInput() {
    return TextField(
      controller: _contentController,
      maxLines: 6,
      decoration: InputDecoration(
        hintText: 'คุณคิดอะไรอยู่เกี่ยวกับชีวิตสีเขียว?',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'แท็ก (คั่นด้วยเครื่องหมายจุลภาค)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _tagsController,
          decoration: InputDecoration(
            hintText: 'เช่น สีเขียว, รักษ์โลก, อินทรีย์',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library),
            label: const Text('เพิ่มรูปภาพ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[50],
              foregroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.videocam),
            label: const Text('เพิ่มวิดีโอ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'รูปภาพที่เลือก (${_selectedImages.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImages.clear();
                });
              },
              child:
                  const Text('ลบทั้งหมด', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImages[index].path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'วิดีโอที่เลือก',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedVideo = null;
                });
              },
              child: const Text('ลบ', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedVideo!.name,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
          // Remove video if images are selected (one media type at a time)
          _selectedVideo = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedVideo = video;
          // Remove images if video is selected (one media type at a time)
          _selectedImages.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกวิดีโอ: $e')),
      );
    }
  }

  Future<void> _createPost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _selectedImages.isEmpty && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มเนื้อหา รูปภาพ หรือวิดีโอ')),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse tags
      final tagsInput = _tagsController.text.trim();
      final tags = tagsInput.isNotEmpty
          ? tagsInput
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList()
          : <String>[];

      // Upload images if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        for (int i = 0; i < _selectedImages.length; i++) {
          // TODO: Implement image upload to Firebase Storage
          // For now, we'll use placeholder URLs
          imageUrls.add('https://placeholder.com/300x200');
        }
      }

      // Upload video if any
      String? videoUrl;
      if (_selectedVideo != null) {
        // TODO: Implement video upload to Firebase Storage
        // For now, we'll use a placeholder URL
        videoUrl = 'https://placeholder.com/video.mp4';
      }

      await _firebaseService.createCommunityPost(
        userId: currentUser.id,
        content: content,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        tags: tags,
      );

      if (mounted) {
        Navigator.pop(
            context, true); // Return true to indicate post was created
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('โพสต์เรียบร้อยแล้ว!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
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
}
