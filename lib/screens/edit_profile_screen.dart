import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopDescriptionController = TextEditingController();
  final _mottoController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _bioController.text = user.bio ?? '';
      _addressController.text = user.address ?? '';
      _shopNameController.text = user.shopName ?? '';
      _shopDescriptionController.text = user.shopDescription ?? '';
      _mottoController.text = user.motto ?? 'ร่วมกันสร้างโลกที่ยั่งยืน 🌱';
      _currentPhotoUrl = user.photoUrl;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _shopNameController.dispose();
    _shopDescriptionController.dispose();
    _mottoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _imageBytes = null; // Will load later
      });
      // Load bytes for web
      _imageBytes = await image.readAsBytes();
      setState(() {}); // Trigger rebuild
    }
  }

  Uint8List? _imageBytes;

  Future<String?> _uploadImage() async {
    if (_selectedImage == null && _imageBytes == null) return _currentPhotoUrl;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;
      if (userId == null) return null;

      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/$userId/$fileName');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      // Use bytes if available (web), otherwise file
      if (_imageBytes != null) {
        await ref.putData(_imageBytes!, metadata);
      } else if (_selectedImage != null) {
        await ref.putFile(_selectedImage!, metadata);
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return _currentPhotoUrl;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image first if selected
      final photoUrl = await _uploadImage();

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await userProvider.updateUserProfile(
        displayName: _displayNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoUrl: photoUrl,
        bio: _bioController.text.trim(),
        address: _addressController.text.trim(),
        shopName: _shopNameController.text.trim(),
        shopDescription: _shopDescriptionController.text.trim(),
        motto: _mottoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตโปรไฟล์สำเร็จ'),
            backgroundColor: Color(0xFF43A047),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      appBar: AppBar(
        title: const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'บันทึก',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipOval(
                            child: kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: _selectedImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const CircularProgressIndicator();
                                      }
                                      return Image.memory(snapshot.data!,
                                          fit: BoxFit.cover);
                                    },
                                  )
                                : Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                  ),
                          )
                        : _currentPhotoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _currentPhotoUrl!,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('เปลี่ยนรูปโปรไฟล์'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionHeader('ข้อมูลส่วนตัว', Icons.person_outline),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _displayNameController,
                label: 'ชื่อที่แสดง',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาใส่ชื่อที่แสดง';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneController,
                label: 'เบอร์โทรศัพท์',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาใส่เบอร์โทรศัพท์';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _bioController,
                label: 'แนะนำตัว',
                icon: Icons.info_outline,
                maxLines: 3,
                hintText: 'เล่าเกี่ยวกับตัวคุณให้คนอื่นรู้จัก...',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _addressController,
                label: 'ที่อยู่',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                hintText: 'ที่อยู่สำหรับการจัดส่ง...',
              ),

              const SizedBox(height: 32),

              // Shop Information Section
              _buildSectionHeader('ข้อมูลร้านค้า', Icons.store_outlined),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _shopNameController,
                label: 'ชื่อร้านค้า',
                icon: Icons.storefront,
                hintText: 'ชื่อร้านที่จะแสดงให้ผู้ซื้อเห็น...',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _shopDescriptionController,
                label: 'คำอธิบายร้านค้า',
                icon: Icons.description,
                maxLines: 3,
                hintText: 'อธิบายเกี่ยวกับร้านค้าและสินค้าของคุณ...',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _mottoController,
                label: 'คำคม/ข้อความกำกับ',
                icon: Icons.format_quote,
                hintText: 'คำคมที่จะแสดงในโปรไฟล์...',
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('กำลังบันทึก...'),
                          ],
                        )
                      : const Text(
                          'บันทึกการเปลี่ยนแปลง',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2E7D32),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF2E7D32),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
