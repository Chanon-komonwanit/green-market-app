// lib/screens/create_story_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:green_market/widgets/modern_dialogs.dart';
import 'dart:io';

/// Create Story Screen - สร้าง Instagram-style Stories
/// พร้อม Text Overlay, Stickers, และ Filters
class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedMedia;
  String _textOverlay = '';
  Color _textColor = Colors.white;
  final double _textSize = 24.0;
  final List<Map<String, dynamic>> _stickers = [];

  bool _isLoading = false;

  final List<Color> _textColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.pink,
  ];

  final List<String> _availableStickers = [
    '🌱',
    '🌿',
    '🍃',
    '♻️',
    '🌍',
    '💚',
    '🌳',
    '🌲',
    '🌺',
    '🌸',
    '🌼',
    '🌻',
    '🌷',
    '🏞️',
    '⛰️',
    '🏕️',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media Preview
          if (_selectedMedia != null)
            Positioned.fill(
              child: kIsWeb
                  ? FutureBuilder<Uint8List>(
                      future: _selectedMedia!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      },
                    )
                  : Image.file(
                      File(_selectedMedia!.path),
                      fit: BoxFit.cover,
                    ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryTeal,
                    AppColors.accentGreen,
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'แตะเพื่อเลือกรูปภาพ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

          // Text Overlay
          if (_textOverlay.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _textOverlay,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: _textSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Stickers
          ..._stickers.map((sticker) {
            return Positioned(
              left: sticker['x'],
              top: sticker['y'],
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    sticker['x'] += details.delta.dx;
                    sticker['y'] += details.delta.dy;
                  });
                },
                child: Text(
                  sticker['emoji'],
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            );
          }),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (_selectedMedia != null)
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.white),
                      onPressed: _isLoading ? null : _publishStory,
                    ),
                ],
              ),
            ),
          ),

          // Bottom Tools
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tool Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToolButton(
                        Icons.image,
                        'รูปภาพ',
                        () => _pickMedia(ImageSource.gallery),
                      ),
                      _buildToolButton(
                        Icons.camera_alt,
                        'กล้อง',
                        () => _pickMedia(ImageSource.camera),
                      ),
                      _buildToolButton(
                        Icons.text_fields,
                        'ข้อความ',
                        _showTextEditor,
                      ),
                      _buildToolButton(
                        Icons.emoji_emotions,
                        'Sticker',
                        _showStickerPicker,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final XFile? media = await _picker.pickImage(source: source);
      if (media != null) {
        setState(() {
          _selectedMedia = media;
        });
      }
    } catch (e) {
      ModernDialog.showError(
        context: context,
        title: 'เกิดข้อผิดพลาด',
        message: 'ไม่สามารถเลือกรูปภาพได้',
      );
    }
  }

  void _showTextEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'พิมพ์ข้อความ...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _textOverlay = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Color Picker
              Wrap(
                spacing: 8,
                children: _textColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _textColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _textColor == color
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('เสร็จสิ้น'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'เลือก Sticker',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _availableStickers.length,
              itemBuilder: (context, index) {
                final emoji = _availableStickers[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _stickers.add({
                        'emoji': emoji,
                        'x': 100.0,
                        'y': 200.0,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishStory() async {
    if (_selectedMedia == null) {
      ModernDialog.showError(
        context: context,
        title: 'กรุณาเลือกรูปภาพ',
        message: 'คุณต้องเลือกรูปภาพก่อนเผยแพร่ Story',
      );
      return;
    }

    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image to Firebase Storage
      // TODO: Implement actual upload

      // Create story document
      await FirebaseFirestore.instance.collection('stories').add({
        'userId': currentUser.id,
        'userName': currentUser.displayName,
        'userPhoto': currentUser.profileImageUrl,
        'mediaUrl':
            'https://placeholder.com/story.jpg', // TODO: Replace with actual URL
        'mediaType': 'image',
        'textOverlay': _textOverlay,
        'textColor': _textColor.value,
        'textSize': _textSize,
        'stickers': _stickers,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
        'views': [],
      });

      ModernDialog.showSuccess(
        context: context,
        title: 'เผยแพร่สำเร็จ!',
        message: 'Story ของคุณถูกเผยแพร่แล้ว',
      );

      // Return true to indicate success
      Navigator.pop(context, true);
    } catch (e) {
      ModernDialog.showError(
        context: context,
        title: 'เกิดข้อผิดพลาด',
        message: e.toString(),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
