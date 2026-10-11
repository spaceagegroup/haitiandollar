import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/wallet_state.dart';
import '../utils/qr_payload.dart';
import '../widgets/qr_display.dart';
import '../widgets/receipt_dialog.dart';

import 'package:url_launcher/url_launcher.dart';
import '../theme/htd_theme.dart';

/// Agent / merchant terminal.
///
/// Implements the Phase 1 closed-loop role: a merchant raises a dynamic QR
/// invoice in H$, the customer pays in HTD, and 0.5% merchant processing is
/// retained. The pilot's published guardrails and fee schedule are shown inline
/// so an operator can quote a customer without leaving the screen.
class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  double _invoiceHtd = 100;

  Future<void> _settleCharge(WalletState wallet) async {
    final receipt = wallet.applyMerchantCharge(
      htdAmount: _invoiceHtd,
      memo: 'Dynamic QR · H\$ ${_invoiceHtd.toStringAsFixed(2)}',
    );
    if (!mounted) return;
    await showReceiptDialog(context, receipt: receipt);
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletState>();
    final htgDue = _invoiceHtd * kHtgPerHtd;
    final fee = _invoiceHtd * kMerchantFeeRate;
    final net = _invoiceHtd - fee;
    final recent = wallet.ledger.take(3).toList();
    final isSun = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => wallet.refreshRates(),
          color: isSun ? kSunYellowText : const Color(0xFFFCC419),
          backgroundColor: isSun ? kSunCardSurface : const Color(0xFF141414),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => wallet.setMode(AppMode.consumer),
                  tooltip: 'Consumer wallet',
                  icon: Icon(
                    Icons.swap_horiz,
                    size: 20,
                    color: isSun ? kSunHeaderText : Colors.white,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AGENT TERMINAL',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                          color: isSun ? kSunHeaderText : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pilot Phase 1 · closed loop, Port-au-Prince',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSun ? kSunSecondaryText : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Merchant charge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSun ? kSunCardSurface : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSun ? kSunBorder : Colors.white.withValues(alpha: 0.07),
                  width: isSun ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Charge a customer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSun ? kSunHeaderText : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '100',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Invoice amount (HTD)',
                      prefixText: 'H\$ ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(
                      () => _invoiceHtd = double.tryParse(val) ?? 0.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Line(
                    label: 'Customer pays',
                    value: '${formatAmount(htgDue)} HTG',
                    emphasis: true,
                  ),
                  _Line(
                    label: 'Merchant fee (0.5%)',
                    value: '- ${formatHtd(fee)}',
                  ),
                  _Line(label: 'You receive', value: formatHtd(net)),
                  const SizedBox(height: 14),
                  if (_invoiceHtd > 0) ...[
                    Center(
                      child: QrDisplay(
                        payload: QrPayload(
                          walletAddress: wallet.walletAddress,
                          amount: _invoiceHtd,
                          reference:
                              'INV-${DateTime.now().millisecondsSinceEpoch}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'htd:${compactAddress(wallet.walletAddress)} · H\$ ${_invoiceHtd.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSun ? kSunSecondaryText : Colors.white38,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: isSun ? kSunCardSurface : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSun ? kSunBorder : Colors.white.withValues(alpha: 0.10),
                          width: isSun ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 40,
                            color: isSun ? kSunSecondaryText : Colors.white24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter an amount above to generate QR',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isSun ? kSunSecondaryText : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFCC419),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: _invoiceHtd > 0
                        ? () => _settleCharge(wallet)
                        : null,
                    child: Text(
                      _invoiceHtd > 0
                          ? 'Mark H\$ ${_invoiceHtd.toStringAsFixed(2)} as paid'
                          : 'Enter an invoice amount',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Fee schedule
            _Panel(
              title: 'Published fee schedule',
              rows: const <(String, String)>[
                ('Peer-to-peer / B2B', '0%'),
                ('Merchant processing', '0.5%'),
                ('Redemption / cash-out', '3%'),
                ('Cash-in', 'no published fee'),
              ],
            ),
            const SizedBox(height: 12),

            // Rate source verification
            _Panel(
              title: 'Exchange rate source',
              rows: <(String, String)>[
                ('Reference', wallet.quoteSourceLabel),
                ('Current rate', '${formatAmount(wallet.brhRate)} HTG per USD'),
                (
                  'Last updated',
                  wallet.ratesUpdatedAt == null
                      ? 'Not yet read'
                      : formatRateAge(wallet.ratesUpdatedAt!),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => _openBrhSource(context),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.open_in_new,
                        size: 13,
                        color: isSun ? kSunYellowText : const Color(0xFFFCC419),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Verify on haitiandollar.com/htd#official-rates',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isSun ? kSunYellowText : const Color(0xFFFCC419),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: isSun ? kSunYellowText : const Color(0xFFFCC419),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Pilot guardrails
            _Panel(
              title: 'Phase 1 guardrails',
              rows: <(String, String)>[
                ('Reserve floor', '${formatAmount(kPilotReserveFloorHtg)} HTG'),
                (
                  'Monthly volume',
                  '${formatAmount(kPilotMonthlyVolumeFloorHtg)} – '
                      '${formatAmount(kPilotMonthlyVolumeCeilingHtg)} HTG',
                ),
                ('Average ticket', '2,500 – 5,000 HTG'),
                (
                  'Settlement',
                  kSandboxSettlement
                      ? 'sandbox · nothing broadcast'
                      : 'Base L2 · live',
                ),
              ],
            ),

            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent terminal activity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSun ? kSunHeaderText : Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                if (recent.isEmpty)
                  Text(
                    'No charges settled on this terminal yet.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isSun ? kSunSecondaryText : Colors.white38,
                    ),
                  )
                else
                  ...recent.map(
                    (receipt) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              receipt.title,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSun ? kSunHeaderText : Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formatHtd(receipt.htdAmount),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSun ? kSunHeaderText : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final isSun = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSun ? kSunSecondaryText : Colors.white60,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasis ? 14 : 12.5,
              fontWeight: FontWeight.bold,
              color: emphasis
                  ? (isSun ? kSunHeaderText : Colors.white)
                  : (isSun ? kSunYellowText : const Color(0xFFFCC419)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final isSun = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSun ? kSunCardSurface : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSun ? kSunBorder : Colors.white.withValues(alpha: 0.06),
          width: isSun ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isSun ? kSunHeaderText : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row.$1,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isSun ? kSunSecondaryText : Colors.white54,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isSun ? kSunHeaderText : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openBrhSource(BuildContext context) async {
  final url = Uri.parse(kOfficialRatesUrl);
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open haitiandollar.com')),
      );
    }
  }
}
