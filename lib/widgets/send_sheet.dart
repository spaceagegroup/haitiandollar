import 'package:flutter/material.dart';

import '../models/wallet_state.dart';

/// Outcome of the peer-to-peer sheet.
class SendResult {
  const SendResult({required this.htdAmount, required this.recipient});

  /// HTD transferred.
  final double htdAmount;

  /// Destination mobile number, normalised to eight national digits.
  final String recipient;
}

/// Peer-to-peer payment: HTD to any Haitian mobile number, free of charge.
///
/// The recipient does not need an account to be notified, so the destination is
/// taken only from the field the holder actually typed — there is no fallback
/// number to silently absorb a valid-looking transfer.
Future<SendResult?> showSendSheet(
  BuildContext context, {
  required double maxBalance,
}) {
  double amount = 15.0;
  String recipient = '';

  return showModalBottomSheet<SendResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final phoneError = validateHaitianMsisdn(recipient);
        final overBalance = amount > maxBalance;
        final bool valid =
            amount > 0 &&
            !overBalance &&
            recipient.isNotEmpty &&
            phoneError == null;

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
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Send HTD',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Peer-to-peer transfers carry no protocol fee · settles in seconds',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(height: 16),

              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Recipient mobile number',
                  hintText: '3712 3456',
                  prefixText: '+509 ',
                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                  border: const OutlineInputBorder(),
                  errorText: recipient.isEmpty ? null : phoneError,
                  helperText: 'They are notified even without an HTD account',
                  helperStyle: const TextStyle(fontSize: 10.5),
                ),
                onChanged: (val) => setModalState(() => recipient = val),
              ),

              const SizedBox(height: 12),

              TextFormField(
                initialValue: '15',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount (HTD)',
                  prefixText: 'H\$ ',
                  border: const OutlineInputBorder(),
                  suffixText: 'Max: ${maxBalance.toStringAsFixed(2)}',
                  errorText: overBalance ? 'Insufficient balance' : null,
                ),
                onChanged: (val) =>
                    setModalState(() => amount = double.tryParse(val) ?? 0.0),
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recipient receives (5:1):',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    Text(
                      '${formatAmount(amount * kHtgPerHtd)} HTG',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFCC419),
                      ),
                    ),
                  ],
                ),
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
                        SendResult(
                          htdAmount: amount,
                          recipient: normalizeMsisdn(recipient),
                        ),
                      )
                    : null,
                child: Text(
                  overBalance
                      ? 'Insufficient balance'
                      : phoneError != null
                      ? 'Enter recipient number'
                      : 'Send H\$ ${amount.toStringAsFixed(2)}',
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
