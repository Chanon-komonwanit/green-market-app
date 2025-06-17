import 'package:flutter/material.dart';
// เราจะย้าย Model มาไว้ที่นี่
import 'package:green_market/models/investment_opportunity.dart';
import 'package:green_market/utils/constants.dart';

class InvestmentOpportunityDetailPage extends StatelessWidget {
  final InvestmentOpportunity opportunity;

  const InvestmentOpportunityDetailPage({super.key, required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(opportunity.name,
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
                Hero(
                  tag: 'opportunityIcon_${opportunity.id}', // Same unique tag
                  child: Icon(opportunity.icon,
                      size: 50, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    opportunity.name,
                    style: AppTextStyles.headline
                        .copyWith(color: AppColors.primaryDarkGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              opportunity.description,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.modernDarkGrey, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Details Section
            _buildDetailRow(context, "ประเภทการลงทุน:", opportunity.type),
            _buildDetailRow(
                context, "ผลตอบแทนที่คาดหวัง:", opportunity.expectedReturn),
            _buildDetailRow(context, "ระดับความเสี่ยง:", opportunity.riskLevel,
                valueColor: _getRiskColor(opportunity.riskLevel)),
            const SizedBox(height: 24),

            // Additional Information (Placeholder)
            Text(
              'ข้อมูลเพิ่มเติม:',
              style: AppTextStyles.title
                  .copyWith(color: AppColors.primaryDarkGreen),
            ),
            const SizedBox(height: 8),
            Text(
              'ที่นี่คุณสามารถใส่รายละเอียดเพิ่มเติมเกี่ยวกับโอกาสการลงทุนนี้ เช่น ข้อมูลบริษัท, รายงานผลกระทบทางสิ่งแวดล้อม, หรือเอกสารโครงการ (Prospectus) เป็นต้น',
              style: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
            ),
            const SizedBox(height: 32),

            // Call to Action Button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.trending_up),
                label: const Text('ลงทุนเลย'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: AppTextStyles.button,
                ),
                onPressed: () {
                  // TODO: Implement investment action
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('ดำเนินการลงทุนใน: ${opportunity.name}')),
                  );
                },
              ),
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

  Color _getRiskColor(String riskLevel) {
    if (riskLevel.toLowerCase().contains('สูง')) {
      return AppColors.warningOrange;
    } else if (riskLevel.toLowerCase().contains('ปานกลาง')) {
      return AppColors.primaryTeal;
    } else {
      return AppColors.accentGreen; // ต่ำ
    }
  }
}
