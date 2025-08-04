import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/providers/eco_coins_provider.dart';

void main() {
  group('EcoCoinsProvider', () {
    test('initial balance is not null and not negative', () {
      final ecoCoinsProvider = EcoCoinProvider();
      expect(ecoCoinsProvider.balance, isNotNull);
      expect(ecoCoinsProvider.balance!.availableCoins >= 0, true);
    });

    test('award coins increases availableCoins', () async {
      final ecoCoinsProvider = EcoCoinProvider();
      final initial = ecoCoinsProvider.balance?.availableCoins ?? 0;
      await ecoCoinsProvider.awardCoins(amount: 10, source: 'test');
      expect(ecoCoinsProvider.balance?.availableCoins, initial + 10);
    });

    test('spend coins decreases availableCoins, not negative', () async {
      final ecoCoinsProvider = EcoCoinProvider();
      await ecoCoinsProvider.awardCoins(amount: 10, source: 'test');
      final beforeSpend = ecoCoinsProvider.balance?.availableCoins ?? 0;
      await ecoCoinsProvider.spendCoins(amount: 5, source: 'test');
      expect(ecoCoinsProvider.balance?.availableCoins, beforeSpend - 5);
      expect(ecoCoinsProvider.balance!.availableCoins >= 0, true);
    });

    test(
        'spend more coins than available returns false and does not go negative',
        () async {
      final ecoCoinsProvider = EcoCoinProvider();
      final result =
          await ecoCoinsProvider.spendCoins(amount: 9999, source: 'test');
      expect(result, false);
      expect(ecoCoinsProvider.balance!.availableCoins >= 0, true);
    });

    test('refresh loads mock data if not logged in', () async {
      final ecoCoinsProvider = EcoCoinProvider();
      await ecoCoinsProvider.refresh();
      expect(ecoCoinsProvider.balance, isNotNull);
    });

    test('error is set on spendCoins with invalid input', () async {
      final ecoCoinsProvider = EcoCoinProvider();
      await ecoCoinsProvider.spendCoins(amount: -1, source: 'test');
      expect(ecoCoinsProvider.error, isNotNull);
    });

    test('mission progress and available/completed missions', () async {
      final ecoCoinsProvider = EcoCoinProvider();
      expect(ecoCoinsProvider.availableMissions, isA<List>());
      expect(ecoCoinsProvider.completedMissions, isA<List>());
    });
  });
}
