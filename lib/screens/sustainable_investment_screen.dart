import 'package:flutter/material.dart';
import 'package:green_market/models/investment_opportunity.dart';
import 'package:green_market/models/my_investment.dart';
import 'package:green_market/utils/constants.dart'; // Assuming AppTextStyles and AppColors are here
import 'package:green_market/models/news_article.dart';
import 'package:green_market/screens/investment_opportunity_detail_screen.dart';
import 'package:green_market/screens/my_investment_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:green_market/screens/news_article_detail_screen.dart';

class SustainableInvestmentScreen extends StatefulWidget {
  const SustainableInvestmentScreen({super.key});

  @override
  State<SustainableInvestmentScreen> createState() =>
      _SustainableInvestmentScreenState();
}

class _SustainableInvestmentScreenState
    extends State<SustainableInvestmentScreen> {
  int _selectedIndex = 0; // Index for the internal BottomNavigationBar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ignore: deprecated_member_use
      backgroundColor: AppColors.lightTeal.withOpacity(0.1),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined), // หรือ Icons.show_chart
            activeIcon: Icon(Icons.store), // หรือ Icons.show_chart
            label: 'ตลาดลงทุน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'กระเป๋าลงทุน',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor:
            AppColors.primaryGreen, // สีไอคอนและข้อความเมื่อเลือก
        unselectedItemColor: AppColors.modernGrey,
        onTap: _onItemTapped,
        backgroundColor: AppColors.white, // สีพื้นหลังของ BottomNavBar
        type: BottomNavigationBarType.fixed, // ให้แสดง label เสมอ
      ),
      body: IndexedStack(
        // ใช้ IndexedStack เพื่อรักษา state ของแต่ละหน้า
        index: _selectedIndex,
        children: [
          InvestmentHomePage(onNavigateToTab: _onItemTapped), // Pass callback
          const InvestmentMarketPage(),
          const InvestmentWalletPage(),
        ],
      ),
    );
  }
}

// Placeholder Widget for Investment Home Page
class InvestmentHomePage extends StatefulWidget {
  final Function(int) onNavigateToTab;
  const InvestmentHomePage({super.key, required this.onNavigateToTab});

  @override
  State<InvestmentHomePage> createState() => _InvestmentHomePageState();
}

class _InvestmentHomePageState extends State<InvestmentHomePage>
    with TickerProviderStateMixin {
  late AnimationController _newsAnimationController;

  @override
  void initState() {
    super.initState();
    _newsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  // Simulate fetching featured opportunities
  Future<List<InvestmentOpportunity>> _fetchFeaturedOpportunities() async {
    await Future.delayed(
        const Duration(milliseconds: 800)); // Simulate network delay
    // Sample data
    return [
      InvestmentOpportunity(
        id: 'feat1',
        name: 'โครงการพลังงานแสงอาทิตย์ชุมชน',
        description:
            'ลงทุนในอนาคตพลังงานสะอาด สร้างผลกระทบเชิงบวกต่อสิ่งแวดล้อมและชุมชน พร้อมรับผลตอบแทนที่น่าสนใจ',
        type: 'หุ้นส่วนทุน',
        expectedReturn: '5-7% ต่อปี',
        riskLevel: 'ปานกลาง',
        icon: Icons.solar_power_outlined,
      ),
      InvestmentOpportunity(
        id: 'feat2',
        name: 'กองทุนเกษตรอินทรีย์เพื่อชุมชน',
        description:
            'สนับสนุนเกษตรกรรายย่อยที่เปลี่ยนมาทำเกษตรอินทรีย์ สร้างความมั่นคงทางอาหารและระบบนิเวศที่ยั่งยืน',
        type: 'กองทุนรวม',
        expectedReturn: '4-6% ต่อปี',
        riskLevel: 'ต่ำ-ปานกลาง',
        icon: Icons.eco_outlined,
      ),
    ];
  }

  // Simulate fetching portfolio summary
  Future<Map<String, String>> _fetchPortfolioSummaryData() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return {'totalValue': '฿123,456.78', 'returns': '+5.67%'};
  }

  // Simulate fetching news articles
  Future<List<NewsArticle>> _fetchNewsArticles() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return [
      NewsArticle(
          id: 'news1',
          title: 'แนวโน้มการลงทุนอย่างยั่งยืนในปี 2024',
          summary:
              'การลงทุน ESG ยังคงเติบโตอย่างต่อเนื่อง ผู้เชี่ยวชาญชี้ปัจจัยสำคัญที่นักลงทุนควรจับตามอง...',
          source: 'GreenInvest Today',
          publishedDate: DateTime(2024, 3, 10),
          imageUrl: 'https://via.placeholder.com/150/A9DBCF/000000?Text=News1'),
      NewsArticle(
          id: 'news2',
          title: 'พลังงานหมุนเวียน: โอกาสทองของนักลงทุนยุคใหม่',
          summary:
              'เจาะลึกศักยภาพการเติบโตของอุตสาหกรรมพลังงานสะอาด และโอกาสในการสร้างผลตอบแทนที่ยั่งยืน',
          source: 'EcoFinance Hub',
          publishedDate: DateTime(2024, 3, 8),
          imageUrl: 'https://via.placeholder.com/150/B2DFDB/000000?Text=News2'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _newsAnimationController.forward();
    // Sample data for featured investment opportunities

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Text(
              'ยินดีต้อนรับสู่โซนลงทุนความยั่งยืน',
              textAlign: TextAlign.center,
              style: AppTextStyles.headline.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'เริ่มต้นเส้นทางการลงทุนเพื่ออนาคตที่ยั่งยืนกับเรา',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.modernDarkGrey),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'การลงทุนแนะนำ',
              trailing: TextButton.icon(
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: const Text('ดูทั้งหมด'),
                onPressed: () =>
                    widget.onNavigateToTab(1), // Navigate to Market tab
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal),
              )),
          FutureBuilder<List<InvestmentOpportunity>>(
            future: _fetchFeaturedOpportunities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryTeal));
              }
              if (snapshot.hasError) {
                return _buildEmptyStateMessage('เกิดข้อผิดพลาดในการโหลดข้อมูล');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyStateMessage('ยังไม่มีการลงทุนแนะนำในขณะนี้');
              }
              final featuredOpportunities = snapshot.data!;
              return Column(
                children: [
                  if (featuredOpportunities.isNotEmpty)
                    _buildFeaturedInvestmentCard(
                        context, featuredOpportunities[0]),
                  if (featuredOpportunities.length > 1)
                    _buildFeaturedInvestmentCard(
                        context, featuredOpportunities[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'สรุปพอร์ตของคุณ',
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.primaryTeal)),
          FutureBuilder<Map<String, String>>(
            future: _fetchPortfolioSummaryData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryTeal));
              }
              if (snapshot.hasError) {
                return _buildEmptyStateMessage('ไม่สามารถโหลดข้อมูลพอร์ตได้');
              }
              final summaryData =
                  snapshot.data ?? {'totalValue': 'N/A', 'returns': 'N/A'};
              return _buildPortfolioSummaryCard(
                  context,
                  summaryData['totalValue']!,
                  summaryData['returns']!,
                  widget.onNavigateToTab);
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'ข่าวสารและบทความน่ารู้',
              trailing: TextButton.icon(
                icon: const Icon(Icons.article_outlined, size: 18),
                label: const Text('ดูทั้งหมด'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('TODO: Navigate to News List Screen')),
                  );
                },
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal),
              )),
          FutureBuilder<List<NewsArticle>>(
            future: _fetchNewsArticles(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryTeal));
              }
              if (snapshot.hasError) {
                return _buildEmptyStateMessage(
                    'เกิดข้อผิดพลาดในการโหลดข่าวสาร');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyStateMessage(
                    'ยังไม่มีข่าวสารหรือบทความในขณะนี้');
              }
              final newsArticles = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: newsArticles.length,
                itemBuilder: (context, index) {
                  final article = newsArticles[index];
                  final animationDelay = Duration(milliseconds: 100 * index);
                  final itemAnimation =
                      Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _newsAnimationController,
                      curve: Interval(
                        (animationDelay.inMilliseconds /
                                _newsAnimationController
                                    .duration!.inMilliseconds)
                            .clamp(0.0, 1.0),
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  );
                  return FadeTransition(
                    opacity: itemAnimation,
                    child: SlideTransition(
                        position: Tween<Offset>(
                                begin: const Offset(0, 0.2), end: Offset.zero)
                            .animate(itemAnimation),
                        child: _buildNewsArticleCard(context, article)),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Center(
        child: Column(
          // Added Column for icon and text
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded,
                // ignore: deprecated_member_use
                color: AppColors.modernGrey.withOpacity(0.7),
                size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title,
      {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
                color: AppColors.primaryDarkGreen, fontWeight: FontWeight.w600),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildFeaturedInvestmentCard(
      BuildContext context, InvestmentOpportunity opportunity) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                InvestmentOpportunityDetailPage(opportunity: opportunity),
          ),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: AppColors.white,
        // ignore: deprecated_member_use
        shadowColor: AppColors.primaryGreen.withOpacity(0.15),
        // ignore: deprecated_member_use
        surfaceTintColor: AppColors.lightTeal.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(opportunity.icon, size: 40, color: AppColors.primaryGreen),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opportunity.name,
                        style: AppTextStyles.subtitleBold
                            .copyWith(color: AppColors.primaryDarkGreen)),
                    const SizedBox(height: 4),
                    Text(
                      opportunity.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.modernDarkGrey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.modernGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioSummaryCard(BuildContext context, String totalValueText,
      String returnsText, Function(int) onNavigateToTab) {
    return InkWell(
      onTap: () => onNavigateToTab(2), // Navigate to Wallet tab (index 2)
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [
                // ignore: deprecated_member_use
                AppColors.primaryGreen.withOpacity(0.85),
                // ignore: deprecated_member_use
                AppColors.primaryTeal.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: AppColors.primaryTeal.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('มูลค่ารวมในพอร์ต',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.white.withOpacity(0.8))),
                    Text(totalValueText,
                        style: AppTextStyles.title.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('ผลตอบแทนโดยประมาณ',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.white.withOpacity(0.8))),
                    Text(returnsText,
                        style: AppTextStyles.subtitle
                            .copyWith(color: AppColors.white.withOpacity(0.9))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: AppColors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsArticleCard(BuildContext context, NewsArticle article) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsArticleDetailPage(article: article),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (article.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Hero(
                        tag: 'newsImage_home_${article.id}',
                        child: Image.network(
                          article.imageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 80,
                              height: 80,
                              color: AppColors.lightGrey.withOpacity(0.5),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2.0,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 80,
                            height: 80,
                            color: AppColors.lightGrey.withOpacity(0.7),
                            child: Icon(Icons.broken_image_outlined,
                                size: 30, color: AppColors.modernDarkGrey),
                          ),
                        ),
                      )),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title, // Corrected: Use article.title
                        style: AppTextStyles.subtitleBold.copyWith(
                            fontSize: 15, color: AppColors.primaryDarkGreen)),
                    const SizedBox(height: 4),
                    Text(
                      article.summary, // Corrected: Use article.summary
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.modernDarkGrey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                        '${article.source} - ${DateFormat('dd MMM yy', 'th').format(article.publishedDate)}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.modernGrey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newsAnimationController.dispose();
    super.dispose();
  }
}

// Placeholder Widget for Investment Market Page
class InvestmentMarketPage extends StatefulWidget {
  const InvestmentMarketPage({super.key});

  @override
  State<InvestmentMarketPage> createState() => _InvestmentMarketPageState();
}

class _InvestmentMarketPageState extends State<InvestmentMarketPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    _animationController.forward(); // Start animation when widget builds
    // Sample data for investment opportunities
    final List<InvestmentOpportunity> opportunities = [
      InvestmentOpportunity(
        id: 'opp1',
        name: 'หุ้นกู้สีเขียว (Green Bond) ABC Corp',
        description: 'สนับสนุนโครงการพลังงานหมุนเวียนของ ABC Corp.',
        type: 'หุ้นกู้',
        expectedReturn: '4.5% ต่อปี',
        riskLevel: 'ต่ำ-ปานกลาง',
        icon: Icons.business_center_outlined,
      ),
      InvestmentOpportunity(
        id: 'opp2',
        name: 'กองทุนรวมโครงสร้างพื้นฐานยั่งยืน XYZ',
        description: 'ลงทุนในโครงการสาธารณูปโภคที่เป็นมิตรต่อสิ่งแวดล้อม',
        type: 'กองทุนรวม',
        expectedReturn: '6-8% ต่อปี',
        riskLevel: 'ปานกลาง',
        icon: Icons.account_balance_outlined,
      ),
      InvestmentOpportunity(
        id: 'opp3',
        name: 'สตาร์ทอัพเทคโนโลยีการเกษตรอัจฉริยะ',
        description: 'ร่วมเป็นส่วนหนึ่งในการปฏิวัติเกษตรกรรมด้วยเทคโนโลยี',
        type: 'หุ้นส่วนทุน (Equity)',
        expectedReturn: 'สูง (ขึ้นอยู่กับผลประกอบการ)',
        riskLevel: 'สูง',
        icon: Icons.agriculture_outlined,
      ),
    ];

    if (opportunities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'ยังไม่มีโอกาสในการลงทุนในขณะนี้',
            style: AppTextStyles.body.copyWith(color: AppColors.modernGrey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: opportunities.length,
      itemBuilder: (context, index) {
        final opportunity = opportunities[index];
        // Calculate animation delay for staggered effect
        final animationDelay = Duration(milliseconds: 100 * index);
        final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (animationDelay.inMilliseconds /
                      _animationController.duration!.inMilliseconds)
                  .clamp(0.0, 1.0),
              1.0,
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return FadeTransition(
          opacity: itemAnimation,
          child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                      .animate(itemAnimation),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => InvestmentOpportunityDetailPage(
                            opportunity: opportunity)),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  // ignore: deprecated_member_use
                  color: AppColors.white,
                  // ignore: deprecated_member_use
                  shadowColor: AppColors.primaryGreen.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(opportunity.icon,
                            size: 40, color: AppColors.primaryGreen),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(opportunity.name,
                                  style: AppTextStyles.subtitleBold.copyWith(
                                      color: AppColors.primaryDarkGreen)),
                              const SizedBox(height: 4),
                              Text(opportunity.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.modernDarkGrey)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      'ผลตอบแทน: ${opportunity.expectedReturn}',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.accentGreen,
                                          fontWeight: FontWeight.w500)),
                                  Text('ความเสี่ยง: ${opportunity.riskLevel}',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.warningOrange,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Placeholder Widget for Investment Wallet Page
class InvestmentWalletPage extends StatefulWidget {
  const InvestmentWalletPage({super.key});

  @override
  State<InvestmentWalletPage> createState() => _InvestmentWalletPageState();
}

class _InvestmentWalletPageState extends State<InvestmentWalletPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _walletAnimationController;

  @override
  void initState() {
    super.initState();
    _walletAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    _walletAnimationController.forward();
    // Sample data for user's investments
    final List<MyInvestment> myInvestments = [
      MyInvestment(
        id: 'myinv1',
        name: 'โครงการพลังงานแสงอาทิตย์ชุมชน',
        assetType: 'หุ้นส่วนทุน',
        quantity: 100,
        currentValue: 12500.00,
        totalReturn: 2500.00,
        returnPercentage: 20.0,
        icon: Icons.solar_power_outlined,
      ),
      MyInvestment(
        id: 'myinv2',
        name: 'หุ้นกู้สีเขียว (Green Bond) ABC Corp',
        assetType: 'หุ้นกู้',
        quantity: 50,
        currentValue: 5150.00,
        totalReturn: 150.00,
        returnPercentage: 3.0,
        icon: Icons.business_center_outlined,
      ),
    ];

    double totalPortfolioValue =
        myInvestments.fold(0, (sum, item) => sum + item.currentValue);
    double totalPortfolioReturn =
        myInvestments.fold(0, (sum, item) => sum + item.totalReturn);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'กระเป๋าลงทุนของฉัน',
            style: AppTextStyles.headline.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            // ignore: deprecated_member_use
            color: AppColors.white, // Use white for a clean look
            // ignore: deprecated_member_use
            shadowColor: AppColors.primaryGreen.withOpacity(0.2), // Add shadow
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)), // Round edges
            surfaceTintColor:
                // ignore: deprecated_member_use
                AppColors.lightTeal.withOpacity(0.3), // Add a subtle tint
            margin: const EdgeInsets.symmetric(horizontal: 8),
            // Make the card tappable

            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('มูลค่าพอร์ตรวม',
                      style: AppTextStyles.subtitle.copyWith(
                          // ignore: deprecated_member_use
                          color: AppColors.modernDarkGrey.withOpacity(0.8))),
                  Text('฿${totalPortfolioValue.toStringAsFixed(2)}',
                      style: AppTextStyles.headline.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('ผลตอบแทนรวม',
                      style: AppTextStyles.subtitle.copyWith(
                          // ignore: deprecated_member_use
                          color: AppColors.modernDarkGrey.withOpacity(0.8))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('฿${totalPortfolioReturn.toStringAsFixed(2)}',
                          style: AppTextStyles.title.copyWith(
                              color: totalPortfolioReturn >= 0
                                  ? AppColors.accentGreen
                                  : AppColors.warningOrange)),
                      Icon(Icons.trending_up,
                          color: totalPortfolioReturn >= 0
                              ? AppColors.accentGreen
                              : AppColors.warningOrange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'การลงทุนของฉัน',
            style: AppTextStyles.title.copyWith(
                color: AppColors.primaryDarkGreen, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (myInvestments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'คุณยังไม่มีรายการลงทุน',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.modernGrey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true, // Important for ListView inside Column
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling for this ListView
              itemCount: myInvestments.length,
              itemBuilder: (context, index) {
                final investment = myInvestments[index];
                final animationDelay = Duration(milliseconds: 100 * index);
                final itemAnimation =
                    Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _walletAnimationController,
                    curve: Interval(
                      (animationDelay.inMilliseconds /
                              _walletAnimationController
                                  .duration!.inMilliseconds)
                          .clamp(0.0, 1.0),
                      1.0,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                );
                return FadeTransition(
                  opacity: itemAnimation,
                  child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.2), end: Offset.zero)
                          .animate(itemAnimation),
                      child: _buildMyInvestmentCard(context, investment)),
                );
              },
            ),
          // TODO: Add transaction history, deposit/withdraw options etc.
        ],
      ),
    );
  }

  Widget _buildMyInvestmentCard(BuildContext context, MyInvestment investment) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MyInvestmentDetailPage(investment: investment),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12), // Added for InkWell splash
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // ignore: deprecated_member_use
        color: AppColors.white,
        // ignore: deprecated_member_use
        shadowColor: AppColors.primaryGreen.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(investment.icon, size: 40, color: AppColors.primaryGreen),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(investment.name,
                        style: AppTextStyles.subtitleBold
                            .copyWith(color: AppColors.primaryDarkGreen)),
                    const SizedBox(height: 4),
                    Text('ประเภท: ${investment.assetType}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.modernDarkGrey)),
                    Text(
                        'มูลค่าปัจจุบัน: ฿${investment.currentValue.toStringAsFixed(2)}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.modernDarkGrey)),
                  ],
                ),
              ),
              const SizedBox(width: 8), // Added spacing
              Column(
                mainAxisAlignment: MainAxisAlignment.center, // Align vertically
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${investment.returnPercentage >= 0 ? '+' : ''}${investment.returnPercentage.toStringAsFixed(1)}%',
                    style: AppTextStyles.subtitleBold.copyWith(
                      fontSize: 18, // Made return percentage more prominent
                      color: investment.returnPercentage >= 0
                          ? AppColors.accentGreen
                          : AppColors.warningOrange,
                    ),
                  ),
                  Text('ผลตอบแทน',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.modernGrey)), // Label for return
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Copied _buildMyInvestmentCard from InvestmentWalletPage to InvestmentHomePage
  // to ensure consistency, as it was slightly different.
  // This is the version from InvestmentWalletPage, which seems more up-to-date.
  // The original _buildMyInvestmentCard in InvestmentHomePage has been removed.
  @override
  void dispose() {
    _walletAnimationController.dispose();
    super.dispose();
  }
}
