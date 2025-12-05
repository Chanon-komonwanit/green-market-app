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
import '../models/post_location.dart';
import '../services/firebase_service.dart';
import '../services/content_moderation_service.dart';
import '../services/eco_influence_service.dart';
import '../services/image_compression_service.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../utils/hashtag_detector.dart';
import '../services/post_auto_categorizer.dart';
import '../widgets/post_type_selector.dart';
import '../widgets/post_category_selector.dart';
import '../widgets/hashtag_suggestions_widget.dart';
import '../widgets/user_picker_dialog.dart';
import '../widgets/location_picker_dialog.dart';

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
  PostCategory? _selectedCategory; // NEW: Selected category
  PostCategorizationResult? _autoCategorizationResult; // NEW: AI suggestion
  bool _showAutoSuggestion = true; // NEW: Show AI suggestion banner
  String? _selectedProductId;
  String? _selectedActivityId;

  // Poll fields
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _pollDuration = 1; // days

  // NEW: Friend tagging and location fields
  List<String> _taggedUserIds = [];
  Map<String, String> _taggedUserNames = {};
  PostLocation? _selectedLocation;

  bool get _isEditing => widget.postToEdit != null;

  @override
  void initState() {
    super.initState();

    // Listen to content changes for auto-categorization
    _contentController.addListener(_onContentChanged);

    if (_isEditing) {
      _contentController.text = widget.postToEdit!.content;
      _tagsController.text = widget.postToEdit!.tags.join(', ');
      _selectedPostType = widget.postToEdit!.postType;
      _selectedProductId = widget.postToEdit!.productId;
      _selectedActivityId = widget.postToEdit!.activityId;
      _taggedUserIds = List.from(widget.postToEdit!.taggedUserIds);
      _taggedUserNames = Map.from(widget.postToEdit!.taggedUserNames);
      _selectedLocation = widget.postToEdit!.location;
    }
  }

  /// Auto-categorize when content changes
  void _onContentChanged() {
    if (_contentController.text.length > 20 && !_isEditing) {
      // Debounce: only categorize after user stops typing
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          final result =
              PostAutoCategorizer.categorize(_contentController.text);
          if (result.isHighConfidence || result.isMediumConfidence) {
            setState(() {
              _autoCategorizationResult = result;
              _showAutoSuggestion = true;
            });
          }
        }
      });
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

                  // AI Auto-Categorization Suggestion
                  if (_autoCategorizationResult != null && _showAutoSuggestion)
                    _buildAutoCategorizationBanner(),

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

                  // Activity Selector (if applicable)
                  if (_selectedPostType == PostType.marketplace)
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
                          const SizedBox(height: 12),
                          _buildTagUsersButton(),
                          const SizedBox(height: 8),
                          _buildLocationButton(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Hashtag Suggestions (แบบ Instagram)
                  HashtagSuggestionsWidget(
                    contentController: _contentController,
                    onHashtagTapped: (tag) {
                      final currentText = _contentController.text;
                      if (!currentText.contains('#$tag')) {
                        setState(() {
                          _contentController.text = '$currentText #$tag';
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Tagged Users Display
                  if (_taggedUserIds.isNotEmpty) _buildTaggedUsersDisplay(),

                  // Location Display
                  if (_selectedLocation != null) _buildLocationDisplay(),

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

  /// AI Auto-Categorization Suggestion Banner (Facebook/Instagram style)
  Widget _buildAutoCategorizationBanner() {
    final result = _autoCategorizationResult!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryTeal.withOpacity(0.1),
            AppColors.accentGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.isHighConfidence
              ? AppColors.primaryTeal
              : AppColors.accentGreen,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'คำแนะนำจาก AI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      result.isHighConfidence
                          ? 'ความมั่นใจสูง (${(result.confidence * 100).toInt()}%)'
                          : 'ความมั่นใจปานกลาง (${(result.confidence * 100).toInt()}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _showAutoSuggestion = false);
                },
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'เราคิดว่าโพสต์นี้เกี่ยวกับ "${result.suggestedType.description}"',
            style: AppTextStyles.body,
          ),
          if (result.detectedKeywords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.detectedKeywords.take(5).map((keyword) {
                return Chip(
                  label: Text(
                    keyword,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: AppColors.grayBorder,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedPostType = result.suggestedType;
                      if (result.suggestedCategoryId != null) {
                        _selectedCategory =
                            HashtagDetector.getStandardCategories().firstWhere(
                                (cat) => cat.id == result.suggestedCategoryId);
                      }
                      // Auto-add suggested tags
                      final currentTags = _tagsController.text
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();
                      final newTags =
                          {...currentTags, ...result.suggestedTags}.toList();
                      _tagsController.text = newTags.join(', ');
                      _showAutoSuggestion = false;
                    });
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('ใช้คำแนะนำนี้'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() => _showAutoSuggestion = false);
                },
                child: const Text('ข้าม'),
              ),
            ],
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.image, color: AppColors.primaryTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'รูปภาพที่เลือก (${_selectedImages.length}/5)',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImages.clear();
                    _mediaChanged = true;
                  });
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('ลบทั้งหมด'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return FutureBuilder<Uint8List>(
                  future: _selectedImages[index].readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.grayBorder,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final bytes = snapshot.data!;
                    final fileSize = bytes.length;
                    final fileSizeMB =
                        (fileSize / (1024 * 1024)).toStringAsFixed(2);

                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  bytes,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Badge แสดงลำดับ
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: AppTextStyles.captionBold.copyWith(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              // ปุ่มลบ
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                      _mediaChanged = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('ลบรูปที่ ${index + 1} แล้ว'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.errorRed,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
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
                          const SizedBox(height: 6),
                          // แสดงขนาดไฟล์
                          SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.insert_drive_file,
                                  size: 12,
                                  color: bytes.length > 10 * 1024 * 1024
                                      ? AppColors.errorRed
                                      : AppColors.graySecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$fileSizeMB MB',
                                  style: AppTextStyles.caption.copyWith(
                                    color: bytes.length > 10 * 1024 * 1024
                                        ? AppColors.errorRed
                                        : AppColors.graySecondary,
                                    fontWeight: bytes.length > 10 * 1024 * 1024
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          if (bytes.length > 10 * 1024 * 1024)
                            Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.errorRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '⚠️ ใหญ่เกิน',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.errorRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.videocam, color: AppColors.primaryTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'วิดีโอที่เลือก',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedVideo = null;
                    _mediaChanged = true;
                  });
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('ลบวิดีโอ'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<int>(
            future: _selectedVideo!.length(),
            builder: (context, snapshot) {
              final fileSize = snapshot.data ?? 0;
              final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
              final isTooBig = fileSize > 50 * 1024 * 1024; // 50 MB limit

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.grayPrimary,
                          AppColors.grayPrimary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTooBig
                            ? AppColors.errorRed
                            : AppColors.primaryTeal.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_fill,
                                color: isTooBig
                                    ? AppColors.errorRed.withOpacity(0.8)
                                    : AppColors.white,
                                size: 72,
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  children: [
                                    Text(
                                      _selectedVideo!.name,
                                      style: AppTextStyles.bodyBold
                                          .copyWith(color: AppColors.white),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isTooBig
                                            ? AppColors.errorRed
                                            : AppColors.primaryTeal,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isTooBig
                                                ? Icons.error_outline
                                                : Icons.videocam,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$fileSizeMB MB',
                                            style: AppTextStyles.captionBold
                                                .copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isTooBig)
                          Positioned(
                            top: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ไฟล์ใหญ่เกิน 50 MB',
                                      style: AppTextStyles.bodyBold.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            size: 16,
                            color: isTooBig
                                ? AppColors.errorRed
                                : AppColors.graySecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ขนาด: $fileSizeMB MB',
                            style: AppTextStyles.caption.copyWith(
                              color: isTooBig
                                  ? AppColors.errorRed
                                  : AppColors.graySecondary,
                              fontWeight: isTooBig
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      if (isTooBig)
                        Text(
                          'ใหญ่เกินไป!',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.errorRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  if (isTooBig)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠️ แนะนำ: บีบอัดวิดีโอก่อนอัปโหลด หรือเลือกวิดีโอที่สั้นกว่า',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.errorRed,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
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
        // จำกัดจำนวนรูปสูงสุด 5 รูป
        const maxImages = 5;
        final remainingSlots = maxImages - _selectedImages.length;

        if (remainingSlots <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ เลือกได้สูงสุด 5 รูปเท่านั้น'),
                backgroundColor: AppColors.errorRed,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        final imagesToAdd = images.take(remainingSlots).toList();

        if (images.length > remainingSlots) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '⚠️ เลือกได้เพิ่มอีกเพียง $remainingSlots รูป (เพิ่ม ${imagesToAdd.length} รูป)'),
                backgroundColor: AppColors.warningAmber,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        // ตรวจสอบขนาดไฟล์แต่ละรูป (จำกัด 10MB)
        const maxFileSize = 10 * 1024 * 1024; // 10 MB
        final validImages = <XFile>[];

        for (final image in imagesToAdd) {
          final fileSize = await image.length();
          if (fileSize > maxFileSize) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '❌ รูป "${image.name}" ใหญ่เกินไป (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB)\nจำกัดไม่เกิน 10 MB'),
                  backgroundColor: AppColors.errorRed,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } else {
            validImages.add(image);
          }
        }

        if (validImages.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(validImages);
            // Remove video if images are selected (one media type at a time)
            _selectedVideo = null;
            _mediaChanged = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ เพิ่มรูปภาพ ${validImages.length} รูป (รวม ${_selectedImages.length}/$maxImages)'),
                backgroundColor: AppColors.successGreen,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'ไม่สามารถเลือกรูปภาพได้';

        if (e.toString().contains('permission')) {
          errorMessage = 'กรุณาอนุญาตให้แอปเข้าถึงคลังรูปภาพ';
        } else if (e.toString().contains('camera')) {
          errorMessage = 'ไม่สามารถเข้าถึงกล้องหรือคลังรูปภาพได้';
        } else if (e.toString().contains('format')) {
          errorMessage = 'รูปภาพมีรูปแบบไฟล์ที่ไม่รองรับ';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ $errorMessage\n\nหมายเหตุ: รองรับไฟล์ JPG, PNG เท่านั้น'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1), // จำกัด 60 วินาที
      );

      if (video != null) {
        // ตรวจสอบขนาดไฟล์ (จำกัด 50MB)
        final fileSize = await video.length();
        const maxSize =
            50 * 1024 * 1024; // 50 MB (ลดลงจาก 100MB เพื่อประสิทธิภาพ)

        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ วิดีโอใหญ่เกินไป\n'
                    'ขนาด: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB\n'
                    'จำกัดไม่เกิน: 50 MB'),
                backgroundColor: AppColors.errorRed,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        // แสดง loading indicator
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        // บน Mobile: ตรวจสอบความยาววิดีโอ (จำกัด 60 วินาที)
        if (!kIsWeb) {
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
                    content: Text('❌ วิดีโอยาวเกินไป\n'
                        'ความยาว: ${duration.inSeconds} วินาที\n'
                        'จำกัดไม่เกิน: 60 วินาที'),
                    backgroundColor: AppColors.errorRed,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
              return;
            }
          } catch (e) {
            debugPrint('⚠️ Cannot verify video duration: $e');
            // ดำเนินการต่อ แม้ไม่สามารถตรวจสอบความยาวได้
          }
        }

        setState(() {
          _selectedVideo = video;
          _selectedImages.clear(); // ลบรูปทั้งหมด (1 ประเภทมีเดียต่อครั้ง)
          _mediaChanged = true;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ เลือกวิดีโอสำเร็จ\n'
                'ขนาด: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
              ),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาดในการเลือกวิดีโอ:\n$e'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
          ),
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
      // Parse tags - Auto-extract hashtags from content (Instagram style)
      final tagsInput = _tagsController.text.trim();
      final manualTags = tagsInput.isNotEmpty
          ? tagsInput
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList()
          : <String>[];

      // Auto-extract hashtags from content
      final autoTags = HashtagDetector.extractHashtags(content);

      // Combine manual tags and auto-extracted hashtags (remove duplicates)
      final allTags = <String>{...manualTags, ...autoTags}.toList();

      // Extract mentions (@username)
      final mentions = HashtagDetector.extractMentions(content);

      // Add category tags if selected
      if (_selectedCategory != null) {
        allTags.addAll(
            _selectedCategory!.tags.where((tag) => !allTags.contains(tag)));
      }

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
          tags: allTags, // Use auto-extracted tags
          imageUrls: _mediaChanged ? imageUrls : null,
          videoUrl: _mediaChanged ? videoUrl : null,
          pollData: pollData,
          taggedUserIds: _taggedUserIds,
          taggedUserNames: _taggedUserNames,
          location: _selectedLocation,
        );
      } else {
        // ✅ เพิ่ม Content Moderation ก่อนโพสต์
        final moderationService = ContentModerationService();
        final moderationResult = await moderationService.moderateContent(
          content,
          imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
          videoUrl: videoUrl,
        );

        // ถ้าเจอเนื้อหาไม่เหมาะสม
        if (!moderationResult.isClean) {
          // แสดงแจ้งเตือนผู้ใช้
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('⚠️ ตรวจพบเนื้อหาไม่เหมาะสม'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('เนื้อหาของคุณมีปัญหาดังนี้:'),
                    const SizedBox(height: 8),
                    ...moderationResult.issues.map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Text('• $issue',
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'กรุณาแก้ไขเนื้อหาก่อนโพสต์\n\nการโพสต์เนื้อหาไม่เหมาะสมจะส่งผลให้คะแนนอิทธิพลของคุณลดลง',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ตกลง'),
                  ),
                ],
              ),
            );
          }
          return; // ยกเลิกการโพสต์
        }

        final newPostId = await _firebaseService.createCommunityPost(
          userId: currentUser.id,
          content: content,
          imageUrls: imageUrls,
          videoUrl: videoUrl,
          tags: allTags, // Use auto-extracted tags
          pollData: pollData,
          taggedUserIds: _taggedUserIds,
          taggedUserNames: _taggedUserNames,
          location: _selectedLocation,
        );

        // 🌟 เพิ่มคะแนนอิทธิพลเมื่อโพสต์
        final ecoInfluenceService = EcoInfluenceService();
        await ecoInfluenceService.awardPostPoints(currentUser.id);

        // เพิ่ม engagement base score สำหรับการโพสต์ (1 คะแนน)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.id)
            .update({
          'communityEngagement': FieldValue.increment(1),
        });

        // ถ้าเจอเนื้อหาน่าสงสัย (Low/Medium) - อนุญาตให้โพสต์แต่ส่งรายงานไป Admin
        if (moderationResult.severity != ModerationSeverity.none) {
          await moderationService.sendAutoReportToAdmin(
            contentId: newPostId,
            contentType: 'community_post',
            userId: currentUser.id,
            severity: moderationResult.severity,
            issues: moderationResult.issues,
            contentPreview:
                content.length > 100 ? content.substring(0, 100) : content,
            imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
            videoUrl: videoUrl,
          );

          // หักคะแนนถ้าเป็น Medium หรือ High
          if (moderationResult.severity == ModerationSeverity.medium ||
              moderationResult.severity == ModerationSeverity.high) {
            await moderationService.recordViolationAndApplyPenalty(
              userId: currentUser.id,
              contentId: newPostId,
              contentType: 'community_post',
              severity: moderationResult.severity,
              issues: moderationResult.issues,
            );
          }
        }

        // Send notifications to tagged users
        if (_taggedUserIds.isNotEmpty) {
          await _sendTagNotifications(newPostId, currentUser);
        }

        // Send notifications to mentioned users
        if (mentions.isNotEmpty) {
          await _sendMentionNotifications(newPostId, currentUser, mentions);
        }
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
        String errorMessage = 'ไม่สามารถโพสต์ได้';

        if (e.toString().contains('network')) {
          errorMessage =
              'เกิดข้อผิดพลาดเกี่ยวกับการเชื่อมต่อเครือข่าย กรุณาตรวจสอบอินเทอร์เน็ต';
        } else if (e.toString().contains('storage')) {
          errorMessage =
              'ไม่สามารถอัพโหลดรูปภาพหรือวีดีโอได้ กรุณาลองใหม่อีกครั้ง';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'ไม่มีสิทธิ์ในการดำเนินการ กรุณาตรวจสอบการเข้าสู่ระบบ';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'หมดเวลาในการเชื่อมต่อ กรุณาลองใหม่อีกครั้ง';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ $errorMessage\n\nรายละเอียด: ${e.toString().length > 100 ? "${e.toString().substring(0, 100)}..." : e.toString()}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'ลองอีกครั้ง',
              textColor: Colors.white,
              onPressed: () => _submitPost(),
            ),
          ),
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

  // ============================================================================
  // NEW METHODS: Friend Tagging Feature
  // ============================================================================

  Widget _buildTagUsersButton() {
    return OutlinedButton.icon(
      onPressed: _showUserPicker,
      icon: const Icon(Icons.person_add, size: 20),
      label: Text(
        _taggedUserIds.isEmpty
            ? 'แท็กเพื่อน'
            : 'แท็กเพื่อน (${_taggedUserIds.length})',
        style: AppTextStyles.body,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _taggedUserIds.isEmpty
            ? AppColors.grayPrimary
            : AppColors.primaryTeal,
        side: BorderSide(
          color: _taggedUserIds.isEmpty
              ? AppColors.grayBorder
              : AppColors.primaryTeal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Future<void> _showUserPicker() async {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('กรุณาเข้าสู่ระบบก่อน');
      return;
    }

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => UserPickerDialog(
        alreadySelectedIds: _taggedUserIds,
        currentUserId: currentUser.id,
      ),
    );

    if (result != null) {
      setState(() {
        _taggedUserIds = result;
      });

      // Fetch user names
      await _fetchTaggedUserNames();
    }
  }

  Future<void> _fetchTaggedUserNames() async {
    final names = <String, String>{};

    for (final userId in _taggedUserIds) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          names[userId] = data?['displayName'] ?? 'Unknown';
        }
      } catch (e) {
        debugPrint('Error fetching user $userId: $e');
        names[userId] = 'Unknown';
      }
    }

    setState(() {
      _taggedUserNames = names;
    });
  }

  Widget _buildTaggedUsersDisplay() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryTeal.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_add,
                size: 16,
                color: AppColors.primaryTeal,
              ),
              const SizedBox(width: 6),
              Text(
                'แท็กเพื่อน (${_taggedUserIds.length})',
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _taggedUserIds.map((userId) {
              final displayName = _taggedUserNames[userId] ?? 'Loading...';
              return Chip(
                label: Text(displayName),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _taggedUserIds.remove(userId);
                    _taggedUserNames.remove(userId);
                  });
                },
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // NEW METHODS: Location/Check-in Feature
  // ============================================================================

  Widget _buildLocationButton() {
    return OutlinedButton.icon(
      onPressed: _showLocationPicker,
      icon: Icon(
        _selectedLocation?.typeIcon ?? Icons.add_location,
        size: 20,
      ),
      label: Text(
        _selectedLocation?.name ?? 'เพิ่มสถานที่',
        style: AppTextStyles.body,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _selectedLocation != null
            ? AppColors.primaryTeal
            : AppColors.grayPrimary,
        side: BorderSide(
          color: _selectedLocation != null
              ? AppColors.primaryTeal
              : AppColors.grayBorder,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    final result = await showDialog<PostLocation>(
      context: context,
      builder: (context) => const LocationPickerDialog(),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  Widget _buildLocationDisplay() {
    if (_selectedLocation == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _selectedLocation!.typeIcon,
              color: _selectedLocation!.typeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedLocation!.name,
                  style: AppTextStyles.bodyBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_selectedLocation!.address != null)
                  Text(
                    _selectedLocation!.displayAddress,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _selectedLocation = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  Future<void> _sendTagNotifications(String postId, dynamic currentUser) async {
    for (final userId in _taggedUserIds) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
          'type': 'tag',
          'fromUserId': currentUser.id,
          'fromUserName': currentUser.displayName ?? 'ผู้ใช้',
          'fromUserPhoto': currentUser.photoUrl,
          'postId': postId,
          'message': '${currentUser.displayName ?? 'ผู้ใช้'} แท็กคุณในโพสต์',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      } catch (e) {
        debugPrint('Error sending notification to $userId: $e');
      }
    }
  }

  Future<void> _sendMentionNotifications(
      String postId, dynamic currentUser, List<String> mentions) async {
    // Search for users by displayName matching mentions
    for (final mention in mentions) {
      try {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('displayName', isEqualTo: mention)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userId = userQuery.docs.first.id;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .add({
            'type': 'mention',
            'fromUserId': currentUser.id,
            'fromUserName': currentUser.displayName ?? 'ผู้ใช้',
            'fromUserPhoto': currentUser.photoUrl,
            'postId': postId,
            'message':
                '${currentUser.displayName ?? 'ผู้ใช้'} กล่าวถึงคุณในโพสต์',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      } catch (e) {
        debugPrint('Error sending mention notification for @$mention: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }
}
