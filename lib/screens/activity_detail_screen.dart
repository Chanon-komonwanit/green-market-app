import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/activity.dart';
import '../utils/constants.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  bool _isInterested = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryTeal,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.activity.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.activity.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primaryTeal,
                          child: const Center(
                            child: Icon(
                              Icons.eco,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.primaryTeal,
                      child: const Center(
                        child: Icon(
                          Icons.eco,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isInterested ? Icons.favorite : Icons.favorite_border,
                  color: _isInterested ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isInterested = !_isInterested;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isInterested
                            ? '💚 เพิ่มในกิจกรรมที่สนใจ'
                            : '💔 ลบออกจากกิจกรรมที่สนใจ',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and Type
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primaryTeal.withOpacity(0.3)),
                        ),
                        child: Text(
                          widget.activity.activityType,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.activity.isStartingSoon)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: const Text(
                            '🔥 เริ่มเร็วๆ นี้',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.activity.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Organizer Info
                  Container(
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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ผู้จัดกิจกรรม',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                widget.activity.organizerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  _buildSectionCard(
                    title: 'รายละเอียดกิจกรรม',
                    icon: Icons.description,
                    child: Text(
                      widget.activity.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date & Time
                  _buildSectionCard(
                    title: 'วันและเวลา',
                    icon: Icons.access_time,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 20, color: AppColors.primaryTeal),
                            const SizedBox(width: 8),
                            Text(
                              widget.activity.formattedDate,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 20, color: AppColors.primaryTeal),
                            const SizedBox(width: 8),
                            Text(
                              widget.activity.formattedTime,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getTimeStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _getTimeStatusColor().withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getTimeStatusIcon(),
                                color: _getTimeStatusColor(),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getTimeStatusText(),
                                style: TextStyle(
                                  color: _getTimeStatusColor(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location
                  _buildSectionCard(
                    title: 'สถานที่',
                    icon: Icons.location_on,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 20, color: AppColors.primaryTeal),
                            const SizedBox(width: 8),
                            Text(
                              widget.activity.province,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.activity.locationDetails,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contact Info
                  _buildSectionCard(
                    title: 'ข้อมูลติดต่อ',
                    icon: Icons.contact_phone,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.activity.contactInfo,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _launchContact(widget.activity.contactInfo),
                                icon: const Icon(Icons.phone,
                                    color: Colors.white),
                                label: const Text(
                                  'ติดต่อ',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tags
                  if (widget.activity.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'แท็ก',
                      icon: Icons.tag,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.activity.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      AppColors.primaryTeal.withOpacity(0.3)),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      widget.activity.isActive ? () => _showJoinDialog() : null,
                  icon: Icon(
                    widget.activity.isActive
                        ? Icons.volunteer_activism
                        : Icons.event_busy,
                    color: Colors.white,
                  ),
                  label: Text(
                    widget.activity.isActive
                        ? 'เข้าร่วมกิจกรรม'
                        : 'กิจกรรมหมดเวลาแล้ว',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.activity.isActive
                        ? AppColors.primaryTeal
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
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
              Icon(icon, color: AppColors.primaryTeal, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
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

  Color _getTimeStatusColor() {
    if (!widget.activity.isActive) {
      return Colors.grey;
    } else if (widget.activity.isStartingSoon) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  IconData _getTimeStatusIcon() {
    if (!widget.activity.isActive) {
      return Icons.event_busy;
    } else if (widget.activity.isStartingSoon) {
      return Icons.schedule;
    } else {
      return Icons.event_available;
    }
  }

  String _getTimeStatusText() {
    if (!widget.activity.isActive) {
      return 'กิจกรรมหมดเวลาแล้ว';
    } else if (widget.activity.isStartingSoon) {
      return 'กิจกรรมจะเริ่มเร็วๆ นี้';
    } else {
      final daysLeft =
          widget.activity.activityDateTime.difference(DateTime.now()).inDays;
      return 'เหลืออีก $daysLeft วัน';
    }
  }

  Future<void> _launchContact(String contact) async {
    // ตรวจสอบว่าเป็นเบอร์โทรหรือไม่
    if (RegExp(r'^\d{9,10}$')
        .hasMatch(contact.replaceAll(RegExp(r'[^\d]'), ''))) {
      final phoneNumber = contact.replaceAll(RegExp(r'[^\d]'), '');
      final url = Uri.parse('tel:$phoneNumber');

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showErrorDialog('ไม่สามารถเปิดแอปโทรศัพท์ได้');
      }
    } else {
      // คัดลอกข้อมูลติดต่อ
      _showContactDialog();
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ข้อมูลติดต่อ'),
          content: SelectableText(
            widget.activity.contactInfo,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('เข้าร่วมกิจกรรม'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'คุณต้องการเข้าร่วมกิจกรรม "${widget.activity.title}" หรือไม่?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '📋 หมายเหตุ:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('• กรุณาติดต่อผู้จัดกิจกรรมเพื่อยืนยันการเข้าร่วม'),
                    Text('• มาตรงเวลาตามที่กำหนด'),
                    Text('• เตรียมอุปกรณ์ตามที่ระบุไว้'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _launchContact(widget.activity.contactInfo);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 ขอบคุณที่สนใจเข้าร่วมกิจกรรม!'),
                    backgroundColor: AppColors.primaryTeal,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
              ),
              child: const Text(
                'ติดต่อเลย',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('เกิดข้อผิดพลาด'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }
}
