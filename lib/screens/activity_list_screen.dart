import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../utils/constants.dart';
import 'activity_detail_screen.dart';

class ActivityListScreen extends StatefulWidget {
  final String? province;
  final String? activityType;
  final String title;

  const ActivityListScreen({
    super.key,
    this.province,
    this.activityType,
    this.title = 'กิจกรรมทั้งหมด',
  });

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? _selectedProvince;
  String? _selectedActivityType;
  String _searchQuery = '';
  String _sortBy = 'date'; // date, title, province

  // ประเภทกิจกรรม
  final List<String> _activityTypes = [
    'ทั้งหมด',
    'สิ่งแวดล้อม',
    'สังคม',
    'การศึกษา',
    'ชุมชน',
    'อาสาสมัคร',
    'อื่นๆ'
  ];

  @override
  void initState() {
    super.initState();
    _selectedProvince = widget.province;
    _selectedActivityType = widget.activityType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหากิจกรรม...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.primaryTeal),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryTeal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primaryTeal, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter Summary
          if (_selectedProvince != null ||
              _selectedActivityType != null ||
              _searchQuery.isNotEmpty) ...[
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedProvince != null) ...[
                      _buildFilterChip(
                        '📍 ${_selectedProvince!}',
                        Colors.blue,
                        () {
                          setState(() {
                            _selectedProvince = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_selectedActivityType != null &&
                        _selectedActivityType != 'ทั้งหมด') ...[
                      _buildFilterChip(
                        '🏷️ ${_selectedActivityType!}',
                        Colors.green,
                        () {
                          setState(() {
                            _selectedActivityType = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_searchQuery.isNotEmpty) ...[
                      _buildFilterChip(
                        '🔍 "$_searchQuery"',
                        Colors.orange,
                        () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // Activities List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getActivitiesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryTeal,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'เกิดข้อผิดพลาด: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ไม่พบกิจกรรม',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'ลองเปลี่ยนคำค้นหาหรือกรองข้อมูล'
                              : 'ยังไม่มีกิจกรรมในหมวดหมู่นี้',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                List<Activity> activities = snapshot.data!.docs
                    .map((doc) => Activity.fromFirestore(doc))
                    .where((activity) =>
                        activity.isActive) // เฉพาะกิจกรรมที่ยังไม่หมดเวลา
                    .toList();

                // กรองตาม search query
                if (_searchQuery.isNotEmpty) {
                  activities = activities.where((activity) {
                    final searchLower = _searchQuery.toLowerCase();
                    return activity.title.toLowerCase().contains(searchLower) ||
                        activity.description
                            .toLowerCase()
                            .contains(searchLower) ||
                        activity.province.toLowerCase().contains(searchLower) ||
                        activity.locationDetails
                            .toLowerCase()
                            .contains(searchLower);
                  }).toList();
                }

                // กรองตามจังหวัด
                if (_selectedProvince != null) {
                  activities = activities
                      .where(
                          (activity) => activity.province == _selectedProvince)
                      .toList();
                }

                // กรองตามประเภทกิจกรรม
                if (_selectedActivityType != null &&
                    _selectedActivityType != 'ทั้งหมด') {
                  activities = activities
                      .where((activity) =>
                          activity.activityType == _selectedActivityType)
                      .toList();
                }

                // เรียงลำดับ
                _sortActivities(activities);

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: activities.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'ไม่พบผลการค้นหา',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'ลองปรับเงื่อนไขการค้นหา',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            final activity = activities[index];
                            return _buildActivityCard(activity);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getActivitiesStream() {
    return FirebaseFirestore.instance
        .collection('activities')
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void _sortActivities(List<Activity> activities) {
    switch (_sortBy) {
      case 'date':
        activities
            .sort((a, b) => a.activityDateTime.compareTo(b.activityDateTime));
        break;
      case 'title':
        activities.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'province':
        activities.sort((a, b) => a.province.compareTo(b.province));
        break;
    }
  }

  Widget _buildFilterChip(String label, Color color, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailScreen(activity: activity),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Activity Type and Date
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
                        activity.activityType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (activity.isStartingSoon)
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

                const SizedBox(height: 12),

                // Title
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Details
                _buildDetailRow(Icons.location_on,
                    '${activity.province} • ${activity.locationDetails}'),
                const SizedBox(height: 6),
                _buildDetailRow(Icons.access_time,
                    '${activity.formattedDate} • ${activity.formattedTime}'),
                const SizedBox(height: 6),
                _buildDetailRow(
                    Icons.person, 'จัดโดย ${activity.organizerName}'),

                // Image thumbnail if available
                if (activity.imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      activity.imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Tags
                if (activity.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: activity.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                // Action Button
                Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ActivityDetailScreen(activity: activity),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('ดูรายละเอียด'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryTeal,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempProvince = _selectedProvince;
        String? tempActivityType = _selectedActivityType;
        String tempSortBy = _sortBy;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('กรองและเรียงลำดับ'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // จังหวัด
                    const Text(
                      'จังหวัด',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempProvince,
                      decoration: const InputDecoration(
                        hintText: 'เลือกจังหวัด',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('ทั้งหมด')),
                        ...ThaiProvinces.all.map((province) {
                          return DropdownMenuItem(
                            value: province,
                            child: Text(province),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempProvince = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // ประเภทกิจกรรม
                    const Text(
                      'ประเภทกิจกรรม',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempActivityType ?? 'ทั้งหมด',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _activityTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          tempActivityType = value == 'ทั้งหมด' ? null : value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // เรียงลำดับ
                    const Text(
                      'เรียงลำดับ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempSortBy,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'date', child: Text('วันที่จัดกิจกรรม')),
                        DropdownMenuItem(
                            value: 'title', child: Text('ชื่อกิจกรรม')),
                        DropdownMenuItem(
                            value: 'province', child: Text('จังหวัด')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempSortBy = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedProvince = null;
                      _selectedActivityType = null;
                      _sortBy = 'date';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('ล้างทั้งหมด'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedProvince = tempProvince;
                      _selectedActivityType = tempActivityType;
                      _sortBy = tempSortBy;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
