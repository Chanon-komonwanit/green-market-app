// lib/screens/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:green_market/models/post.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';

class CreatePostScreen extends StatefulWidget {
  final Post? editPost;

  const CreatePostScreen({
    super.key,
    this.editPost,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _existingImageUrl;
  bool _isSubmitting = false;
  bool get _isEditing => widget.editPost != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _textController.text = widget.editPost!.text;
      _existingImageUrl = widget.editPost!.imageUrl;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'แก้ไขโพสต์' : 'สร้างโพสต์ใหม่',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final currentUser = userProvider.currentUser;
          if (currentUser == null) {
            return const Center(
              child: Text('กรุณาเข้าสู่ระบบ'),
            );
          }

          return Column(
            children: [
              // User Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF059669),
                      backgroundImage: currentUser.profileImageUrl != null
                          ? NetworkImage(currentUser.profileImageUrl!)
                          : null,
                      child: currentUser.profileImageUrl == null
                          ? Text(
                              currentUser.displayName?.isNotEmpty == true
                                  ? currentUser.displayName![0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.displayName ?? 'ผู้ใช้ไม่ระบุชื่อ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.door_front_door,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'สาธารณะ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content Input
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Input
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _textFocus,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'คุณคิดอย่างไร...',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      // Image Preview
                      if (_selectedImage != null || _existingImageUrl != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        _existingImageUrl!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImage = null;
                                      _existingImageUrl = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
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
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Image Picker Button
                    IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(
                        Icons.image,
                        color: Color(0xFF059669),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Camera Button
                    IconButton(
                      onPressed: _takePhoto,
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF059669),
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEditing ? 'บันทึก' : 'โพสต์',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _existingImageUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _existingImageUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Future<void> _submitPost() async {
    if (_textController.text.trim().isEmpty &&
        _selectedImage == null &&
        _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเขียนข้อความหรือเลือกรูปภาพ')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.currentUser;

      if (currentUser == null || userData == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      String? imageUrl;
      if (_selectedImage != null) {
        // Upload new image
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('posts')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putFile(_selectedImage!);
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      } else if (_existingImageUrl != null) {
        // Keep existing image
        imageUrl = _existingImageUrl;
      }

      final postData = {
        'userId': currentUser.uid,
        'userName': userData.displayName ?? 'ผู้ใช้ไม่ระบุชื่อ',
        'userProfileImage': userData.profileImageUrl,
        'text': _textController.text.trim(),
        'imageUrl': imageUrl,
        'likes': _isEditing ? widget.editPost!.likes : <String>[],
        'commentCount': _isEditing ? widget.editPost!.commentCount : 0,
        'createdAt': _isEditing
            ? widget.editPost!.createdAt
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'tags': <String>[],
        'type': _getPostType(),
      };

      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.editPost!.id)
            .update(postData);
      } else {
        await FirebaseFirestore.instance.collection('posts').add(postData);
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'แก้ไขโพสต์สำเร็จ' : 'โพสต์สำเร็จ'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบโพสต์'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบโพสต์นี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost();
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    if (!_isEditing) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.editPost!.id)
          .delete();

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบโพสต์สำเร็จ'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _getPostType() {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasImage = _selectedImage != null || _existingImageUrl != null;

    if (hasText && hasImage) {
      return 'mixed';
    } else if (hasImage) {
      return 'image';
    } else {
      return 'text';
    }
  }
}
