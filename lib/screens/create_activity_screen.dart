import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../utils/constants.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationDetailsController = TextEditingController();
  final _contactInfoController = TextEditingController();

  String? _selectedProvince;
  DateTime? _selectedDateTime;
  File? _selectedImage;
  String _selectedActivityType = 'สิ่งแวดล้อม';
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final ActivityService _activityService = ActivityService();
  final ImagePicker _picker = ImagePicker();

  // ประเภทกิจกรรม
  final List<String> _activityTypes = [
    'สิ่งแวดล้อม',
    'สังคม',
    'การศึกษา',
    'ชุมชน',
    'อาสาสมัคร',
    'อื่นๆ'
  ];

  // รายชื่อจังหวัดทั้งหมดในประเทศไทย (ใช้จาก ThaiProvinces)
  final List<String> _provinces = ThaiProvinces.all;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationDetailsController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryTeal,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitActivity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกจังหวัด'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกวันและเวลา'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อน');
      }

      // สร้างกิจกรรมใหม่ผ่าน Service
      await _activityService.createActivity(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _selectedImage?.path ?? '', // ใช้ path ของไฟล์ชั่วคราว
        province: _selectedProvince!,
        locationDetails: _locationDetailsController.text.trim(),
        activityDateTime: _selectedDateTime!,
        contactInfo: _contactInfoController.text.trim(),
        tags: _selectedTags,
        activityType: _selectedActivityType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 ส่งกิจกรรมเรียบร้อย! รอแอดมินอนุมัติ'),
            backgroundColor: AppColors.primaryTeal,
            duration: Duration(seconds: 3),
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
          _isSubmitting = false;
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
          'สร้างกิจกรรมใหม่',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'กิจกรรมเพื่อความยั่งยืน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'สร้างกิจกรรมเพื่อชวนคนในชุมชนมาร่วมทำกิจกรรมเพื่อสังคมและสิ่งแวดล้อม',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ประเภทกิจกรรม
              _buildSectionCard(
                title: 'ประเภทกิจกรรม',
                icon: Icons.category,
                child: Column(
                  children: _activityTypes.map((type) {
                    return RadioListTile<String>(
                      title: Text(_getActivityTypeDisplayName(type)),
                      subtitle: Text(_getActivityTypeDescription(type)),
                      value: type,
                      groupValue: _selectedActivityType,
                      onChanged: (value) {
                        setState(() {
                          _selectedActivityType = value!;
                        });
                      },
                      activeColor: AppColors.primaryTeal,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // ชื่อกิจกรรม
              _buildSectionCard(
                title: 'ชื่อกิจกรรม',
                icon: Icons.title,
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'เช่น "ปลูกป่าชุมชน" หรือ "ทำความสะอาดชายหาด"',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อกิจกรรม';
                    }
                    if (value.trim().length < 5) {
                      return 'ชื่อกิจกรรมต้องมีอย่างน้อย 5 ตัวอักษร';
                    }
                    return null;
                  },
                  maxLength: 100,
                ),
              ),

              const SizedBox(height: 16),

              // รายละเอียดกิจกรรม
              _buildSectionCard(
                title: 'รายละเอียดกิจกรรม',
                icon: Icons.description,
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText:
                        'อธิบายรายละเอียดกิจกรรม วัตถุประสงค์ และสิ่งที่ผู้เข้าร่วมจะได้รับ',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกรายละเอียดกิจกรรม';
                    }
                    if (value.trim().length < 20) {
                      return 'รายละเอียดต้องมีอย่างน้อย 20 ตัวอักษร';
                    }
                    return null;
                  },
                  maxLength: 1000,
                ),
              ),

              const SizedBox(height: 16),

              // จังหวัด
              _buildSectionCard(
                title: 'จังหวัดที่จัดกิจกรรม',
                icon: Icons.location_on,
                child: DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: const InputDecoration(
                    hintText: 'เลือกจังหวัด',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  items: _provinces.map((province) {
                    return DropdownMenuItem(
                      value: province,
                      child: Text(province),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'กรุณาเลือกจังหวัด';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // รายละเอียดสถานที่
              _buildSectionCard(
                title: 'รายละเอียดสถานที่นัดพบ',
                icon: Icons.place,
                child: TextFormField(
                  controller: _locationDetailsController,
                  decoration: const InputDecoration(
                    hintText:
                        'เช่น "หน้าเทสโก้โลตัส สาขา..." หรือ "วัดประจำหมู่บ้าน"',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกรายละเอียดสถานที่';
                    }
                    return null;
                  },
                  maxLength: 200,
                ),
              ),

              const SizedBox(height: 16),

              // วันและเวลา
              _buildSectionCard(
                title: 'วันและเวลาจัดกิจกรรม',
                icon: Icons.access_time,
                child: InkWell(
                  onTap: _selectDateTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.primaryTeal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDateTime == null
                                ? 'เลือกวันและเวลา'
                                : '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year + 543} เวลา ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')} น.',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedDateTime == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ข้อมูลติดต่อ
              _buildSectionCard(
                title: 'ข้อมูลติดต่อ',
                icon: Icons.contact_phone,
                child: TextFormField(
                  controller: _contactInfoController,
                  decoration: const InputDecoration(
                    hintText: 'เบอร์โทร, Line ID, หรือ Facebook',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกข้อมูลติดต่อ';
                    }
                    return null;
                  },
                  maxLength: 100,
                ),
              ),

              const SizedBox(height: 16),

              // รูปภาพ
              _buildSectionCard(
                title: 'รูปภาพกิจกรรม (ไม่บังคับ)',
                icon: Icons.photo_camera,
                child: Column(
                  children: [
                    if (_selectedImage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _selectImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text(_selectedImage == null
                          ? 'เลือกรูปภาพ'
                          : 'เปลี่ยนรูปภาพ'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ปุ่มส่ง
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isSubmitting
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
                            Text(
                              'กำลังส่ง...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          '📤 ส่งเพื่อรออนุมัติ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // คำแนะนำ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'คำแนะนำ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• กิจกรรมจะต้องผ่านการตรวจสอบจากแอดมินก่อน\n'
                      '• ใช้เวลาอนุมัติประมาณ 1-3 วันทำการ\n'
                      '• กรอกข้อมูลให้ครบถ้วนเพื่อการอนุมัติที่รวดเร็ว\n'
                      '• กิจกรรมที่ผ่านวันที่กำหนดจะถูกซ่อนโดยอัตโนมัติ',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  String _getActivityTypeDisplayName(String type) {
    switch (type) {
      case 'สิ่งแวดล้อม':
        return '🌱 สิ่งแวดล้อม';
      case 'สังคม':
        return '🤝 สังคม';
      case 'การศึกษา':
        return '📚 การศึกษา';
      case 'ชุมชน':
        return '🏘️ ชุมชน';
      case 'อาสาสมัคร':
        return '💪 อาสาสมัคร';
      case 'อื่นๆ':
        return '🌟 อื่นๆ';
      default:
        return '🌱 สิ่งแวดล้อม';
    }
  }

  String _getActivityTypeDescription(String type) {
    switch (type) {
      case 'สิ่งแวดล้อม':
        return 'ปลูกป่า ทำความสะอาด รักษาธรรมชาติ';
      case 'สังคม':
        return 'ช่วยเหลือผู้ด้อยโอกาส กิจกรรมสังคม';
      case 'การศึกษา':
        return 'อบรม สอน แบ่งปันความรู้';
      case 'ชุมชน':
        return 'พัฒนาชุมชน กิจกรรมหมู่บ้าน';
      case 'อาสาสมัคร':
        return 'กิจกรรมอาสาสมัครทั่วไป';
      case 'อื่นๆ':
        return 'กิจกรรมอื่นๆ เพื่อความยั่งยืน';
      default:
        return 'ปลูกป่า ทำความสะอาด รักษาธรรมชาติ';
    }
  }
}
