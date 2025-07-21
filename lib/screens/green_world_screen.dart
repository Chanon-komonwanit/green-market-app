import 'package:flutter/material.dart';

class GreenWorldScreen extends StatelessWidget {
  const GreenWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.97),
        elevation: 2,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.door_front_door, color: Color(0xFF14B8A6), size: 30),
            SizedBox(width: 10),
            Text(
              'เปิดโลกสีเขียว',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF14B8A6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF14B8A6)),
            tooltip: 'เกี่ยวกับโลกสีเขียว',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('เปิดโลกสีเขียว'),
                  content: const Text(
                      'Green World คือศูนย์กลางกิจกรรมและการลงทุนเพื่อความยั่งยืน พร้อมฟีเจอร์ระดับโลกสำหรับทุกคน'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิด'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF99F6E4), Color(0xFFE0F2FE), Color(0xFFFFFFFF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Onboarding/Welcome Section (World-class, animated, inspiring)
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF99F6E4),
                          Color(0xFFE0F2FE),
                          Colors.white
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.13),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeInOut,
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.public,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Welcome to Green World',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0xFF14B8A6),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'ค้นหาแรงบันดาลใจใหม่ ๆ ในการลงทุนและร่วมกิจกรรมเพื่อโลกที่ดีกว่า พร้อมฟีเจอร์ระดับโลก',
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Main Zones
              // Main Zones (World-class, animated, clear separation, CTA)
              Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.85, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) => Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                      child: _ZoneCard(
                        icon: Icons.groups,
                        color: Color(0xFF10B981),
                        title: 'กิจกรรมเพื่อสังคมและสิ่งแวดล้อม',
                        description:
                            'ฟีดกิจกรรม แชร์ เข้าร่วม สถิติ badge leaderboard',
                        ctaText: 'เข้าร่วมกิจกรรม',
                        onTap: () {
                          Navigator.pushNamed(
                              context, '/sustainable-activities-hub');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.85, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) => Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                      child: _ZoneCard(
                        icon: Icons.auto_graph,
                        color: Color(0xFF3B82F6),
                        title: 'การลงทุนเพื่อความยั่งยืน',
                        description:
                            'ฟีดการลงทุน กราฟ ข่าวสาร ผลตอบแทน ปุ่มลงทุน',
                        ctaText: 'เริ่มลงทุน',
                        onTap: () {
                          Navigator.pushNamed(context, '/investment-hub');
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF14B8A6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'รูปแบบการลงทุน',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: Color(0xFF14B8A6)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InvestmentTypeCard(
                      icon: Icons.eco,
                      color: Color(0xFF10B981),
                      title: 'ลงทุนโครงการสีเขียว',
                      enabled: true,
                      onTap: () {
                        Navigator.pushNamed(context, '/investment-hub');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InvestmentTypeCard(
                      icon: Icons.energy_savings_leaf,
                      color: Color(0xFF14B8A6),
                      title: 'กองทุน ESG',
                      enabled: false,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InvestmentTypeCard(
                      icon: Icons.door_front_door,
                      color: Color(0xFF3B82F6),
                      title: 'หุ้นยั่งยืน',
                      enabled: false,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Spacer(),
                  _ComingSoonLabel(enabled: false),
                  SizedBox(width: 60),
                  _ComingSoonLabel(enabled: false),
                  Spacer(),
                ],
              ),
              // Animation: Fade-in ป้ายเร็วๆนี้
              Row(
                children: const [
                  Spacer(),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 1200),
                    child: _ComingSoonLabel(enabled: false),
                  ),
                  SizedBox(width: 60),
                  AnimatedScale(
                    scale: 1.0,
                    duration: Duration(milliseconds: 900),
                    child: _ComingSoonLabel(enabled: false),
                  ),
                  Spacer(),
                ],
              ),

              // Mock: ข้อมูลโครงการลงทุน/กิจกรรม (สามารถเชื่อมต่อ Firestore ได้)
              const SizedBox(height: 24),
              Text('ตัวอย่างโครงการล่าสุด',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF14B8A6))),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _ZoneCard(
                      icon: Icons.eco,
                      color: Color(0xFF10B981),
                      title: 'ปลูกป่า 1 ล้านต้น',
                      description: 'ร่วมลงทุนและปลูกต้นไม้ทั่วไทย',
                      ctaText: 'ดูรายละเอียด',
                      onTap: () {},
                    ),
                    SizedBox(width: 12),
                    _ZoneCard(
                      icon: Icons.energy_savings_leaf,
                      color: Color(0xFF14B8A6),
                      title: 'พลังงานสะอาด',
                      description: 'ลงทุนโซลาร์ฟาร์มและพลังงานลม',
                      ctaText: 'ดูรายละเอียด',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String? ctaText;
  final VoidCallback onTap;

  const _ZoneCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.ctaText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 44),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 13.5,
                    color: color.withOpacity(0.85),
                  ),
              textAlign: TextAlign.center,
            ),
            if (ctaText != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                icon: Icon(icon, size: 20),
                label: Text(ctaText!),
                onPressed: onTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvestmentTypeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  const _InvestmentTypeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonLabel extends StatelessWidget {
  final bool enabled;
  const _ComingSoonLabel({required this.enabled});
  @override
  Widget build(BuildContext context) {
    if (enabled) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'เร็วๆนี้',
        style: TextStyle(
          color: Colors.orange[700],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
