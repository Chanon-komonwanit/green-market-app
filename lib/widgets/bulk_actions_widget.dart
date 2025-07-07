// lib/widgets/bulk_actions_widget.dart
import 'package:flutter/material.dart';
import 'package:green_market/utils/constants.dart';

class BulkActionsWidget extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onPrintLabels;
  final VoidCallback onMarkAsShipped;
  final VoidCallback onCancel;

  const BulkActionsWidget({
    super.key,
    required this.selectedCount,
    required this.onPrintLabels,
    required this.onMarkAsShipped,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.primaryTeal.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              Text(
                'เลือกแล้ว $selectedCount รายการ',
                style: AppTextStyles.bodyBold
                    .copyWith(color: AppColors.primaryTeal),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.print,
                  label: 'พิมพ์ใบปะหน้า',
                  onPressed: onPrintLabels,
                  color: AppColors.primaryTeal,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.local_shipping,
                  label: 'จัดส่งแล้ว',
                  onPressed: onMarkAsShipped,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.cancel,
                  label: 'ยกเลิก',
                  onPressed: onCancel,
                  color: AppColors.errorRed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
