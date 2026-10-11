import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:haitiandollar/services/moncash_gateway_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('MoncashGatewayService Tests', () {
    test('createDeposit parses HTTP 200 response correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/deposits/create');
        return http.Response(
          jsonEncode({
            'orderId': 'HTD-DEP-999',
            'htdAmount': 100.0,
            'htgAmount': 500,
            'redirectUrl': 'https://sandbox.moncashbutton.digicelgroup.com/pay?token=xyz',
            'paymentToken': 'xyz',
            'simulated': false,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MoncashGatewayService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final result = await service.createDeposit(htdAmount: 100.0);
      expect(result.orderId, 'HTD-DEP-999');
      expect(result.htdAmount, 100.0);
      expect(result.htgAmount, 500);
      expect(result.isSimulated, isFalse);
    });

    test('createCashOut parses HTTP 200 response correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/withdrawals/create');
        return http.Response(
          jsonEncode({
            'withdrawalId': 'HTD-WTH-555',
            'htdAmount': 50.0,
            'netHtg': 242,
            'feeHtg': 7.5,
            'moncashTxId': 'MC-TXN-REAL-777',
            'simulated': false,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MoncashGatewayService(
        baseUrl: 'http://localhost:4000',
        httpClient: mockClient,
      );

      final result = await service.createCashOut(htdAmount: 50.0, phone: '37000000');
      expect(result.withdrawalId, 'HTD-WTH-555');
      expect(result.moncashTxId, 'MC-TXN-REAL-777');
      expect(result.netHtg, 242);
      expect(result.isSimulated, isFalse);
    });

    test('falls back gracefully to offline simulation if network fails', () async {
      final failingClient = MockClient((request) async {
        throw Exception('Connection refused');
      });

      final service = MoncashGatewayService(
        baseUrl: 'http://localhost:4000',
        httpClient: failingClient,
      );

      final dep = await service.createDeposit(htdAmount: 20.0);
      expect(dep.isSimulated, isTrue);
      expect(dep.htgAmount, 100);

      final wth = await service.createCashOut(htdAmount: 20.0, phone: '37000000');
      expect(wth.isSimulated, isTrue);
      expect(wth.netHtg, 97); // 100 HTG - 3%
    });
  });
}
