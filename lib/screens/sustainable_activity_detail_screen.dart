import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:green_market/utils/constants.dart';

/// หน้าแสดงรายละเอียดกิจกรรมยั่งยืน (Activity Detail Screen)
class SustainableActivityDetailScreen extends StatelessWidget {
  final Map<String, dynamic> activity;

  const SustainableActivityDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดกิจกรรม'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryTeal,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Image
            if (activity['imageUrl'] != null &&
                activity['imageUrl'].toString().isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    activity['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
                  ),
                ),
              ),

            // Activity Title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['title'] ?? 'ไม่มีชื่อกิจกรรม',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (activity['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightTeal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activity['category'],
                        style: const TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Activity Description
            if (activity['description'] != null &&
                activity['description'].toString().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'รายละเอียด',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activity['description'],
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Activity Info Grid
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ข้อมูลกิจกรรม',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'จำนวนผู้เข้าร่วม',
                    '${activity['participantCount'] ?? 0} คน',
                    Icons.people,
                  ),
                  if (activity['ecoCoinsReward'] != null)
                    _buildInfoRow(
                      'รางวัล Eco Coins',
                      '${activity['ecoCoinsReward']} เหรียญ',
                      Icons.eco,
                    ),
                  if (activity['location'] != null)
                    _buildInfoRow(
                      'สถานที่',
                      activity['location'],
                      Icons.location_on,
                    ),
                  if (activity['organizer'] != null)
                    _buildInfoRow(
                      'ผู้จัดกิจกรรม',
                      activity['organizer'],
                      Icons.person,
                    ),
                  if (activity['status'] != null)
                    _buildInfoRow(
                      'สถานะ',
                      _getStatusText(activity['status']),
                      Icons.info,
                      statusColor: _getStatusColor(activity['status']),
                    ),
                  if (activity['createdAt'] != null)
                    _buildInfoRow(
                      'วันที่สร้าง',
                      DateFormat('dd/MM/yyyy HH:mm', 'th_TH')
                          .format(activity['createdAt'].toDate()),
                      Icons.calendar_today,
                    ),
                  if (activity['startDate'] != null)
                    _buildInfoRow(
                      'วันที่เริ่ม',
                      DateFormat('dd/MM/yyyy HH:mm', 'th_TH')
                          .format(activity['startDate'].toDate()),
                      Icons.play_arrow,
                    ),
                  if (activity['endDate'] != null)
                    _buildInfoRow(
                      'วันที่สิ้นสุด',
                      DateFormat('dd/MM/yyyy HH:mm', 'th_TH')
                          .format(activity['endDate'].toDate()),
                      Icons.stop,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Environmental Impact
            if (activity['environmentalImpact'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.eco, color: AppColors.primaryTeal),
                        SizedBox(width: 8),
                        Text(
                          'ผลกระทบต่อสิ่งแวดล้อม',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activity['environmentalImpact'],
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: statusColor ?? AppColors.primaryTeal,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'กำลังดำเนินการ';
      case 'completed':
        return 'เสร็จสิ้น';
      case 'pending':
        return 'รอดำเนินการ';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
