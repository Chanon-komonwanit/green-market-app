// investment_opportunity_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/investment_project.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';

// A helper extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class InvestmentOpportunityDetailPage extends StatelessWidget {
  final InvestmentProject opportunity;

  const InvestmentOpportunityDetailPage({super.key, required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'รายละเอียดการลงทุน',
          style: AppTextStyles.title.copyWith(color: AppColors.primaryGreen),
        ),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryGreen),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'investmentIcon_${opportunity.id}',
              child: Container(
                height: 200,
                width: double.infinity,
                color: AppColors.lightTeal,
                child: Icon(
                  Icons
                      .eco_outlined, // Placeholder, replace with opportunity.imageUrl if available
                  size: 80,
                  color: AppColors.primaryGreen.withAlpha(150),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    style: AppTextStyles.headline
                        .copyWith(color: AppColors.primaryDarkGreen),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    opportunity.description,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.modernDarkGrey),
                  ),
                  const SizedBox(height: 24),
                  // --- CORRECTED: Use new getter and enum properties ---
                  _buildInfoRow(Icons.show_chart, 'ผลตอบแทนที่คาดหวัง',
                      opportunity.formattedExpectedReturn),
                  _buildInfoRow(Icons.shield_outlined, 'ระดับความเสี่ยง',
                      opportunity.riskLevel.name.capitalize()),
                  // REMOVED: The 'type' field was removed from the model.
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildInvestButton(context),
    );
  }

  Widget _buildInvestButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        onPressed: () => _showInvestmentDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('ลงทุนตอนนี้', style: AppTextStyles.subtitleBold),
      ),
    );
  }

  void _showInvestmentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ระบุจำนวนเงินลงทุน'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'จำนวนเงิน (฿)',
                prefixText: '฿ ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณาระบุจำนวนเงิน';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'จำนวนเงินต้องมากกว่า 0';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text);
                  Navigator.of(dialogContext).pop(amount);
                }
              },
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    ).then((amount) async {
      if (amount != null && amount > 0) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        try {
          await userProvider.investInProject(
              opportunity.id, opportunity.title, amount);
          showAppSnackBar(context, 'ลงทุนสำเร็จ!', isSuccess: true);
        } catch (e) {
          showAppSnackBar(context, 'การลงทุนล้มเหลว: ${e.toString()}',
              isError: true);
        }
      }
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.modernGrey)),
              Text(value, style: AppTextStyles.subtitleBold),
            ],
          ),
        ],
      ),
    );
  }
}
