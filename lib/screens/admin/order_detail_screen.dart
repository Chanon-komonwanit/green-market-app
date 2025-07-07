// lib/screens/admin/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/utils/constants.dart';
import 'package:green_market/utils/order_utils.dart'; // Import order_utils
import 'package:green_market/screens/image_viewer_screen.dart'; // Import image viewer
import 'package:green_market/services/firebase_service.dart'; // Import firebase service
import 'package:provider/provider.dart'; // For Provider
import 'package:green_market/providers/user_provider.dart'; // For user provider
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching URLs

class OrderDetailScreen extends StatefulWidget {
  final app_order.Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late app_order.Order currentOrder;
  bool isLoading = false;

  // Controllers for shipping info
  final TextEditingController _trackingNumberController =
      TextEditingController();
  final TextEditingController _trackingUrlController = TextEditingController();
  String? _selectedCarrier;
  String? _selectedMethod;

  // List of shipping carriers
  final List<Map<String, String>> _shippingCarriers = [
    {'name': 'Kerry Express', 'code': 'KERRY'},
    {'name': 'J&T Express', 'code': 'JT'},
    {'name': 'Flash Express', 'code': 'FLASH'},
    {'name': 'ไปรษณีย์ไทย', 'code': 'THAILAND_POST'},
    {'name': 'DHL', 'code': 'DHL'},
    {'name': 'FedEx', 'code': 'FEDEX'},
  ];

  // List of shipping methods
  final List<Map<String, String>> _shippingMethods = [
    {'name': 'Standard Delivery', 'code': 'STANDARD'},
    {'name': 'Express Delivery', 'code': 'EXPRESS'},
    {'name': 'Same Day Delivery', 'code': 'SAME_DAY'},
    {'name': 'Cash on Delivery (COD)', 'code': 'COD'},
  ];

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
    _initializeControllers();
  }

  void _initializeControllers() {
    _trackingNumberController.text = currentOrder.trackingNumber ?? '';
    _trackingUrlController.text = currentOrder.trackingUrl ?? '';
    _selectedCarrier = currentOrder.shippingCarrier;
    _selectedMethod = currentOrder.shippingMethod;
  }

  // Auto-generate tracking URL based on carrier and tracking number
  void _generateTrackingUrl() {
    if (_selectedCarrier == null || _trackingNumberController.text.isEmpty) {
      return;
    }

    String baseUrl = '';
    switch (_selectedCarrier) {
      case 'KERRY':
        baseUrl = 'https://th.kerryexpress.com/th/track/?track=';
        break;
      case 'JT':
        baseUrl = 'https://www.jtexpress.co.th/index/query/gzquery.html?bill=';
        break;
      case 'FLASH':
        baseUrl = 'https://www.flashexpress.co.th/tracking/?se=';
        break;
      case 'THAILAND_POST':
        baseUrl = 'https://track.thailandpost.co.th/?trackNumber=';
        break;
      case 'DHL':
        baseUrl = 'https://www.dhl.com/th-en/home/tracking.html?tracking-id=';
        break;
      case 'FEDEX':
        baseUrl = 'https://www.fedex.com/fedextrack/?tracknum=';
        break;
    }

    if (baseUrl.isNotEmpty) {
      _trackingUrlController.text = baseUrl + _trackingNumberController.text;
    }
  }

  Future<void> _updateShippingInfo() async {
    if (_trackingNumberController.text.isEmpty || _selectedCarrier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลการขนส่งให้ครบถ้วน')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      // Update order with shipping info
      final updatedOrder = currentOrder.copyWith(
        trackingNumber: _trackingNumberController.text,
        trackingUrl: _trackingUrlController.text,
        shippingCarrier: _selectedCarrier,
        shippingMethod: _selectedMethod,
        shippedAt: currentOrder.shippedAt ?? Timestamp.now(),
        status: currentOrder.status == 'processing'
            ? 'shipped'
            : currentOrder.status,
      );

      await firebaseService.updateOrder(updatedOrder);

      setState(() {
        currentOrder = updatedOrder;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลการขนส่งสำเร็จ!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิดลิงก์: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final canEditShipping = userProvider.isAdmin || userProvider.isSeller;

    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดคำสั่งซื้อ #${currentOrder.id.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Information Section
            _buildOrderInfoSection(),

            // Shipping Information Section
            _buildShippingInfoSection(canEditShipping),

            // Shipping Address Section
            _buildShippingAddressSection(),

            // Order Items Section
            _buildOrderItemsSection(),

            // Total Section
            _buildTotalSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ข้อมูลคำสั่งซื้อ'),
        _buildInfoRow('หมายเลขคำสั่งซื้อ:', currentOrder.id),
        _buildInfoRow(
            'วันที่สั่งซื้อ:',
            DateFormat('dd MMMM yyyy, HH:mm', 'th_TH')
                .format(currentOrder.orderDate.toDate())),
        _buildInfoRow('สถานะ:', getOrderStatusText(currentOrder.status),
            highlight: true),
        _buildInfoRow(
            'ยอดรวม:', '฿${currentOrder.totalAmount.toStringAsFixed(2)}',
            highlight: true),
        _buildInfoRow(
            'วิธีการชำระเงิน:',
            currentOrder.paymentMethod == 'qr_code'
                ? 'QR Code'
                : 'เก็บเงินปลายทาง'),
        if (currentOrder.paymentSlipUrl != null &&
            currentOrder.paymentSlipUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('สลิปการชำระเงิน:', style: AppTextStyles.bodyBold),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ImageViewerScreen(
                              imageUrl: currentOrder.paymentSlipUrl!,
                              heroTag: 'slip_${currentOrder.id}',
                            )));
                  },
                  child: Image.network(
                    currentOrder.paymentSlipUrl!,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text('ไม่สามารถโหลดรูปสลิปได้'),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShippingInfoSection(bool canEditShipping) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ข้อมูลการจัดส่ง'),

        // Display current shipping info
        if (currentOrder.shippingCarrier != null ||
            currentOrder.trackingNumber != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentOrder.shippingCarrier != null)
                    _buildInfoRow('บริษัทขนส่ง:',
                        _getCarrierName(currentOrder.shippingCarrier!)),
                  if (currentOrder.shippingMethod != null)
                    _buildInfoRow('วิธีการส่ง:',
                        _getMethodName(currentOrder.shippingMethod!)),
                  if (currentOrder.trackingNumber != null)
                    _buildInfoRow(
                        'หมายเลขติดตาม:', currentOrder.trackingNumber!),
                  if (currentOrder.shippedAt != null)
                    _buildInfoRow(
                        'วันที่จัดส่ง:',
                        DateFormat('dd MMMM yyyy, HH:mm', 'th_TH')
                            .format(currentOrder.shippedAt!.toDate())),
                  if (currentOrder.deliveredAt != null)
                    _buildInfoRow(
                        'วันที่ส่งถึง:',
                        DateFormat('dd MMMM yyyy, HH:mm', 'th_TH')
                            .format(currentOrder.deliveredAt!.toDate())),
                  if (currentOrder.trackingUrl != null &&
                      currentOrder.trackingUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _launchURL(context, currentOrder.trackingUrl!),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('ติดตามพัสดุ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Edit shipping info form (only for admin/seller)
        if (canEditShipping)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('จัดการข้อมูลการจัดส่ง',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.primaryDarkGreen,
                      )),
                  const SizedBox(height: 16),

                  // Shipping Carrier Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCarrier,
                    decoration: const InputDecoration(
                      labelText: 'บริษัทขนส่ง',
                      border: OutlineInputBorder(),
                    ),
                    items: _shippingCarriers.map((carrier) {
                      return DropdownMenuItem(
                        value: carrier['code'],
                        child: Text(carrier['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCarrier = value;
                      });
                      _generateTrackingUrl();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Shipping Method Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'วิธีการส่ง',
                      border: OutlineInputBorder(),
                    ),
                    items: _shippingMethods.map((method) {
                      return DropdownMenuItem(
                        value: method['code'],
                        child: Text(method['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tracking Number Input
                  TextFormField(
                    controller: _trackingNumberController,
                    decoration: const InputDecoration(
                      labelText: 'หมายเลขติดตาม',
                      border: OutlineInputBorder(),
                      hintText: 'เช่น TH1234567890',
                    ),
                    onChanged: (value) {
                      _generateTrackingUrl();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tracking URL Input
                  TextFormField(
                    controller: _trackingUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL ติดตาม (สร้างอัตโนมัติ)',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updateShippingInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('บันทึกข้อมูลการจัดส่ง'),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShippingAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ที่อยู่ในการจัดส่ง'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentOrder.fullName, style: AppTextStyles.bodyBold),
                const SizedBox(height: 4),
                Text(currentOrder.addressLine1, style: AppTextStyles.body),
                Text(
                    '${currentOrder.subDistrict}, ${currentOrder.district}, ${currentOrder.province}, ${currentOrder.zipCode}',
                    style: AppTextStyles.body),
                const SizedBox(height: 4),
                Text('โทร: ${currentOrder.phoneNumber}',
                    style: AppTextStyles.body),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOrderItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('รายการสินค้า'),
        ...currentOrder.items.map((item) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: item.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          item.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      )
                    : const Icon(Icons.image_not_supported),
                title: Text(item.productName, style: AppTextStyles.bodyBold),
                subtitle: Text(
                    'จำนวน: ${item.quantity} x ฿${item.pricePerUnit.toStringAsFixed(2)}',
                    style: AppTextStyles.body),
                trailing: Text(
                    '฿${(item.quantity * item.pricePerUnit).toStringAsFixed(2)}',
                    style: AppTextStyles.bodyBold),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Card(
      color: AppColors.veryLightTeal,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ยอดรวมทั้งสิ้น', style: AppTextStyles.bodyBold),
            Text('฿${currentOrder.totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.title.copyWith(
                  color: AppColors.primaryDarkGreen,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getCarrierName(String code) {
    final carrier = _shippingCarriers.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'name': code, 'code': code},
    );
    return carrier['name'] ?? code;
  }

  String _getMethodName(String code) {
    final method = _shippingMethods.firstWhere(
      (m) => m['code'] == code,
      orElse: () => {'name': code, 'code': code},
    );
    return method['name'] ?? code;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: AppTextStyles.subtitle.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDarkGreen,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: highlight
                  ? AppTextStyles.bodyBold.copyWith(
                      color: AppColors.primaryDarkGreen,
                    )
                  : AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
