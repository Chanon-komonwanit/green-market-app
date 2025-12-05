# 🚀 Priority Implementation Guide - Green Market Community

## 📋 Overview

คู่มือการพัฒนาฟีเจอร์ลำดับความสำคัญสูง พร้อม code examples และ implementation steps

**Created:** ${(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")}  
**Based on:** PLATFORM_COMPARISON_ANALYSIS.md  
**Target:** Phase 1 Implementation (1-2 weeks)

---

## 🏷️ Feature 1: Friend Tagging in Posts

### **Priority:** 🔴 HIGH  
### **Effort:** MEDIUM (8-12 hours)  
### **Impact:** VERY HIGH  

### **Benefits**
- ✅ เพิ่ม engagement (tagged users get notified)
- ✅ Viral effect (แท็กเพื่อน → เพื่อนเห็น → เพื่อนของเพื่อนเห็น)
- ✅ Social proof (คนรู้จักใช้ Green Market)
- ✅ ฟีเจอร์พื้นฐานที่ทุกแพลตฟอร์มมี

### **Use Cases**
1. แท็กเพื่อนที่ร่วมกิจกรรม Zero Waste
2. แท็กเพื่อนแนะนำร้านค้าเขียว
3. แท็กเพื่อนที่ควรดู Tips
4. แท็กเพื่อนในภาพที่อัพโหลด

---

### **Implementation Steps**

#### **Step 1: Update Data Models**

```dart
// lib/models/community_post.dart

class CommunityPost {
  // ... existing fields
  
  // NEW: Tagged users
  List<String> taggedUserIds;
  Map<String, String> taggedUserNames; // {userId: displayName}
  
  CommunityPost({
    // ... existing params
    this.taggedUserIds = const [],
    this.taggedUserNames = const {},
  });
  
  factory CommunityPost.fromMap(Map<String, dynamic> map, String id) {
    return CommunityPost(
      // ... existing mappings
      taggedUserIds: List<String>.from(map['taggedUserIds'] ?? []),
      taggedUserNames: Map<String, String>.from(map['taggedUserNames'] ?? {}),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      // ... existing fields
      'taggedUserIds': taggedUserIds,
      'taggedUserNames': taggedUserNames,
    };
  }
}
```

---

#### **Step 2: Create User Picker Widget**

```dart
// lib/widgets/user_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/models/app_user.dart';
import 'package:green_market/utils/constants.dart';

class UserPickerDialog extends StatefulWidget {
  final List<String> alreadySelectedIds;
  final String currentUserId;
  
  const UserPickerDialog({
    super.key,
    required this.alreadySelectedIds,
    required this.currentUserId,
  });

  @override
  State<UserPickerDialog> createState() => _UserPickerDialogState();
}

class _UserPickerDialogState extends State<UserPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedUserIds = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedUserIds = List.from(widget.alreadySelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'แท็กเพื่อน',
                  style: AppTextStyles.headline,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาเพื่อน...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Selected users chips
            if (_selectedUserIds.isNotEmpty)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedUserIds.length,
                  itemBuilder: (context, index) {
                    return _buildSelectedUserChip(_selectedUserIds[index]);
                  },
                ),
              ),
            
            const Divider(),
            
            // User list
            Expanded(
              child: _buildUserList(),
            ),
            
            const SizedBox(height: 16),
            
            // Done button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedUserIds),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'เสร็จสิ้น (${_selectedUserIds.length})',
                  style: AppTextStyles.bodyBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUserChip(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final displayName = userData?['displayName'] ?? 'Unknown';
        
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            avatar: CircleAvatar(
              backgroundImage: userData?['photoUrl'] != null
                  ? NetworkImage(userData!['photoUrl'])
                  : null,
              child: userData?['photoUrl'] == null
                  ? Text(displayName[0])
                  : null,
            ),
            label: Text(displayName),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              setState(() {
                _selectedUserIds.remove(userId);
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildUserList() {
    // Priority: Friends first, then all users
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('id', isNotEqualTo: widget.currentUserId)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('ไม่พบผู้ใช้'),
          );
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final displayName = (data['displayName'] ?? '').toString().toLowerCase();
          return _searchQuery.isEmpty || displayName.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final isSelected = _selectedUserIds.contains(userId);

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: userData['photoUrl'] != null
                    ? NetworkImage(userData['photoUrl'])
                    : null,
                child: userData['photoUrl'] == null
                    ? Text((userData['displayName'] ?? 'U')[0])
                    : null,
              ),
              title: Text(userData['displayName'] ?? 'Unknown'),
              subtitle: userData['bio'] != null
                  ? Text(
                      userData['bio'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primaryTeal)
                  : const Icon(Icons.circle_outlined),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedUserIds.remove(userId);
                  } else {
                    _selectedUserIds.add(userId);
                  }
                });
              },
            );
          },
        );
      },
    );
  }
}
```

---

#### **Step 3: Update Create Post Screen**

```dart
// lib/screens/create_community_post_screen.dart

class _CreateCommunityPostScreenState extends State<CreateCommunityPostScreen> {
  // ... existing fields
  
  // NEW: Tagged users
  List<String> _taggedUserIds = [];
  Map<String, String> _taggedUserNames = {};

  @override
  void initState() {
    super.initState();
    // ... existing init
    
    if (widget.postToEdit != null) {
      // Load existing tagged users
      _taggedUserIds = widget.postToEdit!.taggedUserIds;
      _taggedUserNames = widget.postToEdit!.taggedUserNames;
    }
  }

  // Add this method after _buildMediaButtons()
  Widget _buildTagUsersButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: _showUserPicker,
        icon: const Icon(Icons.person_add, size: 20),
        label: Text(
          _taggedUserIds.isEmpty
              ? 'แท็กเพื่อน'
              : 'แท็กเพื่อน (${_taggedUserIds.length})',
          style: AppTextStyles.body,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryTeal,
          side: BorderSide(
            color: _taggedUserIds.isEmpty
                ? AppColors.grayBorder
                : AppColors.primaryTeal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // Show user picker dialog
  Future<void> _showUserPicker() async {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) return;

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => UserPickerDialog(
        alreadySelectedIds: _taggedUserIds,
        currentUserId: currentUser.id,
      ),
    );

    if (result != null) {
      setState(() {
        _taggedUserIds = result;
      });
      
      // Fetch user names
      await _fetchTaggedUserNames();
    }
  }

  Future<void> _fetchTaggedUserNames() async {
    final names = <String, String>{};
    
    for (final userId in _taggedUserIds) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        names[userId] = data['displayName'] ?? 'Unknown';
      }
    }
    
    setState(() {
      _taggedUserNames = names;
    });
  }

  // Display tagged users
  Widget _buildTaggedUsersDisplay() {
    if (_taggedUserIds.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryTeal.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_add,
                size: 16,
                color: AppColors.primaryTeal,
              ),
              const SizedBox(width: 6),
              Text(
                'แท็กเพื่อน (${_taggedUserIds.length})',
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _taggedUserIds.map((userId) {
              final displayName = _taggedUserNames[userId] ?? 'Loading...';
              return Chip(
                label: Text(displayName),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _taggedUserIds.remove(userId);
                    _taggedUserNames.remove(userId);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Update build method - add after _buildMediaButtons()
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... existing code
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... existing widgets
            
            _buildMediaButtons(),
            _buildTagUsersButton(), // ← ADD THIS
            
            if (_taggedUserIds.isNotEmpty)
              _buildTaggedUsersDisplay(), // ← ADD THIS
            
            // ... rest of widgets
          ],
        ),
      ),
    );
  }

  // Update _submitPost() to include tagged users
  Future<void> _submitPost() async {
    // ... existing validation
    
    final postData = {
      // ... existing fields
      'taggedUserIds': _taggedUserIds,
      'taggedUserNames': _taggedUserNames,
    };
    
    // ... rest of submit logic
    
    // NEW: Send notifications to tagged users
    for (final userId in _taggedUserIds) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'tag',
        'fromUserId': currentUser.id,
        'fromUserName': currentUser.displayName,
        'fromUserPhoto': currentUser.photoUrl,
        'postId': newPostId,
        'message': '${currentUser.displayName} แท็กคุณในโพสต์',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }
}
```

---

#### **Step 4: Update Post Card Widget**

```dart
// lib/widgets/post_card_widget.dart

class PostCardWidget extends StatefulWidget {
  // ... existing code
}

class _PostCardWidgetState extends State<PostCardWidget> {
  // ... existing code
  
  // Add after _buildUserHeader()
  Widget _buildTaggedUsers() {
    if (widget.post.taggedUserIds.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: Wrap(
        spacing: 4,
        children: [
          const Icon(Icons.person_pin, size: 14, color: AppColors.graySecondary),
          const SizedBox(width: 4),
          Text(
            'กับ ',
            style: AppTextStyles.caption,
          ),
          ...widget.post.taggedUserNames.entries.take(3).map((entry) {
            return GestureDetector(
              onTap: () {
                // Navigate to user profile
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityProfileScreen(
                      userId: entry.key,
                    ),
                  ),
                );
              },
              child: Text(
                entry.value,
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.primaryTeal,
                  decoration: TextDecoration.none,
                ),
              ),
            );
          }).toList(),
          if (widget.post.taggedUserIds.length > 3)
            Text(
              ' และอีก ${widget.post.taggedUserIds.length - 3} คน',
              style: AppTextStyles.caption,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // ... existing card code
      child: Column(
        children: [
          _buildUserHeader(),
          _buildTaggedUsers(), // ← ADD THIS
          // ... rest of widgets
        ],
      ),
    );
  }
}
```

---

#### **Step 5: Update Firebase Security Rules**

```javascript
// firestore.rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... existing rules
    
    match /community_posts/{postId} {
      allow read: if true;
      allow create: if request.auth != null
        && request.resource.data.authorId == request.auth.uid
        // NEW: Validate tagged users array
        && request.resource.data.taggedUserIds is list
        && request.resource.data.taggedUserIds.size() <= 20; // Max 20 tags
      
      allow update: if request.auth != null
        && resource.data.authorId == request.auth.uid
        && request.resource.data.taggedUserIds is list
        && request.resource.data.taggedUserIds.size() <= 20;
    }
  }
}
```

---

### **Testing Checklist**

- [ ] แท็กผู้ใช้ 1 คน
- [ ] แท็กผู้ใช้หลายคน (10+ คน)
- [ ] ค้นหาผู้ใช้ในDialog
- [ ] ลบแท็กที่เลือกไว้
- [ ] แท็กในโพสต์ใหม่
- [ ] แท็กในโพสต์แก้ไข
- [ ] คลิกชื่อผู้ใช้ที่ถูกแท็ก → ไปหน้าProfile
- [ ] รับการแจ้งเตือนเมื่อถูกแท็ก
- [ ] แสดงชื่อผู้ใช้ที่ถูกแท็กถูกต้อง
- [ ] Firebase rules ป้องกันแท็กเกิน 20 คน

---

## 📍 Feature 2: Location/Check-in Tags

### **Priority:** 🔴 HIGH  
### **Effort:** MEDIUM (10-14 hours)  
### **Impact:** VERY HIGH  

### **Benefits**
- ✅ Promote green businesses (ร้านค้าเขียว)
- ✅ Map eco-friendly locations (จุดรีไซเคิล, ร้านอาหารอินทรีย์)
- ✅ Activity tracking (กิจกรรมปลูกต้นไม้ที่ไหน)
- ✅ Social proof (คนอื่นไปที่นี่)
- ✅ SEO & Discovery (ค้นหาสถานที่)

### **Use Cases**
1. เช็คอินร้านค้าเขียวที่ซื้อของ
2. แชร์จุดรีไซเคิลที่ดี
3. แชร์กิจกรรมปลูกต้นไม้พร้อมสถานที่
4. แนะนำร้านอาหารอินทรีย์

---

### **Implementation Steps**

#### **Step 1: Create Location Model**

```dart
// lib/models/post_location.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PostLocation {
  String id;
  String name;
  double latitude;
  double longitude;
  String? address;
  String? placeType; // 'shop', 'recycling', 'restaurant', 'event', 'other'
  String? photoUrl;
  
  // For pre-registered places
  String? placeId; // If it's a registered green business
  
  PostLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeType,
    this.photoUrl,
    this.placeId,
  });
  
  factory PostLocation.fromMap(Map<String, dynamic> map) {
    return PostLocation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'],
      placeType: map['placeType'],
      photoUrl: map['photoUrl'],
      placeId: map['placeId'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (placeType != null) 'placeType': placeType,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (placeId != null) 'placeId': placeId,
    };
  }
  
  String get displayAddress {
    if (address != null) return address!;
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
  
  IconData get typeIcon {
    switch (placeType) {
      case 'shop':
        return Icons.store;
      case 'recycling':
        return Icons.recycling;
      case 'restaurant':
        return Icons.restaurant;
      case 'event':
        return Icons.event;
      default:
        return Icons.location_on;
    }
  }
}
```

---

#### **Step 2: Add Location Picker (ใช้ Google Places API หรือ Manual)**

```dart
// pubspec.yaml
dependencies:
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  # Optional: google_maps_flutter: ^2.5.0

// lib/widgets/location_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:green_market/models/post_location.dart';
import 'package:green_market/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingLocation = false;
  Position? _currentPosition;
  String? _currentAddress;
  List<PostLocation> _nearbyPlaces = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadNearbyPlaces();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _currentAddress =
              '${place.street}, ${place.subLocality}, ${place.locality}';
        }
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถระบุตำแหน่งได้: $e')),
        );
      }
    }
  }

  Future<void> _loadNearbyPlaces() async {
    // Load registered green places from Firestore
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('green_places')
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();

      final places = snapshot.docs.map((doc) {
        final data = doc.data();
        return PostLocation(
          id: doc.id,
          name: data['name'] ?? '',
          latitude: (data['latitude'] ?? 0.0).toDouble(),
          longitude: (data['longitude'] ?? 0.0).toDouble(),
          address: data['address'],
          placeType: data['placeType'],
          photoUrl: data['photoUrl'],
          placeId: doc.id,
        );
      }).toList();

      setState(() {
        _nearbyPlaces = places;
      });
    } catch (e) {
      debugPrint('Error loading nearby places: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('เพิ่มสถานที่', style: AppTextStyles.headline),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาสถานที่...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 16),

            // Current location option
            if (_currentPosition != null)
              _buildCurrentLocationTile(),

            const Divider(),

            // Nearby registered places
            Expanded(
              child: _buildPlacesList(),
            ),

            const SizedBox(height: 16),

            // Manual location button
            OutlinedButton.icon(
              onPressed: _showManualLocationDialog,
              icon: const Icon(Icons.edit_location),
              label: const Text('ป้อนสถานที่เอง'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationTile() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.my_location,
          color: AppColors.primaryTeal,
        ),
      ),
      title: const Text('ตำแหน่งปัจจุบัน'),
      subtitle: Text(
        _currentAddress ?? 'Loading...',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        if (_currentPosition != null) {
          final location = PostLocation(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'ตำแหน่งปัจจุบัน',
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            address: _currentAddress,
            placeType: 'other',
          );
          Navigator.pop(context, location);
        }
      },
    );
  }

  Widget _buildPlacesList() {
    final filteredPlaces = _nearbyPlaces.where((place) {
      return _searchQuery.isEmpty ||
          place.name.toLowerCase().contains(_searchQuery) ||
          (place.address?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (filteredPlaces.isEmpty && _searchQuery.isNotEmpty) {
      return const Center(
        child: Text('ไม่พบสถานที่ที่ค้นหา'),
      );
    }

    return ListView.builder(
      itemCount: filteredPlaces.length,
      itemBuilder: (context, index) {
        final place = filteredPlaces[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getPlaceTypeColor(place.placeType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              place.typeIcon,
              color: _getPlaceTypeColor(place.placeType),
            ),
          ),
          title: Text(place.name),
          subtitle: Text(
            place.displayAddress,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => Navigator.pop(context, place),
        );
      },
    );
  }

  Color _getPlaceTypeColor(String? type) {
    switch (type) {
      case 'shop':
        return AppColors.primaryTeal;
      case 'recycling':
        return AppColors.accentGreen;
      case 'restaurant':
        return Colors.orange;
      case 'event':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showManualLocationDialog() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<PostLocation>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ป้อนสถานที่เอง'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสถานที่ *',
                hintText: 'เช่น ร้านกาแฟสีเขียว',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'ที่อยู่',
                hintText: 'เช่น ถนนสุขุมวิท กรุงเทพฯ',
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณาป้อนชื่อสถานที่')),
                );
                return;
              }

              final location = PostLocation(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                latitude: _currentPosition?.latitude ?? 0.0,
                longitude: _currentPosition?.longitude ?? 0.0,
                address: addressController.text.trim().isNotEmpty
                    ? addressController.text.trim()
                    : null,
                placeType: 'other',
              );

              Navigator.pop(context, location);
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }
}
```

---

#### **Step 3: Update Create Post Screen (Add Location)**

```dart
// lib/screens/create_community_post_screen.dart

class _CreateCommunityPostScreenState extends State<CreateCommunityPostScreen> {
  // ... existing fields
  
  // NEW: Location
  PostLocation? _selectedLocation;

  @override
  void initState() {
    super.initState();
    // ... existing init
    
    if (widget.postToEdit != null && widget.postToEdit!.location != null) {
      _selectedLocation = widget.postToEdit!.location;
    }
  }

  // Add this method
  Widget _buildLocationButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: _showLocationPicker,
        icon: Icon(
          _selectedLocation?.typeIcon ?? Icons.add_location,
          size: 20,
        ),
        label: Text(
          _selectedLocation?.name ?? 'เพิ่มสถานที่',
          style: AppTextStyles.body,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _selectedLocation != null
              ? AppColors.primaryTeal
              : AppColors.grayPrimary,
          side: BorderSide(
            color: _selectedLocation != null
                ? AppColors.primaryTeal
                : AppColors.grayBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    final result = await showDialog<PostLocation>(
      context: context,
      builder: (context) => const LocationPickerDialog(),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  Widget _buildLocationDisplay() {
    if (_selectedLocation == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _selectedLocation!.typeIcon,
              color: AppColors.accentGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedLocation!.name,
                  style: AppTextStyles.bodyBold,
                ),
                if (_selectedLocation!.address != null)
                  Text(
                    _selectedLocation!.displayAddress,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _selectedLocation = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // Update build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... existing widgets
            
            _buildMediaButtons(),
            _buildTagUsersButton(),
            _buildLocationButton(), // ← ADD THIS
            
            if (_selectedLocation != null)
              _buildLocationDisplay(), // ← ADD THIS
            
            // ... rest
          ],
        ),
      ),
    );
  }

  // Update _submitPost()
  Future<void> _submitPost() async {
    // ... existing code
    
    final postData = {
      // ... existing fields
      if (_selectedLocation != null)
        'location': _selectedLocation!.toMap(),
    };
    
    // ... rest
  }
}
```

---

#### **Step 4: Update Post Card (Display Location)**

```dart
// lib/widgets/post_card_widget.dart

class _PostCardWidgetState extends State<PostCardWidget> {
  // Add after _buildTaggedUsers()
  Widget _buildLocation() {
    if (widget.post.location == null) return const SizedBox.shrink();
    
    final location = widget.post.location!;
    
    return GestureDetector(
      onTap: () => _openLocationMap(location),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.grayBorder.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                location.typeIcon,
                color: AppColors.primaryTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: AppTextStyles.bodyBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.address != null)
                    Text(
                      location.displayAddress,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.graySecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _openLocationMap(PostLocation location) {
    // Open Google Maps or in-app map
    // For now, just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(location.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location.address != null)
              Text('ที่อยู่: ${location.address}'),
            const SizedBox(height: 8),
            Text(
              'พิกัด: ${location.latitude.toStringAsFixed(6)}, '
              '${location.longitude.toStringAsFixed(6)}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Open in Google Maps
              // final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
              // launch(url);
            },
            child: const Text('เปิดในแผนที่'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildUserHeader(),
          _buildTaggedUsers(),
          _buildLocation(), // ← ADD THIS
          // ... rest
        ],
      ),
    );
  }
}
```

---

### **Testing Checklist**

- [ ] เลือกตำแหน่งปัจจุบัน
- [ ] ค้นหาสถานที่ที่ลงทะเบียนแล้ว
- [ ] ป้อนสถานที่เอง (manual)
- [ ] แสดงสถานที่ใน Post Card
- [ ] คลิกสถานที่เพื่อดูรายละเอียด
- [ ] ลบสถานที่ที่เลือกไว้
- [ ] สถานที่แสดงใน Feed
- [ ] แก้ไขโพสต์พร้อมสถานที่

---

## 🎯 Summary

### **Phase 1 Priorities (1-2 weeks)**

| Feature | Priority | Effort | Impact | Status |
|---------|----------|--------|--------|--------|
| 1. Friend Tagging | 🔴 HIGH | 8-12h | VERY HIGH | Ready |
| 2. Location Tags | 🔴 HIGH | 10-14h | VERY HIGH | Ready |
| 3. Threads | 🔴 HIGH | 12-16h | HIGH | Next |
| 4. Quote Posts | 🔴 HIGH | 6-8h | HIGH | Next |
| 5. Hashtag Challenges | 🔴 HIGH | 14-18h | VERY HIGH | Next |

**Total Estimated Time:** 50-68 hours (~2 weeks for 1 developer)

---

### **Implementation Order**

**Week 1:**
- Day 1-2: Friend Tagging (12h)
- Day 3-4: Location Tags (14h)
- Day 5: Testing & Bug fixes (8h)

**Week 2:**
- Day 1-2: Quote Posts (8h)
- Day 3-4: Threads (16h)
- Day 5: Testing & Documentation (8h)

---

### **Next Steps**

1. ✅ Implement Friend Tagging (Code provided above)
2. ✅ Implement Location Tags (Code provided above)
3. ⏭️ Review and test thoroughly
4. ⏭️ Deploy to staging
5. ⏭️ Get user feedback
6. ⏭️ Move to Phase 2 features

---

**Generated:** ${(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")}  
**Author:** AI Development Assistant  
**Version:** 1.0
