// lib/screens/checkout/coupon_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:green_market/providers/coupon_provider.dart';
import 'package:green_market/models/user_coupon.dart';
import 'package:green_market/models/cart_item.dart';
import 'package:green_market/theme/app_colors.dart';

class CouponSelectionScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final UserCoupon? currentCoupon;

  const CouponSelectionScreen({
    super.key,
    required this.cartItems,
    this.currentCoupon,
  });

  @override
  State<CouponSelectionScreen> createState() => _CouponSelectionScreenState();
}

class _CouponSelectionScreenState extends State<CouponSelectionScreen> {
  final TextEditingController _codeController = TextEditingController();
  UserCoupon? _selectedCoupon;

  @override
  void initState() {
    super.initState();
    _selectedCoupon = widget.currentCoupon;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CouponProvider>().loadUserCoupons();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'เลือกโค้ดส่วนลด',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _selectedCoupon != null ? _applyCoupon : null,
            child: Text(
              'ใช้',
              style: TextStyle(
                color: _selectedCoupon != null ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ป้อนโค้ดส่วนลด',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: 'กรอกโค้ดส่วนลด',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_offer),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _searchCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('ค้นหา'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Available coupons
          Expanded(
            child: Consumer<CouponProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final availableCoupons = provider.availableCoupons
                    .where((coupon) => _canUseCoupon(coupon))
                    .toList();

                if (availableCoupons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีโค้ดที่ใช้ได้กับสินค้าในตะกร้า',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableCoupons.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildNoCouponOption();
                    }

                    final coupon = availableCoupons[index - 1];
                    return _buildCouponCard(coupon);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCouponOption() {
    final isSelected = _selectedCoupon == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedCoupon = null),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : Colors.grey[400],
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'ไม่ใช้โค้ดส่วนลด',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponCard(UserCoupon coupon) {
    final promotion = coupon.promotion;
    final isSelected = _selectedCoupon?.id == coupon.id;
    final calculation =
        context.read<CouponProvider>().calculateDiscount(widget.cartItems);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedCoupon = coupon),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Left side - discount info
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[400],
                          ),
                          const SizedBox(width: 12),
                          if (promotion.iconEmoji != null) ...[
                            Text(
                              promotion.iconEmoji!,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              promotion.discountText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promotion.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promotion.conditionText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (calculation != null && calculation.hasDiscount) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ประหยัด ฿${calculation.discountAmount.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (promotion.endDate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'หมดอายุ ${_formatDate(promotion.endDate!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Right side - code
              if (promotion.discountCode != null)
                Container(
                  width: 80,
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      promotion.discountCode!,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _searchCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final provider = context.read<CouponProvider>();
    final coupon = await provider.findCouponByCode(code);

    if (coupon != null && _canUseCoupon(coupon)) {
      setState(() => _selectedCoupon = coupon);
      _codeController.clear();
      _showMessage('พบโค้ดส่วนลด!', isError: false);
    } else {
      _showMessage('ไม่พบโค้ดหรือไม่สามารถใช้กับสินค้าในตะกร้าได้');
    }
  }

  void _applyCoupon() {
    final provider = context.read<CouponProvider>();

    if (_selectedCoupon != null) {
      provider.applyCoupon(_selectedCoupon!);
    } else {
      provider.removeCoupon();
    }

    Navigator.pop(context, _selectedCoupon);
  }

  bool _canUseCoupon(UserCoupon coupon) {
    if (!coupon.isUsable) return false;

    final promotion = coupon.promotion;
    final subtotal =
        widget.cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

    // ตรวจสอบยอดขั้นต่ำ
    if (promotion.minimumPurchase != null &&
        subtotal < promotion.minimumPurchase!) {
      return false;
    }

    // TODO: ตรวจสอบสินค้าที่ใช้ได้
    // if (promotion.applicableProductIds != null) {
    //   // ตรวจสอบว่ามีสินค้าที่ใช้ได้หรือไม่
    // }

    return true;
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}
