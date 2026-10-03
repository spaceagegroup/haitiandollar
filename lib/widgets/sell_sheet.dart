import 'package:flutter/material.dart';

import '../models/wallet_state.dart';

/// Outcome of the cash-out sheet.
class SellResult {
  const SellResult({
    required this.htdAmount,
    required this.msisdn,
    required this.feeHtd,
    required this.htgPayout,
    required this.channel,
  });

  /// HTD burned by the redemption.
  final double htdAmount;

  /// Destination mobile number.
  final String msisdn;

  /// Bridge fee retained in HTD (3%).
  final double feeHtd;

  /// Gourdes disbursed to the holder after the fee.
  final double htgPayout;

  /// `MonCash wallet` or `Authorized agent`.
  final String channel;
}

/// Cash-out: burns HTD and disburses gourdes off-chain.
///
/// Two rails exist — direct to a MonCash wallet, or cash from an authorized
/// agent. The 3% bridge fee is retained in HTD and converted at the same fixed
/// 5:1 convention (100 HTD redeems to 485 HTG).
Future<SellResult?> showSellSheet(
  BuildContext context, {
  required double maxBalance,
}) {
  const channels = <String>['MonCash wallet', 'Authorized agent (cash)'];
  double amount = 20.0;
  String msisdn = '';
  String channel = channels.first;

  return showModalBottomSheet<SellResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final fee = amount * kBridgeFeeRate;
        final net = amount - fee;
        final htgPayout = net * kHtgPerHtd;
        final toAgent = channel == channels.last;
        final phoneError = toAgent ? null : validateHaitianMsisdn(msisdn);
        final bool valid =
            amount > 0 &&
            amount <= maxBalance &&
            (toAgent || phoneError == null);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Handle(),
              const SizedBox(height: 14),
              const Text(
                'Cash out HTD',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Burned on Base, disbursed off-chain · 3% bridge fee',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: channel,
                decoration: const InputDecoration(
                  labelText: 'Payout rail',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                dropdownColor: const Color(0xFF1E1E1E),
                items: channels
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => channel = val);
                },
              ),

              const SizedBox(height: 12),

              if (!toAgent) ...[
                TextFormField(
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'MonCash number',
                    hintText: '3712 3456',
                    prefixText: '+509 ',
                    prefixIcon: const Icon(Icons.phone_android, size: 18),
                    border: const OutlineInputBorder(),
                    errorText: msisdn.isEmpty ? null : phoneError,
                  ),
                  onChanged: (val) => setModalState(() => msisdn = val),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: const Text(
                    'The customer collects cash from an authorized agent. '
                    'The agent releases gourdes against this redemption.',
                    style: TextStyle(fontSize: 11.5, color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                initialValue: '20',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Redemption amount (HTD)',
                  prefixText: 'H\$ ',
                  border: const OutlineInputBorder(),
                  suffixText: 'Max: ${maxBalance.toStringAsFixed(2)}',
                  errorText: amount > maxBalance
                      ? 'Insufficient balance'
                      : null,
                ),
                onChanged: (val) =>
                    setModalState(() => amount = double.tryParse(val) ?? 0.0),
              ),

              const SizedBox(height: 14),

              _Quote(
                rows: <(String, String)>[
                  ('Gourde value', '${formatAmount(amount * kHtgPerHtd)} HTG'),
                  (
                    'Bridge fee (3%)',
                    '- ${formatAmount(fee)} H\$ / ${formatAmount(fee * kHtgPerHtd)} HTG',
                  ),
                  ('Net payout', '${formatAmount(htgPayout)} HTG'),
                ],
              ),

              const SizedBox(height: 18),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCC419),
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: valid
                    ? () => Navigator.pop(
                        ctx,
                        SellResult(
                          htdAmount: amount,
                          msisdn: normalizeMsisdn(msisdn),
                          feeHtd: fee,
                          htgPayout: htgPayout,
                          channel: channel,
                        ),
                      )
                    : null,
                child: Text(
                  toAgent
                      ? 'Generate agent redemption'
                      : amount > maxBalance
                      ? 'Insufficient balance'
                      : phoneError != null
                      ? 'Enter MonCash number'
                      : 'Cash out H\$ ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.$1,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                    Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFCC419),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
