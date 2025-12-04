import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/providers/eco_coins_provider.dart';
import '../mocks/mock_eco_coins_service.dart';

void main() {
  group('EcoCoinsProvider', () {
    late MockEcoCoinsService mockService;
    late EcoCoinProvider provider;

    setUp(() {
      mockService = MockEcoCoinsService();
      provider = EcoCoinProvider(ecoCoinsService: mockService);
    });

    tearDown(() {
      mockService.reset();
      provider.dispose();
    });

    test('initial balance is not null and not negative', () async {
      await provider.initialize();

      expect(provider.balance, isNotNull);
      expect(provider.balance!.availableCoins >= 0, true);
    });
    test('award coins increases availableCoins', () async {
      await provider.initialize();

      final initial = provider.balance?.availableCoins ?? 0;
      await provider.awardCoins(amount: 10, source: 'test');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.balance?.availableCoins, initial + 10);
    });

    test('spend coins decreases availableCoins, not negative', () async {
      await provider.initialize();

      await provider.awardCoins(amount: 10, source: 'test');
      await Future.delayed(const Duration(milliseconds: 50));
      final beforeSpend = provider.balance?.availableCoins ?? 0;
      await provider.spendCoins(amount: 5, source: 'test');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.balance?.availableCoins, beforeSpend - 5);
      expect(provider.balance!.availableCoins >= 0, true);
    });

    test(
        'spend more coins than available returns false and does not go negative',
        () async {
      await provider.initialize();

      final result = await provider.spendCoins(amount: 9999, source: 'test');

      expect(result, false);
      expect(provider.balance!.availableCoins >= 0, true);
    });

    test('refresh loads mock data if not logged in', () async {
      await provider.initialize(); // Initialize streams first
      await provider.refresh();

      expect(provider.balance, isNotNull);
    });

    test('error is set on spendCoins with invalid input', () async {
      provider.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      await provider.spendCoins(amount: -1, source: 'test');

      expect(provider.error, isNotNull);
    });

    test('mission progress and available/completed missions', () {
      provider.initialize();

      expect(provider.availableMissions, isA<List>());
      expect(provider.completedMissions, isA<List>());
    });
  });
}
