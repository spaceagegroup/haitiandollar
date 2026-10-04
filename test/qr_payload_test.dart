import 'package:flutter_test/flutter_test.dart';
import 'package:haitiandollar/utils/qr_payload.dart';

void main() {
  group('QrPayload', () {
    test('encodes and decodes standard invoice payload', () {
      final payload = QrPayload(
        walletAddress: '0x71C8394A84e52514d7a9bA7879e604f323B049B2',
        amount: 25.00,
        reference: 'INV-1728403200',
      );

      final encoded = payload.encode();
      expect(
        encoded,
        'htd:0x71C8394A84e52514d7a9bA7879e604f323B049B2?amount=25.00&ref=INV-1728403200',
      );

      final decoded = QrPayload.decode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.walletAddress, payload.walletAddress);
      expect(decoded.amount, 25.00);
      expect(decoded.reference, 'INV-1728403200');
    });

    test('decodes address-only htd: URI', () {
      const raw = 'htd:0x71C8394A84e52514d7a9bA7879e604f323B049B2';
      final decoded = QrPayload.decode(raw);
      expect(decoded, isNotNull);
      expect(
        decoded!.walletAddress,
        '0x71C8394A84e52514d7a9bA7879e604f323B049B2',
      );
      expect(decoded.amount, 0.0);
      expect(decoded.reference, '');
    });

    test('decodes raw 0x address', () {
      const raw = '0x71C8394A84e52514d7a9bA7879e604f323B049B2';
      final decoded = QrPayload.decode(raw);
      expect(decoded, isNotNull);
      expect(decoded!.walletAddress, raw);
      expect(decoded.amount, 0.0);
    });

    test('returns null for malformed strings', () {
      expect(QrPayload.decode(''), isNull);
      expect(QrPayload.decode('invalid-scheme:0x123'), isNull);
      expect(QrPayload.decode('htd:'), isNull);
    });
  });
}
