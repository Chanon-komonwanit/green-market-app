import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/widgets/order_status_badge.dart';

void main() {
  testWidgets('OrderStatusBadge golden test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: const [
              OrderStatusBadge(status: 'pending_payment'),
              SizedBox(height: 8),
              OrderStatusBadge(status: 'processing'),
              SizedBox(height: 8),
              OrderStatusBadge(status: 'shipped'),
              SizedBox(height: 8),
              OrderStatusBadge(status: 'delivered'),
              SizedBox(height: 8),
              OrderStatusBadge(status: 'cancelled'),
              SizedBox(height: 8),
              OrderStatusBadge(status: 'unknown'),
            ],
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Column),
      matchesGoldenFile('order_status_badge_golden.png'),
    );
  });
}
