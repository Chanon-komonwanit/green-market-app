// lib/screens/create_community_post_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../models/community_post.dart';
import '../models/post_type.dart';
import '../services/firebase_service.dart';
import '../services/content_moderation_service.dart';
import '../services/image_compression_service.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/post_type_selector.dart';

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
  final ContentModerationService _moderationService =
      ContentModerationService();
  final ImagePicker _picker = ImagePicker();

  final List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  bool _isLoading = false;
  bool _mediaChanged = false;
  PostType _selectedPostType = PostType.normal;
  String? _selectedProductId;
  String? _selectedActivityId;

  // Poll fields
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _pollDuration = 1; // days

  bool get _isEditing => widget.postToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _contentController.text = widget.postToEdit!.content;
      _tagsController.text = widget.postToEdit!.tags.join(', ');
      _selectedPostType = widget.postToEdit!.postType;
      _selectedProductId = widget.postToEdit!.productId;
      _selectedActivityId = widget.postToEdit!.activityId;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    for (var controller in _pollOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        elevation: 0,
        title: Text(_isEditing ? 'แก้ไขโพสต์' : 'สร้างโพสต์ใหม่',
            style:
                AppTextStyles.headline.copyWith(color: AppColors.surfaceWhite)),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.surfaceWhite,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: ElevatedButton(
                onPressed: _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _isEditing ? 'บันทึก' : 'โพสต์',
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primaryTeal,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังสร้างโพสต์...',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.graySecondary,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info
                  _buildUserHeader(),

                  const SizedBox(height: 20),

                  // Post Type Selector
                  PostTypeSelector(
                    selectedType: _selectedPostType,
                    onTypeSelected: (type) {
                      setState(() {
                        _selectedPostType = type;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Product/Activity Selector (if applicable)
                  if (_selectedPostType == PostType.product)
                    _buildProductSelector(),
                  if (_selectedPostType == PostType.activity)
                    _buildActivitySelector(),

                  const SizedBox(height: 16),

                  // Poll Builder (if poll type)
                  if (_selectedPostType == PostType.poll) ...[
                    _buildPollBuilder(),
                    const SizedBox(height: 16),
                  ],

                  // Main Content Card
                  Card(
                    elevation: 1,
                    shadowColor: AppColors.grayBorder.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContentInput(),
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 20),
                          _buildTagsInput(),
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Text(
                            'เพิ่มสื่อ',
                            style: AppTextStyles.bodyBold.copyWith(
                              color: AppColors.grayPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMediaButtons(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Selected Images Preview
                  if (_selectedImages.isNotEmpty) _buildImagesPreview(),

                  // Selected Video Preview
                  if (_selectedVideo != null) _buildVideoPreview(),

                  const SizedBox(height: 80), // Extra space for FAB
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เขียนอะไรสักหน่อย...',
          style: AppTextStyles.captionBold.copyWith(
            color: AppColors.graySecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          maxLines: 8,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'แชร์ความคิดเห็น ไอเดีย หรือประสบการณ์ด้านสิ่งแวดล้อม...',
            hintStyle:
                TextStyle(color: AppColors.graySecondary.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.grayBorder.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.grayBorder.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryTeal, width: 2),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'แท็กที่เกี่ยวข้อง',
          style: AppTextStyles.captionBold.copyWith(
            color: AppColors.graySecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _tagsController,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: '#สีเขียว #รักษ์โลก #อินทรีย์',
            hintStyle:
                TextStyle(color: AppColors.graySecondary.withOpacity(0.7)),
            prefixIcon:
                Icon(Icons.tag_rounded, color: AppColors.primaryTeal, size: 22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.grayBorder.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.grayBorder.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryTeal, width: 2),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaButtons() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: _selectedImages.isNotEmpty
                ? AppColors.primaryTeal.withOpacity(0.1)
                : AppColors.surfaceGray,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      color: _selectedImages.isNotEmpty
                          ? AppColors.primaryTeal
                          : AppColors.graySecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedImages.isEmpty
                          ? 'รูปภาพ'
                          : 'รูป (${_selectedImages.length})',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: _selectedImages.isNotEmpty
                            ? AppColors.primaryTeal
                            : AppColors.grayPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: _selectedVideo != null
                ? AppColors.primaryTeal.withOpacity(0.1)
                : AppColors.surfaceGray,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _pickVideo,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_outlined,
                      color: _selectedVideo != null
                          ? AppColors.primaryTeal
                          : AppColors.graySecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedVideo == null ? 'วิดีโอ' : 'วิดีโอ (1)',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: _selectedVideo != null
                            ? AppColors.primaryTeal
                            : AppColors.grayPrimary,
                      ),
                    ),
                  ],
                ),
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

  Widget _buildPollBuilder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryTeal.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              Text(
                'ตัวเลือกโพล',
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Poll Options
          ..._pollOptionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'ตัวเลือก ${index + 1}',
                        hintText: 'ใส่ตัวเลือก...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primaryTeal,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  if (index >= 2) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          controller.dispose();
                          _pollOptionControllers.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                    ),
                  ],
                ],
              ),
            );
          }),

          // Add Option Button
          if (_pollOptionControllers.length < 4)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _pollOptionControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('เพิ่มตัวเลือก'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
              ),
            ),

          const SizedBox(height: 16),

          // Poll Duration
          Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 20, color: AppColors.graySecondary),
              const SizedBox(width: 8),
              Text('ระยะเวลา:', style: AppTextStyles.body),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: _pollDuration,
                items: [1, 3, 7, 14].map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text('$days วัน'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _pollDuration = value;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
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
        // ตรวจสอบขนาดไฟล์ (จำกัด 100MB)
        final fileSize = await video.length();
        const maxSize = 100 * 1024 * 1024; // 100 MB

        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'วิดีโอใหญ่เกินไป (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB) จำกัดไม่เกิน 100 MB'),
                backgroundColor: AppColors.errorRed,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        // แสดงการโหลด
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        // บน Web/Mobile ตรวจสอบความยาววิดีโอ (จำกัด 60 วินาที)
        if (!kIsWeb) {
          // Mobile: ใช้ video_player ตรวจสอบ
          try {
            final videoFile = File(video.path);
            final controller = VideoPlayerController.file(videoFile);
            await controller.initialize();
            final duration = controller.value.duration;
            await controller.dispose();

            if (duration.inSeconds > 60) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'วิดีโอยาวเกินไป (${duration.inSeconds} วินาที) จำกัดไม่เกิน 60 วินาที'),
                    backgroundColor: AppColors.errorRed,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
              return;
            }
          } catch (e) {
            debugPrint('Cannot check video duration: $e');
          }
        }

        setState(() {
          _selectedVideo = video;
          _selectedImages.clear();
          _mediaChanged = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกวิดีโอ: $e')),
        );
      }
    }
  }

  Future<void> _submitPost() async {
    var content = _contentController.text.trim();

    if (content.isEmpty && _selectedImages.isEmpty && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มเนื้อหา รูปภาพ หรือวิดีโอ')),
      );
      return;
    }

    // Content Moderation Check
    if (content.isNotEmpty) {
      final moderationResult =
          await _moderationService.moderateContent(content);

      if (moderationResult.severity == ModerationSeverity.high) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('เนื้อหาของคุณมีเนื้อหาไม่เหมาะสม กรุณาแก้ไขก่อนโพสต์'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      if (moderationResult.severity == ModerationSeverity.medium) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ตรวจพบเนื้อหาที่ต้องสงสัย โปรดระวัง'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Use cleaned content
      content = moderationResult.cleanedContent;
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

      // Validate and create poll data if poll type
      Map<String, dynamic>? pollData;
      if (_selectedPostType == PostType.poll) {
        final validOptions = _pollOptionControllers
            .where((controller) => controller.text.trim().isNotEmpty)
            .map((controller) => controller.text.trim())
            .toList();

        if (validOptions.length < 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('กรุณากรอกตัวเลือกอย่างน้อย 2 ตัวเลือก'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        pollData = {
          'options': {
            for (var i = 0; i < validOptions.length; i++)
              'option_$i': {
                'id': 'option_$i',
                'text': validOptions[i],
                'votes': 0,
                'votedBy': [],
              }
          },
          'endTime': Timestamp.fromDate(
            DateTime.now().add(Duration(days: _pollDuration)),
          ),
          'totalVotes': 0,
          'allowMultipleVotes': false,
        };
      }

      // Upload images if any (with compression)
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final compressionService = ImageCompressionService();
        final uploadTasks = _selectedImages.map((image) async {
          if (kIsWeb) {
            // Web platform: compress bytes before upload
            final bytes = await image.readAsBytes();

            // บีบอัดรูปด้วย image package
            final img.Image? originalImage = img.decodeImage(bytes);
            if (originalImage != null) {
              // Resize ถ้าใหญ่เกิน 1920px
              img.Image resized = originalImage;
              if (originalImage.width > 1920 || originalImage.height > 1920) {
                resized = img.copyResize(
                  originalImage,
                  width: originalImage.width > 1920 ? 1920 : null,
                  height: originalImage.height > 1920 ? 1920 : null,
                );
              }

              // บีบอัดเป็น JPEG คุณภาพ 80%
              final compressedBytes =
                  Uint8List.fromList(img.encodeJpg(resized, quality: 80));

              final fileName =
                  '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
              return _firebaseService.uploadImageBytes(
                'community_posts/${currentUser.id}',
                fileName,
                compressedBytes,
              );
            } else {
              // ถ้าบีบอัดไม่ได้ ใช้ไฟล์เดิม
              final fileName =
                  '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
              return _firebaseService.uploadImageBytes(
                'community_posts/${currentUser.id}',
                fileName,
                bytes,
              );
            }
          } else {
            // Mobile platform: compress then upload
            final imageFile = File(image.path);
            final compressedFile =
                await compressionService.compressImageForPost(imageFile);
            final fileName =
                'community_posts/${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
            return _firebaseService.uploadImageFile(compressedFile, fileName);
          }
        }).toList();
        imageUrls = await Future.wait(uploadTasks);
      }

      // Upload video if any
      String? videoUrl;
      if (_selectedVideo != null) {
        if (kIsWeb) {
          // Web platform: use bytes
          final bytes = await _selectedVideo!.readAsBytes();
          final fileName = _selectedVideo!.name;
          videoUrl = await _firebaseService.uploadVideoBytes(
            bytes,
            'community_posts/${currentUser.id}/$fileName',
          );
        } else {
          // Mobile platform
          final videoFile = File(_selectedVideo!.path);
          final fileName =
              'community_posts/${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}_${_selectedVideo!.name}';
          videoUrl =
              await _firebaseService.uploadVideoFile(videoFile, fileName);
        }
      }

      if (_isEditing) {
        await _firebaseService.updateCommunityPost(
          postId: widget.postToEdit!.id,
          content: content,
          tags: tags,
          imageUrls: _mediaChanged ? imageUrls : null,
          videoUrl: _mediaChanged ? videoUrl : null,
          pollData: pollData,
        );
      } else {
        await _firebaseService.createCommunityPost(
          userId: currentUser.id,
          content: content,
          imageUrls: imageUrls,
          videoUrl: videoUrl,
          tags: tags,
          pollData: pollData,
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

  Widget _buildProductSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.shopping_bag, color: AppColors.primaryTeal),
        title:
            Text(_selectedProductId == null ? 'เลือกสินค้า' : 'สินค้าที่เลือก'),
        subtitle: _selectedProductId != null
            ? FutureBuilder<Map<String, dynamic>?>(
                future: _firebaseService.getProductById(_selectedProductId!),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Text(
                      snapshot.data!['name'] ?? 'สินค้า',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primaryTeal),
                    );
                  }
                  return Text('ID: $_selectedProductId');
                },
              )
            : const Text('แตะเพื่อเลือกสินค้าที่ต้องการแชร์'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedProductId != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => setState(() => _selectedProductId = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => _showProductSelectorDialog(),
      ),
    );
  }

  Future<void> _showProductSelectorDialog() async {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.padding),
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('เลือกสินค้า', style: AppTextStyles.headline),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              // Product List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where('sellerId', isEqualTo: currentUser.id)
                      .where('isActive', isEqualTo: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: AppColors.graySecondary),
                            const SizedBox(height: 16),
                            Text('ยังไม่มีสินค้า', style: AppTextStyles.body),
                            const SizedBox(height: 8),
                            Text('กรุณาเพิ่มสินค้าก่อนแชร์',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final product = snapshot.data!.docs[index];
                        final data = product.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: data['imageUrls'] != null &&
                                  (data['imageUrls'] as List).isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    data['imageUrls'][0],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.grayPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image,
                                      color: AppColors.graySecondary),
                                ),
                          title: Text(data['name'] ?? 'ไม่มีชื่อ',
                              style: AppTextStyles.body),
                          subtitle: Text(
                            '฿${data['price']?.toStringAsFixed(0) ?? '0'}',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.primaryTeal),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, product.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedProductId = selected;
      });
    }
  }

  Widget _buildActivitySelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.eco, color: AppColors.primaryTeal),
        title: Text(
            _selectedActivityId == null ? 'เลือกกิจกรรม' : 'กิจกรรมที่เลือก'),
        subtitle: _selectedActivityId != null
            ? FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('activities')
                    .doc(_selectedActivityId!)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    return Text(
                      data['title'] ?? 'กิจกรรม',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primaryTeal),
                    );
                  }
                  return Text('ID: $_selectedActivityId');
                },
              )
            : const Text('แตะเพื่อเลือกกิจกรรมที่ต้องการแชร์'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedActivityId != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => setState(() => _selectedActivityId = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => _showActivitySelectorDialog(),
      ),
    );
  }

  Future<void> _showActivitySelectorDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.padding),
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('เลือกกิจกรรม', style: AppTextStyles.headline),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              // Activity List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('activities')
                      .where('isActive', isEqualTo: true)
                      .orderBy('startDate', descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 64, color: AppColors.graySecondary),
                            const SizedBox(height: 16),
                            Text('ยังไม่มีกิจกรรม', style: AppTextStyles.body),
                            const SizedBox(height: 8),
                            Text('รอกิจกรรมใหม่', style: AppTextStyles.caption),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final activity = snapshot.data!.docs[index];
                        final data = activity.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.eco,
                                color: AppColors.primaryTeal),
                          ),
                          title: Text(data['title'] ?? 'ไม่มีชื่อ',
                              style: AppTextStyles.body),
                          subtitle: Text(
                            '${data['ecoCoins'] ?? 0} Eco Coins',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.accentGreen),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, activity.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedActivityId = selected;
      });
    }
  }
}
