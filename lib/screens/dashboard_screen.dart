import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/wallet_state.dart';
import '../utils/qr_payload.dart';
import '../widgets/buy_sheet.dart';
import '../widgets/loan_sheet.dart';
import '../widgets/receipt_dialog.dart';
import '../widgets/sell_sheet.dart';
import '../widgets/send_sheet.dart';


import '../widgets/pin_keypad_sheet.dart';

import 'scanner_screen.dart';
import 'rates_screen.dart';
import '../theme/htd_theme.dart';
import '../utils/app_strings.dart';

/// Primary consumer shell.
///
/// Launches the typed bottom sheets, captures the result each one returns,
/// applies it through [WalletState] (which re-validates every bound after the
/// sheet has closed), then presents the shared receipt modal.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<bool> _requireOutflowAuth(BuildContext context) async {
    final wallet = context.read<WalletState>();
    if (!wallet.pinAuth.isPinSet) {
      return true; // Progressive security: guest mode allows outflow until PIN is set
    }
    final authenticated = await PinKeypadSheet.show(
      context,
      authService: wallet.pinAuth,
      locale: wallet.currentLocale,
      onDuressDetected: (_) => wallet.activateDuressMode(),
    );
    return authenticated == true;
  }

  Future<void> _buy(BuildContext context) async {
    final wallet = context.read<WalletState>();
    final result = await showBuySheet(context, maxBalance: wallet.balance);
    if (result == null || !context.mounted) return;
    final receipt = wallet.applyBuy(result.htdAmount, method: result.method);
    if (!context.mounted) return;
    await showReceiptDialog(context, receipt: receipt);
  }

  Future<void> _sell(BuildContext context) async {
    final wallet = context.read<WalletState>();
    final result = await showSellSheet(context, maxBalance: wallet.balance);
    if (result == null || !context.mounted) return;
    if (!await _requireOutflowAuth(context) || !context.mounted) return;
    final receipt = wallet.applySell(
      htdAmount: result.htdAmount,
      msisdn: result.msisdn,
      channel: result.channel,
    );
    if (!context.mounted) return;
    await showReceiptDialog(context, receipt: receipt);
  }

  Future<void> _send(BuildContext context) async {
    final wallet = context.read<WalletState>();
    final result = await showSendSheet(context, maxBalance: wallet.balance);
    if (result == null || !context.mounted) return;
    if (!await _requireOutflowAuth(context) || !context.mounted) return;
    final receipt = wallet.applySend(
      htdAmount: result.htdAmount,
      recipient: result.recipient,
    );
    if (!context.mounted) return;
    await showReceiptDialog(context, receipt: receipt);
  }

  Future<void> _repayLoan(BuildContext context) async {
    final wallet = context.read<WalletState>();
    final result = await showLoanSheet(context, maxBalance: wallet.balance);
    if (result == null || !context.mounted) return;
    if (!await _requireOutflowAuth(context) || !context.mounted) return;
    final receipt = wallet.applyLoanRepayment(
      htdAmount: result.htdAmount,
      mfiName: result.mfiName,
      mfiWallet: result.mfiWallet,
      loanId: result.loanId,
    );
    if (!context.mounted) return;
    await showReceiptDialog(context, receipt: receipt);
  }

  Future<void> _scanAndPay(BuildContext context) async {
    final payload = await Navigator.push<QrPayload>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (payload == null || !context.mounted) return;

    final wallet = context.read<WalletState>();
    final result = await showSendSheet(
      context,
      maxBalance: wallet.balance,
      initialPayload: payload,
    );
    if (result == null || !context.mounted) return;
    if (!await _requireOutflowAuth(context) || !context.mounted) return;
    final receipt = wallet.applySend(
      htdAmount: result.htdAmount,
      recipient: result.recipient,
    );
    if (!context.mounted) return;
    await showReceiptDialog(context, receipt: receipt);
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletState>();
    final mode = wallet.mode;
    final loc = wallet.currentLocale;

    final isSun = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: SafeArea(
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => wallet.resetUnmaskTimer(),
          onPointerMove: (_) => wallet.resetUnmaskTimer(),
          child: RefreshIndicator(
            onRefresh: () => wallet.refreshRates(),
            color: isSun ? kSunYellowText : const Color(0xFFFCC419),
            backgroundColor: isSun ? kSunCardSurface : const Color(0xFF141414),
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
            _Header(
              onSwitchShell: () => wallet.setMode(
                mode == AppMode.consumer ? AppMode.kiosk : AppMode.consumer,
              ),
              onScan: () => _scanAndPay(context),
              currentLocale: loc,
              onSelectLocale: (lang) {
                if (lang == '__debug_toggle_theme__') {
                  wallet.toggleOutdoorMode();
                } else if (lang == '__manage_pin__') {
                  PinKeypadSheet.show(
                    context,
                    authService: wallet.pinAuth,
                    locale: loc,
                    isSettingNewPin: true,
                  );
                } else {
                  wallet.setLocale(lang);
                }
              },
              isOutdoorMode: wallet.isOutdoorMode,
              onToggleOutdoorMode: () => wallet.toggleOutdoorMode(),
            ),
            const SizedBox(height: 18),
            _BalanceCard(
              balance: wallet.balance,
              htgValue: wallet.htgFor(wallet.balance),
              usdValue: wallet.usdFor(wallet.balance),
              isMasked: wallet.isBalanceMasked,
              onToggleMask: () => wallet.toggleBalanceMask(),
              locale: loc,
            ),
            const SizedBox(height: 12),
            _RateBar(wallet: wallet),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: Icons.add_circle_outline,
                    label: AppStrings.get('buy_action', loc),
                    detail: loc == 'ht' ? 'Depo kach' : (loc == 'fr' ? 'Dépôt cash' : 'Cash-in'),
                    onTap: () => _buy(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    icon: Icons.arrow_upward_rounded,
                    label: AppStrings.get('cashout_action', loc),
                    detail: loc == 'ht' ? 'Pasrèl 3%' : (loc == 'fr' ? 'Pont 3%' : '3% bridge'),
                    onTap: () => _sell(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: Icons.send_rounded,
                    label: AppStrings.get('send_action', loc),
                    detail: loc == 'ht' ? 'Gratis, pa nimewo' : (loc == 'fr' ? 'Gratuit, par tél' : 'Free, by phone'),
                    onTap: () => _send(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    icon: Icons.account_balance_outlined,
                    label: AppStrings.get('repay_loan_action', loc),
                    detail: loc == 'ht' ? 'Mikwofinans' : (loc == 'fr' ? 'Microfinance' : 'via institution'),
                    onTap: () => _repayLoan(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Activity(ledger: wallet.ledger, locale: loc),
            const SizedBox(height: 24),
            const _Disclaimer(),
          ],
        ),
      ),
    ),
  ),
);
}
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onSwitchShell,
    required this.onScan,
    required this.currentLocale,
    required this.onSelectLocale,
    required this.isOutdoorMode,
    required this.onToggleOutdoorMode,
  });

  final VoidCallback onSwitchShell;
  final VoidCallback onScan;
  final String currentLocale;
  final ValueChanged<String> onSelectLocale;
  final bool isOutdoorMode;
  final VoidCallback onToggleOutdoorMode;

  @override
  Widget build(BuildContext context) {
    final isSun = Theme.of(context).brightness == Brightness.light;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE03131), width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/brand/logo.png',
              fit: BoxFit.cover,
              semanticLabel: 'Haitian Dollar coin',
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFFCC419),
                child: Icon(Icons.paid_outlined, size: 20, color: Colors.black),
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HAITIAN DOLLAR',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: isSun ? kSunHeaderText : Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Digital settlement infrastructure for Haiti',
                style: TextStyle(
                  fontSize: 10,
                  color: isSun ? kSunSecondaryText : Colors.white38,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            isOutdoorMode ? Icons.nightlight_round : Icons.wb_sunny_outlined,
            size: 20,
            color: isSun ? kSunHeaderText : Colors.white,
          ),
          tooltip: isOutdoorMode
              ? AppStrings.get('mode_night', currentLocale)
              : AppStrings.get('mode_sun', currentLocale),
          onPressed: onToggleOutdoorMode,
        ),
        PopupMenuButton<String>(
          tooltip: 'Chanje Lang / Language',
          initialValue: currentLocale,
          onSelected: onSelectLocale,
          color: isSun ? kSunCardSurface : const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSun ? kSunBorder : Colors.white12),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: isSun
                  ? kSunCardSurface
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSun ? kSunBorder : Colors.white.withValues(alpha: 0.12),
                width: isSun ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLocale.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSun ? kSunYellowText : const Color(0xFFFCC419),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 14,
                  color: isSun ? kSunHeaderText : Colors.white70,
                ),
              ],
            ),
          ),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'ht', child: Text('🇭🇹 Kreyòl (Ayisyen)')),
            const PopupMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
            const PopupMenuItem(value: 'en', child: Text('🇺🇸 English')),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: '__manage_pin__',
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 16),
                  SizedBox(width: 8),
                  Text('Kòd Sekrè PIN', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (kDebugMode) ...[
              const PopupMenuDivider(),
              PopupMenuItem(
                value: '__debug_toggle_theme__',
                child: Text(
                  isOutdoorMode ? '🌙 Force Night Mode' : '☀️ Force Sun Mode',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        IconButton(
          onPressed: onScan,
          tooltip: 'Scan QR to pay',
          icon: Icon(
            Icons.qr_code_scanner,
            size: 21,
            color: isSun ? kSunYellowText : const Color(0xFFFCC419),
          ),
        ),
        IconButton(
          onPressed: onSwitchShell,
          tooltip: 'Agent terminal',
          icon: Icon(
            Icons.storefront_outlined,
            size: 20,
            color: isSun ? kSunHeaderText : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.htgValue,
    required this.usdValue,
    required this.isMasked,
    required this.onToggleMask,
    required this.locale,
  });

  final double balance;
  final double htgValue;
  final double usdValue;
  final bool isMasked;
  final VoidCallback onToggleMask;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final isSun = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFCC419), Color(0xFFE8A600)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: isSun ? Border.all(color: kSunBorder, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 14,
                      color: isSun ? kSunHeaderText : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        AppStrings.get('balance_title', locale),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: isSun ? kSunHeaderText : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onToggleMask,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        isMasked ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                        color: isSun ? kSunHeaderText : Colors.black87,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMasked ? 'Kache' : 'Vizib',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSun ? kSunHeaderText : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isMasked ? 'H\$ ••••••' : formatHtd(balance),
            style: TextStyle(
              fontSize: 33,
              fontWeight: FontWeight.w900,
              color: isSun ? kSunHeaderText : Colors.black,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isMasked
                ? '•••••• HTG   ·   •••• USD'
                : '≈ ${formatAmount(htgValue)} HTG   ·   ≈ \$${usdValue.toStringAsFixed(2)} USD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSun ? kSunBodyText : Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              const _Chip(text: '1 HTD = 5 HTG. Fixed.'),
              _Chip(
                text: kSandboxSettlement ? 'Sandbox build' : 'Base L2 · live',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isSun = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isSun
            ? Colors.white.withValues(alpha: 0.60)
            : Colors.black.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: isSun ? Border.all(color: kSunBorder, width: 1.0) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isSun ? kSunHeaderText : Colors.black87,
        ),
      ),
    );
  }
}


class _RateBar extends StatelessWidget {
  const _RateBar({required this.wallet});

  final WalletState wallet;

  @override
  Widget build(BuildContext context) {
    final isSun = Theme.of(context).brightness == Brightness.light;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RatesScreen()),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSun ? kSunCardSurface : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSun ? kSunBorder : Colors.white.withValues(alpha: 0.10),
              width: isSun ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: isSun ? kSunSuccess : const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 8),
                  // Expanded so a larger accessibility font scale ellipsises the
                  // label instead of overflowing the card.
                  Expanded(
                    child: Text(
                      wallet.rateCardTitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSun ? kSunBodyText : Colors.white60,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: wallet.isRefreshing ? null : () => wallet.refreshRates(),
                    child: wallet.isRefreshing
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.refresh,
                              size: 13,
                              color: isSun ? kSunSecondaryText : Colors.white54,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '1 USD = ${wallet.brhRate.toStringAsFixed(4)} HTG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: isSun ? kSunYellowText : const Color(0xFFFCC419),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Expanded so the provenance line ellipsises rather than pushing
                  // the verification link off the card.
                  Expanded(
                    child: Text(
                      wallet.rateStatusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSun ? kSunSecondaryText : Colors.white38,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RatesScreen()),
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Verify official rates →',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSun ? kSunYellowText : const Color(0xFFFCC419),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: isSun ? kSunYellowText : const Color(0xFFFCC419),
                        ),
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

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSun = Theme.of(context).brightness == Brightness.light;

    return Material(
      color: isSun ? kSunCardSurface : const Color(0xFF141414),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSun ? kSunBorder : Colors.white.withValues(alpha: 0.07),
              width: isSun ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSun
                      ? kBrandYellow.withValues(alpha: 0.22)
                      : const Color(0xFFFCC419).withValues(alpha: 0.12),
                  border: isSun ? Border.all(color: kSunBorder, width: 1.0) : null,
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: isSun ? kSunYellowText : const Color(0xFFFCC419),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSun ? kSunHeaderText : Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 10,
                  color: isSun ? kSunSecondaryText : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.ledger, required this.locale});

  final List<TxnReceipt> ledger;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final isSun = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.get('recent_txns', locale),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSun ? kSunHeaderText : Colors.white,
              ),
            ),
            Text(
              ledger.isEmpty
                  ? 'no settlements yet'
                  : '${ledger.length} settlement${ledger.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 10.5,
                color: isSun ? kSunSecondaryText : Colors.white38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (ledger.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
            decoration: BoxDecoration(
              color: isSun ? kSunCardSurface : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSun ? kSunBorder : Colors.white.withValues(alpha: 0.08),
                width: isSun ? 1.5 : 1.0,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 22,
                  color: isSun ? kSunSecondaryText : Colors.white24,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get('no_txns', locale),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isSun ? kSunSecondaryText : Colors.white38,
                  ),
                ),
              ],
            ),
          )
        else
          ...ledger.map((receipt) => _LedgerTile(receipt: receipt)),
      ],
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.receipt});

  final TxnReceipt receipt;

  static const _credits = <TxnKind>{TxnKind.buy, TxnKind.charge};

  IconData get _icon => switch (receipt.kind) {
    TxnKind.buy => Icons.add_circle_outline,
    TxnKind.charge => Icons.qr_code_2,
    TxnKind.sell => Icons.arrow_upward_rounded,
    TxnKind.send => Icons.send_rounded,
    TxnKind.loan => Icons.account_balance_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final isCredit = _credits.contains(receipt.kind);
    final isSun = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSun
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.05),
              border: isSun ? Border.all(color: kSunBorder, width: 1.0) : null,
            ),
            child: Icon(
              _icon,
              size: 16,
              color: isSun ? kSunHeaderText : Colors.white70,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isSun ? kSunHeaderText : Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${receipt.counterparty} · ${receipt.formattedTimestamp}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSun ? kSunSecondaryText : Colors.white38,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '−'}${formatHtd(receipt.htdAmount)}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isCredit
                      ? (isSun ? kSunSuccess : const Color(0xFF51CF66))
                      : (isSun ? kSunHeaderText : const Color(0xFFFFFBF0)),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                receipt.isLive ? 'on-chain' : 'sandbox',
                style: TextStyle(
                  fontSize: 9,
                  color: isSun ? kSunSecondaryText : Colors.white24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final isSun = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSun ? kSunCardSurface : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: isSun ? Border.all(color: kSunDivider, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HTD is a redemption receipt, not a stablecoin. Tokens may have no '
            'value. 1 HTD = 5 HTG is a settlement convention, not a market peg.',
            style: TextStyle(
              fontSize: 10,
              color: isSun ? kSunSecondaryText : Colors.white38,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Haitian Dollar Inc. · legal@haitiandollar.com',
            style: TextStyle(
              fontSize: 9.5,
              color: isSun ? kSunSecondaryText : Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}
