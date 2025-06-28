// d:/Development/green_market/lib/screens/checkout_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/providers/cart_provider.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/models/order_item.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/screens/order_confirmation_screen.dart';
import 'package:green_market/screens/payment_confirmation_screen.dart';

class CheckoutSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> shippingAddress;
  const CheckoutSummaryScreen({super.key, required this.shippingAddress});

  @override
  State<CheckoutSummaryScreen> createState() => _CheckoutSummaryScreenState();
}

class _CheckoutSummaryScreenState extends State<CheckoutSummaryScreen> {
  static const double _defaultShippingFee = 50.00;

  String? _selectedPaymentMethod;
  bool _isLoading = false;
  String? _qrCodeImageUrl;

  void _onPaymentMethodChanged(String? value) async {
    setState(() {
      _selectedPaymentMethod = value;
      _qrCodeImageUrl = null;
    });

    if (value == 'qr_code') {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      try {
        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        // final cartProvider = Provider.of<CartProvider>(context, listen: false);
        // final double totalAmount =
        //     cartProvider.totalAmount + _defaultShippingFee;

        final String generatedQrUrl =
            await firebaseService.generateMockQrCode();
        if (mounted) {
          setState(() {
            _qrCodeImageUrl = generatedQrUrl;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('เกิดข้อผิดพลาดในการสร้าง QR Code: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedPaymentMethod == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกวิธีการชำระเงิน')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('ผู้ใช้ไม่ได้เข้าสู่ระบบ');
      }

      final List<OrderItem> orderItems =
          cartProvider.items.values.map((cartItem) {
        return OrderItem(
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          quantity: cartItem.quantity,
          pricePerUnit: cartItem.product.price,
          imageUrl: cartItem.product.imageUrls.isNotEmpty
              ? cartItem.product.imageUrls[0]
              : '',
          ecoScore: cartItem.product.ecoScore,
          sellerId: cartItem.product.sellerId,
        );
      }).toList();

      final Set<String> sellerIdsSet =
          orderItems.map((item) => item.sellerId).toSet();
      final List<String> sellerIds = sellerIdsSet.toList();

      final double subTotal = cartProvider.totalAmount;
      final double totalAmount = subTotal + _defaultShippingFee;

      final newOrder = app_order.Order(
        id: '',
        userId: currentUser.uid,
        orderDate: Timestamp.now(),
        status: _selectedPaymentMethod == 'qr_code'
            ? 'pending_payment'
            : 'pending_delivery',
        paymentMethod: _selectedPaymentMethod!,
        totalAmount: totalAmount,
        shippingFee: _defaultShippingFee,
        subTotal: subTotal,
        fullName: widget.shippingAddress['fullName'],
        phoneNumber: widget.shippingAddress['phoneNumber'],
        addressLine1: widget.shippingAddress['addressLine1'],
        subDistrict: widget.shippingAddress['subDistrict'],
        district: widget.shippingAddress['district'],
        province: widget.shippingAddress['province'],
        zipCode: widget.shippingAddress['zipCode'],
        note: widget.shippingAddress['note'],
        items: orderItems,
        sellerIds: sellerIds,
      );

      await firebaseService.placeOrder(newOrder);

      cartProvider.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สั่งซื้อสำเร็จแล้ว!')),
        );
        if (_selectedPaymentMethod == 'qr_code') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    PaymentConfirmationScreen(order: newOrder)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => OrderConfirmationScreen(order: newOrder)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ข้อผิดพลาดการยืนยันตัวตน: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการสั่งซื้อ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final double subTotal = cartProvider.totalAmount;
    final double totalAmount = subTotal + _defaultShippingFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('สรุปคำสั่งซื้อและชำระเงิน'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สรุปรายการสินค้า (${cartProvider.totalItemsInCart})',
                      style: AppTextStyles.subtitle
                          .copyWith(color: AppColors.primaryGreen)),
                  const SizedBox(height: 12),
                  _CartItemsList(cartProvider: cartProvider),
                  const SizedBox(height: 20),
                  Text('ที่อยู่สำหรับจัดส่ง',
                      style: AppTextStyles.subtitle
                          .copyWith(color: AppColors.primaryGreen)),
                  const SizedBox(height: 8),
                  _ShippingAddressCard(shippingAddress: widget.shippingAddress),
                  const SizedBox(height: 20),
                  Text('วิธีการชำระเงิน',
                      style: AppTextStyles.subtitle
                          .copyWith(color: AppColors.primaryGreen)),
                  const SizedBox(height: 8),
                  _PaymentMethodOptions(
                    selectedPaymentMethod: _selectedPaymentMethod,
                    qrCodeImageUrl: _qrCodeImageUrl,
                    isLoading: _isLoading,
                    onPaymentMethodChanged: _onPaymentMethodChanged,
                    subTotal: subTotal,
                    shippingFee: _defaultShippingFee,
                  ),
                ],
              ),
            ),
          ),
          _OrderTotalsAndConfirm(
            subTotal: subTotal,
            shippingFee: _defaultShippingFee,
            totalAmount: totalAmount,
            isLoading: _isLoading,
            selectedPaymentMethod: _selectedPaymentMethod,
            onPlaceOrder: _placeOrder,
          ),
        ],
      ),
    );
  }
}

class _CartItemsList extends StatelessWidget {
  final CartProvider cartProvider;

  const _CartItemsList({required this.cartProvider});

  @override
  Widget build(BuildContext context) {
    if (cartProvider.items.isEmpty) {
      return const Center(child: Text('ตะกร้าสินค้าของคุณว่างเปล่า'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cartProvider.items.length,
      itemBuilder: (ctx, i) {
        final cartItem = cartProvider.items.values.toList()[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Image.network(
                  cartItem.product.imageUrls.isNotEmpty
                      ? cartItem.product.imageUrls[0]
                      : 'https://via.placeholder.com/50',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: AppColors.lightGrey,
                      child: const Icon(Icons.broken_image,
                          color: AppColors.darkGrey)),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        Text(cartItem.product.name, style: AppTextStyles.body)),
                Text('x${cartItem.quantity}', style: AppTextStyles.body),
                const SizedBox(width: 10),
                Text('฿${cartItem.totalPrice.toStringAsFixed(2)}',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShippingAddressCard extends StatelessWidget {
  final Map<String, dynamic> shippingAddress;

  const _ShippingAddressCard({required this.shippingAddress});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shippingAddress['fullName'],
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            Text(shippingAddress['phoneNumber'], style: AppTextStyles.body),
            Text(
                '${shippingAddress['addressLine1']}${shippingAddress['addressLine2'] != null && shippingAddress['addressLine2'].isNotEmpty ? ', ${shippingAddress['addressLine2']}' : ''}, ${shippingAddress['subDistrict']}, ${shippingAddress['district']}, ${shippingAddress['province']} ${shippingAddress['zipCode']}',
                style: AppTextStyles.body),
            if (shippingAddress['note'] != null &&
                shippingAddress['note'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('หมายเหตุ: ${shippingAddress['note']}',
                    style: AppTextStyles.body
                        .copyWith(fontStyle: FontStyle.italic, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodOptions extends StatelessWidget {
  final String? selectedPaymentMethod;
  final String? qrCodeImageUrl;
  final bool isLoading;
  final void Function(String?) onPaymentMethodChanged;
  final double subTotal;
  final double shippingFee;

  const _PaymentMethodOptions({
    required this.selectedPaymentMethod,
    this.qrCodeImageUrl,
    required this.isLoading,
    required this.onPaymentMethodChanged,
    required this.subTotal,
    required this.shippingFee,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          RadioListTile<String>(
            title: Text('โอนเงินผ่าน PromptPay / QR Code',
                style: AppTextStyles.body),
            subtitle: Text('สแกน QR Code เพื่อชำระเงิน',
                style: AppTextStyles.body
                    .copyWith(fontSize: 12, color: AppColors.darkGrey)),
            value: 'qr_code',
            groupValue: selectedPaymentMethod,
            onChanged: isLoading ? null : onPaymentMethodChanged,
            activeColor: AppColors.primaryGreen,
          ),
          if (selectedPaymentMethod == 'qr_code')
            _QrCodeSection(
              qrCodeImageUrl: qrCodeImageUrl,
              isLoading: isLoading,
              totalAmount: subTotal + shippingFee,
            ),
          RadioListTile<String>(
            title: Text('เก็บเงินปลายทาง (COD)', style: AppTextStyles.body),
            subtitle: Text('ชำระเงินเมื่อได้รับสินค้า',
                style: AppTextStyles.body
                    .copyWith(fontSize: 12, color: AppColors.darkGrey)),
            value: 'cash_on_delivery',
            groupValue: selectedPaymentMethod,
            onChanged: isLoading ? null : onPaymentMethodChanged,
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}

class _QrCodeSection extends StatelessWidget {
  final String? qrCodeImageUrl;
  final bool isLoading;
  final double totalAmount;

  const _QrCodeSection({
    this.qrCodeImageUrl,
    required this.isLoading,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    if (qrCodeImageUrl != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.network(
              qrCodeImageUrl!,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 200,
                height: 200,
                color: AppColors.lightGrey,
                child: const Icon(Icons.qr_code,
                    size: 80, color: AppColors.darkGrey),
              ),
            ),
            const SizedBox(height: 8),
            Text('สแกน QR Code นี้เพื่อชำระเงิน',
                style: AppTextStyles.body.copyWith(color: AppColors.darkGrey)),
            Text('จำนวน: ฿${totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.primaryGreen)),
            const SizedBox(height: 16),
            Text('โปรดชำระเงินภายใน 30 นาที มิฉะนั้นคำสั่งซื้อจะถูกยกเลิก',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.red.shade700)),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _OrderTotalsAndConfirm extends StatelessWidget {
  final double subTotal;
  final double shippingFee;
  final double totalAmount;
  final bool isLoading;
  final String? selectedPaymentMethod;
  final Future<void> Function() onPlaceOrder;

  const _OrderTotalsAndConfirm({
    required this.subTotal,
    required this.shippingFee,
    required this.totalAmount,
    required this.isLoading,
    this.selectedPaymentMethod,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
                color: AppColors.darkGrey.withAlpha((0.1 * 255).round()),
                blurRadius: 4,
                offset: const Offset(0, -2)),
          ],
          border: Border(
              top: BorderSide(
                  color: AppColors.lightGrey.withAlpha((0.5 * 255).round()),
                  width: 1))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ยอดรวมสินค้า:', style: AppTextStyles.body),
              Text('฿${subTotal.toStringAsFixed(2)}',
                  style: AppTextStyles.body),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ค่าจัดส่ง:', style: AppTextStyles.body),
              Text('฿${shippingFee.toStringAsFixed(2)}',
                  style: AppTextStyles.body),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('รวมทั้งสิ้น:',
                  style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold)),
              Text('฿${totalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.price
                      .copyWith(fontSize: 22, color: AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (selectedPaymentMethod == null || isLoading)
                  ? null
                  : onPlaceOrder,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text('ยืนยันคำสั่งซื้อ',
                      style: AppTextStyles.subtitle
                          .copyWith(color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
