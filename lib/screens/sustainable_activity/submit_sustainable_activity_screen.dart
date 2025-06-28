// lib/screens/sustainable_activity/submit_sustainable_activity_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:green_market/models/sustainable_activity.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/ui_helpers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SubmitSustainableActivityScreen extends StatefulWidget {
  final SustainableActivity?
      activity; // Optional: for editing existing activity

  const SubmitSustainableActivityScreen({super.key, this.activity});

  @override
  State<SubmitSustainableActivityScreen> createState() =>
      _SubmitSustainableActivityScreenState();
}

class _SubmitSustainableActivityScreenState
    extends State<SubmitSustainableActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _provinceController = TextEditingController();
  final _contactInfoController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  XFile? _pickedImageFile;
  String? _currentImageUrl; // To store the current image URL from activity

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _provinceController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.activity != null) {
      _loadActivityData(widget.activity!);
    }
  }

  void _loadActivityData(SustainableActivity activity) {
    _titleController.text = activity.title;
    _descriptionController.text = activity.description;
    _provinceController.text = activity.province;
    _contactInfoController.text = activity.contactInfo;
    _selectedStartDate = activity.startDate;
    _selectedEndDate = activity.endDate; // Corrected: Already correct
    _currentImageUrl = activity.imageUrl;
  }

  Future<void> _submitActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (_selectedStartDate == null || _selectedEndDate == null) {
      showAppSnackBar(context, 'กรุณาเลือกวันที่เริ่มต้นและสิ้นสุด',
          isError: true);
      return;
    }

    if (_selectedEndDate!.isBefore(_selectedStartDate!)) {
      showAppSnackBar(context, 'วันที่สิ้นสุดต้องอยู่หลังวันที่เริ่มต้น',
          isError: true);
      return;
    }

    if (_pickedImageFile == null && _currentImageUrl == null) {
      showAppSnackBar(context, 'กรุณาเลือกรูปภาพกิจกรรม', isError: true);
      return;
    }

    // Show loading indicator
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider
        .currentUser; // Change 'user' to the correct property name, e.g., 'currentUser'

    if (currentUser == null) {
      showAppSnackBar(context, 'กรุณาเข้าสู่ระบบเพื่อส่งกิจกรรม',
          isError: true);
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(
              child: CircularProgressIndicator(),
            ));

    try {
      String? finalImageUrl = _currentImageUrl;
      if (_pickedImageFile != null) {
        // Only upload if a new image is picked
        const storagePath = 'sustainable_activities_images';
        final fileName =
            '${firebaseService.generateNewDocId(storagePath)}_${_pickedImageFile!.name}';

        if (kIsWeb) {
          final bytes = await _pickedImageFile!.readAsBytes();
          finalImageUrl = await firebaseService.uploadWebImage(bytes, fileName);
        } else {
          finalImageUrl = await firebaseService.uploadImageFile(
              File(_pickedImageFile!.path), fileName);
        }
      } else if (_currentImageUrl == null) {
        // If no new image and no current image, ensure it's null
        finalImageUrl = null;
      }

      if (finalImageUrl == null) {
        throw Exception('ไม่สามารถอัปโหลดรูปภาพได้');
      }

      final activityToSave = SustainableActivity(
        id: widget.activity?.id ??
            firebaseService.generateNewDocId('sustainable_activities'),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        province: _provinceController.text.trim(),
        startDate: _selectedStartDate!,
        endDate: _selectedEndDate!,
        imageUrl: finalImageUrl, // Use the uploaded image URL
        contactInfo: _contactInfoController.text.trim(),
        organizerId: currentUser.id,
        location: '', // Added default location
        organizerName: currentUser.displayName ?? '',
        submissionStatus: 'pending',
        createdAt: Timestamp.now(), // Set to pending for admin approval
      );

      if (widget.activity == null) {
        await firebaseService.addSustainableActivity(activityToSave);
      } else {
        await firebaseService.updateSustainableActivity(activityToSave);
      }

      // Pop loading indicator
      if (mounted) Navigator.of(context).pop();

      showAppSnackBar(context, 'ส่งกิจกรรมสำเร็จ! รอการอนุมัติจากแอดมิน',
          isSuccess: true);
      if (mounted) Navigator.of(context).pop(); // Go back after submission
    } catch (e) {
      // Pop loading indicator
      if (mounted) Navigator.of(context).pop();
      showAppSnackBar(context, 'เกิดข้อผิดพลาด: ${e.toString()}',
          isError: true);
    }
  }

  Future<void> _pickImage() async {
    final XFile? selectedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (selectedImage != null) {
      if (mounted) {
        setState(() {
          _pickedImageFile = selectedImage;
          _currentImageUrl = null; // Clear current URL if new image picked
        });
      }
    }
  }

  Widget _buildImagePreview() {
    if (_pickedImageFile != null) {
      // If a new file is picked
      return kIsWeb
          ? Image.network(_pickedImageFile!.path,
              height: 150, fit: BoxFit.cover)
          : Image.file(File(_pickedImageFile!.path),
              height: 150, fit: BoxFit.cover);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      // If there's an existing URL
      return Image.network(_currentImageUrl!, height: 150, fit: BoxFit.cover);
    }
    return Container(
        height: 150,
        color: Colors.grey[200],
        child: const Icon(Icons.image_outlined, size: 50, color: Colors.grey));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.activity == null
                ? 'เสนอกิจกรรมความยั่งยืน'
                : 'แก้ไขกิจกรรมความยั่งยืน',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                  controller: _titleController,
                  decoration: buildInputDecoration(context, 'ชื่อกิจกรรม'),
                  validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อกิจกรรม' : null),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _descriptionController,
                  decoration: buildInputDecoration(context, 'คำอธิบายกิจกรรม'),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'กรุณากรอกคำอธิบาย' : null),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _provinceController,
                  decoration: buildInputDecoration(context, 'จังหวัด'),
                  validator: (v) => v!.isEmpty ? 'กรุณากรอกจังหวัด' : null),
              const SizedBox(height: 10),
              _buildImagePreview(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('เลือกรูปภาพกิจกรรม'),
                ),
              ),
              if (_currentImageUrl != null || _pickedImageFile != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                            _pickedImageFile = null;
                            _currentImageUrl = null;
                          }),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: const Text('ลบรูปภาพ')),
                ),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _contactInfoController,
                  decoration: buildInputDecoration(context, 'ข้อมูลติดต่อ'),
                  validator: (v) =>
                      v!.isEmpty ? 'กรุณากรอกข้อมูลติดต่อ' : null),
              const SizedBox(height: 10),
              _buildDatePicker(
                // Corrected: Already correct
                context,
                'วันที่เริ่มต้น',
                _selectedStartDate,
                (date) => setState(() => _selectedStartDate = date),
              ),
              const SizedBox(height: 10),
              _buildDatePicker(
                context,
                'วันที่สิ้นสุด',
                _selectedEndDate,
                (date) => setState(() => _selectedEndDate = date),
                minDate: _selectedStartDate,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitActivity,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: Text(widget.activity == null
                      ? 'ส่งกิจกรรมเพื่อขออนุมัติ'
                      : 'บันทึกการแก้ไขกิจกรรม'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label,
      DateTime? selectedDate, Function(DateTime?) onDateSelected,
      {DateTime? minDate}) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: minDate ?? DateTime(2020),
          lastDate: DateTime(2101),
        );
        onDateSelected(pickedDate);
      },
      child: InputDecorator(
        decoration: buildInputDecoration(context, label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate != null
                  ? DateFormat('dd MMMM yyyy').format(selectedDate)
                  : 'เลือกวันที่',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
