// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/providers/cart_provider_enhanced.dart';
import 'package:green_market/providers/coupon_provider.dart';
import 'package:green_market/screens/shipping_address_screen.dart';
import 'package:green_market/screens/checkout/coupon_selection_screen.dart';
import 'package:green_market/models/user_coupon.dart';
import 'package:green_market/models/cart_item.dart' as models;
import 'package:green_market/theme/app_colors.dart' as theme;
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  final bool navigateToCheckout;

  const CartScreen({super.key, this.navigateToCheckout = false});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessingCheckout = false; // State for checkout button loading

  @override
  void initState() {
    super.initState();
    // Using addPostFrameCallback to ensure that the build method has completed
    // and context is fully available for navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.navigateToCheckout) {
        final cart = Provider.of<CartProviderEnhanced>(context, listen: false);
        if (cart.items.isNotEmpty) {
          // Navigate to ShippingAddressScreen or directly to a simplified CheckoutScreen
          // if address is already known or handled differently for "Buy Now".
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const ShippingAddressScreen(),
          ));
        }
      }
    });
  }

  void _handleCheckoutPressed(
      BuildContext context, CartProviderEnhanced cart) async {
    if (cart.totalAmount <= 0) {
      // Prevent checkout if cart is empty or total is zero
      return;
    }
    if (!mounted) return;
    setState(() {
      _isProcessingCheckout = true;
    });

    // Simulate network call or processing
    // await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    // Navigate to ShippingAddressScreen
    // Note: Consider how to handle the _isProcessingCheckout state if the user navigates back.
    // For now, we'll reset it when the new screen is pushed.
    // If the push is successful and this screen is still in the widget tree (e.g. not replaced),
    // you might want to reset _isProcessingCheckout in a .then() or after await.
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ShippingAddressScreen()));

    if (mounted) {
      // Reset loading state when navigation is done (e.g., user comes back)
      setState(() {
        _isProcessingCheckout = false;
      });
    }
  }

  Widget _buildCouponSection(BuildContext context,
      CouponProvider couponProvider, CartProviderEnhanced cart) {
    final appliedCoupon = couponProvider.appliedCoupon;
    final cartItemsConverted = _convertCartItems(cart.items.values.toList());
    final calculation = appliedCoupon != null
        ? couponProvider.calculateDiscount(cartItemsConverted)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _selectCoupon(context, cart),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.local_offer,
                color: appliedCoupon != null
                    ? theme.AppColors.primary
                    : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: appliedCoupon != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appliedCoupon.promotion.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (calculation != null && calculation.hasDiscount)
                            Text(
                              'ประหยัด ฿${calculation.discountAmount.toInt()}',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      )
                    : const Text(
                        'เลือกโค้ดส่วนลด',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (appliedCoupon != null) ...[
                    Text(
                      appliedCoupon.promotion.discountCode ?? '',
                      style: TextStyle(
                        color: theme.AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<models.CartItem> _convertCartItems(List<CartItem> providerCartItems) {
    return providerCartItems
        .map((item) => models.CartItem(
              id: item.product.id,
              productId: item.product.id,
              name: item.product.name,
              imageUrl: item.product.imageUrls.isNotEmpty
                  ? item.product.imageUrls.first
                  : '',
              price: item.product.price,
              quantity: item.quantity,
              sellerId: item.product.sellerId,
            ))
        .toList();
  }

  Future<void> _selectCoupon(
      BuildContext context, CartProviderEnhanced cart) async {
    final cartItems = _convertCartItems(cart.items.values.toList());
    final couponProvider = context.read<CouponProvider>();

    await Navigator.push<UserCoupon?>(
      context,
      MaterialPageRoute(
        builder: (context) => CouponSelectionScreen(
          cartItems: cartItems,
          currentCoupon: couponProvider.appliedCoupon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตะกร้าสินค้า'),
      ),
      body: Consumer<CartProviderEnhanced>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return const _EmptyCartView();
          }
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) {
                    final cartItemKey = cart.items.keys.toList()[i];
                    final cartItem = cart.items.values.toList()[i];
                    return Dismissible(
                      key: ValueKey(cartItemKey),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.errorRed,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(
                            vertical: 6.0, horizontal: 8.0),
                        child: const Icon(Icons.delete,
                            color: AppColors.white, size: 30),
                      ),
                      confirmDismiss: (direction) {
                        return showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('ยืนยันการลบ'),
                            content: Text(
                                'คุณต้องการลบ "${cartItem.product.name}" ออกจากตะกร้าหรือไม่?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('ยกเลิก',
                                    style:
                                        TextStyle(color: AppColors.modernGrey)),
                                onPressed: () {
                                  Navigator.of(ctx).pop(false);
                                },
                              ),
                              TextButton(
                                child: const Text('ลบ',
                                    style:
                                        TextStyle(color: AppColors.errorRed)),
                                onPressed: () {
                                  Navigator.of(ctx).pop(true);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        cart.removeItem(cartItemKey);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${cartItem.product.name} ถูกลบออกจากตะกร้าแล้ว'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: _CartItemTile(cartItem: cartItem, cart: cart),
                    );
                  },
                ),
              ),
              // const Divider(height: 1, thickness: 1, color: AppColors.lightModernGrey), // Divider is now part of the Container below
              Consumer<CouponProvider>(
                builder: (context, couponProvider, child) {
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border(
                        top: BorderSide(
                            color: AppColors.lightModernGrey, width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.modernGrey.withOpacity(0.15),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Coupon section
                        _buildCouponSection(context, couponProvider, cart),
                        const SizedBox(height: 16),
                        // Cart summary
                        _CartSummary(
                          cart: cart,
                          couponProvider: couponProvider,
                          isProcessing: _isProcessingCheckout,
                          onCheckoutPressed: () {
                            _handleCheckoutPressed(context, cart);
                          },
                        ),
                      ],
                    ),
                  );
                },
              )
            ],
          );
        },
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.local_florist_outlined,
            // ignore: deprecated_member_use
            size: 80,
            // ignore: deprecated_member_use
            color: AppColors.primaryGreen.withOpacity(0.6)),
        const SizedBox(height: 20),
        Text('ตะกร้าสินค้าของคุณยังว่างอยู่',
            style: AppTextStyles.title
                .copyWith(color: AppColors.primaryDarkGreen)),
        const SizedBox(height: 10),
        Text('มาเลือกซื้อสินค้า Green Market คุณภาพดีกัน!',
            style:
                AppTextStyles.body.copyWith(color: AppColors.modernDarkGrey)),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          icon: const Icon(Icons.explore_outlined),
          label: const Text('เลือกดูสินค้า'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            textStyle: AppTextStyles.button,
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Go back to previous screen
          },
        )
      ],
    ));
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem cartItem;
  final CartProviderEnhanced cart;

  const _CartItemTile({required this.cartItem, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                cartItem.product.imageUrls.isNotEmpty
                    ? cartItem.product.imageUrls[0]
                    : 'https://via.placeholder.com/80', // Consider making this a constant
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: AppColors.lightGrey,
                    child: const Icon(Icons.eco_outlined,
                        color: AppColors.primaryGreen, size: 40),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(cartItem.product.name,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('฿${cartItem.product.price.toStringAsFixed(2)}',
                      style: AppTextStyles.price.copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.primaryGreen, size: 22),
                        onPressed: () {
                          cart.updateItemQuantity(
                              cartItem.product.id, cartItem.quantity - 1);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Text('${cartItem.quantity}',
                          style: AppTextStyles.body.copyWith(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppColors.primaryGreen, size: 22),
                        onPressed: () {
                          cart.updateItemQuantity(
                              cartItem.product.id, cartItem.quantity + 1);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  )
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
              onPressed: () {
                // This IconButton is now mainly for visual consistency if Dismissible fails or is not used.
                // The primary removal mechanism is Dismissible.
                // However, keeping its logic can be a fallback or for non-swipe actions if needed.
                cart.removeItem(cartItem.product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('${cartItem.product.name} ถูกลบออกจากตะกร้าแล้ว'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartProviderEnhanced cart;
  final CouponProvider couponProvider;
  final bool isProcessing;
  final VoidCallback onCheckoutPressed;

  const _CartSummary({
    required this.cart,
    required this.couponProvider,
    required this.isProcessing,
    required this.onCheckoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    final appliedCoupon = couponProvider.appliedCoupon;
    final cartItemsConverted = _convertCartItems(cart.items.values.toList());
    final calculation = appliedCoupon != null
        ? couponProvider.calculateDiscount(cartItemsConverted)
        : null;

    final subtotal = cart.totalAmount;
    final discount = calculation?.discountAmount ?? 0.0;
    final total = subtotal - discount;

    return Column(
      children: [
        // Subtotal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ยอดรวม (${cart.totalItemsInCart} ชิ้น)',
              style: AppTextStyles.body,
            ),
            Text(
              '฿${subtotal.toStringAsFixed(2)}',
              style: AppTextStyles.body,
            ),
          ],
        ),

        // Discount
        if (discount > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ส่วนลด',
                style: AppTextStyles.body.copyWith(color: Colors.green[600]),
              ),
              Text(
                '-฿${discount.toStringAsFixed(2)}',
                style: AppTextStyles.body.copyWith(
                  color: Colors.green[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],

        const Divider(height: 16, thickness: 1),

        // Total and checkout button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ยอดที่ต้องชำระ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '฿${total.toStringAsFixed(2)}',
                  style: AppTextStyles.price.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.payment_rounded, size: 18),
              label: isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Text('ดำเนินการชำระเงิน'),
              onPressed: isProcessing || total <= 0 ? null : onCheckoutPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: AppTextStyles.button,
                disabledBackgroundColor: AppColors.lightGrey,
                disabledForegroundColor: AppColors.modernGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<models.CartItem> _convertCartItems(List<CartItem> providerCartItems) {
    return providerCartItems
        .map((item) => models.CartItem(
              id: item.product.id,
              productId: item.product.id,
              name: item.product.name,
              imageUrl: item.product.imageUrls.isNotEmpty
                  ? item.product.imageUrls.first
                  : '',
              price: item.product.price,
              quantity: item.quantity,
              sellerId: item.product.sellerId,
            ))
        .toList();
  }
}
