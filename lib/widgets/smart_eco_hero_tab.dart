// lib/widgets/smart_eco_hero_tab.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/smart_product_analytics_service.dart';
import '../widgets/product_card.dart';
import '../screens/product_detail_screen.dart';
import '../utils/constants.dart';

/// Smart Eco Hero Tab - แท็บแสดงสินค้า Eco Hero อัจฉริยะ
/// ใช้ AI-like algorithm เพื่อเลือกสินค้าที่ดีที่สุด 8 รายการ
class SmartEcoHeroTab extends StatefulWidget {
  const SmartEcoHeroTab({super.key});

  @override
  State<SmartEcoHeroTab> createState() => _SmartEcoHeroTabState();
}

class _SmartEcoHeroTabState extends State<SmartEcoHeroTab> {
  final SmartProductAnalyticsService _analyticsService =
      SmartProductAnalyticsService();

  List<Product> _ecoHeroProducts = [];
  Map<String, dynamic> _analyticsSummary = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSmartEcoHeroProducts();
  }

  Future<void> _loadSmartEcoHeroProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // โหลดสินค้า Eco Hero อัจฉริยะ (รุ่นปรับปรุง)
      final products =
          await _analyticsService.getSmartEcoHeroProductsEnhanced();
      final summary = await _analyticsService.getAnalyticsSummary();

      setState(() {
        _ecoHeroProducts = products;
        _analyticsSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadSmartEcoHeroProducts,
        color: const Color(0xFF2E7D32),
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: _buildSmartHeader(),
            ),

            // Products Grid
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                    ),
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverToBoxAdapter(
                child: _buildErrorWidget(),
              )
            else if (_ecoHeroProducts.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = _ecoHeroProducts[index];
                      return _buildSmartProductCard(product, index + 1);
                    },
                    childCount: _ecoHeroProducts.length,
                  ),
                ),
              ),

            // Footer with Analytics Summary
            SliverToBoxAdapter(
              child: _buildAnalyticsSummary(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Eco Hero',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'สินค้าคัดสรรโดย AI อัจฉริยะ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.psychology, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ระบบวิเคราะห์อัจฉริยะ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'คัดเลือกจาก ${_analyticsSummary['totalProducts'] ?? 0} สินค้า โดยวิเคราะห์ระดับ Eco Score, คะแนนรีวิว, ยอดขาย และความนิยม',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartProductCard(Product product, int rank) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank Badge & Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Product Image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: product.imageUrls.isNotEmpty
                          ? Image.network(
                              product.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported,
                                      size: 40),
                            )
                          : const Icon(Icons.image_not_supported, size: 40),
                    ),
                  ),

                  // Rank Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: _getRankGradient(rank),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRankIcon(rank),
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '#$rank',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Eco Level Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getEcoLevelColor(product.ecoScore),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getEcoLevelText(product.ecoScore),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      '฿${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),

                    // Eco Score & Rating
                    Row(
                      children: [
                        Icon(
                          Icons.eco,
                          size: 14,
                          color: _getEcoLevelColor(product.ecoScore),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.ecoScore}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          '4.5',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)]);
      case 2:
        return const LinearGradient(
            colors: [Color(0xFFC0C0C0), Color(0xFF808080)]);
      case 3:
        return const LinearGradient(
            colors: [Color(0xFFCD7F32), Color(0xFF8B4513)]);
      default:
        return const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)]);
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.workspace_premium;
      default:
        return Icons.star;
    }
  }

  Color _getEcoLevelColor(int ecoScore) {
    if (ecoScore >= 80) return const Color(0xFF1B5E20);
    if (ecoScore >= 60) return const Color(0xFF2E7D32);
    if (ecoScore >= 40) return const Color(0xFF43A047);
    if (ecoScore >= 20) return const Color(0xFF66BB6A);
    return const Color(0xFF81C784);
  }

  String _getEcoLevelText(int ecoScore) {
    if (ecoScore >= 80) return 'LEGEND';
    if (ecoScore >= 60) return 'HERO';
    if (ecoScore >= 40) return 'PREMIUM';
    if (ecoScore >= 20) return 'STANDARD';
    return 'BASIC';
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'เกิดข้อผิดพลาด',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'ไม่สามารถโหลดข้อมูลได้',
            style: TextStyle(color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadSmartEcoHeroProducts,
            icon: const Icon(Icons.refresh),
            label: const Text('ลองใหม่'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีสินค้า Eco Hero',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'รอสักครู่ เราจะเพิ่มสินค้าคุณภาพสูงให้เร็วๆ นี้',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    if (_analyticsSummary.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'สรุปการวิเคราะห์',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'วิเคราะห์จากสินค้า ${_analyticsSummary['totalProducts']} รายการ • คะแนนเฉลี่ย ${(_analyticsSummary['averageScore'] * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
