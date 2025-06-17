import 'package:flutter/material.dart';
import 'package:green_market/models/my_investment.dart';
import 'package:green_market/utils/constants.dart'; // Assuming AppTextStyles and AppColors are here

class MyInvestmentDetailPage extends StatelessWidget {
  final MyInvestment investment;

  const MyInvestmentDetailPage({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(investment.name,
            style: AppTextStyles.title.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primaryGreen,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header Section
            Row(
              children: [
                Icon(investment.icon, size: 50, color: AppColors.primaryGreen),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    investment.name,
                    style: AppTextStyles.headline
                        .copyWith(color: AppColors.primaryDarkGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Investment Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        context, "ประเภทสินทรัพย์:", investment.assetType),
                    _buildDetailRow(context, "จำนวนหน่วย/ปริมาณ:",
                        investment.quantity.toString()),
                    _buildDetailRow(context, "มูลค่าปัจจุบัน:",
                        '฿${investment.currentValue.toStringAsFixed(2)}',
                        valueColor: AppColors.primaryTeal),
                    _buildDetailRow(context, "ผลตอบแทนรวม:",
                        '฿${investment.totalReturn.toStringAsFixed(2)}',
                        valueColor: investment.totalReturn >= 0
                            ? AppColors.accentGreen
                            : AppColors.warningOrange),
                    _buildDetailRow(context, "ผลตอบแทน (%):",
                        '${investment.returnPercentage >= 0 ? '+' : ''}${investment.returnPercentage.toStringAsFixed(1)}%',
                        valueColor: investment.returnPercentage >= 0
                            ? AppColors.accentGreen
                            : AppColors.warningOrange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Placeholder for Performance Chart or Transaction History
            Text(
              'ประวัติและผลการดำเนินงาน:',
              style: AppTextStyles.title
                  .copyWith(color: AppColors.primaryDarkGreen),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border:
                    // ignore: deprecated_member_use
                    Border.all(color: AppColors.modernGrey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'ส่วนนี้สำหรับแสดงกราฟผลการดำเนินงาน หรือ ประวัติการทำธุรกรรมที่เกี่ยวข้องกับการลงทุนนี้ (จะพัฒนาในภายหลัง)',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.modernDarkGrey),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons (Example)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: AppColors.white),
                  onPressed: () {
                    // TODO: Implement "Sell" action
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'ดำเนินการ "ขาย" สำหรับ: ${investment.name}')),
                    );
                  },
                  child: const Text('ขาย'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: AppColors.white),
                  onPressed: () {
                    // TODO: Implement "Buy More" action
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'ดำเนินการ "ซื้อเพิ่ม" สำหรับ: ${investment.name}')),
                    );
                  },
                  child: const Text('ซื้อเพิ่ม'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.subtitle
                  .copyWith(color: AppColors.modernDarkGrey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.subtitleBold
                  .copyWith(color: valueColor ?? AppColors.primaryDarkGreen),
            ),
          ),
        ],
      ),
    );
  }
}
