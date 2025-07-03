// lib/screens/my_investment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/models/user_investment.dart';
import 'package:green_market/providers/user_provider.dart';
import 'package:green_market/utils/app_utils.dart';
import 'package:green_market/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MyInvestmentDetailPage extends StatelessWidget {
  final UserInvestment investment;

  const MyInvestmentDetailPage({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    final double currentReturn =
        investment.amount * 0.05; // Placeholder 5% return
    final double returnPercentage =
        (investment.amount > 0) ? (currentReturn / investment.amount) * 100 : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'รายละเอียดการลงทุนของฉัน',
          style: AppTextStyles.title.copyWith(color: AppColors.primaryGreen),
        ),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryGreen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              investment.projectTitle,
              style: AppTextStyles.headline.copyWith(
                color: AppColors.primaryDarkGreen,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      Icons.account_balance_wallet_outlined,
                      'จำนวนเงินลงทุน',
                      currencyFormat.format(investment.amount),
                    ),
                    _buildInfoRow(
                      Icons.calendar_today_outlined,
                      'วันที่ลงทุน',
                      DateFormat(
                        'dd MMM yyyy',
                      ).format(investment.investedAt.toDate()),
                    ),
                    _buildInfoRow(
                      Icons.show_chart,
                      'ผลตอบแทนโดยประมาณ',
                      '${currencyFormat.format(currentReturn)} (${returnPercentage.toStringAsFixed(1)}%)',
                      valueColor: returnPercentage >= 0
                          ? AppColors.accentGreen
                          : AppColors.warningOrange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'รายละเอียดการลงทุน',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('วันที่ลงทุน'),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(
                                  investment.investedAt.toDate(),
                                ),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('สถานะการลงทุน'),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'กำลังดำเนินการ',
                                  style: TextStyle(
                                    color: AppColors.accentGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('ระยะเวลาการลงทุน'),
                              Text(
                                '12 เดือน',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('ซื้อเพิ่ม'),
                    onPressed: () => _showBuyMoreDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.sell_outlined),
                    label: const Text('ขาย'),
                    onPressed: () => _showSellDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
              ),
              Text(
                value,
                style: AppTextStyles.subtitleBold.copyWith(color: valueColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBuyMoreDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ซื้อเพิ่ม'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'จำนวนเงิน (฿)',
                prefixText: '฿ ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'กรุณาระบุจำนวนเงิน';
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
          await userProvider.buyMoreInvestment(investment.id, amount);
          showAppSnackBar(context, 'ซื้อเพิ่มสำเร็จ!', isSuccess: true);
        } catch (e) {
          showAppSnackBar(
            context,
            'ซื้อเพิ่มล้มเหลว: ${e.toString()}',
            isError: true,
          );
        }
      }
    });
  }

  void _showSellDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ขายการลงทุน'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'จำนวนเงินที่ต้องการขาย (฿)',
                prefixText: '฿ ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'กรุณาระบุจำนวนเงิน';
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'จำนวนเงินต้องมากกว่า 0';
                }
                // Add validation to ensure amount <= investment.amount
                if (amount > investment.amount) {
                  return 'จำนวนเงินที่ขายต้องไม่เกินจำนวนที่ลงทุน';
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
          await userProvider.sellInvestment(investment.id, amount);
          showAppSnackBar(context, 'ขายสำเร็จ!', isSuccess: true);
          // Optionally, pop this screen if the investment is fully sold
          if (amount == investment.amount && context.mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          showAppSnackBar(
            context,
            'ขายล้มเหลว: ${e.toString()}',
            isError: true,
          );
        }
      }
    });
  }
}
