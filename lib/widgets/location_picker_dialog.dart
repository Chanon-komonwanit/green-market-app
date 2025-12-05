// lib/widgets/location_picker_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/post_location.dart';
import '../utils/constants.dart';

/// Dialog for picking location/check-in for posts
/// Features:
/// - Current location with GPS
/// - Search registered green places
/// - Manual location input
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Get current GPS location
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

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _currentPosition = position;
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            _currentAddress = [
              place.street,
              place.subLocality,
              place.locality,
              place.administrativeArea,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
          }
          _isLoadingLocation = false;
        });
      } catch (e) {
        // Geocoding failed, but we have coordinates
        setState(() {
          _currentPosition = position;
          _currentAddress =
              'พิกัด: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถระบุตำแหน่งได้: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  /// Load registered green places from Firestore
  Future<void> _loadNearbyPlaces() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('green_places')
          .where('isActive', isEqualTo: true)
          .limit(50)
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

      if (mounted) {
        setState(() {
          _nearbyPlaces = places;
        });
      }
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),

            const SizedBox(height: 16),

            // Current location option
            if (_isLoadingLocation)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (_currentPosition != null)
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        maxLines: 2,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.graySecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่พบสถานที่ที่ค้นหา',
              style: AppTextStyles.body.copyWith(
                color: AppColors.graySecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ลองค้นหาด้วยคำอื่นหรือป้อนสถานที่เอง',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (filteredPlaces.isEmpty && _nearbyPlaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: AppColors.graySecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีสถานที่ที่ลงทะเบียน',
              style: AppTextStyles.body.copyWith(
                color: AppColors.graySecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ใช้ตำแหน่งปัจจุบันหรือป้อนสถานที่เอง',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              color: place.typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              place.typeIcon,
              color: place.typeColor,
            ),
          ),
          title: Text(place.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (place.address != null)
                Text(
                  place.displayAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              Text(
                place.typeName,
                style: AppTextStyles.caption.copyWith(
                  color: place.typeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          onTap: () => Navigator.pop(context, place),
        );
      },
    );
  }

  Future<void> _showManualLocationDialog() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    String selectedType = 'other';

    final result = await showDialog<PostLocation>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ป้อนสถานที่เอง'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อสถานที่ *',
                    hintText: 'เช่น ร้านกาแฟสีเขียว',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'ที่อยู่',
                    hintText: 'เช่น ถนนสุขุมวิท กรุงเทพฯ',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'ประเภทสถานที่',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'shop', child: Text('🏪 ร้านค้าเขียว')),
                    DropdownMenuItem(
                        value: 'recycling', child: Text('♻️ จุดรีไซเคิล')),
                    DropdownMenuItem(
                        value: 'restaurant', child: Text('🍽️ ร้านอาหาร')),
                    DropdownMenuItem(value: 'event', child: Text('🎉 กิจกรรม')),
                    DropdownMenuItem(value: 'other', child: Text('📍 อื่นๆ')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
              ],
            ),
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
                    const SnackBar(
                      content: Text('กรุณาป้อนชื่อสถานที่'),
                      duration: Duration(seconds: 2),
                    ),
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
                  placeType: selectedType,
                );

                Navigator.pop(context, location);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
              ),
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }
}
