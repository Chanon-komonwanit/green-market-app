import 'package:flutter/material.dart';

class GreenWorldScreen extends StatelessWidget {
  const GreenWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'เปิดโลกสีเขียว',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero Section - วิสัยทัศน์
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    const Text(
                      '🌍',
                      style: TextStyle(fontSize: 50),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'ร่วมสร้างโลกที่ยั่งยืน',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'แพลตฟอร์มเชื่อมต่อการลงทุนและกิจกรรมเพื่อสิ่งแวดล้อม',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // สถิติสำคัญ
            Container(
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('🌱', '2.5M+', 'ต้นไม้'),
                    _buildStatItem('💰', '500M+', 'บาท'),
                    _buildStatItem('👥', '100K+', 'คน'),
                  ],
                ),
              ),
            ),

            // ปุ่มหลัก 2 ปุ่ม
            const Text(
              'เลือกกิจกรรมของคุณ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ปุ่ม 1: กิจกรรมเพื่อสังคมและสิ่งแวดล้อม
            _buildMainActionCard(
              context,
              icon: '🌿',
              title: 'กิจกรรมเพื่อสังคมและสิ่งแวดล้อม',
              subtitle: 'ร่วมกิจกรรมอนุรักษ์ธรรมชาติและช่วยเหลือสังคม',
              color: const Color(0xFF4CAF50),
              onTap: () {
                Navigator.pushNamed(context, '/sustainable-activities-hub');
              },
            ),

            const SizedBox(height: 20),

            // ปุ่ม 2: การลงทุนความยั่งยืน
            _buildMainActionCard(
              context,
              icon: '💎',
              title: 'การลงทุนความยั่งยืน',
              subtitle: 'ลงทุนในโครงการที่เป็นมิตรต่อสิ่งแวดล้อม',
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.pushNamed(context, '/investment-hub');
              },
            ),

            const SizedBox(height: 40),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Text(
                    '🏆',
                    style: TextStyle(fontSize: 30),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ร่วมกันสร้างผลกระทบเชิงบวกต่อโลก',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ทุกการกระทำเล็กๆ นำไปสู่การเปลี่ยนแปลงใหญ่',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String number, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 30),
        ),
        const SizedBox(height: 8),
        Text(
          number,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMainActionCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'เริ่มต้นเลย',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
