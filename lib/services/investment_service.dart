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

  // Add new investment opportunity (Admin only)
  Future<bool> addInvestmentOpportunity(
      Map<String, dynamic> opportunityData) async {
    try {
      await _firestore.collection('investment_opportunities').add({
        ...opportunityData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, approved, rejected
        'totalRaised': 0.0,
        'investorCount': 0,
      });
      print('Investment opportunity added successfully');
      return true;
    } catch (e) {
      print('Error adding investment opportunity: $e');
      return false;
    }
  }

  // Update investment opportunity (Admin only)
  Future<bool> updateInvestmentOpportunity(
      String opportunityId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('investment_opportunities')
          .doc(opportunityId)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Investment opportunity updated successfully');
      return true;
    } catch (e) {
      print('Error updating investment opportunity: $e');
      return false;
    }
  }

  // Delete investment opportunity (Admin only)
  Future<bool> deleteInvestmentOpportunity(String opportunityId) async {
    try {
      // First check if there are any investments
      final investments = await _firestore
          .collection('investments')
          .where('opportunityId', isEqualTo: opportunityId)
          .get();

      if (investments.docs.isNotEmpty) {
        print('Cannot delete opportunity with existing investments');
        return false;
      }

      await _firestore
          .collection('investment_opportunities')
          .doc(opportunityId)
          .delete();
      print('Investment opportunity deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting investment opportunity: $e');
      return false;
    }
  }

  // Make an investment
  Future<bool> makeInvestment({
    required String userId,
    required String opportunityId,
    required double amount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if opportunity exists and is active
      final opportunityDoc = await _firestore
          .collection('investment_opportunities')
          .doc(opportunityId)
          .get();

      if (!opportunityDoc.exists) {
        print('Investment opportunity not found');
        return false;
      }

      final opportunity = opportunityDoc.data()!;
      final currentRaised =
          (opportunity['totalRaised'] as num?)?.toDouble() ?? 0.0;
      final targetAmount =
          (opportunity['targetAmount'] as num?)?.toDouble() ?? 0.0;
      final minimumInvestment =
          (opportunity['minimumInvestment'] as num?)?.toDouble() ?? 0.0;

      // Validate investment amount
      if (amount < minimumInvestment) {
        print('Investment amount below minimum');
        return false;
      }

      if (currentRaised + amount > targetAmount) {
        print('Investment would exceed target amount');
        return false;
      }

      // Create investment record
      final investmentData = {
        'userId': userId,
        'opportunityId': opportunityId,
        'amount': amount,
        'investmentDate': FieldValue.serverTimestamp(),
        'status': 'active', // active, completed, withdrawn
        'returns': 0.0,
        'metadata': metadata ?? {},
      };

      await _firestore.collection('investments').add(investmentData);

      // Update opportunity totals
      await _firestore
          .collection('investment_opportunities')
          .doc(opportunityId)
          .update({
        'totalRaised': FieldValue.increment(amount),
        'investorCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Investment made successfully');
      return true;
    } catch (e) {
      print('Error making investment: $e');
      return false;
    }
  }

  // Get user's investments
  Future<List<Map<String, dynamic>>> getUserInvestments(String userId) async {
    try {
      final investments = await _firestore
          .collection('investments')
          .where('userId', isEqualTo: userId)
          .orderBy('investmentDate', descending: true)
          .get();

      final investmentList = <Map<String, dynamic>>[];

      for (final doc in investments.docs) {
        final investmentData = doc.data();
        investmentData['id'] = doc.id;

        // Get opportunity details
        final opportunityDoc = await _firestore
            .collection('investment_opportunities')
            .doc(investmentData['opportunityId'])
            .get();

        if (opportunityDoc.exists) {
          investmentData['opportunity'] = opportunityDoc.data();
        }

        investmentList.add(investmentData);
      }

      return investmentList;
    } catch (e) {
      print('Error fetching user investments: $e');
      return [];
    }
  }

  // Calculate returns for an investment
  Future<bool> updateInvestmentReturns(
      String investmentId, double returns) async {
    try {
      await _firestore.collection('investments').doc(investmentId).update({
        'returns': returns,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Investment returns updated successfully');
      return true;
    } catch (e) {
      print('Error updating investment returns: $e');
      return false;
    }
  }

  // Get investment statistics for a user
  Future<Map<String, dynamic>> getUserInvestmentStats(String userId) async {
    try {
      final investments = await _firestore
          .collection('investments')
          .where('userId', isEqualTo: userId)
          .get();

      double totalInvested = 0.0;
      double totalReturns = 0.0;
      int activeInvestments = 0;

      for (final doc in investments.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final returns = (data['returns'] as num?)?.toDouble() ?? 0.0;
        final status = data['status'] as String? ?? '';

        totalInvested += amount;
        totalReturns += returns;

        if (status == 'active') {
          activeInvestments++;
        }
      }

      return {
        'totalInvested': totalInvested,
        'totalReturns': totalReturns,
        'netGain': totalReturns - totalInvested,
        'activeInvestments': activeInvestments,
        'totalInvestments': investments.docs.length,
        'averageReturn': investments.docs.isNotEmpty
            ? totalReturns / investments.docs.length
            : 0.0,
      };
    } catch (e) {
      print('Error calculating investment stats: $e');
      return {
        'totalInvested': 0.0,
        'totalReturns': 0.0,
        'netGain': 0.0,
        'activeInvestments': 0,
        'totalInvestments': 0,
        'averageReturn': 0.0,
      };
    }
  }
}
