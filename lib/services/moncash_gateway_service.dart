import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MoncashDepositResponse {
  const MoncashDepositResponse({
    required this.orderId,
    required this.htdAmount,
    required this.htgAmount,
    required this.redirectUrl,
    required this.paymentToken,
    this.isSimulated = false,
  });

  final String orderId;
  final double htdAmount;
  final int htgAmount;
  final String redirectUrl;
  final String paymentToken;
  final bool isSimulated;
}

class MoncashWithdrawalResponse {
  const MoncashWithdrawalResponse({
    required this.withdrawalId,
    required this.htdAmount,
    required this.netHtg,
    required this.feeHtg,
    required this.moncashTxId,
    this.isSimulated = false,
  });

  final String withdrawalId;
  final double htdAmount;
  final int netHtg;
  final double feeHtg;
  final String moncashTxId;
  final bool isSimulated;
}

/// Client gateway connecting the Flutter wallet to the HTD MonCash Settlement Service.
class MoncashGatewayService {
  MoncashGatewayService({
    String? baseUrl,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? (kIsWeb ? 'http://localhost:4000' : 'http://10.0.2.2:4000'),
        _client = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Requests a new MonCash deposit payment link for purchasing HTD.
  Future<MoncashDepositResponse> createDeposit({
    required double htdAmount,
    String? userAddress,
    String? phone,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/deposits/create');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'htdAmount': htdAmount,
          'userAddress': userAddress,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MoncashDepositResponse(
          orderId: data['orderId'] as String,
          htdAmount: (data['htdAmount'] as num).toDouble(),
          htgAmount: (data['htgAmount'] as num).toInt(),
          redirectUrl: data['redirectUrl'] as String,
          paymentToken: data['paymentToken'] as String,
          isSimulated: data['simulated'] as bool? ?? false,
        );
      }
    } catch (e) {
      debugPrint('MoncashGatewayService.createDeposit fallback: $e');
    }

    // Graceful offline fallback simulation
    final orderId = 'HTD-SIM-DEP-${DateTime.now().millisecondsSinceEpoch}';
    return MoncashDepositResponse(
      orderId: orderId,
      htdAmount: htdAmount,
      htgAmount: (htdAmount * 5.0).round(),
      redirectUrl: 'https://sandbox.moncashbutton.digicelgroup.com/redirect?sim=$orderId',
      paymentToken: 'sim_token_$orderId',
      isSimulated: true,
    );
  }

  /// Initiates a cash-out buyback from merchant reserve to user's MonCash phone.
  Future<MoncashWithdrawalResponse> createCashOut({
    required double htdAmount,
    required String phone,
    String? userAddress,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/withdrawals/create');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'htdAmount': htdAmount,
          'phone': phone,
          'userAddress': userAddress,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MoncashWithdrawalResponse(
          withdrawalId: data['withdrawalId'] as String,
          htdAmount: (data['htdAmount'] as num).toDouble(),
          netHtg: (data['netHtg'] as num).toInt(),
          feeHtg: (data['feeHtg'] as num).toDouble(),
          moncashTxId: data['moncashTxId'] as String,
          isSimulated: data['simulated'] as bool? ?? false,
        );
      }
    } catch (e) {
      debugPrint('MoncashGatewayService.createCashOut fallback: $e');
    }

    // Graceful offline fallback simulation
    final grossHtg = htdAmount * 5.0;
    final feeHtg = grossHtg * 0.03;
    final netHtg = (grossHtg - feeHtg).round();
    final txId = 'MC-SIM-${DateTime.now().millisecondsSinceEpoch}';

    return MoncashWithdrawalResponse(
      withdrawalId: 'HTD-WTH-${DateTime.now().millisecondsSinceEpoch}',
      htdAmount: htdAmount,
      netHtg: netHtg,
      feeHtg: feeHtg,
      moncashTxId: txId,
      isSimulated: true,
    );
  }
}
