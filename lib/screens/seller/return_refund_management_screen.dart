// lib/screens/seller/return_refund_management_screen.dart
// Return & Refund Management Screen - จัดการคำขอคืนสินค้า/เงิน

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_market/models/return_request.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class ReturnRefundManagementScreen extends StatefulWidget {
  const ReturnRefundManagementScreen({super.key});

  @override
  State<ReturnRefundManagementScreen> createState() =>
      _ReturnRefundManagementScreenState();
}

class _ReturnRefundManagementScreenState
    extends State<ReturnRefundManagementScreen>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  final _logger = Logger();

  late TabController _tabController;
  bool _isLoading = true;
  List<ReturnRequest> _allRequests = [];
  String? _sellerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (_sellerId != null) {
      _loadReturnRequests();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReturnRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await _firebaseService.getSellerReturnRequests(_sellerId!);
      _allRequests = data.map((d) => ReturnRequest.fromMap(d)).toList();
    } catch (e) {
      _logger.e('Error loading return requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ReturnRequest> _getFilteredRequests(ReturnRequestStatus? status) {
    if (status == null) return _allRequests;
    return _allRequests.where((r) => r.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ReturnRequestStats.fromRequests(_allRequests);

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการคำขอคืนสินค้า/เงิน'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'รอตรวจสอบ (${stats.pendingCount})'),
            Tab(text: 'อนุมัติแล้ว (${stats.approvedCount})'),
            Tab(text: 'คืนเงินแล้ว (${stats.refundedCount})'),
            Tab(text: 'ทั้งหมด (${stats.totalRequests})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsBar(stats),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestsList(ReturnRequestStatus.pending),
                      _buildRequestsList(ReturnRequestStatus.approved),
                      _buildRequestsList(ReturnRequestStatus.refunded),
                      _buildRequestsList(null), // All
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsBar(ReturnRequestStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'รอตรวจสอบ',
              '${stats.pendingCount}',
              Icons.pending_actions,
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'คืนเงินแล้ว',
              '฿${_formatNumber(stats.totalRefundAmount)}',
              Icons.account_balance_wallet,
              AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(ReturnRequestStatus? status) {
    final requests = _getFilteredRequests(status);

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_return, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              status == null ? 'ยังไม่มีคำขอคืนสินค้า' : 'ไม่มีคำขอในสถานะนี้',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReturnRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(requests[index]);
        },
      ),
    );
  }

  Widget _buildRequestCard(ReturnRequest request) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'th');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  if (request.productImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        request.productImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'จำนวน: ${request.quantity} ชิ้น',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(request.statusColor).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      request.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(request.statusColor),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Details
              _buildInfoRow(Icons.label, 'เหตุผล', request.reasonText),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.attach_money, 'จำนวนเงิน',
                  '฿${_formatNumber(request.refundAmount)}'),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.schedule,
                'วันที่ขอ',
                request.createdAt != null
                    ? dateFormat.format(request.createdAt!.toDate())
                    : '-',
              ),

              if (request.reasonDetail != null &&
                  request.reasonDetail!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request.reasonDetail!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action Buttons
              if (request.canSellerReview ||
                  request.canConfirmReceived ||
                  request.canProcessRefund) ...[
                const Divider(height: 24),
                _buildActionButtons(request),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ReturnRequest request) {
    return Row(
      children: [
        if (request.canSellerReview) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _rejectRequest(request),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('ปฏิเสธ'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _approveRequest(request),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('อนุมัติ'),
            ),
          ),
        ],
        if (request.canConfirmReceived)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmReceived(request),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
              icon: const Icon(Icons.inventory, size: 18),
              label: const Text('ยืนยันรับสินค้าแล้ว'),
            ),
          ),
        if (request.canProcessRefund)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _processRefund(request),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              icon: const Icon(Icons.account_balance_wallet, size: 18),
              label: const Text('คืนเงิน'),
            ),
          ),
      ],
    );
  }

  void _showRequestDetails(ReturnRequest request) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'th');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  const Text(
                    'รายละเอียดคำขอ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Product Info
              ListTile(
                leading: request.productImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          request.productImage!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.inventory_2, size: 50),
                title: Text(request.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'จำนวน: ${request.quantity} ชิ้น\nยอดคืน: ฿${_formatNumber(request.refundAmount)}'),
              ),

              const Divider(),

              // Status
              _buildDetailRow('สถานะ', request.statusText,
                  color: Color(request.statusColor)),
              _buildDetailRow('เหตุผล', request.reasonText),
              if (request.reasonDetail != null)
                _buildDetailRow('รายละเอียด', request.reasonDetail!),

              const Divider(),

              // Timeline
              _buildDetailRow(
                  'วันที่ขอ',
                  request.createdAt != null
                      ? dateFormat.format(request.createdAt!.toDate())
                      : '-'),
              if (request.approvedAt != null)
                _buildDetailRow('วันที่อนุมัติ',
                    dateFormat.format(request.approvedAt!.toDate())),
              if (request.refundedAt != null)
                _buildDetailRow('วันที่คืนเงิน',
                    dateFormat.format(request.refundedAt!.toDate())),

              if (request.trackingNumber != null) ...[
                const Divider(),
                _buildDetailRow('เลขพัสดุส่งคืน', request.trackingNumber!),
              ],

              if (request.rejectionReason != null) ...[
                const Divider(),
                _buildDetailRow('เหตุผลที่ปฏิเสธ', request.rejectionReason!,
                    color: Colors.red),
              ],

              if (request.sellerNote != null) ...[
                const Divider(),
                _buildDetailRow('หมายเหตุจากผู้ขาย', request.sellerNote!),
              ],

              // Images
              if (request.imageUrls.isNotEmpty) ...[
                const Divider(),
                const Text('รูปภาพประกอบ:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: request.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            request.imageUrls[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(ReturnRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('อนุมัติคำขอคืนสินค้า'),
        content: Text(
            'ยืนยันอนุมัติคำขอคืนสินค้า "${request.productName}" หรือไม่?\n\nลูกค้าจะได้รับการแจ้งเตือนและสามารถส่งสินค้าคืนได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('อนุมัติ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firebaseService.approveReturnRequest(request.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อนุมัติคำขอสำเร็จ')),
        );
        _loadReturnRequests();
      }
    } catch (e) {
      _logger.e('Error approving request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(ReturnRequest request) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปฏิเสธคำขอ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'ต้องการปฏิเสธคำขอคืนสินค้า "${request.productName}" หรือไม่?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'เหตุผลที่ปฏิเสธ *',
                hintText: 'กรุณาระบุเหตุผล...',
                border: OutlineInputBorder(),
              ),
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
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณาระบุเหตุผล')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ปฏิเสธ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firebaseService.rejectReturnRequest(
        request.id,
        reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ปฏิเสธคำขอสำเร็จ')),
        );
        _loadReturnRequests();
      }
    } catch (e) {
      _logger.e('Error rejecting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _confirmReceived(ReturnRequest request) async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันรับสินค้าคืน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ยืนยันว่าได้รับสินค้าคืนแล้ว?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'หมายเหตุ (ไม่บังคับ)',
                hintText: 'สภาพสินค้า, ข้อสังเกต...',
                border: OutlineInputBorder(),
              ),
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
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firebaseService.confirmReturnReceived(
        request.id,
        sellerNote: noteController.text.trim().isNotEmpty
            ? noteController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยืนยันรับสินค้าคืนสำเร็จ')),
        );
        _loadReturnRequests();
      }
    } catch (e) {
      _logger.e('Error confirming received: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _processRefund(ReturnRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('คืนเงิน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ยืนยันคืนเงินให้ลูกค้า?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('รายละเอียด:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('สินค้า: ${request.productName}'),
                  Text('จำนวนเงิน: ฿${_formatNumber(request.refundAmount)}'),
                  const Text('คืนเงินเข้า: Wallet ของลูกค้า'),
                ],
              ),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('คืนเงิน'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firebaseService.processFullRefund(
        request.id,
        request.buyerId,
        request.refundAmount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คืนเงินสำเร็จ ✓'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadReturnRequests();
      }
    } catch (e) {
      _logger.e('Error processing refund: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00', 'th');
    return formatter.format(number);
  }
}
