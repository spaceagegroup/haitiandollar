import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/wallet_state.dart';

/// Universal proof-of-settlement modal.
///
/// Shared by every money movement in the app (deposit, cash-out, P2P payment,
/// MFI loan repayment) so a holder always sees the same six facts: what moved,
/// its gourde principal at the fixed invariant, where it went, when, whether it
/// was broadcast, and the transaction hash. Loan receipts additionally carry the
/// borrower's loan account so the MFI can allocate the payment.
Future<void> showReceiptDialog(
  BuildContext context, {
  required TxnReceipt receipt,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _ReceiptSheet(receipt: receipt),
  );
}

class _ReceiptSheet extends StatelessWidget {
  const _ReceiptSheet({required this.receipt});

  final TxnReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final accent = receipt.isLive
        ? const Color(0xFF2F9E44)
        : const Color(0xFFF59F00);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SingleChildScrollView(
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
              const SizedBox(height: 18),

              // Settlement mark
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.7, end: 1),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.14),
                      border: Border.all(color: accent.withValues(alpha: 0.45)),
                    ),
                    child: Icon(Icons.check_rounded, color: accent, size: 30),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                receipt.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatHtd(receipt.htdAmount),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFCC419),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '≈ ${formatAmount(receipt.htgEquivalent)} HTG at 5 Goud = 1 H\$',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: Colors.white54),
              ),
              const SizedBox(height: 18),

              _StatusPill(isLive: receipt.isLive),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    _Row(label: 'Beneficiary', value: receipt.counterparty),
                    if (receipt.loanId != null)
                      _Row(
                        label: 'Loan account',
                        value: receipt.loanId!,
                        highlight: true,
                      ),
                    if (receipt.feeHtd > 0)
                      _Row(
                        label: 'Fee (${receipt.feeRateLabel})',
                        value: '- ${formatHtd(receipt.feeHtd)}',
                      ),
                    if (receipt.feeHtd > 0)
                      _Row(
                        label: 'Net gourde payout',
                        value: '${formatAmount(receipt.netHtgPayout)} HTG',
                      ),
                    _Row(label: 'Settled', value: receipt.formattedTimestamp),
                    _Row(
                      label: 'Transaction',
                      value: compactAddress(receipt.txHash, lead: 10, tail: 8),
                      monospace: true,
                      onCopy: () => Clipboard.setData(
                        ClipboardData(text: receipt.txHash),
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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  receipt.isLive
                      ? 'Settled on-chain · retained in your activity history'
                      : 'Testnet settlement · no mainnet funds moved',
                  style: const TextStyle(fontSize: 10.5, color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final accent = isLive ? const Color(0xFF2F9E44) : const Color(0xFFF59F00);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLive ? Icons.verified_user_outlined : Icons.science_outlined,
              size: 13,
              color: accent,
            ),
            const SizedBox(width: 6),
            Text(
              isLive ? 'CONFIRMED ON-CHAIN' : 'TESTNET SETTLEMENT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.monospace = false,
    this.highlight = false,
    this.onCopy,
  });

  final String label;
  final String value;
  final bool monospace;
  final bool highlight;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Colors.white54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontFamily: monospace ? 'monospace' : null,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? const Color(0xFFFCC419) : Colors.white,
              ),
            ),
          ),
          if (onCopy != null)
            GestureDetector(
              onTap: onCopy,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 8, top: 1),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: Colors.white38,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
