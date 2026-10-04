import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haitiandollar/models/wallet_state.dart';
import 'package:haitiandollar/screens/kiosk_screen.dart';
import 'package:haitiandollar/utils/qr_payload.dart';
import 'package:haitiandollar/widgets/qr_display.dart';
import 'package:haitiandollar/widgets/send_sheet.dart';
import 'package:provider/provider.dart';

void main() {
  group('QR Integration & Kiosk', () {
    testWidgets('KioskScreen renders QrDisplay with invoice payload', (
      tester,
    ) async {
      final wallet = WalletState(openingBalance: 200.0);

      await tester.pumpWidget(
        ChangeNotifierProvider<WalletState>.value(
          value: wallet,
          child: const MaterialApp(home: KioskScreen()),
        ),
      );

      // Kiosk opens with default 100 HTD invoice
      expect(find.text('Dynamic QR invoice in H\$'), findsNothing);
      expect(find.byType(QrDisplay), findsOneWidget);

      final qrWidget = tester.widget<QrDisplay>(find.byType(QrDisplay));
      expect(qrWidget.payload.walletAddress, wallet.walletAddress);
      expect(qrWidget.payload.amount, 100.0);
      expect(qrWidget.payload.reference.startsWith('INV-'), isTrue);
    });

    testWidgets('Send sheet pre-populates with initial payload from QR scan', (
      tester,
    ) async {
      final payload = QrPayload(
        walletAddress: '0x71C8394A84e52514d7a9bA7879e604f323B049B2',
        amount: 45.0,
        reference: 'INV-TEST-45',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSendSheet(
                  context,
                  maxBalance: 100.0,
                  initialPayload: payload,
                ),
                child: const Text('Open Send Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Send Sheet'));
      await tester.pumpAndSettle();

      // Recipient address and amount should be pre-filled
      expect(find.text(payload.walletAddress), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('Send H\$ 45.00'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });
  });
}
