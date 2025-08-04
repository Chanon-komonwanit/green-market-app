import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/product.dart';

class DebugProductsScreen extends StatefulWidget {
  const DebugProductsScreen({super.key});

  @override
  State<DebugProductsScreen> createState() => _DebugProductsScreenState();
}

class _DebugProductsScreenState extends State<DebugProductsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<String> debugLogs = [];

  @override
  void initState() {
    super.initState();
    _runDebugChecks();
  }

  void _addLog(String message) {
    setState(() {
      debugLogs.add('[${DateTime.now().toLocal()}] $message');
    });
    print(message);
  }

  Future<void> _runDebugChecks() async {
    _addLog('=== Starting Product Debug ===');

    try {
      // Check all products in collection
      _addLog('Checking all products in collection...');
      final productsSnapshot =
          await FirebaseFirestore.instance.collection('products').get();

      _addLog('Total products found: ${productsSnapshot.docs.length}');

      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        _addLog('Product ID: ${doc.id}');
        _addLog('  Name: ${data['name'] ?? 'No name'}');
        _addLog('  Status: ${data['status'] ?? 'No status'}');
        _addLog('  isApproved: ${data['isApproved']}');
        _addLog('  sellerId: ${data['sellerId'] ?? 'No seller'}');
        _addLog('---');
      }

      // Check approved products using Firebase Service
      _addLog('\nChecking approved products via FirebaseService...');
      final approvedProducts =
          await _firebaseService.getApprovedProducts().first;
      _addLog('Approved products from service: ${approvedProducts.length}');

      for (var product in approvedProducts) {
        _addLog('Approved: ${product.name} (ID: ${product.id})');
        _addLog('  Status: ${product.status}');
      }

      // Check product requests
      _addLog('\nChecking product requests...');
      final requestsSnapshot =
          await FirebaseFirestore.instance.collection('product_requests').get();

      _addLog('Total product requests: ${requestsSnapshot.docs.length}');

      for (var doc in requestsSnapshot.docs) {
        final data = doc.data();
        _addLog('Request ID: ${doc.id}');
        _addLog('  Status: ${data['status'] ?? 'No status'}');
        if (data['productData'] != null) {
          final productData = data['productData'] as Map<String, dynamic>;
          _addLog('  Product Name: ${productData['name'] ?? 'No name'}');
        }
        _addLog('---');
      }

      _addLog('=== Debug Complete ===');
    } catch (e) {
      _addLog('ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Products'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                debugLogs.clear();
              });
              _runDebugChecks();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Product Debug Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${debugLogs.length} logs',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: debugLogs.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: debugLogs.length,
                    itemBuilder: (context, index) {
                      final log = debugLogs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: log.contains('ERROR')
                              ? Colors.red.shade50
                              : log.contains('===')
                                  ? Colors.blue.shade50
                                  : Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: log.contains('ERROR')
                                ? Colors.red
                                : log.contains('===')
                                    ? Colors.blue
                                    : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
