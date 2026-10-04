import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:haitiandollar/main.dart';
import 'package:haitiandollar/models/wallet_state.dart';

void main() {
  group('protocol economics', () {
    test('100 HTD redeems to 485 HTG after the 3% bridge fee', () {
      final wallet = WalletState(openingBalance: 1000);

      expect(wallet.htgFor(100), 500);
      expect(wallet.bridgeFeeFor(100), closeTo(3, 1e-9));
      expect(wallet.netHtgPayoutFor(100), closeTo(485, 1e-9));
    });

    test('buy then sell returns the balance and records both receipts', () {
      final wallet = WalletState(openingBalance: 0);

      final buy = wallet.applyBuy(100, method: 'Authorized agent (cash)');
      expect(wallet.balance, 100);
      expect(buy.htgEquivalent, 500);

      final sell = wallet.applySell(htdAmount: 100, msisdn: '37123456');
      expect(wallet.balance, closeTo(0, 1e-9));
      expect(sell.feeHtd, closeTo(3, 1e-9));
      expect(sell.netHtgPayout, closeTo(485, 1e-9));
      expect(wallet.ledger.length, 2);
      // Newest first.
      expect(wallet.ledger.first.kind, TxnKind.sell);
    });

    test('a transfer larger than the balance is rejected', () {
      final wallet = WalletState(openingBalance: 10);

      expect(
        () => wallet.applySend(htdAmount: 11, recipient: '37123456'),
        throwsArgumentError,
      );
      expect(wallet.balance, 10);
    });

    test('peer-to-peer and merchant transfers carry their published fees', () {
      final wallet = WalletState(openingBalance: 500);

      final send = wallet.applySend(htdAmount: 10, recipient: '37123456');
      expect(send.feeHtd, 0);
      expect(wallet.balance, 490);

      final charge = wallet.applyMerchantCharge(htdAmount: 100);
      expect(charge.feeHtd, closeTo(0.5, 1e-9));
      expect(charge.feeRateLabel, '0.5%');
      // The 0.5% is withheld, so the credit matches the terminal's "You receive"
      // line and the receipt's net payout.
      expect(wallet.balance, closeTo(589.5, 1e-9));
      expect(charge.netHtgPayout, closeTo(497.5, 1e-9));
    });

    test('an address recipient is compacted and stripped of overrides', () {
      final wallet = WalletState(openingBalance: 500);
      const address = '0x71C8394A84e52514d7a9bA7879e604f323B049B2';

      final receipt = wallet.applySend(htdAmount: 5, recipient: address);
      expect(receipt.counterparty, '0x71C839…B049B2');
      expect(receipt.counterparty, isNot(startsWith('+509')));

      // A right-to-left override must not survive into the value the payer is
      // asked to verify.
      final spoofed = wallet.applySend(
        htdAmount: 5,
        recipient: '0x71C8\u202E394A84e52514d7a9bA7879e604f323B049B2',
      );
      expect(spoofed.counterparty.contains('\u202E'), isFalse);
    });
  });

  group('loan repayment', () {
    test('preserves the loan ID and binds the partner settlement wallet', () {
      final wallet = WalletState(openingBalance: 500);
      final mfi = WalletState.availableMfis.first;

      final receipt = wallet.applyLoanRepayment(
        htdAmount: 30,
        mfiName: mfi.name,
        mfiWallet: mfi.activeAddress,
        loanId: '  FKZ-8821-09  ',
      );

      expect(receipt.loanId, 'FKZ-8821-09');
      expect(receipt.kind, TxnKind.loan);
      expect(receipt.counterparty, contains(compactAddress(mfi.activeAddress)));
      expect(receipt.htgEquivalent, 150);
      expect(wallet.balance, 470);
    });

    test('requires a loan ID', () {
      final wallet = WalletState(openingBalance: 500);
      final mfi = WalletState.availableMfis.first;

      expect(
        () => wallet.applyLoanRepayment(
          htdAmount: 10,
          mfiName: mfi.name,
          mfiWallet: mfi.activeAddress,
          loanId: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('refuses a partner with no active settlement wallet', () {
      final wallet = WalletState(openingBalance: 500);

      expect(
        () => wallet.applyLoanRepayment(
          htdAmount: 10,
          mfiName: 'Unvetted lender',
          mfiWallet: '',
          loanId: 'FKZ-1',
        ),
        throwsArgumentError,
      );
    });

    test('only vetted institutions are selectable', () {
      expect(WalletState.availableMfis, isNotEmpty);
      expect(WalletState.availableMfis.first.isLive, isTrue);
      expect(
        WalletState.availableMfis.every((m) => m.activeAddress.isNotEmpty),
        isTrue,
      );
      expect(WalletState.pendingMfis.every((m) => !m.isLive), isTrue);
    });
  });

  group('input hygiene', () {
    test('Haitian mobile numbers are validated and normalised', () {
      expect(validateHaitianMsisdn('3712 3456'), isNull);
      expect(validateHaitianMsisdn('+509 4455 6677'), isNull);
      expect(validateHaitianMsisdn(''), isNotNull);
      expect(validateHaitianMsisdn('371234'), isNotNull);
      expect(validateHaitianMsisdn('27123456'), isNotNull);

      expect(normalizeMsisdn('+509 3712 3456'), '37123456');
      expect(maskMsisdn('37123456'), '+509 3712 3456');
    });

    test('sanitizeText strips control characters and collapses whitespace', () {
      expect(sanitizeText('  Fork\n\tz  '), 'Fork z');
      expect(sanitizeText('aaaaaaaaaaaa', maxLength: 5), 'aaaaa');
      // Directional overrides are stripped too, so a scanned value cannot be
      // displayed reordered.
      expect(sanitizeText('0x1\u202E2'), '0x1 2');
      expect(sanitizeText('a\u200Bb'), 'a b');
    });

    test('amounts are grouped for display', () {
      expect(formatAmount(12480), '12,480.00');
      expect(formatAmount(485), '485.00');
      expect(formatHtd(30), 'H\$ 30.00');
      // Non-finite and exponential values must not be comma-mangled.
      expect(formatAmount(double.infinity), '∞');
      expect(formatAmount(double.negativeInfinity), '-∞');
      expect(formatAmount(double.nan), 'NaN');
      expect(formatAmount(1e25), '1e+25');
    });
  });

  group('shell', () {
    testWidgets('consumer dashboard shows the fixed parity and balance', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => WalletState(),
          child: const HtdApp(),
        ),
      );
      await tester.pump();

      expect(find.text('HAITIAN DOLLAR'), findsOneWidget);
      expect(find.text('1 HTD = 5 HTG. Fixed.'), findsOneWidget);
      expect(find.textContaining('128.50'), findsWidgets);
      expect(find.text('Buy HTD'), findsOneWidget);
      expect(find.text('Loan repayment'), findsOneWidget);
    });

    testWidgets(
      'tapping Loan repayment opens loan sheet without render errors',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => WalletState(),
            child: const HtdApp(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Loan repayment'));
        await tester.pumpAndSettle();

        expect(find.text('Microfinance Loan Repayment'), findsOneWidget);
        expect(find.text('Participating Institution'), findsOneWidget);
      },
    );

    testWidgets('switching mode shows the agent terminal', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final wallet = WalletState();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(value: wallet, child: const HtdApp()),
      );

      wallet.setMode(AppMode.kiosk);
      await tester.pumpAndSettle();

      expect(find.text('AGENT TERMINAL'), findsOneWidget);
      expect(find.text('Published fee schedule'), findsOneWidget);
      expect(find.text('Phase 1 guardrails'), findsOneWidget);
    });
  });
}
