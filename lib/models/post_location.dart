// lib/models/post_location.dart
import 'package:flutter/material.dart';

/// Model for post location/check-in
/// Used for tagging locations in community posts
class PostLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String?
      placeType; // 'shop', 'recycling', 'restaurant', 'event', 'other'
  final String? photoUrl;
  final String? placeId; // If it's a registered green business

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

  /// Create from Firestore map
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

  /// Convert to Firestore map
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

  /// Display address or coordinates
  String get displayAddress {
    if (address != null && address!.isNotEmpty) return address!;
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Get icon based on place type
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

  /// Get color based on place type
  Color get typeColor {
    switch (placeType) {
      case 'shop':
        return const Color(0xFF059669); // Teal
      case 'recycling':
        return const Color(0xFF10B981); // Green
      case 'restaurant':
        return Colors.orange;
      case 'event':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get type display name in Thai
  String get typeName {
    switch (placeType) {
      case 'shop':
        return 'ร้านค้าเขียว';
      case 'recycling':
        return 'จุดรีไซเคิล';
      case 'restaurant':
        return 'ร้านอาหาร';
      case 'event':
        return 'กิจกรรม';
      default:
        return 'สถานที่';
    }
  }

  @override
  String toString() {
    return 'PostLocation(id: $id, name: $name, lat: $latitude, lng: $longitude)';
  }
}
