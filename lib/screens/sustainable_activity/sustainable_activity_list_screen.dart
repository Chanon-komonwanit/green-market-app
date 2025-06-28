// lib/screens/sustainable_activity/sustainable_activity_list_screen.dart
// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:green_market/models/sustainable_activity.dart';
import 'package:green_market/screens/sustainable_activity/sustainable_activity_detail_screen.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SustainableActivityListScreen extends StatefulWidget {
  const SustainableActivityListScreen({super.key});

  @override
  State<SustainableActivityListScreen> createState() =>
      _SustainableActivityListScreenState();
}

class _SustainableActivityListScreenState
    extends State<SustainableActivityListScreen> {
  final TextEditingController _searchController = TextEditingController();
  // String _provinceFilter = ''; // Removed unused variable
  Timer? _debounce;

  String? _selectedSortBy; // New sort by option
  bool _sortDescending = false; // Default to ascending for dates
  String? _selectedStatusFilter; // New status filter
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          // Search functionality removed temporarily
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('กิจกรรมเพื่อสังคมและสิ่งแวดล้อม',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหากิจกรรมตามจังหวัด...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Status Filter Chips
                  Wrap(
                    spacing: 8.0,
                    children: ['upcoming', 'ongoing', 'past'].map((status) {
                      final isSelected = _selectedStatusFilter == status;
                      return FilterChip(
                        label: Text(status == 'upcoming'
                            ? 'กำลังจะมาถึง'
                            : status == 'ongoing'
                                ? 'กำลังดำเนินอยู่'
                                : 'สิ้นสุดแล้ว'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatusFilter = selected ? status : null;
                          });
                        },
                        selectedColor: theme.colorScheme.primaryContainer,
                        checkmarkColor: theme.colorScheme.onPrimaryContainer,
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 16),
                  // Sort By Dropdown
                  DropdownButton<String>(
                    value: _selectedSortBy,
                    hint: const Text('เรียงตาม'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSortBy = newValue;
                      });
                    },
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                          value: 'startDate', child: Text('วันที่เริ่มต้น')),
                      DropdownMenuItem(
                          value: 'endDate', child: Text('วันที่สิ้นสุด')),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Sort Order Toggle
                  IconButton(
                    icon: Icon(_sortDescending
                        ? Icons.arrow_downward
                        : Icons.arrow_upward),
                    onPressed: () {
                      setState(() {
                        _sortDescending = !_sortDescending;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SustainableActivity>>(
              stream: firebaseService.getAllSustainableActivities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  // Corrected: Already correct
                  return _buildEmptyState(context);
                }

                final activities = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActivityCard(context, activity);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nature_people_outlined,
            size: 80,
            color: theme.colorScheme.onSurface // Corrected: Already correct
                .withAlpha((0.4 * 255).round()), // Corrected: Already correct
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีกิจกรรมในขณะนี้',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface
                  .withAlpha((0.6 * 255).round()), // Fixed deprecation
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ลองค้นหาจังหวัดอื่น หรือกลับมาดูใหม่ภายหลัง',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface
                  .withAlpha((0.5 * 255).round()), // Fixed deprecation
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
      BuildContext context, SustainableActivity activity) {
    final theme = Theme.of(context);
    final daysLeft = activity.endDate.difference(DateTime.now()).inDays;
    final daysLeftText = daysLeft >= 0 ? '$daysLeft วัน' : 'สิ้นสุดแล้ว';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      elevation: 4,
      shadowColor:
          Colors.black.withAlpha((0.1 * 255).round()), // Fixed deprecation
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                SustainableActivityDetailScreen(activity: activity),
          ));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.network(
                    activity.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: theme.colorScheme.surfaceContainer,
                      child: Icon(Icons.image_not_supported,
                          color: theme.colorScheme.onSurfaceVariant, size: 50),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Chip(
                    avatar: Icon(Icons.location_on_outlined,
                        size: 16,
                        color: theme.colorScheme.onSecondaryContainer),
                    label: Text(activity.province,
                        style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer)),
                    backgroundColor: theme.colorScheme.secondaryContainer
                        .withAlpha((0.9 * 255).round()), // Fixed deprecation
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoIconText(
                        context,
                        Icons.calendar_today_outlined,
                        '${DateFormat('dd MMM', 'th').format(activity.startDate)} - ${DateFormat('dd MMM', 'th').format(activity.endDate)}',
                      ),
                      _buildInfoIconText(
                        context,
                        Icons.timer_outlined,
                        'เหลือ $daysLeftText',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIconText(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
