import 'package:flutter/material.dart';

class GreenWorldScreen extends StatelessWidget {
  const GreenWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Section
              _buildHeader(),
              const SizedBox(height: 60),

              // Main Actions Section
              _buildMainActions(context),

              const SizedBox(height: 60),

              // Simple Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C853).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.eco,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        const Text(
          'เปิดโลกสีเขียว',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            letterSpacing: -1.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Subtitle
        Text(
          'เลือกเส้นทางการสร้างผลกระทบเชิงบวกของคุณ',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainActions(BuildContext context) {
    return Column(
      children: [
        // Title for actions
        const Text(
          'เลือกกิจกรรมของคุณ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 32),

        // Action 1: กิจกรรมเพื่อสังคมและสิ่งแวดล้อม
        _buildActionCard(
          context,
          title: 'กิจกรรมเพื่อสังคมและสิ่งแวดล้อม',
          subtitle: 'ร่วมสร้างผลกระทบเชิงบวกต่อสังคมและธรรมชาติ',
          icon: Icons.nature_people,
          gradientColors: [const Color(0xFF00C853), const Color(0xFF4CAF50)],
          onTap: () =>
              Navigator.pushNamed(context, '/sustainable-activities-hub'),
        ),

        const SizedBox(height: 20),

        // Action 2: การลงทุนความยั่งยืน
        _buildActionCard(
          context,
          title: 'การลงทุนความยั่งยืน',
          subtitle: 'ลงทุนในอนาคตที่ยั่งยืนและเติบโตไปด้วยกัน',
          icon: Icons.trending_up,
          gradientColors: [const Color(0xFF2196F3), const Color(0xFF1976D2)],
          onTap: () => Navigator.pushNamed(context, '/investment-hub'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Call to action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'เริ่มต้นเลย',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco,
            color: Colors.green[600],
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'ร่วมกันสร้างโลกที่ดีกว่า',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'ทุกการกระทำเล็กๆ สร้างการเปลี่ยนแปลงใหญ่',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
