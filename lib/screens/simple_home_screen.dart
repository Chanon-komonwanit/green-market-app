// lib/screens/simple_home_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/widgets/test_eco_widget.dart';
import 'package:green_market/screens/green_world_hub_screen.dart';

class SimpleHomeScreen extends StatelessWidget {
  const SimpleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar Header
            SliverAppBar(
              expandedHeight: 80, // ลดขนาดจาก 120 เป็น 80
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 30, 16, 8), // ลด padding
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4, // เพิ่มพื้นที่ให้ชื่อแอพ
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GREEN MARKET',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16, // ลดขนาดอีก
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Text(
                                'ตลาดออนไลน์เพื่อสิ่งแวดล้อม',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Test Eco Widget - โซนเหรียญทดสอบ (ขนาดเล็กมาก)
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.eco, color: Colors.white, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                '1250',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_forward_ios,
                                  color: Colors.white, size: 6),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GreenWorldHubScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.explore,
                                color: Colors.white, size: 16),
                            constraints: const BoxConstraints.tightFor(
                                width: 28, height: 28),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Simple content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notice about Eco Coins
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.eco, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ระบบ Eco Coins กำลังพัฒนา',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                Text(
                                  'โซนเหรียญ Eco ที่มุมขวาบนสามารถคลิกได้',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Categories Section
                    Text(
                      'หมวดหมู่สินค้า',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          final categories = [
                            'ผักปลอดสาร',
                            'ผลไม้อินทรีย์',
                            'ข้าวธัญพืช',
                            'ผลิตภัณฑ์เพื่อสุขภาพ',
                            'ของใช้รีไซเคิล'
                          ];
                          final icons = [
                            Icons.grass,
                            Icons.apple,
                            Icons.grain,
                            Icons.health_and_safety,
                            Icons.recycling
                          ];

                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icons[index],
                                    color: Colors.green, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  categories[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Featured Products
                    Text(
                      'สินค้าแนะนำ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final products = [
                          'ผักกาดอินทรีย์',
                          'น้ำผึ้งป่า',
                          'ข้าวหอมมะลิ',
                          'น้ำมันมะพร้าว'
                        ];
                        final prices = ['฿45', '฿120', '฿85', '฿95'];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(8)),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.image,
                                        size: 40, color: Colors.grey.shade400),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      products[index],
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      prices[index],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
