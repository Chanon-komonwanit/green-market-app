// lib/screens/create_community_post_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/community_post.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';

class CreateCommunityPostScreen extends StatefulWidget {
  final CommunityPost? postToEdit;

  const CreateCommunityPostScreen({super.key, this.postToEdit});

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
  bool _mediaChanged = false;

  bool get _isEditing => widget.postToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _contentController.text = widget.postToEdit!.content;
      _tagsController.text = widget.postToEdit!.tags.join(', ');
    }
  }

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
        title: Text(_isEditing ? 'แก้ไขโพสต์' : 'สร้างโพสต์ใหม่',
            style:
                AppTextStyles.headline.copyWith(color: AppColors.surfaceWhite)),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.surfaceWhite,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: Text(_isEditing ? 'บันทึก' : 'โพสต์',
                style: AppTextStyles.button),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Header
                  _buildUserHeader(),

                  const SizedBox(height: AppTheme.padding),

                  // Content Input
                  _buildContentInput(),

                  const SizedBox(height: AppTheme.padding),

                  // Tags Input
                  _buildTagsInput(),

                  const SizedBox(height: AppTheme.padding),

                  // Media Selection Buttons
                  _buildMediaButtons(),

                  const SizedBox(height: AppTheme.padding),

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
              backgroundColor: AppColors.grayBorder,
              backgroundImage:
                  user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null
                  ? const Icon(Icons.person, color: AppColors.graySecondary)
                  : null,
            ),
            const SizedBox(width: AppTheme.padding),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.displayName ?? 'ผู้ใช้ไม่ระบุชื่อ',
                    style: AppTextStyles.bodyBold),
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
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppColors.grayBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppTheme.padding),
      ),
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'แท็ก (คั่นด้วย ,)',
          style: AppTextStyles.bodyBold,
        ),
        const SizedBox(height: AppTheme.smallPadding),
        TextField(
          controller: _tagsController,
          decoration: InputDecoration(
            hintText: 'เช่น สีเขียว, รักษ์โลก, อินทรีย์',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              borderSide: const BorderSide(color: AppColors.grayBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              borderSide:
                  const BorderSide(color: AppColors.primaryTeal, width: 2),
            ),
            contentPadding: const EdgeInsets.all(AppTheme.padding),
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
              backgroundColor: AppColors.primaryTeal.withOpacity(0.1),
              foregroundColor: AppColors.primaryTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.padding),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.videocam),
            label: const Text('เพิ่มวิดีโอ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.infoBlue.withOpacity(0.1),
              foregroundColor: AppColors.infoBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
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
              style: AppTextStyles.bodyBold,
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImages.clear();
                  _mediaChanged = true;
                });
              },
              child: Text('ลบทั้งหมด',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.errorRed)),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.smallPadding),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: AppTheme.smallPadding),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
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
                            color: AppColors.errorRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.white,
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
        const SizedBox(height: AppTheme.padding),
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
              style: AppTextStyles.bodyBold,
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedVideo = null;
                  _mediaChanged = true;
                });
              },
              child: Text('ลบ',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.errorRed)),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.smallPadding),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.grayPrimary,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      color: AppColors.white,
                      size: 64,
                    ),
                    const SizedBox(height: AppTheme.smallPadding),
                    Text(
                      _selectedVideo!.name,
                      style:
                          AppTextStyles.body.copyWith(color: AppColors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.padding),
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
          _mediaChanged = true;
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
          _mediaChanged = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกวิดีโอ: $e')),
      );
    }
  }

  Future<void> _submitPost() async {
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
        final uploadTasks = _selectedImages.map((image) {
          final imageFile = File(image.path);
          final fileName =
              'community_posts/${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
          return _firebaseService.uploadImageFile(imageFile, fileName);
        }).toList();
        imageUrls = await Future.wait(uploadTasks);
      }

      // Upload video if any
      String? videoUrl;
      if (_selectedVideo != null) {
        final videoFile = File(_selectedVideo!.path);
        final fileName =
            'community_posts/${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}_${_selectedVideo!.name}';
        videoUrl = await _firebaseService.uploadVideoFile(videoFile, fileName);
      }

      if (_isEditing) {
        await _firebaseService.updateCommunityPost(
          postId: widget.postToEdit!.id,
          content: content,
          tags: tags,
          imageUrls: _mediaChanged ? imageUrls : null,
          videoUrl: _mediaChanged ? videoUrl : null,
        );
      } else {
        await _firebaseService.createCommunityPost(
          userId: currentUser.id,
          content: content,
          imageUrls: imageUrls,
          videoUrl: videoUrl,
          tags: tags,
        );
      }

      if (mounted) {
        Navigator.pop(
            context, true); // Return true to indicate post was created
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEditing ? 'แก้ไขโพสต์แล้ว!' : 'โพสต์เรียบร้อยแล้ว!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: AppColors.errorRed),
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
