// lib/screens/seller/shop_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentShopImageUrl;
  XFile? _pickedImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      final shopData = await firebaseService.getShopDetails(user.uid);
      if (shopData != null) {
        _shopNameController.text = shopData['shopName'] ?? '';
        _shopDescriptionController.text = shopData['shopDescription'] ?? '';
        _currentShopImageUrl = shopData['shopImageUrl'];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลร้านค้า: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickShopImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = pickedFile;
        // _currentShopImageUrl = null; // Optional: clear current image preview immediately
      });
    }
  }

  Future<void> _saveShopDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    String? newShopImageUrl = _currentShopImageUrl;
    String? oldShopImageUrlToDelete;

    if (_pickedImageFile != null) {
      try {
        var uuid = const Uuid();
        String extension = _pickedImageFile!.name.split('.').last;
        if (_currentShopImageUrl != null && _currentShopImageUrl!.isNotEmpty) {
          oldShopImageUrlToDelete =
              _currentShopImageUrl; // Store old URL for deletion
        }
        String fileName =
            'shop_profiles/${user.uid}/${uuid.v4()}.$extension'; // Store in a user-specific folder

        if (kIsWeb) {
          final bytes = await _pickedImageFile!.readAsBytes();
          newShopImageUrl = await firebaseService.uploadImageBytes(
              'shops', fileName, bytes); // Changed storagePath
        } else {
          newShopImageUrl = await firebaseService.uploadImage(
              'shops', _pickedImageFile!.path,
              fileName: fileName); // Changed storagePath
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูป: $e'),
              backgroundColor: AppColors.errorRed));
        }
        setState(() => _isSaving = false);
        return;
      }
    }

    try {
      await firebaseService.updateShopDetails(
          user.uid, _shopNameController.text, _shopDescriptionController.text,
          shopImageUrl: newShopImageUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('บันทึกข้อมูลร้านค้าสำเร็จ!'),
              backgroundColor: AppColors.successGreen),
        );
      }
      // Delete the old shop image from storage if a new one was uploaded and shop details update was successful
      if (oldShopImageUrlToDelete != null &&
          oldShopImageUrlToDelete != newShopImageUrl) {
        // Ensure we don't delete the new image if URLs are somehow the same
        await firebaseService.deleteImageByUrl(oldShopImageUrlToDelete);
      }

      // Update current image URL if a new one was uploaded and saved
      if (_pickedImageFile != null && newShopImageUrl != null) {
        setState(() => _currentShopImageUrl = newShopImageUrl);
      }
      _pickedImageFile = null; // Reset picked file
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการบันทึก: ${e.toString()}'),
              backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ตั้งค่าร้านค้า',
            style: AppTextStyles.title
                .copyWith(color: AppColors.white, fontSize: 20)),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.lightModernGrey,
                            backgroundImage: _pickedImageFile != null
                                ? (kIsWeb
                                        ? NetworkImage(_pickedImageFile!
                                            .path) // For web, path is a URL
                                        : FileImage(
                                            File(_pickedImageFile!.path)))
                                    as ImageProvider // For mobile
                                : (_currentShopImageUrl != null &&
                                        _currentShopImageUrl!.isNotEmpty
                                    ? NetworkImage(_currentShopImageUrl!)
                                    : null),
                            child: (_pickedImageFile == null &&
                                    (_currentShopImageUrl == null ||
                                        _currentShopImageUrl!.isEmpty))
                                ? const Icon(Icons.storefront,
                                    size: 60, color: AppColors.modernGrey)
                                : null,
                          ),
                          MaterialButton(
                            onPressed: _pickShopImage,
                            color: AppColors.primaryTeal,
                            textColor: Colors.white,
                            padding: const EdgeInsets.all(8),
                            shape: const CircleBorder(),
                            child: const Icon(Icons.camera_alt, size: 20),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                          onPressed: _pickShopImage,
                          child: Text(
                              _currentShopImageUrl != null ||
                                      _pickedImageFile != null
                                  ? 'เปลี่ยนรูปโปรไฟล์ร้าน'
                                  : 'เพิ่มรูปโปรไฟล์ร้าน',
                              style: AppTextStyles.link
                                  .copyWith(color: AppColors.primaryTeal))),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _shopNameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อร้านค้า',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                                color: AppColors.primaryTeal, width: 2.0)),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'กรุณากรอกชื่อร้านค้า'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _shopDescriptionController,
                      decoration: InputDecoration(
                        labelText: 'คำอธิบายร้านค้า',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                                color: AppColors.primaryTeal, width: 2.0)),
                      ),
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty
                          ? 'กรุณากรอกคำอธิบายร้านค้า'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveShopDetails,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: AppTextStyles.subtitle.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold)),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: AppColors.white, strokeWidth: 3.0))
                          : Text('บันทึกการเปลี่ยนแปลง',
                              style: AppTextStyles.subtitle
                                  .copyWith(color: AppColors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
