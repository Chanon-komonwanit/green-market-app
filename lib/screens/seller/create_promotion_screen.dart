// lib/screens/seller/create_promotion_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/shop_customization.dart';
import 'package:green_market/theme/app_colors.dart';

class CreatePromotionScreen extends StatefulWidget {
  final ShopPromotion? editPromotion;

  const CreatePromotionScreen({
    super.key,
    this.editPromotion,
  });

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountCodeController = TextEditingController();
  final _termsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _trackingCodeController = TextEditingController();
  final _campaignNameController = TextEditingController();
  final _targetAudienceController = TextEditingController();

  PromotionType _selectedType = PromotionType.percentDiscount;
  Priority _selectedPriority = Priority.normal;

  // Discount fields
  double? _discountPercent;
  double? _discountAmount;
  double? _minimumPurchase;
  double? _maximumDiscount;

  // Buy X Get Y fields
  int? _buyQuantity;
  int? _getQuantity;

  // Limit fields
  int? _usageLimit;
  int? _usageLimitPerUser;
  int? _maxUsagePerDay;

  // Date and time
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Flash Sale fields
  int? _flashSaleStock;
  double? _originalPrice;
  double? _flashSalePrice;

  // Categories and products
  List<String> _selectedCategories = [];
  List<String> _selectedProducts = [];

  // Settings
  bool _isActive = true;
  bool _isPublic = true;
  String? _iconEmoji;
  String? _backgroundColor;

  @override
  void initState() {
    super.initState();
    if (widget.editPromotion != null) {
      _loadExistingPromotion();
    }
  }

  void _loadExistingPromotion() {
    final promo = widget.editPromotion!;
    _titleController.text = promo.title;
    _descriptionController.text = promo.description;
    _discountCodeController.text = promo.discountCode ?? '';
    _termsController.text = promo.terms ?? '';
    _imageUrlController.text = promo.imageUrl ?? '';

    _selectedType = promo.type;
    _selectedPriority = promo.priority;
    _discountPercent = promo.discountPercent;
    _discountAmount = promo.discountAmount;
    _minimumPurchase = promo.minimumPurchase;
    _maximumDiscount = promo.maximumDiscount;
    _buyQuantity = promo.buyQuantity;
    _getQuantity = promo.getQuantity;
    _usageLimit = promo.usageLimit;
    _usageLimitPerUser = promo.usageLimitPerUser;
    _maxUsagePerDay = promo.maxUsagePerDay;
    _startDate = promo.startDate;
    _endDate = promo.endDate;
    _startTime = promo.startTime;
    _endTime = promo.endTime;
    _flashSaleStock = promo.flashSaleStock;
    _originalPrice = promo.originalPrice;
    _flashSalePrice = promo.flashSalePrice;
    _selectedCategories = promo.applicableCategories ?? [];
    _selectedProducts = promo.applicableProductIds ?? [];
    _isActive = promo.isActive;
    _isPublic = promo.isPublic;
    _iconEmoji = promo.iconEmoji;
    _backgroundColor = promo.backgroundColor;
    _trackingCodeController.text = promo.trackingCode ?? '';
    _campaignNameController.text = promo.campaignName ?? '';
    _targetAudienceController.text = promo.targetAudience ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.editPromotion != null ? 'แก้ไขโปรโมชั่น' : 'สร้างโปรโมชั่น',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _savePromotion,
            child: const Text(
              'บันทึก',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildPromotionTypeSection(),
              const SizedBox(height: 24),
              _buildDiscountDetailsSection(),
              const SizedBox(height: 24),
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              _buildLimitationsSection(),
              const SizedBox(height: 24),
              _buildTrackingSection(),
              const SizedBox(height: 24),
              _buildApplicabilitySection(),
              const SizedBox(height: 24),
              _buildSettingsSection(),
              const SizedBox(height: 24),
              _buildPreviewSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'ข้อมูลพื้นฐาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อโปรโมชั่น *',
                hintText: 'เช่น ลด 20% สำหรับสินค้าเกษตรอินทรีย์',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'กรุณาใส่ชื่อโปรโมชั่น';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด *',
                hintText: 'อธิบายรายละเอียดของโปรโมชั่น',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'กรุณาใส่รายละเอียดโปรโมชั่น';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountCodeController,
              decoration: const InputDecoration(
                labelText: 'รหัสส่วนลด (ไม่บังคับ)',
                hintText: 'เช่น ORGANIC20',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'รูปภาพ URL (ไม่บังคับ)',
                hintText: 'https://example.com/image.jpg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionTypeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'ประเภทโปรโมชั่น',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...PromotionType.values.map((type) => _buildTypeOption(type)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(PromotionType type) {
    String title, description, icon;

    switch (type) {
      case PromotionType.percentDiscount:
        title = 'ส่วนลดเปอร์เซ็นต์';
        description = 'ลดราคาตามเปอร์เซ็นต์ เช่น ลด 20%';
        icon = '📊';
        break;
      case PromotionType.fixedDiscount:
        title = 'ส่วนลดจำนวนคงที่';
        description = 'ลดราคาจำนวนเงินคงที่ เช่น ลด 100 บาท';
        icon = '💰';
        break;
      case PromotionType.freeShipping:
        title = 'ฟรีค่าจัดส่ง';
        description = 'ไม่คิดค่าจัดส่งสำหรับคำสั่งซื้อ';
        icon = '🚚';
        break;
      case PromotionType.buyXGetY:
        title = 'ซื้อ X แถม Y';
        description = 'ซื้อสินค้าจำนวนหนึ่งแล้วได้สินค้าเพิ่ม';
        icon = '🎁';
        break;
      case PromotionType.flashSale:
        title = 'Flash Sale';
        description = 'ลดราคาพิเศษในช่วงเวลาจำกัด';
        icon = '⚡';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedType == type
                  ? AppColors.primary
                  : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _selectedType == type
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedType == type
                            ? AppColors.primary
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedType == type)
                Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountDetailsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'รายละเอียดส่วนลด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._buildDiscountFields(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDiscountFields() {
    switch (_selectedType) {
      case PromotionType.percentDiscount:
        return [
          TextFormField(
            initialValue: _discountPercent?.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'เปอร์เซ็นต์ส่วนลด (%) *',
              hintText: 'เช่น 20',
              border: OutlineInputBorder(),
              suffixText: '%',
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณาใส่เปอร์เซ็นต์ส่วนลด';
              final percent = double.tryParse(value!);
              if (percent == null || percent <= 0 || percent > 100) {
                return 'เปอร์เซ็นต์ต้องอยู่ระหว่าง 1-100';
              }
              return null;
            },
            onChanged: (value) => _discountPercent = double.tryParse(value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _maximumDiscount?.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ส่วนลดสูงสุด (บาท)',
              hintText: 'เช่น 500',
              border: OutlineInputBorder(),
              suffixText: '฿',
            ),
            onChanged: (value) => _maximumDiscount = double.tryParse(value),
          ),
        ];

      case PromotionType.fixedDiscount:
        return [
          TextFormField(
            initialValue: _discountAmount?.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'จำนวนเงินส่วนลด (บาท) *',
              hintText: 'เช่น 100',
              border: OutlineInputBorder(),
              suffixText: '฿',
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณาใส่จำนวนเงินส่วนลด';
              final amount = double.tryParse(value!);
              if (amount == null || amount <= 0) {
                return 'จำนวนเงินต้องมากกว่า 0';
              }
              return null;
            },
            onChanged: (value) => _discountAmount = double.tryParse(value),
          ),
        ];

      case PromotionType.buyXGetY:
        return [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _buyQuantity?.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ซื้อจำนวน *',
                    hintText: '2',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณาใส่จำนวน';
                    final qty = int.tryParse(value!);
                    if (qty == null || qty <= 0) return 'จำนวนต้องมากกว่า 0';
                    return null;
                  },
                  onChanged: (value) => _buyQuantity = int.tryParse(value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _getQuantity?.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'แถมจำนวน *',
                    hintText: '1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณาใส่จำนวน';
                    final qty = int.tryParse(value!);
                    if (qty == null || qty <= 0) return 'จำนวนต้องมากกว่า 0';
                    return null;
                  },
                  onChanged: (value) => _getQuantity = int.tryParse(value),
                ),
              ),
            ],
          ),
        ];

      case PromotionType.flashSale:
        return [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _originalPrice?.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ราคาเดิม (บาท) *',
                    hintText: '1000',
                    border: OutlineInputBorder(),
                    suffixText: '฿',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณาใส่ราคาเดิม';
                    final price = double.tryParse(value!);
                    if (price == null || price <= 0) return 'ราคาต้องมากกว่า 0';
                    return null;
                  },
                  onChanged: (value) => _originalPrice = double.tryParse(value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _flashSalePrice?.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ราคา Flash Sale (บาท) *',
                    hintText: '700',
                    border: OutlineInputBorder(),
                    suffixText: '฿',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'กรุณาใส่ราคา Flash Sale';
                    }
                    final price = double.tryParse(value!);
                    if (price == null || price <= 0) return 'ราคาต้องมากกว่า 0';
                    if (_originalPrice != null && price >= _originalPrice!) {
                      return 'ราคา Flash Sale ต้องน้อยกว่าราคาเดิม';
                    }
                    return null;
                  },
                  onChanged: (value) =>
                      _flashSalePrice = double.tryParse(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _flashSaleStock?.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'จำนวนสต็อก Flash Sale *',
              hintText: 'เช่น 50',
              border: OutlineInputBorder(),
              suffixText: 'ชิ้น',
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณาใส่จำนวนสต็อก';
              final stock = int.tryParse(value!);
              if (stock == null || stock <= 0) return 'จำนวนสต็อกต้องมากกว่า 0';
              return null;
            },
            onChanged: (value) => _flashSaleStock = int.tryParse(value),
          ),
        ];

      case PromotionType.freeShipping:
        return [
          const Text(
            'โปรโมชั่นฟรีค่าจัดส่งไม่ต้องตั้งค่าเพิ่มเติม\nสามารถกำหนดยอดซื้อขั้นต่ำได้ในส่วนวันเวลา',
            style: TextStyle(color: Colors.grey),
          ),
        ];
    }
  }

  Widget _buildDateTimeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'ช่วงเวลาใช้งาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('วันเริ่มต้น',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _startDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                : 'เลือกวันที่',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('วันสิ้นสุด',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'เลือกวันที่',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('เวลาเริ่มต้น',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _startTime != null
                                ? _startTime!.format(context)
                                : 'เลือกเวลา',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('เวลาสิ้นสุด',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _endTime != null
                                ? _endTime!.format(context)
                                : 'เลือกเวลา',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _minimumPurchase?.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ยอดซื้อขั้นต่ำ (บาท)',
                hintText: 'เช่น 500',
                border: OutlineInputBorder(),
                suffixText: '฿',
              ),
              onChanged: (value) => _minimumPurchase = double.tryParse(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitationsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.interests, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'ข้อจำกัดการใช้งาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _usageLimit?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'จำนวนการใช้งานทั้งหมด',
                      hintText: 'เช่น 100 (ไม่ใส่ = ไม่จำกัด)',
                      border: OutlineInputBorder(),
                      suffixText: 'ครั้ง',
                    ),
                    onChanged: (value) => _usageLimit = int.tryParse(value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _usageLimitPerUser?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'จำนวนการใช้งานต่อคน',
                      hintText: 'เช่น 1 (ไม่ใส่ = ไม่จำกัด)',
                      border: OutlineInputBorder(),
                      suffixText: 'ครั้ง',
                    ),
                    onChanged: (value) =>
                        _usageLimitPerUser = int.tryParse(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _maxUsagePerDay?.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'จำนวนการใช้งานสูงสุดต่อวัน',
                hintText: 'เช่น 50 (ไม่ใส่ = ไม่จำกัด)',
                border: OutlineInputBorder(),
                suffixText: 'ครั้ง',
              ),
              onChanged: (value) => _maxUsagePerDay = int.tryParse(value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'ความสำคัญ',
                border: OutlineInputBorder(),
              ),
              items: Priority.values.map((priority) {
                String text;
                switch (priority) {
                  case Priority.low:
                    text = 'ต่ำ';
                    break;
                  case Priority.normal:
                    text = 'ปกติ';
                    break;
                  case Priority.high:
                    text = 'สูง';
                    break;
                  case Priority.urgent:
                    text = 'เร่งด่วน';
                    break;
                }
                return DropdownMenuItem(
                  value: priority,
                  child: Text(text),
                );
              }).toList(),
              onChanged: (priority) =>
                  setState(() => _selectedPriority = priority!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'ระบบติดตามและแคมเปญ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _trackingCodeController,
              decoration: const InputDecoration(
                labelText: 'โค้ดติดตาม (ไม่บังคับ)',
                hintText: 'เช่น TRACK2024001',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.track_changes),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (value.length < 5 || value.length > 50) {
                    return 'โค้ดติดตามต้องมี 5-50 ตัวอักษร';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _campaignNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อแคมเปญ (ไม่บังคับ)',
                hintText: 'เช่น แคมเปญสินค้าเกษตรอินทรีย์',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.campaign),
              ),
              validator: (value) {
                if (value != null && value.length > 100) {
                  return 'ชื่อแคมเปญต้องไม่เกิน 100 ตัวอักษร';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetAudienceController,
              decoration: const InputDecoration(
                labelText: 'กลุ่มเป้าหมาย (ไม่บังคับ)',
                hintText: 'เช่น ลูกค้าใหม่, ลูกค้า VIP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicabilitySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'สินค้าที่ใช้ได้',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'เลือกหมวดหมู่สินค้าที่ใช้โปรโมชั่นได้:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'ผักสด',
                'ผลไม้',
                'ข้าวโพด',
                'มะเขือเทศ',
                'สมุนไพร',
                'เครื่องเทศ',
                'ข้าว',
                'น้ำผึ้ง',
                'ไข่',
                'นม'
              ]
                  .map((category) => FilterChip(
                        label: Text(category),
                        selected: _selectedCategories.contains(category),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _termsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'เงื่อนไขการใช้งาน',
                hintText: 'ระบุเงื่อนไขเพิ่มเติม (ถ้ามี)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'การตั้งค่า',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('เปิดใช้งานโปรโมชั่น'),
              subtitle: const Text('เปิด/ปิดการใช้งานโปรโมชั่น'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeColor: AppColors.primary,
            ),
            SwitchListTile(
              title: const Text('เปิดให้ใช้งานทั่วไป'),
              subtitle:
                  const Text('ลูกค้าสามารถใช้โปรโมชั่นได้โดยไม่ต้องใส่โค้ด'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _iconEmoji,
                    decoration: const InputDecoration(
                      labelText: 'ไอคอน Emoji',
                      hintText: '🎉',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _iconEmoji = value,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _backgroundColor,
                    decoration: const InputDecoration(
                      labelText: 'สีพื้นหลัง',
                      hintText: '#FF5722',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _backgroundColor = value,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'ตัวอย่างโปรโมชั่น',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPromotionPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionPreview() {
    final backgroundColor = _backgroundColor != null
        ? Color(int.parse(_backgroundColor!.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_iconEmoji != null) ...[
                Text(_iconEmoji!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  _titleController.text.isNotEmpty
                      ? _titleController.text
                      : 'ชื่อโปรโมชั่น',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getDiscountText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : 'รายละเอียดโปรโมชั่น',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (_getConditionText().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _getConditionText(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          if (!_isActive) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ปิดใช้งาน',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDiscountText() {
    switch (_selectedType) {
      case PromotionType.percentDiscount:
        return '${_discountPercent?.toInt() ?? 0}% OFF';
      case PromotionType.fixedDiscount:
        return '฿${_discountAmount?.toInt() ?? 0} OFF';
      case PromotionType.freeShipping:
        return 'FREE SHIP';
      case PromotionType.buyXGetY:
        return 'ซื้อ ${_buyQuantity ?? 0} แถม ${_getQuantity ?? 0}';
      case PromotionType.flashSale:
        return 'FLASH SALE';
    }
  }

  String _getConditionText() {
    List<String> conditions = [];

    if (_minimumPurchase != null && _minimumPurchase! > 0) {
      conditions.add('ซื้อขั้นต่ำ ฿${_minimumPurchase!.toInt()}');
    }

    if (_usageLimit != null) {
      conditions.add('จำกัด $_usageLimit ครั้ง');
    }

    if (_startDate != null || _endDate != null) {
      conditions.add('มีเงื่อนไขเวลา');
    }

    return conditions.join(' • ');
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  void _savePromotion() {
    if (_formKey.currentState?.validate() ?? false) {
      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId == null) return;

      final promotion = ShopPromotion(
        id: widget.editPromotion?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        sellerId: sellerId,
        createdAt: widget.editPromotion?.createdAt ?? DateTime.now(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        discountCode: _discountCodeController.text.trim().isEmpty
            ? null
            : _discountCodeController.text.trim(),
        discountPercent: _discountPercent,
        discountAmount: _discountAmount,
        minimumPurchase: _minimumPurchase,
        maximumDiscount: _maximumDiscount,
        buyQuantity: _buyQuantity,
        getQuantity: _getQuantity,
        applicableProductIds:
            _selectedProducts.isEmpty ? null : _selectedProducts,
        applicableCategories:
            _selectedCategories.isEmpty ? null : _selectedCategories,
        usageLimit: _usageLimit,
        usageLimitPerUser: _usageLimitPerUser,
        maxUsagePerDay: _maxUsagePerDay,
        startDate: _startDate,
        endDate: _endDate,
        startTime: _startTime,
        endTime: _endTime,
        // Flash Sale fields
        flashSaleStock: _flashSaleStock,
        originalPrice: _originalPrice,
        flashSalePrice: _flashSalePrice,
        // Tracking fields
        trackingCode: _trackingCodeController.text.trim().isEmpty
            ? null
            : _trackingCodeController.text.trim(),
        campaignName: _campaignNameController.text.trim().isEmpty
            ? null
            : _campaignNameController.text.trim(),
        targetAudience: _targetAudienceController.text.trim().isEmpty
            ? null
            : _targetAudienceController.text.trim(),
        isActive: _isActive,
        isPublic: _isPublic,
        iconEmoji: _iconEmoji?.isEmpty ?? true ? null : _iconEmoji,
        backgroundColor:
            _backgroundColor?.isEmpty ?? true ? null : _backgroundColor,
        terms: _termsController.text.trim().isEmpty
            ? null
            : _termsController.text.trim(),
        priority: _selectedPriority,
      );

      // Validate promotion
      final error = promotion.validate();
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // TODO: Save to Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกโปรโมชั่นสำเร็จ!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, promotion);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountCodeController.dispose();
    _termsController.dispose();
    _imageUrlController.dispose();
    _trackingCodeController.dispose();
    _campaignNameController.dispose();
    _targetAudienceController.dispose();
    super.dispose();
  }
}
