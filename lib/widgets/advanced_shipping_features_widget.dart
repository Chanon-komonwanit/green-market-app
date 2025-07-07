// lib/widgets/advanced_shipping_features_widget.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/order.dart' as app_order;
import 'package:green_market/services/shipping/shipping_service_manager.dart';
import 'package:green_market/services/shipping/shipping_notification_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';

class AdvancedShippingFeaturesWidget extends StatefulWidget {
  final app_order.Order order;
  final VoidCallback onUpdated;

  const AdvancedShippingFeaturesWidget({
    super.key,
    required this.order,
    required this.onUpdated,
  });

  @override
  State<AdvancedShippingFeaturesWidget> createState() =>
      _AdvancedShippingFeaturesWidgetState();
}

class _AdvancedShippingFeaturesWidgetState
    extends State<AdvancedShippingFeaturesWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ฟีเจอร์ขั้นสูง',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            _buildQuickActionsSection(),
            const SizedBox(height: 16),

            // Shipping Templates
            _buildShippingTemplatesSection(),
            const SizedBox(height: 16),

            // Batch Operations
            _buildBatchOperationsSection(),
            const SizedBox(height: 16),

            // Smart Suggestions
            _buildSmartSuggestionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'การดำเนินการด่วน',
          style: AppTextStyles.bodyBold,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickActionChip(
              label: 'ส่ง SMS แจ้งลูกค้า',
              icon: Icons.sms,
              onTap: () => _sendSMSNotification(),
            ),
            _buildQuickActionChip(
              label: 'พิมพ์ใบปะหน้า',
              icon: Icons.print,
              onTap: () => _printShippingLabel(),
            ),
            _buildQuickActionChip(
              label: 'สร้าง QR Code',
              icon: Icons.qr_code,
              onTap: () => _generateQRCode(),
            ),
            _buildQuickActionChip(
              label: 'ส่งอีเมล',
              icon: Icons.email,
              onTap: () => _sendEmailNotification(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShippingTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เทมเพลตการจัดส่ง',
          style: AppTextStyles.bodyBold,
        ),
        const SizedBox(height: 8),
        _buildTemplateOption(
          'เทมเพลตสินค้าทั่วไป',
          'Kerry Express, Standard, 3-5 วัน',
          Icons.local_shipping,
          () => _applyTemplate('general'),
        ),
        _buildTemplateOption(
          'เทมเพลตสินค้าด่วน',
          'J&T Express, Express, 1-2 วัน',
          Icons.speed,
          () => _applyTemplate('express'),
        ),
        _buildTemplateOption(
          'เทมเพลตสินค้าแตกง่าย',
          'ไปรษณีย์ไทย, Special Care, 5-7 วัน',
          Icons.warning,
          () => _applyTemplate('fragile'),
        ),
      ],
    );
  }

  Widget _buildBatchOperationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'การดำเนินการหลายรายการ',
          style: AppTextStyles.bodyBold,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _bulkUpdateStatus(),
                icon: const Icon(Icons.update),
                label: const Text('อัพเดทสถานะ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _bulkPrintLabels(),
                icon: const Icon(Icons.print),
                label: const Text('พิมพ์ใบปะหน้า'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmartSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'คำแนะนำอัจฉริยะ',
          style: AppTextStyles.bodyBold,
        ),
        const SizedBox(height: 8),
        _buildSuggestionCard(
          'แนะนำการจัดส่ง',
          'ลูกค้าในกรุงเทพฯ - ควรใช้ J&T Express เพื่อการส่งที่เร็วขึ้น',
          Icons.lightbulb,
          AppColors.warningOrange,
        ),
        _buildSuggestionCard(
          'ประหยัดค่าใช้จ่าย',
          'รวมพัสดุหลายรายการในพื้นที่เดียวกันเพื่อลดค่าขนส่ง',
          Icons.savings,
          AppColors.primaryGreen,
        ),
        _buildSuggestionCard(
          'ปรับปรุงบริการ',
          'อัพเดทหมายเลขติดตามเพื่อเพิ่มความพึงพอใจของลูกค้า',
          Icons.trending_up,
          AppColors.primaryTeal,
        ),
      ],
    );
  }

  Widget _buildQuickActionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primaryTeal),
      label: Text(label, style: AppTextStyles.bodySmall),
      onPressed: _isLoading ? null : onTap,
      backgroundColor: AppColors.veryLightTeal,
      side: BorderSide(color: AppColors.primaryTeal, width: 1),
    );
  }

  Widget _buildTemplateOption(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightModernGrey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyBold),
                  Text(description, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyBold.copyWith(color: color)),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              // Hide suggestion
            },
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _sendSMSNotification() async {
    setState(() => _isLoading = true);
    try {
      // Simulate SMS sending
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่ง SMS แจ้งลูกค้าเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printShippingLabel() async {
    setState(() => _isLoading = true);
    try {
      // Simulate printing
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เตรียมไฟล์ใบปะหน้าเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateQRCode() async {
    setState(() => _isLoading = true);
    try {
      // Simulate QR code generation
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้าง QR Code เรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendEmailNotification() async {
    setState(() => _isLoading = true);
    try {
      // Simulate email sending
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งอีเมลแจ้งลูกค้าเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyTemplate(String templateType) async {
    setState(() => _isLoading = true);
    try {
      // Simulate template application
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ใช้เทมเพลตเรียบร้อยแล้ว')),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _bulkUpdateStatus() async {
    setState(() => _isLoading = true);
    try {
      // Simulate bulk update
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัพเดทสถานะหลายรายการเรียบร้อยแล้ว')),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _bulkPrintLabels() async {
    setState(() => _isLoading = true);
    try {
      // Simulate bulk printing
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('เตรียมไฟล์ใบปะหน้าหลายรายการเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
