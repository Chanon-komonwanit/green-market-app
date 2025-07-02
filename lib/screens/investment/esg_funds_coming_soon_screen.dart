// lib/screens/investment/esg_funds_coming_soon_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_market/utils/constants.dart';

class ESGFundsComingSoonScreen extends StatefulWidget {
  const ESGFundsComingSoonScreen({super.key});

  @override
  State<ESGFundsComingSoonScreen> createState() =>
      _ESGFundsComingSoonScreenState();
}

class _ESGFundsComingSoonScreenState extends State<ESGFundsComingSoonScreen> {
  final _emailController = TextEditingController();
  bool _emailSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'กองทุน ESG',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryTeal.withAlpha((0.1 * 255).round()),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.pie_chart,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'กองทุน ESG',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Environmental, Social & Governance',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.modernGrey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          'เปิดตัวเร็วๆ นี้',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Description Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.08 * 255).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primaryTeal,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'เกี่ยวกับกองทุน ESG',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'กองทุน ESG คือการลงทุนที่คำนึงถึงปัจจัยด้านสิ่งแวดล้อม สังคม และธรรมาภิบาลในการเลือกบริษัทที่จะลงทุน เพื่อสร้างผลตอบแทนที่ยั่งยืนและสร้างผลกระทบเชิงบวกต่อสังคมและสิ่งแวดล้อม',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.modernGrey,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Features Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.08 * 255).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.stars,
                            color: AppColors.primaryGreen,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'คุณสมบัติเด่น',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureItem(
                        Icons.eco,
                        'ลงทุนเพื่อสิ่งแวดล้อม',
                        'เลือกลงทุนในบริษัทที่มีนโยบายดูแลสิ่งแวดล้อม',
                        Colors.green,
                      ),
                      _buildFeatureItem(
                        Icons.people,
                        'ความรับผิดชอบต่อสังคม',
                        'สนับสนุนธุรกิจที่มีผลกระทบเชิงบวกต่อสังคม',
                        Colors.blue,
                      ),
                      _buildFeatureItem(
                        Icons.balance,
                        'ธรรมาภิบาลที่ดี',
                        'ลงทุนในบริษัทที่มีการบริหารจัดการที่โปร่งใส',
                        Colors.orange,
                      ),
                      _buildFeatureItem(
                        Icons.trending_up,
                        'ผลตอบแทนที่ยั่งยืน',
                        'สร้างกำไรระยะยาวพร้อมช่วยเหลือสังคม',
                        Colors.purple,
                      ),
                      _buildFeatureItem(
                        Icons.dashboard,
                        'กระจายความเสี่ยง',
                        'ลงทุนแบบกระจายในหลายธุรกิจที่ผ่านการคัดเลือก',
                        Colors.teal,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Benefits Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGreen.withAlpha((0.1 * 255).round()),
                        AppColors.primaryTeal.withAlpha((0.1 * 255).round()),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: AppColors.primaryTeal,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'ประโยชน์ที่คุณจะได้รับ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildBenefitItem('การลงทุนที่มีความหมาย'),
                      _buildBenefitItem('ผลตอบแทนที่คุ้มค่าและยั่งยืน'),
                      _buildBenefitItem('ส่วนร่วมในการเปลี่ยนแปลงโลก'),
                      _buildBenefitItem('ความเสี่ยงที่ได้รับการจัดการอย่างดี'),
                      _buildBenefitItem('รายงานผลกระทบที่โปร่งใส'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Email Notification Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.08 * 255).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        size: 48,
                        color: AppColors.primaryTeal,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'รับแจ้งเตือนเมื่อเปิดตัว',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'เป็นคนแรกที่รู้เมื่อกองทุน ESG พร้อมให้บริการ\nและรับข้อมูลโปรโมชั่นพิเศษ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.modernGrey,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (!_emailSubmitted) ...[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'กรอกอีเมลของคุณ',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.modernGrey
                                      .withAlpha((0.3 * 255).round())),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primaryTeal, width: 2),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'รับแจ้งเตือน',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen
                                .withAlpha((0.1 * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryGreen
                                  .withAlpha((0.3 * 255).round()),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.primaryGreen,
                                size: 48,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'ขอบคุณ!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'เราจะแจ้งให้คุณทราบทันทีเมื่อกองทุน ESG พร้อมให้บริการ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.modernGrey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Back Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryTeal),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'กลับสู่หน้าหลัก',
                      style: TextStyle(
                        color: AppColors.primaryTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.modernGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              benefit,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitEmail() async {
    if (_emailController.text.trim().isNotEmpty) {
      setState(() {
        _emailSubmitted = true;
      });

      try {
        // บันทึกอีเมลไว้ใน Firestore เพื่อแจ้งเตือนในอนาคต
        await FirebaseFirestore.instance.collection('esg_fund_waitlist').add({
          'email': _emailController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
          'notified': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ระบบจะแจ้งเตือนคุณเมื่อกองทุน ESG พร้อมให้บริการ'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึกอีเมล: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
