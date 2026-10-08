import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haitiandollar/models/wallet_state.dart';
import 'package:haitiandollar/screens/rates_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('Plausibility Guard Tests', () {
    test('isPlausibleBrhRate rejects unit errors and enforces bounds', () {
      expect(isPlausibleBrhRate(1.313), isFalse);
      expect(isPlausibleBrhRate(1313052), isFalse);
      expect(isPlausibleBrhRate(131.3052), isTrue);
      expect(isPlausibleBrhRate(49.99), isFalse);
      expect(isPlausibleBrhRate(50.0), isTrue);
      expect(isPlausibleBrhRate(2000.0), isTrue);
      expect(isPlausibleBrhRate(2000.01), isFalse);
      expect(isPlausibleBrhRate(double.nan), isFalse);
      expect(isPlausibleBrhRate(double.infinity), isFalse);
      expect(isPlausibleBrhRate(double.negativeInfinity), isFalse);
    });
  });

  group('SanitizeText Security & Invariant Tests', () {
    test('sanitizeText strips bidi overrides and zero-width characters', () {
      const bidiAttack = 'John\u202EDoe';
      expect(sanitizeText(bidiAttack), 'John Doe');

      const zeroWidth = 'Mon\u200BCash';
      expect(sanitizeText(zeroWidth), 'Mon Cash');

      const bomAttack = '\uFEFF0x1234';
      expect(sanitizeText(bomAttack), '0x1234');

      const controlChars = 'Hello\u0000World\u001F!';
      expect(sanitizeText(controlChars), 'Hello World !');
    });

    test('sanitizeText respects maxLength constraint', () {
      final long = 'A' * 100;
      expect(sanitizeText(long, maxLength: 32).length, 32);
    });
  });

  group('formatAmount Formatting & Edge Case Tests', () {
    test('formatAmount handles non-finite values safely', () {
      expect(formatAmount(double.nan), 'NaN');
      expect(formatAmount(double.infinity), '∞');
      expect(formatAmount(double.negativeInfinity), '-∞');
      expect(formatAmount(1234567.89), '1,234,567.89');
      expect(formatAmount(0.0), '0.00');
    });
  });

  group('Quote Parsing & Schema Compatibility Tests', () {
    test('parses payload with reference.raw string', () {
      final json = <String, dynamic>{
        'source': 'BRH Taux du Jour',
        'date': 'Oct 7, 2026',
        'updatedAt': '2026-10-07T08:00:00Z',
        'liveScraped': true,
        'reference': <String, dynamic>{
          'raw': '130.4713',
          'htgPerUsd': 130.4713,
        },
      };

      final quote = Quote.parse(json, 'Fallback', fromNetwork: true);
      expect(quote, isNotNull);
      expect(quote!.rate, 130.4713);
      expect(quote.source, 'BRH Taux du Jour');
      expect(quote.scrapedLive, isTrue);
      expect(quote.fromNetwork, isTrue);
    });

    test('parses payload with reference.htgPerUsd numeric fallback', () {
      final json = <String, dynamic>{
        'source': 'BRH API',
        'reference': <String, dynamic>{
          'htgPerUsd': 131.25,
        },
      };

      final quote = Quote.parse(json, 'Fallback', fromNetwork: false);
      expect(quote, isNotNull);
      expect(quote!.rate, 131.25);
      expect(quote.fromNetwork, isFalse);
    });

    test('rejects corrupt rate or rate outside plausibility window', () {
      final badJson = <String, dynamic>{
        'reference': <String, dynamic>{
          'raw': '1.3047', // Unit error
        },
      };

      final quote = Quote.parse(badJson, 'Fallback', fromNetwork: true);
      expect(quote, isNull);
    });
  });

  group('RatesScreen Widget Tests', () {
    testWidgets('RatesScreen renders core cards and converter', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final wallet = WalletState(openingBalance: 200.0);

      await tester.pumpWidget(
        ChangeNotifierProvider<WalletState>.value(
          value: wallet,
          child: const MaterialApp(home: RatesScreen()),
        ),
      );

      // Verify headers
      expect(find.text('BRH Rates & Parity'), findsOneWidget);
      expect(find.text('1 HTD = 5 HTG'), findsOneWidget);
      expect(find.text('TRI-CURRENCY CALCULATOR'), findsOneWidget);
      expect(find.text('MARKET SPREAD BENCHMARKS'), findsOneWidget);
      expect(find.text('Verify on haitiandollar.com / BRH'), findsOneWidget);

      // Test converter interaction: tap a preset chip
      await tester.tap(find.text('500 HTD'));
      await tester.pump();

      // 500 HTD * 5 = 2,500.00 HTG
      expect(find.text('2,500.00'), findsOneWidget);
    });
  });
}
