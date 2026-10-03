import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/wallet_state.dart';
import '../widgets/buy_sheet.dart';
import '../widgets/loan_sheet.dart';
import '../widgets/receipt_dialog.dart';
import '../widgets/sell_sheet.dart';
import '../widgets/send_sheet.dart';

/// Primary consumer shell.
///
/// Launches the typed bottom sheets, captures the result each one returns,
/// applies it through [WalletState] (which re-validates every bound after the
/// sheet has closed), then presents the shared receipt modal.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
    final receipt = wallet.applyLoanRepayment(
      htdAmount: result.htdAmount,
      mfiName: result.mfiName,
      mfiWallet: result.mfiWallet,
      loanId: result.loanId,
    );
    if (!context.mounted) return;
    await showReceiptDialog(context, receipt: receipt);
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletState>();
    final mode = wallet.mode;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            _Header(
              onSwitchShell: () => wallet.setMode(
                mode == AppMode.consumer ? AppMode.kiosk : AppMode.consumer,
              ),
            ),
            const SizedBox(height: 18),
            _BalanceCard(
              balance: wallet.balance,
              htgValue: wallet.htgFor(wallet.balance),
              usdValue: wallet.usdFor(wallet.balance),
            ),
            const SizedBox(height: 12),
            _RateBar(wallet: wallet),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: Icons.add_circle_outline,
                    label: 'Buy HTD',
                    detail: 'Cash-in',
                    onTap: () => _buy(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Cash out',
                    detail: '3% bridge',
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
                    label: 'Send',
                    detail: 'Free, by phone',
                    onTap: () => _send(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    icon: Icons.account_balance_outlined,
                    label: 'Loan repayment',
                    detail: 'via institution',
                    onTap: () => _repayLoan(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Activity(ledger: wallet.ledger),
            const SizedBox(height: 24),
            const _Disclaimer(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSwitchShell});

  final VoidCallback onSwitchShell;

  @override
  Widget build(BuildContext context) {
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HAITIAN DOLLAR',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Digital settlement infrastructure for Haiti',
                style: TextStyle(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onSwitchShell,
          tooltip: 'Agent terminal',
          icon: const Icon(Icons.storefront_outlined, size: 20),
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
  });

  final double balance;
  final double htgValue;
  final double usdValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFCC419), Color(0xFFE8A600)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 14,
                color: Colors.black54,
              ),
              SizedBox(width: 6),
              Text(
                'AVAILABLE BALANCE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatHtd(balance),
            style: const TextStyle(
              fontSize: 33,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '≈ ${formatAmount(htgValue)} HTG   ·   ≈ \$${usdValue.toStringAsFixed(2)} USD',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const _Chip(text: '1 HTD = 5 HTG. Fixed.'),
              const SizedBox(width: 8),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
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
    final updated = wallet.ratesUpdatedAt;
    final stamp = updated == null
        ? 'not read yet'
        : 'updated ${updated.hour.toString().padLeft(2, '0')}:'
              '${updated.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.public, size: 15, color: Colors.white38),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${wallet.htgPerUsd.toStringAsFixed(4)} HTG / USD',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${wallet.quoteSource} · $stamp'
                  '${wallet.quoteIsLive ? ' · live' : ' · cached'}',
                  style: const TextStyle(fontSize: 9.5, color: Colors.white38),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (wallet.isRefreshing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              onPressed: wallet.refreshRates,
              tooltip: 'Refresh BRH quotation',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh, size: 18),
            ),
        ],
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
    return Material(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFCC419).withValues(alpha: 0.12),
                ),
                child: Icon(icon, size: 17, color: const Color(0xFFFCC419)),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.ledger});

  final List<TxnReceipt> ledger;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activity',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            Text(
              ledger.isEmpty
                  ? 'no settlements yet'
                  : '${ledger.length} settlement${ledger.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 10.5, color: Colors.white38),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (ledger.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 22,
                  color: Colors.white24,
                ),
                SizedBox(height: 8),
                Text(
                  'Your receipts will appear here.',
                  style: TextStyle(fontSize: 11.5, color: Colors.white38),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: Icon(_icon, size: 16, color: Colors.white70),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${receipt.counterparty} · ${receipt.formattedTimestamp}',
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
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
                      ? const Color(0xFF51CF66)
                      : const Color(0xFFFFFBF0),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                receipt.isLive ? 'on-chain' : 'sandbox',
                style: const TextStyle(fontSize: 9, color: Colors.white24),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HTD is a redemption receipt, not a stablecoin. Tokens may have no '
            'value. 1 HTD = 5 HTG is a settlement convention, not a market peg.',
            style: TextStyle(fontSize: 10, color: Colors.white38, height: 1.45),
          ),
          SizedBox(height: 6),
          Text(
            'Haitian Dollar Inc. · legal@haitiandollar.com',
            style: TextStyle(fontSize: 9.5, color: Colors.white24),
          ),
        ],
      ),
    );
  }
}
