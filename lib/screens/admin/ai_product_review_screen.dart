// lib/screens/admin/ai_product_review_screen.dart
// Admin panel for reviewing AI-analyzed products
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/models/ai_settings.dart';
import 'package:green_market/services/ai_eco_analysis_service.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/widgets/ai_status_widget.dart';
import 'package:green_market/screens/admin/ai_settings_screen.dart';

class AIProductReviewScreen extends StatefulWidget {
  const AIProductReviewScreen({super.key});

  @override
  State<AIProductReviewScreen> createState() => _AIProductReviewScreenState();
}

class _AIProductReviewScreenState extends State<AIProductReviewScreen> {
  final AIEcoAnalysisService _aiService = AIEcoAnalysisService();
  final FirebaseService _firebaseService = FirebaseService();
  String _filterStatus = 'all'; // all, pending, verified, discrepancy
  AISettings? _aiSettings;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadAISettings();
  }

  Future<void> _loadAISettings() async {
    try {
      final settings = await _aiService.getAISettings();
      if (mounted) {
        setState(() {
          _aiSettings = settings;
          _isLoadingSettings = false;
        });
      }
    } catch (e) {
      print('Error loading AI settings: $e');
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Product Review'),
        backgroundColor: Colors.deepPurple,
        actions: [
          // AI Status Indicator
          if (!_isLoadingSettings)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _aiSettings?.aiEnabled == true
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _aiSettings?.aiEnabled == true
                          ? Colors.green
                          : Colors.orange,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 16,
                        color: _aiSettings?.aiEnabled == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _aiSettings?.aiEnabled == true ? 'AI ON' : 'AI OFF',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _aiSettings?.aiEnabled == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'AI Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AISettingsScreen(),
                ),
              );
              _loadAISettings(); // Reload after settings change
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'AI Statistics',
            onPressed: _showAIStatistics,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildProductList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Filter:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ทั้งหมด', 'all'),
                  _buildFilterChip('รอตรวจสอบ', 'pending'),
                  _buildFilterChip('ผ่านการตรวจ', 'verified'),
                  _buildFilterChip('คะแนนต่างกัน', 'discrepancy'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = value;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.deepPurple.withOpacity(0.2),
        checkmarkColor: Colors.deepPurple,
        labelStyle: TextStyle(
          color: isSelected ? Colors.deepPurple : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getProductRequests(status: 'pending'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'ไม่มีสินค้าที่รอการอนุมัติ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'สินค้าที่ผู้ขายส่งมาจะแสดงที่นี่',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Filter requests with AI analysis
        final requests = snapshot.data!.where((request) {
          final productData = request['productData'] as Map<String, dynamic>?;
          if (productData == null) return false;

          // Check if AI analyzed
          final aiAnalyzed = productData['aiAnalyzed'] == true;
          if (!aiAnalyzed && _filterStatus != 'all') return false;

          // Apply filter
          switch (_filterStatus) {
            case 'pending':
              return request['status'] == 'pending' && aiAnalyzed;
            case 'verified':
              return request['status'] == 'approved';
            case 'discrepancy':
              if (!aiAnalyzed) return false;
              final aiScore = productData['aiEcoScore'] as int? ?? 0;
              final sellerScore = productData['ecoScore'] as int? ?? 0;
              final diff = (sellerScore - aiScore).abs();
              return diff >= 10 && request['status'] == 'pending';
            case 'all':
            default:
              return true;
          }
        }).toList();

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildProductRequestCard(requests[index]);
          },
        );
      },
    );
  }

  Widget _buildProductRequestCard(Map<String, dynamic> request) {
    final requestId = request['id'] as String;
    final productData = request['productData'] as Map<String, dynamic>;
    final product = Product.fromMap(productData);

    final aiScore = productData['aiEcoScore'] as int? ?? 0;
    final sellerScore = product.ecoScore;
    final scoreDiff = (sellerScore - aiScore).abs();
    final hasDiscrepancy = scoreDiff >= 10;
    final aiAnalyzed = productData['aiAnalyzed'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: hasDiscrepancy ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasDiscrepancy ? Colors.orange : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: aiAnalyzed ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: aiAnalyzed ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        aiAnalyzed ? Icons.check_circle : Icons.pending,
                        size: 16,
                        color: aiAnalyzed ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        aiAnalyzed ? 'AI วิเคราะห์แล้ว' : 'รอ AI วิเคราะห์',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: aiAnalyzed ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (hasDiscrepancy && aiAnalyzed)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'คะแนนต่าง $scoreDiff แต้ม',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Product Info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : 'https://via.placeholder.com/80',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ราคา: ฿${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ส่งคำขอ: ${_formatDateTime(request['submittedAt'] as Timestamp?)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (aiAnalyzed) ...[
              const Divider(height: 24),

              // Score Comparison
              _buildScoreComparison(product, sellerScore, aiScore, scoreDiff),

              const SizedBox(height: 16),

              // AI Reasoning
              if (productData['aiReasoning'] != null) ...[
                const Text(
                  'เหตุผลจาก AI:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Text(
                    productData['aiReasoning'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // AI Suggestions
              if (productData['aiSuggestions'] != null &&
                  (productData['aiSuggestions'] as List).isNotEmpty) ...[
                const Text(
                  'คำแนะนำจาก AI:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...(productData['aiSuggestions'] as List).map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            suggestion.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Score Breakdown
              if (productData['aiScoreBreakdown'] != null) ...[
                const Text(
                  'รายละเอียดคะแนนจาก AI:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildScoreBreakdown(
                  Map<String, double>.from(
                    (productData['aiScoreBreakdown'] as Map).map(
                      (key, value) => MapEntry(
                        key.toString(),
                        (value as num).toDouble(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Admin Actions or Verified Badge
              if (productData['adminVerified'] == true)
                _buildVerifiedBadge(product)
              else
                _buildAdminActions(requestId, product, aiScore),
            ] else ...[
              const Divider(height: 24),

              // Analyze Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _analyzeProduct(requestId, product),
                  icon: const Icon(Icons.psychology),
                  label: const Text('วิเคราะห์ด้วย AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // เพิ่ม method สำหรับวิเคราะห์สินค้าด้วย AI
  Future<void> _analyzeProduct(String requestId, Product product) async {
    // Check AI settings first
    final settings = await _aiService.getAISettings();

    if (!settings.aiEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ ระบบ AI ถูกปิดใช้งาน กรุณาเปิดใช้งานก่อน'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!settings.canUseAI()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ ใช้งาน AI เกินขีดจำกัดวันนี้ (${settings.currentUsage}/${settings.dailyLimit})',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังวิเคราะห์สินค้าด้วย AI...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Prepare product data for AI
      final productEcoData = ProductEcoData(
        productName: product.name,
        description: product.description,
        sellerClaimedScore: product.ecoScore,
        sellerJustification: product.description,
        materials: [], // Product model doesn't have materials field
        certificates: [], // Product model doesn't have certifications field
        manufacturingProcess: '', // Product model doesn't have this field
        packagingType: '', // Product model doesn't have this field
        wasteManagement: '',
        category: product.category,
      );

      // Analyze with AI
      final result = await _aiService.analyzeProduct(productEcoData);

      // Update product request with AI results
      await FirebaseFirestore.instance
          .collection('product_requests')
          .doc(requestId)
          .update({
        'productData.aiEcoScore': result.aiEcoScore,
        'productData.aiReasoning': result.aiReasoning,
        'productData.aiSuggestions': result.aiSuggestions,
        'productData.aiScoreBreakdown': result.scoreBreakdown,
        'productData.aiConfidence': result.confidence,
        'productData.aiAnalyzed': true,
        'productData.aiAnalyzedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // Close loading dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ วิเคราะห์สำเร็จ: ${result.aiEcoScore}/100'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAdminActions(String requestId, Product product, int aiScore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _approveWithAIScore(requestId, aiScore),
          icon: const Icon(Icons.check_circle),
          label: Text('อนุมัติด้วยคะแนน AI ($aiScore/100)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _approveWithSellerScore(requestId, product.ecoScore),
          icon: const Icon(Icons.person),
          label: Text('อนุมัติด้วยคะแนนผู้ขาย (${product.ecoScore}/100)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final customScore = await _showCustomScoreDialog(aiScore);
            if (customScore != null) {
              final feedback = await _showFeedbackDialog(null);
              final confirmed = await _showConfirmDialog(
                title: 'ยืนยันการอนุมัติ',
                message: 'อนุมัติสินค้าด้วยคะแนน $customScore/100?',
                confirmColor: Colors.purple,
              );
              if (confirmed) {
                await _approveWithCustomScore(
                  requestId,
                  customScore,
                  feedback,
                );
              }
            }
          },
          icon: const Icon(Icons.tune),
          label: const Text('กำหนดคะแนนเอง'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.purple,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _rejectProduct(requestId),
          icon: const Icon(Icons.cancel),
          label: const Text('ปฏิเสธ'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Future<void> _approveWithCustomScore(
    String requestId,
    int customScore,
    String? feedback,
  ) async {
    try {
      await _firebaseService.approveProductRequest(
        requestId,
        ecoScore: customScore,
      );

      // Update with admin verification info
      await _updateProductWithVerification(requestId, customScore, feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ อนุมัติสินค้าด้วยคะแนน $customScore/100 สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveWithAIScore(String requestId, int aiScore) async {
    try {
      await _firebaseService.approveProductRequest(
        requestId,
        ecoScore: aiScore,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ อนุมัติสินค้าด้วยคะแนน AI สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveWithSellerScore(
      String requestId, int sellerScore) async {
    try {
      await _firebaseService.approveProductRequest(
        requestId,
        ecoScore: sellerScore,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ อนุมัติสินค้าด้วยคะแนนผู้ขายสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectProduct(String requestId) async {
    // Show reason dialog
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปฏิเสธสินค้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรุณาระบุเหตุผลในการปฏิเสธ:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'เหตุผล...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ปฏิเสธ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firebaseService.rejectProductRequest(
          requestId,
          reasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ ปฏิเสธสินค้าสำเร็จ'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'ไม่ระบุ';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} นาทีที่แล้ว';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ชั่วโมงที่แล้ว';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} วันที่แล้ว';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getEmptyMessage() {
    switch (_filterStatus) {
      case 'pending':
        return 'ไม่มีสินค้าที่รอตรวจสอบ';
      case 'verified':
        return 'ยังไม่มีสินค้าที่ตรวจสอบแล้ว';
      case 'discrepancy':
        return 'ไม่มีสินค้าที่มีคะแนนต่างกัน';
      default:
        return 'ยังไม่มีสินค้าที่วิเคราะห์ด้วย AI';
    }
  }

  // Helper: Show custom score dialog
  Future<int?> _showCustomScoreDialog(int currentScore) async {
    final controller = TextEditingController(text: currentScore.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('กำหนดคะแนนเอง'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรุณาระบุคะแนน Eco Score (0-100):'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'คะแนน 0-100',
                suffixText: '/100',
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
              final score = int.tryParse(controller.text);
              if (score != null && score >= 0 && score <= 100) {
                Navigator.pop(context, score);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาระบุคะแนนระหว่าง 0-100'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  // Helper: Show confirm dialog
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'ยืนยัน',
    String cancelText = 'ยกเลิก',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Helper: Show feedback dialog
  Future<String?> _showFeedbackDialog(String? currentFeedback) async {
    final controller = TextEditingController(text: currentFeedback ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ข้อเสนอแนะสำหรับผู้ขาย'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรุณาระบุข้อเสนอแนะหรือเหตุผล:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'ข้อเสนอแนะ...',
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  // Helper: Update product with admin verification
  Future<void> _updateProductWithVerification(
    String requestId,
    int finalScore,
    String? feedback,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('product_requests')
          .doc(requestId)
          .update({
        'productData.adminVerified': true,
        'productData.adminApprovedScore': finalScore,
        'productData.adminFeedback': feedback,
        'productData.adminVerifiedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ บันทึกการตรวจสอบสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // REMOVED: _buildProductCard - Not used, replaced by _buildProductRequestCard

  Widget _buildVerifiedBadge(Product product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ตรวจสอบแล้ว',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (product.adminFeedback != null)
                  Text(
                    product.adminFeedback!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                if (product.adminApprovedScore != null)
                  Text(
                    'คะแนนสุดท้าย: ${product.adminApprovedScore}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreComparison(
    Product product,
    int sellerScore,
    int aiScore,
    int scoreDiff,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[50]!,
            Colors.purple[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scoreDiff >= 10 ? Colors.orange : Colors.blue[200]!,
          width: scoreDiff >= 10 ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildScoreColumn(
                  'คะแนนผู้ขาย',
                  sellerScore,
                  Colors.blue,
                  Icons.person,
                ),
              ),
              Column(
                children: [
                  Icon(
                    scoreDiff >= 10
                        ? Icons.warning_amber_rounded
                        : Icons.compare_arrows,
                    color: scoreDiff >= 10 ? Colors.orange : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ต่าง $scoreDiff',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: scoreDiff >= 10 ? Colors.orange : Colors.grey,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: _buildScoreColumn(
                  'คะแนน AI',
                  aiScore,
                  Colors.purple,
                  Icons.smart_toy,
                ),
              ),
            ],
          ),
          if (scoreDiff >= 10) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'คะแนนต่างกันมาก แนะนำให้ตรวจสอบอย่างละเอียด',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreColumn(
    String label,
    int score,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        _buildEcoLevelBadge(score),
      ],
    );
  }

  Widget _buildEcoLevelBadge(int score) {
    String level;
    Color color;
    if (score >= 90) {
      level = 'Champion';
      color = Colors.purple;
    } else if (score >= 75) {
      level = 'Excellent';
      color = Colors.green;
    } else if (score >= 60) {
      level = 'Good';
      color = Colors.blue;
    } else {
      level = 'Standard';
      color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown(Map<String, double> breakdown) {
    return Column(
      children: breakdown.entries.map((entry) {
        final percentage = entry.value / 100;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getBreakdownLabel(entry.key),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getBreakdownColor(entry.key),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getBreakdownLabel(String key) {
    switch (key) {
      case 'materials':
        return 'วัสดุ';
      case 'manufacturing':
        return 'การผลิต';
      case 'packaging':
        return 'บรรจุภัณฑ์';
      case 'wasteManagement':
        return 'การจัดการขยะ';
      case 'certificates':
        return 'ใบรับรอง';
      default:
        return key;
    }
  }

  Color _getBreakdownColor(String key) {
    switch (key) {
      case 'materials':
        return Colors.green;
      case 'manufacturing':
        return Colors.blue;
      case 'packaging':
        return Colors.orange;
      case 'wasteManagement':
        return Colors.teal;
      case 'certificates':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showAIStatistics() async {
    try {
      // Fetch AI analysis statistics from Firestore
      final statsSnapshot = await FirebaseFirestore.instance
          .collection('ai_statistics')
          .doc('overall')
          .get();

      if (!mounted) return;

      final stats = statsSnapshot.data() ?? {};
      final totalAnalyzed = stats['totalAnalyzed'] ?? 0;
      final approved = stats['approved'] ?? 0;
      final rejected = stats['rejected'] ?? 0;
      final averageScore = stats['averageScore'] ?? 0.0;
      final accuracyRate = stats['accuracyRate'] ?? 0.0;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue),
              SizedBox(width: 8),
              Text('AI Analysis Statistics'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Total Analyzed', totalAnalyzed.toString()),
              _buildStatRow('Approved', approved.toString()),
              _buildStatRow('Rejected', rejected.toString()),
              _buildStatRow('Average Score', averageScore.toStringAsFixed(1)),
              _buildStatRow('Accuracy Rate',
                  '${(accuracyRate * 100).toStringAsFixed(1)}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading statistics: $e')),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
