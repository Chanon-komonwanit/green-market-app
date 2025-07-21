// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:green_market/services/firebase_service.dart';
import 'package:green_market/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Import FlChart

class AdminDashboardScreen extends StatefulWidget {
  final TabController? tabController;

  const AdminDashboardScreen({super.key, this.tabController});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Widget _buildStatisticCard(
      BuildContext context,
      String title,
      Stream<int> stream,
      IconData icon,
      Color iconColor,
      FirebaseService firebaseService,
      {VoidCallback? onTap,
      String? subtitle}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 40.0, color: iconColor),
              const SizedBox(height: 12.0),
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4.0),
                Text(subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 8.0),
              StreamBuilder<int>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                        height: 24,
                        child: Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    color: theme.colorScheme.primary))));
                  }
                  if (snapshot.hasError) {
                    firebaseService.logger.e(
                        'Error in StreamBuilder for $title: ${snapshot.error}');
                    return Text('N/A',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(color: theme.colorScheme.error));
                  }
                  return Text(
                    snapshot.data?.toString() ?? '0',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'ภาพรวมระบบ',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16.0),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.1,
              children: <Widget>[
                _buildStatisticCard(
                  context,
                  'ผู้ใช้ทั้งหมด', // Corrected: Already correct
                  firebaseService.getTotalUsersCount().asStream(),
                  Icons.people_alt_outlined,
                  theme.colorScheme.primary,
                  firebaseService,
                  onTap: () => widget.tabController?.animateTo(6),
                ),
                _buildStatisticCard(
                  context,
                  'ผู้ขายทั้งหมด', // Corrected: Already correct
                  firebaseService.getTotalApprovedSellersCount().asStream(),
                  Icons.storefront_outlined,
                  Colors.green.shade600,
                  firebaseService,
                  onTap: () => widget.tabController?.animateTo(6),
                ),
                _buildStatisticCard(
                  context,
                  'สินค้าในระบบ', // Corrected: Already correct
                  firebaseService.getTotalApprovedProductsCount().asStream(),
                  Icons.inventory_2_outlined,
                  Colors.orange.shade700,
                  firebaseService,
                  onTap: () => widget.tabController?.animateTo(2),
                ),
                _buildStatisticCard(
                  context,
                  'คำสั่งซื้อทั้งหมด', // Corrected: Already correct
                  firebaseService.getTotalOrdersCount().asStream(),
                  Icons.receipt_long_outlined,
                  Colors.blue.shade600,
                  firebaseService,
                  onTap: () => widget.tabController?.animateTo(3),
                ),
                _buildStatisticCard(
                  context,
                  'สินค้าที่รออนุมัติ', // Corrected: Already correct
                  firebaseService.getPendingProductsCountStream(),
                  Icons.hourglass_top_outlined,
                  Colors.amber.shade800,
                  firebaseService,
                  onTap: () => widget.tabController?.animateTo(2),
                ),
                _buildStatisticCard(
                  context,
                  'คำขอเป็นผู้ขาย', // Corrected: Already correct
                  firebaseService.getPendingSellerApplicationsCountStream(),
                  Icons.person_add_alt_1_outlined,
                  Colors.purple.shade400,
                  firebaseService,
                  onTap: () => widget.tabController?.animateTo(7),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Text(
              'สถิติภาพรวม',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16.0),
            _buildOverviewChart(context, firebaseService),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewChart(
      BuildContext context, FirebaseService firebaseService) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<int>>(
            future: Future.wait([
              firebaseService.getTotalUsersCount(),
              firebaseService.getTotalApprovedSellersCount(),
              firebaseService.getTotalApprovedProductsCount(),
              firebaseService.getTotalOrdersCount(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(child: Text('ไม่สามารถโหลดข้อมูลชาร์ตได้'));
              }

              final data = snapshot.data!;
              final users = data[0].toDouble();
              final sellers = data[1].toDouble();
              final products = data[2].toDouble();
              final orders = data[3].toDouble();

              final maxVal = [users, sellers, products, orders]
                  .reduce((a, b) => a > b ? a : b);

              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal > 0 ? maxVal * 1.2 : 10,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String title;
                        switch (group.x.toInt()) {
                          case 0:
                            title = 'Users';
                            break;
                          case 1:
                            title = 'Sellers';
                            break;
                          case 2:
                            title = 'Products';
                            break;
                          case 3:
                            title = 'Orders';
                            break;
                          default:
                            throw Error();
                        }
                        return BarTooltipItem(
                          '$title\n',
                          const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          children: <TextSpan>[
                            TextSpan(
                              text: (rod.toY - 1).toInt().toString(),
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14);
                          Widget text;
                          switch (value.toInt()) {
                            case 0:
                              text = const Text('Users', style: style);
                              break;
                            case 1:
                              text = const Text('Sellers', style: style);
                              break;
                            case 2:
                              text = const Text('Products', style: style);
                              break;
                            case 3:
                              text = const Text('Orders', style: style);
                              break;
                            default:
                              text = const Text('', style: style);
                              break;
                          }
                          // fl_chart v1.x: meta มี axisSide ใน meta, ต้องส่ง meta เท่านั้น
                          return SideTitleWidget(
                              space: 16, meta: meta, child: text);
                        },
                        reservedSize: 42,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                          toY: users + 1,
                          color: theme.colorScheme
                              .primary) // Corrected: Already correct
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                          toY: sellers + 1, color: Colors.green.shade600)
                    ]),
                    BarChartGroupData(x: 2, barRods: [
                      BarChartRodData(
                          toY: products + 1, color: Colors.orange.shade700)
                    ]),
                    BarChartGroupData(x: 3, barRods: [
                      BarChartRodData(
                          toY: orders + 1, color: Colors.blue.shade600)
                    ]),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
