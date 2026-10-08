import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/wallet_state.dart';

/// Full-screen BRH market rates, protocol parity, and currency converter.
///
/// Consumes [WalletState] to present live official rates, parity mechanics,
/// market spread benchmarks, and a real-time tri-currency converter.
class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  final TextEditingController _htdController = TextEditingController(text: '100');
  final TextEditingController _htgController = TextEditingController();
  final TextEditingController _usdController = TextEditingController();

  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculateFromHtd();
    });
  }

  @override
  void dispose() {
    _htdController.dispose();
    _htgController.dispose();
    _usdController.dispose();
    super.dispose();
  }

  void _recalculateFromHtd() {
    if (_isConverting) return;
    _isConverting = true;
    final wallet = context.read<WalletState>();
    final htd = double.tryParse(_htdController.text.replaceAll(',', '').trim()) ?? 0.0;
    final htg = htd * kHtgPerHtd;
    final usd = wallet.usdFor(htd);

    _htgController.text = htg > 0 ? formatAmount(htg, decimals: 2) : '';
    _usdController.text = usd > 0 ? usd.toStringAsFixed(2) : '';
    _isConverting = false;
  }

  void _recalculateFromHtg() {
    if (_isConverting) return;
    _isConverting = true;
    final wallet = context.read<WalletState>();
    final htg = double.tryParse(_htgController.text.replaceAll(',', '').trim()) ?? 0.0;
    final htd = htg / kHtgPerHtd;
    final usd = htg / wallet.brhRate;

    _htdController.text = htd > 0 ? formatAmount(htd, decimals: 2) : '';
    _usdController.text = usd > 0 ? usd.toStringAsFixed(2) : '';
    _isConverting = false;
  }

  void _recalculateFromUsd() {
    if (_isConverting) return;
    _isConverting = true;
    final wallet = context.read<WalletState>();
    final usd = double.tryParse(_usdController.text.replaceAll(',', '').trim()) ?? 0.0;
    final htg = usd * wallet.brhRate;
    final htd = htg / kHtgPerHtd;

    _htdController.text = htd > 0 ? formatAmount(htd, decimals: 2) : '';
    _htgController.text = htg > 0 ? formatAmount(htg, decimals: 2) : '';
    _isConverting = false;
  }

  void _setPresetHtd(double amount) {
    _htdController.text = amount.toStringAsFixed(0);
    _recalculateFromHtd();
  }

  Future<void> _openExternalRates() async {
    final url = Uri.parse(kOfficialRatesUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open rates URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletState>();
    final brhRate = wallet.brhRate;
    final htdInUsd = wallet.usdFor(1.0);
    final usdInHtd = brhRate / kHtgPerHtd;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'BRH Rates & Parity',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: wallet.isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFCC419),
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Color(0xFFFCC419)),
            onPressed: wallet.isRefreshing ? null : () => wallet.refreshRates(),
            tooltip: 'Refresh rates',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => wallet.refreshRates(),
        color: const Color(0xFFFCC419),
        backgroundColor: const Color(0xFF141414),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Freshness / Provenance Header Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: wallet.quoteIsLive
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFFCC419),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.rateCardTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          wallet.rateStatusLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (wallet.ratesUpdatedAt != null)
                    Text(
                      formatRateAge(wallet.ratesUpdatedAt!),
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Color(0xFFFCC419),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // DUAL KPI CARDS: Invariant & Implied Purchasing Power
            Row(
              children: [
                // Invariant Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFCC419).withValues(alpha: 0.15),
                          const Color(0xFFFCC419).withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFCC419).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PARITY RULE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Colors.white54,
                              ),
                            ),
                            Text(
                              'Fixed',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFCC419),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1 HTD = 5 HTG',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '1 HTG = 0.20 HTD\n1912 Convention',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white60,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // USD Benchmark Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF22C55E).withValues(alpha: 0.12),
                          const Color(0xFF22C55E).withValues(alpha: 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'IMPLIED USD',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Colors.white54,
                              ),
                            ),
                            Text(
                              'BRH Ref',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1 HTD ≈ \$${htdInUsd.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1 USD = ${usdInHtd.toStringAsFixed(2)} HTD\n1 USD = ${brhRate.toStringAsFixed(2)} HTG',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white60,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // LIVE CONVERTER SECTION
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.swap_vert_circle_outlined,
                        size: 16,
                        color: Color(0xFFFCC419),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'TRI-CURRENCY CALCULATOR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '1 USD = ${brhRate.toStringAsFixed(2)} HTG',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Color(0xFFFCC419),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // HTD Input
                  _CurrencyInputField(
                    label: 'Haitian Dollar (HTD)',
                    symbol: 'H\$',
                    controller: _htdController,
                    accentColor: const Color(0xFFFCC419),
                    onChanged: (_) => _recalculateFromHtd(),
                  ),
                  const SizedBox(height: 12),

                  // HTG Input
                  _CurrencyInputField(
                    label: 'Haitian Gourde (HTG)',
                    symbol: 'G',
                    controller: _htgController,
                    accentColor: const Color(0xFFE03131),
                    onChanged: (_) => _recalculateFromHtg(),
                  ),
                  const SizedBox(height: 12),

                  // USD Input
                  _CurrencyInputField(
                    label: 'United States Dollar (USD)',
                    symbol: '\$',
                    controller: _usdController,
                    accentColor: const Color(0xFF22C55E),
                    onChanged: (_) => _recalculateFromUsd(),
                  ),
                  const SizedBox(height: 14),

                  // Quick Presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PresetChip(label: '25 HTD', onTap: () => _setPresetHtd(25)),
                      _PresetChip(label: '100 HTD', onTap: () => _setPresetHtd(100)),
                      _PresetChip(label: '500 HTD', onTap: () => _setPresetHtd(500)),
                      _PresetChip(label: '1,000 HTD', onTap: () => _setPresetHtd(1000)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // MARKET SPREAD BENCHMARK CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_outlined, size: 16, color: Colors.white70),
                      SizedBox(width: 8),
                      Text(
                        'MARKET SPREAD BENCHMARKS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _RateRow(
                    label: 'BRH Reference Benchmark',
                    rateText: '${brhRate.toStringAsFixed(4)} HTG',
                    usdHtd: '${(brhRate / 5.0).toStringAsFixed(2)} HTD',
                    tag: 'Official',
                    tagColor: const Color(0xFF22C55E),
                  ),
                  const Divider(color: Colors.white12, height: 18),
                  _RateRow(
                    label: 'Commercial Bank Acquisition',
                    rateText: '${(brhRate * 1.018).toStringAsFixed(2)} HTG',
                    usdHtd: '${((brhRate * 1.018) / 5.0).toStringAsFixed(2)} HTD',
                    tag: '+1.8% Spread',
                    tagColor: Colors.white38,
                  ),
                  const Divider(color: Colors.white12, height: 18),
                  _RateRow(
                    label: 'Informal Cash Market (Est.)',
                    rateText: '${(brhRate * 1.038).toStringAsFixed(2)} HTG',
                    usdHtd: '${((brhRate * 1.038) / 5.0).toStringAsFixed(2)} HTD',
                    tag: '+3.8% Spread',
                    tagColor: const Color(0xFFFCC419),
                  ),
                  const Divider(color: Colors.white12, height: 18),
                  const _RateRow(
                    label: 'HTD Internal Settlement',
                    rateText: '5.0000 HTG',
                    usdHtd: '1.00 HTD',
                    tag: '0% Parity Invariant',
                    tagColor: Color(0xFFFCC419),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // OFFICIAL SOURCES & VERIFICATION ACTION
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Official Reference Documentation',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Compiled directly from Banque de la République d\'Haïti (BRH) daily publications. Haitian Dollar Inc. is an SEC CIK-registered fintech issuer (CIK 0001906040).',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFCC419),
                        side: const BorderSide(color: Color(0xFFFCC419)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _openExternalRates,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text(
                        'Verify on haitiandollar.com / BRH',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyInputField extends StatelessWidget {
  const _CurrencyInputField({
    required this.label,
    required this.symbol,
    required this.controller,
    required this.accentColor,
    required this.onChanged,
  });

  final String label;
  final String symbol;
  final TextEditingController controller;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                alignment: Alignment.center,
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  ),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({
    required this.label,
    required this.rateText,
    required this.usdHtd,
    required this.tag,
    required this.tagColor,
  });

  final String label;
  final String rateText;
  final String usdHtd;
  final String tag;
  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              rateText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              usdHtd,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
