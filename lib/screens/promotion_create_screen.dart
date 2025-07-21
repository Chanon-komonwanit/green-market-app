import 'package:flutter/material.dart';
import 'package:green_market/models/promotion.dart';
import 'package:green_market/services/promotion_service.dart';

class PromotionCreateScreen extends StatefulWidget {
  final String sellerId;
  const PromotionCreateScreen({super.key, required this.sellerId});

  @override
  State<PromotionCreateScreen> createState() => _PromotionCreateScreenState();
}

class _PromotionCreateScreenState extends State<PromotionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  String discountType = 'percentage';
  double discountValue = 0;
  DateTime? startDate;
  DateTime? endDate;
  bool isActive = true;
  String imageUrl = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('สร้างโปรโมชั่นใหม่'),
          backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'ชื่อโปรโมชั่น'),
                onChanged: (v) => setState(() => title = v),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกชื่อโปรโมชั่น' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'รายละเอียด'),
                onChanged: (v) => setState(() => description = v),
              ),
              DropdownButtonFormField<String>(
                value: discountType,
                decoration: const InputDecoration(labelText: 'ประเภทส่วนลด'),
                items: const [
                  DropdownMenuItem(
                      value: 'percentage', child: Text('เปอร์เซ็นต์ (%)')),
                  DropdownMenuItem(
                      value: 'fixed_amount', child: Text('จำนวนเงิน (บาท)')),
                ],
                onChanged: (v) =>
                    setState(() => discountType = v ?? 'percentage'),
              ),
              TextFormField(
                decoration: InputDecoration(
                    labelText: discountType == 'percentage'
                        ? 'ส่วนลด (%)'
                        : 'ส่วนลด (บาท)'),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    setState(() => discountValue = double.tryParse(v) ?? 0),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                    ? 'กรุณากรอกส่วนลด'
                    : null,
              ),
              ListTile(
                title: Text(startDate == null
                    ? 'เลือกวันเริ่มต้น'
                    : 'เริ่ม ${startDate!.toLocal()}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => startDate = picked);
                },
              ),
              ListTile(
                title: Text(endDate == null
                    ? 'เลือกวันสิ้นสุด'
                    : 'สิ้นสุด ${endDate!.toLocal()}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => endDate = picked);
                },
              ),
              SwitchListTile(
                title: const Text('เปิดใช้งานโปรโมชั่น'),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'ลิงก์รูปภาพโปรโมชั่น (ถ้ามี)'),
                onChanged: (v) => setState(() => imageUrl = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('บันทึกโปรโมชั่น'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () async {
                  if (_formKey.currentState?.validate() != true) return;
                  if (startDate == null || endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('กรุณาเลือกวันเริ่มต้นและสิ้นสุด')));
                    return;
                  }
                  final promo = Promotion(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    sellerId: widget.sellerId,
                    title: title,
                    code: '',
                    description: description,
                    image: imageUrl,
                    discountType: discountType,
                    discountValue: discountValue,
                    startDate: startDate!,
                    endDate: endDate!,
                    isActive: isActive,
                  );
                  await PromotionService().createPromotion(promo);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
