import 'package:flutter/material.dart';
import 'package:green_market/widgets/order_status_badge.dart';

/// ตัวอย่างการใช้งาน OrderStatusBadge พร้อม dark mode toggle
class OrderStatusBadgeDemoWithTheme extends StatefulWidget {
  const OrderStatusBadgeDemoWithTheme({super.key});

  @override
  State<OrderStatusBadgeDemoWithTheme> createState() =>
      _OrderStatusBadgeDemoWithThemeState();
}

class _OrderStatusBadgeDemoWithThemeState
    extends State<OrderStatusBadgeDemoWithTheme> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Order Status Badge Demo'),
          actions: [
            IconButton(
              icon: Icon(_dark ? Icons.dark_mode : Icons.light_mode),
              onPressed: () => setState(() => _dark = !_dark),
              tooltip: 'Toggle Theme',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            OrderStatusBadge(status: 'pending_payment'),
            SizedBox(height: 16),
            OrderStatusBadge(status: 'processing'),
            SizedBox(height: 16),
            OrderStatusBadge(status: 'shipped'),
            SizedBox(height: 16),
            OrderStatusBadge(status: 'delivered'),
            SizedBox(height: 16),
            OrderStatusBadge(status: 'cancelled'),
            SizedBox(height: 16),
            OrderStatusBadge(status: 'unknown'),
          ],
        ),
      ),
    );
  }
}
