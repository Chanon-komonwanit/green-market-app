import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For IconData
import 'package:green_market/models/my_investment.dart';
import 'package:firebase_auth/firebase_auth.dart'; // If you need current user ID

class UserPortfolioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Uncomment if using Firebase Auth

  // Example: Collection path might be 'users/{userId}/my_investments'
  // Or a top-level collection 'user_portfolios' with a 'userId' field.
  // For this example, let's assume a top-level collection for simplicity.
  final String _collectionPath = 'user_portfolios';

  // Helper to convert icon string to IconData (similar to InvestmentService)
  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'solar_power_outlined':
        return Icons.solar_power_outlined;
      case 'business_center_outlined':
        return Icons.business_center_outlined;
      // Add other cases as needed
      default:
        return Icons.attach_money; // Default icon for investments
    }
  }

  Future<List<MyInvestment>> getUserInvestments() async {
    // In a real app, you'd get the userId from FirebaseAuth or your auth system
    // For example:
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('No user logged in. Cannot fetch portfolio.');
        }
      }
      return []; // Or handle not logged in state, throw exception, etc.
    }
    String userId = currentUser.uid;

    try {
      // This query assumes your 'user_portfolios' collection has documents
      // where each document ID is the userId, and inside each user document,
      // there's a subcollection 'my_investments'.
      // OR, if 'user_portfolios' stores all investments and has a 'userId' field:
      // QuerySnapshot snapshot = await _firestore
      //     .collection(_collectionPath) // Assuming this is 'all_my_investments'
      //     .where('userId', isEqualTo: userId) // Filter by userId
      //     .get();

      // For this example, let's assume 'user_portfolios' collection
      // and each document is an investment with a 'userId' field.
      QuerySnapshot snapshot = await _firestore
          .collection(
              _collectionPath) // This should be the collection of individual investments
          .where('userId', isEqualTo: userId) // Filter by the current user's ID
          .get();

      if (snapshot.docs.isEmpty) {
        print('No investments found for user: $userId');
        return [];
      }

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return MyInvestment(
          id: doc.id,
          name: data['name'] ?? 'N/A',
          assetType: data['assetType'] ?? 'Unknown',
          quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
          currentValue: (data['currentValue'] as num?)?.toDouble() ?? 0.0,
          totalReturn: (data['totalReturn'] as num?)?.toDouble() ?? 0.0,
          returnPercentage:
              (data['returnPercentage'] as num?)?.toDouble() ?? 0.0,
          icon: _getIconFromString(data['iconString'] ?? 'attach_money'),
        );
      }).toList();
    } catch (e) {
      print('Error fetching user investments: $e');
      return [];
    }
  }
}
