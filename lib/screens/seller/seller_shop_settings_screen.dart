// lib/screens/seller/seller_shop_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/models/seller.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:uuid/uuid.dart';

class ShopSettingsScreen extends StatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopDescriptionController =
      TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _socialMediaLinkController =
      TextEditingController();

  XFile? _pickedShopImageFile;
  String? _currentShopImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อจัดการร้านค้า')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final seller = await firebaseService.getSellerFullDetails(currentUserId);
      if (mounted && seller != null) {
        _shopNameController.text = seller.shopName;
        _shopDescriptionController.text = seller.shopDescription ?? '';
        _contactEmailController.text = seller.contactEmail;
        _contactPhoneController.text = seller.contactPhone;
        _websiteController.text = seller.website ?? '';
        _socialMediaLinkController.text = seller.socialMediaLink ?? '';
        _currentShopImageUrl = seller.shopImageUrl;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลร้านค้า: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickShopImage() async {
    final XFile? selectedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (selectedImage != null) {
      if (mounted) {
        setState(() {
          _pickedShopImageFile = selectedImage;
          _currentShopImageUrl = null; // Clear current URL if new image picked
        });
      }
    }
  }

  Future<void> _saveShopDetails() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบผู้ใช้งาน')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      String? finalShopImageUrl = _currentShopImageUrl;

      if (_pickedShopImageFile != null) {
        const uuid = Uuid();
        final extension = _pickedShopImageFile!.name.split('.').last;
        final fileName = '${uuid.v4()}.$extension';
        const storagePath = 'shop_images';

        if (kIsWeb) {
          final bytes = await _pickedShopImageFile!.readAsBytes();
          finalShopImageUrl = await firebaseService.uploadImageBytes(
              storagePath, fileName, bytes);
        } else {
          finalShopImageUrl = await firebaseService.uploadImage(
              storagePath, _pickedShopImageFile!.path,
              fileName: fileName);
        }
      } else if (_currentShopImageUrl != null &&
          _currentShopImageUrl!.isEmpty) {
        // If user cleared the URL and didn't pick a new image, set to null
        finalShopImageUrl = null;
      }

      // Get current seller data first
      final currentSeller =
          await firebaseService.getSellerFullDetails(currentUserId);
      if (currentSeller == null) {
        throw Exception('ไม่พบข้อมูลผู้ขาย');
      }

      // Create updated seller object
      final updatedSeller = Seller(
        id: currentSeller.id,
        shopName: _shopNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        phoneNumber: _contactPhoneController.text.trim(),
        status: currentSeller.status,
        rating: currentSeller.rating,
        totalRatings: currentSeller.totalRatings,
        createdAt: currentSeller.createdAt,
        shopImageUrl: finalShopImageUrl,
        shopDescription: _shopDescriptionController.text.trim(),
        website: _websiteController.text.trim(),
        socialMediaLink: _socialMediaLinkController.text.trim(),
      );

      await firebaseService.updateShopDetails(updatedSeller);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลร้านค้าสำเร็จ!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopDescriptionController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _websiteController.dispose();
    _socialMediaLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('ตั้งค่าร้านค้า',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ข้อมูลร้านค้า',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _shopNameController,
                      decoration: _inputDecoration('ชื่อร้านค้า'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่อร้านค้า';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _shopDescriptionController,
                      decoration: _inputDecoration('คำอธิบายร้านค้า'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text('รูปภาพร้านค้า', style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Center(
                      child: _pickedShopImageFile != null
                          ? (kIsWeb
                              ? FutureBuilder<Uint8List>(
                                  future: _pickedShopImageFile!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(snapshot.data!,
                                          height: 150, fit: BoxFit.cover);
                                    }
                                    return const CircularProgressIndicator();
                                  })
                              : Image.file(File(_pickedShopImageFile!.path),
                                  height: 150, fit: BoxFit.cover))
                          : (_currentShopImageUrl != null &&
                                  _currentShopImageUrl!.isNotEmpty
                              ? Image.network(
                                  _currentShopImageUrl!,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildImageErrorPlaceholder(context),
                                )
                              : _buildImageErrorPlaceholder(context)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickShopImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('เลือกรูปภาพร้านค้า'),
                      ),
                    ),
                    if (_currentShopImageUrl != null ||
                        _pickedShopImageFile != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _pickedShopImageFile = null;
                              _currentShopImageUrl = null;
                            });
                          },
                          icon: const Icon(Icons.delete_forever_outlined),
                          label: const Text('ลบรูปภาพ'),
                        ),
                      ),
                    const SizedBox(height: 32),
                    Text('ข้อมูลติดต่อ',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactEmailController,
                      decoration: _inputDecoration('อีเมลติดต่อ'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactPhoneController,
                      decoration: _inputDecoration('เบอร์โทรศัพท์ติดต่อ'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _websiteController,
                      decoration: _inputDecoration('เว็บไซต์ (ถ้ามี)'),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _socialMediaLinkController,
                      decoration:
                          _inputDecoration('ลิงก์โซเชียลมีเดีย (ถ้ามี)'),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveShopDetails,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3),
                              )
                            : const Text('บันทึกการตั้งค่าร้านค้า'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2.0)),
        labelStyle: Theme.of(context).textTheme.bodyMedium);
  }

  Widget _buildImageErrorPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 150,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_outlined,
          size: 50, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
