import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For IconData, can be removed if icon handling changes
import 'package:green_market/models/investment_opportunity.dart';

class InvestmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath =
      'investment_opportunities'; // ชื่อ collection ใน Firestore

  // Method to convert Firestore icon string to IconData
  // This is a simple example; you might need a more robust solution
  // or store icon metadata differently.
  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'business_center_outlined':
        return Icons.business_center_outlined;
      case 'account_balance_outlined':
        return Icons.account_balance_outlined;
      case 'agriculture_outlined':
        return Icons.agriculture_outlined;
      case 'solar_power_outlined':
        return Icons.solar_power_outlined;
      case 'eco_outlined':
        return Icons.eco_outlined;
      default:
        return Icons.help_outline; // Default icon
    }
  }

  Future<List<InvestmentOpportunity>> getInvestmentOpportunities() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection(_collectionPath).get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return InvestmentOpportunity(
          id: doc.id,
          name: data['name'] ?? 'N/A',
          description: data['description'] ?? 'No description available.',
          type: data['type'] ?? 'Unknown',
          expectedReturn: data['expectedReturn'] ?? 'N/A',
          riskLevel: data['riskLevel'] ?? 'Unknown',
          // Assuming you store icon name as a string in Firestore
          icon: _getIconFromString(data['iconString'] ?? 'help_outline'),
        );
      }).toList();
    } catch (e) {
      // Log the error or handle it as per your app's error handling strategy
      print('Error fetching investment opportunities: $e');
      return []; // Return an empty list or throw an exception
    }
  }

  // TODO: Add methods for adding, updating, or deleting opportunities if needed
}
