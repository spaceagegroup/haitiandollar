import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haitiandollar/models/wallet_state.dart';
import 'package:haitiandollar/screens/dashboard_screen.dart';
import 'package:haitiandollar/screens/kiosk_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('BRH Verification Link & Rate Card', () {
    testWidgets('Dashboard renders BRH rate card and verify link', (
      tester,
    ) async {
      final wallet = WalletState(openingBalance: 150.0);

      await tester.pumpWidget(
        ChangeNotifierProvider<WalletState>.value(
          value: wallet,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      expect(find.text('BRH Reference Rate'), findsOneWidget);
      expect(
        find.text('1 USD = ${wallet.brhRate.toStringAsFixed(4)} HTG'),
        findsOneWidget,
      );
      expect(find.text('Verify official rates →'), findsOneWidget);
    });

    testWidgets(
      'Kiosk terminal renders exchange rate source panel and verify link',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final wallet = WalletState(openingBalance: 150.0);

        await tester.pumpWidget(
          ChangeNotifierProvider<WalletState>.value(
            value: wallet,
            child: const MaterialApp(home: KioskScreen()),
          ),
        );

        expect(find.text('Exchange rate source'), findsOneWidget);
        expect(find.text('BRH Taux du Jour'), findsOneWidget);
        expect(
          find.text('Verify on haitiandollar.com/htd#official-rates'),
          findsOneWidget,
        );
      },
    );
  });

  group('BRH quotation integrity', () {
    test('accepts realistic rates and rejects corrupt or mis-unit-ed ones', () {
      expect(isPlausibleBrhRate(130.5583), isTrue);
      expect(isPlausibleBrhRate(131.3052), isTrue);
      expect(isPlausibleBrhRate(kMinPlausibleHtgPerUsd), isTrue);
      expect(isPlausibleBrhRate(kMaxPlausibleHtgPerUsd), isTrue);

      // A units change upstream (1.313 HTG per USD) must never be shown as fact.
      expect(isPlausibleBrhRate(1.313), isFalse);
      expect(isPlausibleBrhRate(0), isFalse);
      expect(isPlausibleBrhRate(-131.31), isFalse);
      expect(isPlausibleBrhRate(1313052), isFalse);
      expect(isPlausibleBrhRate(double.nan), isFalse);
    });

    test(
      'an unread quotation reports an unverified state, not a fresh one',
      () {
        final wallet = WalletState();

        expect(wallet.ratesUpdatedAt, isNull);
        expect(wallet.quoteIsLive, isFalse);
        expect(wallet.rateStatusLabel, 'Not yet read · unverified');
      },
    );

    test('rate ages are labelled relative to now', () {
      final now = DateTime.now();

      expect(formatRateAge(now), 'just now');
      expect(
        formatRateAge(now.subtract(const Duration(minutes: 12))),
        '12 min ago',
      );
      expect(
        formatRateAge(now.subtract(const Duration(hours: 3))),
        matches(r'^\d{2}:\d{2}$'),
      );
    });
  });

  group('rate source alignment with the website', () {
    test('the official rates URL and baseline match haitiandollar.com/htd#official-rates', () {
      expect(kOfficialRatesUrl, 'https://www.haitiandollar.com/htd#official-rates');
      expect(kOfficialHtgPerUsd, 130.5583);
      expect(kMinPlausibleHtgPerUsd, 50);
      expect(kOfflineBaselineHtgPerUsd, 130.5583);
    });

    test('the cache window mirrors the website two-hour TTL', () {
      final now = DateTime(2026, 10, 3, 12);

      expect(
        isQuoteFresh(now.subtract(const Duration(minutes: 119)), now: now),
        isTrue,
      );
      expect(
        isQuoteFresh(now.subtract(const Duration(minutes: 121)), now: now),
        isFalse,
      );
      expect(isQuoteFresh(null, now: now), isFalse);
    });
  });
}
