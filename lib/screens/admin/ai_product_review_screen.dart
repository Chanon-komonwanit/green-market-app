// lib/screens/admin/ai_product_review_screen.dart
// Admin panel for reviewing AI-analyzed products
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:green_market/models/product.dart';
import 'package:green_market/services/ai_eco_analysis_service.dart';
import 'package:green_market/services/firebase_service.dart';

class AIProductReviewScreen extends StatefulWidget {
  const AIProductReviewScreen({super.key});

  @override
  State<AIProductReviewScreen> createState() => _AIProductReviewScreenState();
}

class _AIProductReviewScreenState extends State<AIProductReviewScreen> {
  final AIEcoAnalysisService _aiService = AIEcoAnalysisService();
  String _filterStatus = 'all'; // all, pending, verified, discrepancy

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Product Review'),
        backgroundColor: Colors.deepPurple,
        actions: [
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('aiAnalyzed', isEqualTo: true)
          .orderBy('aiAnalyzedAt', descending: true)
          .snapshots(),
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

        final products = snapshot.data!.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((product) {
          // Apply filter
          switch (_filterStatus) {
            case 'pending':
              return product.adminVerified != true;
            case 'verified':
              return product.adminVerified == true;
            case 'discrepancy':
              if (product.aiEcoScore == null) return false;
              final diff = (product.ecoScore - product.aiEcoScore!).abs();
              return diff >= 10 && product.adminVerified != true;
            case 'all':
            default:
              return true;
          }
        }).toList();

        if (products.isEmpty) {
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
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(products[index]);
          },
        );
      },
    );
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

  Widget _buildProductCard(Product product) {
    final aiScore = product.aiEcoScore ?? 0;
    final sellerScore = product.ecoScore;
    final scoreDiff = (sellerScore - aiScore).abs();
    final hasDiscrepancy = scoreDiff >= 10;

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
            // Header with product info
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
                        'วิเคราะห์: ${_formatDateTime(product.aiAnalyzedAt)}',
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
            const Divider(height: 24),

            // Score Comparison Section
            _buildScoreComparison(product, sellerScore, aiScore, scoreDiff),

            const SizedBox(height: 16),

            // AI Reasoning
            if (product.aiReasoning != null) ...[
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
                  product.aiReasoning!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // AI Suggestions
            if (product.aiSuggestions != null &&
                product.aiSuggestions!.isNotEmpty) ...[
              const Text(
                'คำแนะนำจาก AI:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...product.aiSuggestions!.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          suggestion,
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
            if (product.aiScoreBreakdown != null) ...[
              const Text(
                'รายละเอียดคะแนนจาก AI:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              _buildScoreBreakdown(product.aiScoreBreakdown!),
              const SizedBox(height: 16),
            ],

            // Admin Actions
            if (product.adminVerified != true)
              _buildAdminActions(product, aiScore)
            else
              _buildVerifiedBadge(product),
          ],
        ),
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

  Widget _buildAdminActions(Product product, int aiScore) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _approveWithAIScore(product, aiScore),
            icon: const Icon(Icons.check_circle),
            label: const Text('ใช้คะแนน AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _approveWithSellerScore(product),
            icon: const Icon(Icons.person_outline),
            label: const Text('ใช้คะแนนผู้ขาย'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _showCustomScoreDialog(product),
          icon: const Icon(Icons.edit),
          tooltip: 'กำหนดคะแนนเอง',
          style: IconButton.styleFrom(
            backgroundColor: Colors.orange[100],
            foregroundColor: Colors.orange[800],
          ),
        ),
      ],
    );
  }

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

  Future<void> _approveWithAIScore(Product product, int aiScore) async {
    final confirmed = await _showConfirmDialog(
      'ใช้คะแนน AI',
      'คุณต้องการใช้คะแนนจาก AI ($aiScore คะแนน) ใช่หรือไม่?',
    );

    if (!confirmed) return;

    try {
      final feedback = await _showFeedbackDialog();
      if (feedback == null) return;

      await _updateProduct(
        product,
        aiScore,
        'ใช้คะแนนจาก AI',
        feedback,
      );

      // Learn from admin feedback
      await _aiService.learnFromAdminFeedback(
        productId: product.id,
        adminApprovedScore: aiScore,
        aiPredictedScore: product.aiEcoScore ?? 0,
        adminComments: [feedback],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อนุมัติคะแนนจาก AI เรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveWithSellerScore(Product product) async {
    final confirmed = await _showConfirmDialog(
      'ใช้คะแนนผู้ขาย',
      'คุณต้องการใช้คะแนนจากผู้ขาย (${product.ecoScore} คะแนน) ใช่หรือไม่?',
    );

    if (!confirmed) return;

    try {
      final feedback = await _showFeedbackDialog();
      if (feedback == null) return;

      await _updateProduct(
        product,
        product.ecoScore,
        'ใช้คะแนนจากผู้ขาย',
        feedback,
      );

      // Learn from admin feedback
      await _aiService.learnFromAdminFeedback(
        productId: product.id,
        adminApprovedScore: product.ecoScore,
        aiPredictedScore: product.aiEcoScore ?? 0,
        adminComments: [feedback],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อนุมัติคะแนนจากผู้ขาย เรียบร้อยแล้ว'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCustomScoreDialog(Product product) async {
    final controller = TextEditingController();
    int? customScore;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('กำหนดคะแนนเอง'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'คะแนนผู้ขาย: ${product.ecoScore}\n'
              'คะแนน AI: ${product.aiEcoScore ?? "N/A"}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'คะแนนที่ต้องการกำหนด (0-100)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                customScore = int.tryParse(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (customScore != null &&
                  customScore! >= 0 &&
                  customScore! <= 100) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาใส่คะแนนระหว่าง 0-100'),
                  ),
                );
              }
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (result == true && customScore != null) {
      final feedback = await _showFeedbackDialog();
      if (feedback == null) return;

      await _updateProduct(
        product,
        customScore!,
        'กำหนดคะแนนเอง',
        feedback,
      );

      // Learn from admin feedback
      await _aiService.learnFromAdminFeedback(
        productId: product.id,
        adminApprovedScore: customScore!,
        aiPredictedScore: product.aiEcoScore ?? 0,
        adminComments: [feedback],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กำหนดคะแนนเรียบร้อยแล้ว'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _showFeedbackDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มความคิดเห็น'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'ความคิดเห็น (ไม่บังคับ)',
            border: OutlineInputBorder(),
            hintText: 'เช่น AI วิเคราะห์ถูกต้อง, ผู้ขายให้ข้อมูลไม่ครบ, ฯลฯ',
          ),
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
    return result ?? '';
  }

  Future<void> _updateProduct(
    Product product,
    int finalScore,
    String decision,
    String feedback,
  ) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(product.id)
        .update({
      'ecoScore': finalScore,
      'adminVerified': true,
      'adminApprovedScore': finalScore,
      'adminFeedback': '$decision${feedback.isNotEmpty ? ": $feedback" : ""}',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _showAIStatistics() async {
    try {
      final stats = await _aiService.getAIAccuracyStats();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.analytics, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('AI Statistics'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  'Total Analyzed',
                  '${stats['totalAnalyzed'] ?? 0}',
                  Icons.assessment,
                ),
                _buildStatRow(
                  'Admin Verified',
                  '${stats['verifiedCount'] ?? 0}',
                  Icons.verified,
                ),
                _buildStatRow(
                  'Accuracy',
                  '${(stats['accuracy'] ?? 0).toStringAsFixed(1)}%',
                  Icons.percent,
                ),
                _buildStatRow(
                  'Avg Score Difference',
                  '${(stats['avgScoreDifference'] ?? 0).toStringAsFixed(1)}',
                  Icons.compare_arrows,
                ),
                const Divider(height: 24),
                Text(
                  'Learning Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (stats['accuracy'] ?? 0) / 100,
                    minHeight: 20,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถโหลดสถิติได้: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} นาทีที่แล้ว';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ชั่วโมงที่แล้ว';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} วันที่แล้ว';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
