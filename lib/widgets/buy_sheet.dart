import 'package:flutter/material.dart';

import '../models/wallet_state.dart';

/// Outcome of the cash-in sheet.
class BuyResult {
  const BuyResult({required this.htdAmount, required this.method});

  /// HTD minted to the holder.
  final double htdAmount;

  /// Channel the gourdes arrived through.
  final String method;
}

/// Cash-in: a holder buys HTD with gourdes at the fixed 5:1 convention.
///
/// [maxBalance] is the holder's current HTD balance; it does not constrain a
/// deposit, but it lets the sheet show the resulting balance. The protocol
/// charges no deposit fee, so nothing is deducted here.
Future<BuyResult?> showBuySheet(
  BuildContext context, {
  required double maxBalance,
}) async {
  const methods = <String>[
    'Authorized agent (cash)',
    'MonCash transfer',
    'Correspondent bank transfer',
  ];
  const presets = <double>[25, 50, 100, 250];

  double amount = 25.0;
  String method = methods.first;
  // The visible field is the source of truth for the user, so the preset chips
  // write through the controller rather than only into [amount].
  final controller = TextEditingController(text: '25');

  try {
    return await showModalBottomSheet<BuyResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final htgCost = amount * kHtgPerHtd;
          final valid = amount > 0 && amount.isFinite;

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
                const _DragHandle(),
                const SizedBox(height: 14),
                const Text(
                  'Buy HTD',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Minted against the pooled gourde reserve · 1 HTD = 5 HTG, fixed',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(
                    labelText: 'Funding channel',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.storefront_outlined, size: 18),
                  ),
                  dropdownColor: const Color(0xFF1E1E1E),
                  items: methods
                      .map(
                        (m) => DropdownMenuItem<String>(
                          value: m,
                          child: Text(m, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => method = val);
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Deposit amount (HTD)',
                    prefixText: 'H\$ ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) =>
                      setModalState(() => amount = double.tryParse(val) ?? 0.0),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  children: presets.map((preset) {
                    return ActionChip(
                      backgroundColor: Colors.white10,
                      side: BorderSide.none,
                      label: Text(
                        'H\$ ${preset.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () => setModalState(() {
                        amount = preset;
                        controller.text = preset.toStringAsFixed(0);
                      }),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                _SummaryCard(
                  rows: <(String, String)>[
                    ('You pay', '${formatAmount(htgCost)} HTG'),
                    ('Deposit fee', 'None'),
                    (
                      'Balance after deposit',
                      formatHtd(maxBalance + (valid ? amount : 0)),
                    ),
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
                          BuyResult(htdAmount: amount, method: method),
                        )
                      : null,
                  child: Text(
                    valid
                        ? 'Deposit H\$ ${amount.toStringAsFixed(2)}'
                        : 'Enter an amount',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  } finally {
    controller.dispose();
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

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

/// Shared quote card used by every sheet to show the invariant breakdown.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});

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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: row.$1 == 'You pay'
                            ? Colors.white
                            : const Color(0xFFFCC419),
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
