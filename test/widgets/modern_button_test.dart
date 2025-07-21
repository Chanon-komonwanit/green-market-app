import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/widgets/modern_button.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('ModernButton displays label and triggers onPressed',
      (WidgetTester tester) async {
    bool pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: ModernButton(
        label: 'Click Me',
        onPressed: () {
          pressed = true;
        },
      ),
    ));
    expect(find.text('Click Me'), findsOneWidget);
    await tester.tap(find.text('Click Me'));
    expect(pressed, true);
  });

  testWidgets('ModernButton shows loading indicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ModernButton(
        label: 'Loading',
        isLoading: true,
        onPressed: () {},
      ),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ModernButton is disabled', (WidgetTester tester) async {
    bool pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: ModernButton(
        label: 'Disabled',
        isDisabled: true,
        onPressed: () {
          pressed = true;
        },
      ),
    ));
    await tester.tap(find.text('Disabled'));
    expect(pressed, false);
  });

  testWidgets('ModernButton shows left and right icons',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ModernButton(
        label: 'Icon',
        iconLeft: const Icon(Icons.star),
        iconRight: const Icon(Icons.check),
        onPressed: () {},
      ),
    ));
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('ModernButton is accessible', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ModernButton(
        label: 'Accessible',
        semanticLabel: 'Accessible Button',
        onPressed: () {},
      ),
    ));
    expect(find.bySemanticsLabel('Accessible Button'), findsOneWidget);
  });
}
