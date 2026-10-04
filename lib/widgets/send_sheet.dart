import 'package:flutter/material.dart';

import '../models/wallet_state.dart';
import '../screens/scanner_screen.dart';
import '../utils/qr_payload.dart';

/// Outcome of the peer-to-peer or merchant payment sheet.
class SendResult {
  const SendResult({required this.htdAmount, required this.recipient});

  /// HTD transferred.
  final double htdAmount;

  /// Destination: eight national digits or 0x wallet address.
  final String recipient;
}

/// Peer-to-peer or merchant payment: sends HTD to any Haitian phone number or on-chain address.
///
/// Accepts an optional [initialPayload] when opened directly from an external QR scan.
Future<SendResult?> showSendSheet(
  BuildContext context, {
  required double maxBalance,
  QrPayload? initialPayload,
}) {
  return showModalBottomSheet<SendResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) =>
        _SendSheet(maxBalance: maxBalance, initialPayload: initialPayload),
  );
}

class _SendSheet extends StatefulWidget {
  const _SendSheet({required this.maxBalance, this.initialPayload});

  final double maxBalance;
  final QrPayload? initialPayload;

  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  late final TextEditingController _recipientController;
  late final TextEditingController _amountController;

  late double _amount;
  late String _recipient;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPayload;
    if (initial != null) {
      _recipient = initial.walletAddress;
      _amount = initial.amount > 0 ? initial.amount : 15.0;
    } else {
      _recipient = '';
      _amount = 15.0;
    }
    _recipientController = TextEditingController(text: _recipient);
    _amountController = TextEditingController(
      text: _amount.toStringAsFixed(
        _amount.truncateToDouble() == _amount ? 0 : 2,
      ),
    );
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool _isWalletAddress(String s) => s.startsWith('0x') && s.length >= 10;

  bool get _isAddress => _isWalletAddress(_recipient);

  String? get _recipientError {
    if (_recipient.isEmpty) return null;
    if (_isAddress) return null;
    return validateHaitianMsisdn(_recipient);
  }

  bool get _isValid {
    if (_amount <= 0 || _amount > widget.maxBalance) return false;
    if (_recipient.isEmpty) return false;
    return _recipientError == null;
  }

  Future<void> _scanQr() async {
    final result = await Navigator.push<QrPayload>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _recipient = result.walletAddress;
        _recipientController.text = result.walletAddress;
        if (result.amount > 0) {
          _amount = result.amount;
          _amountController.text = result.amount.toStringAsFixed(2);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final overBalance = _amount > widget.maxBalance;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
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
            'Peer-to-peer and merchant payments carry no protocol fee · settles in seconds',
            style: TextStyle(fontSize: 11, color: Colors.white54),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _recipientController,
                  keyboardType: _isAddress
                      ? TextInputType.text
                      : TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _isAddress
                        ? 'Recipient address'
                        : 'Recipient mobile or wallet',
                    hintText: '3712 3456 or 0x...',
                    prefixText: _isAddress ? null : '+509 ',
                    prefixIcon: Icon(
                      _isAddress
                          ? Icons.account_balance_wallet_outlined
                          : Icons.person_outline,
                      size: 18,
                    ),
                    border: const OutlineInputBorder(),
                    errorText: _recipientError,
                    helperText: _isAddress
                        ? 'Settles on Base to merchant / user wallet'
                        : 'They are notified even without an HTD account',
                    helperStyle: const TextStyle(fontSize: 10.5),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _recipient = val.trim();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFCC419).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFCC419).withValues(alpha: 0.35),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFFFCC419),
                  ),
                  tooltip: 'Scan QR',
                  onPressed: _scanQr,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (HTD)',
              prefixText: 'H\$ ',
              border: const OutlineInputBorder(),
              suffixText: 'Max: ${widget.maxBalance.toStringAsFixed(2)}',
              errorText: overBalance ? 'Insufficient balance' : null,
            ),
            onChanged: (val) {
              setState(() {
                _amount = double.tryParse(val) ?? 0.0;
              });
            },
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recipient receives (5:1):',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                ),
                Text(
                  '${formatAmount(_amount * kHtgPerHtd)} HTG',
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
            onPressed: _isValid
                ? () => Navigator.pop(
                    context,
                    SendResult(
                      htdAmount: _amount,
                      recipient: _isAddress
                          ? _recipient
                          : normalizeMsisdn(_recipient),
                    ),
                  )
                : null,
            child: Text(
              overBalance
                  ? 'Insufficient balance'
                  : _recipientError != null
                  ? 'Enter valid recipient'
                  : _recipient.isEmpty
                  ? 'Enter recipient or scan QR'
                  : 'Send H\$ ${_amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
