import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

/// Which shell the application is currently presenting.
enum AppMode { consumer, kiosk }

/// The protocol invariant printed on the coin itself: `5 Goud = 1 Haitian Dollar`.
///
/// Every redemption path in the protocol settles at this fixed ratio; the
/// USD valuation is derived from the daily BRH quotation, never from a market
/// float. Do not replace this with a mutable rate.
const double kHtgPerHtd = 5.0;

/// Fee retained on a redemption / cash-out (whitepaper: 100 HTD → 485 HTG).
const double kBridgeFeeRate = 0.03;

/// Merchant processing fee on a dynamic QR invoice.
const double kMerchantFeeRate = 0.005;

/// Peer-to-peer and B2B transfers are free.
const double kP2pFeeRate = 0.0;

/// Settlement is not yet wired to the Base deployment, so receipts produced by
/// this build are simulated. Flip to `false` once the ERC-4337 settlement
/// service is live on Base mainnet; every receipt then reports a real hash.
const bool kSandboxSettlement = true;

/// Pilot guardrails from the whitepaper's Phase 1 (closed-loop Port-au-Prince).
const double kPilotReserveFloorHtg = 400000;
const double kPilotMonthlyVolumeFloorHtg = 500000;
const double kPilotMonthlyVolumeCeilingHtg = 1500000;

/// Plausible band for a gourdes-per-USD reference quotation.
///
/// The floor matches the website's own guard (`fetchedRate > 50`). The ceiling is
/// deliberately wide: it rejects unit errors and typos — a payload published as
/// `1.313` or `1313052` instead of `131.3052` — while still tolerating an extreme
/// devaluation. The HTD↔HTG invariant is hard-coded and so is unaffected by a bad
/// rate; the exposure is the displayed USD valuation and the credibility of the
/// rate card.
const double kMinPlausibleHtgPerUsd = 50;
const double kMaxPlausibleHtgPerUsd = 2000;

/// Whether [rate] can be trusted as a gourdes-per-USD reference.
bool isPlausibleBrhRate(double rate) =>
    rate.isFinite &&
    rate >= kMinPlausibleHtgPerUsd &&
    rate <= kMaxPlausibleHtgPerUsd;

/// The authoritative published URL for Bank of Haiti official rates.
const String kOfficialRatesUrl =
    'https://www.haitiandollar.com/htd#official-rates';

/// Official Bank of Haiti (BRH) reference rate (gourdes per USD),
/// as published at https://www.haitiandollar.com/htd#official-rates.
const double kOfficialHtgPerUsd = 130.5583;

/// Last-resort gourdes-per-USD value, matching the official Bank of Haiti
/// reference rate published at https://www.haitiandollar.com/htd#official-rates.
const double kOfflineBaselineHtgPerUsd = kOfficialHtgPerUsd;

/// The quotation endpoints the website itself publishes, rewritten daily by
/// `.github/workflows/fetch-rates.yml`.
const List<String> _kQuoteUrls = <String>[
  'https://www.haitiandollar.com/htd-quote.json',
  'https://haitiandollar.com/htd-quote.json',
];

/// The open forex endpoints the website falls back through, in the same order.
const List<String> _kForexEndpoints = <String>[
  'https://open.er-api.com/v6/latest/USD',
  'https://api.exchangerate-api.com/v4/latest/USD',
];

/// How long any single rate source may take before the next one is tried.
const Duration _kFetchTimeout = Duration(seconds: 4);

/// How long a cached quotation stays usable before the open forex fallbacks are
/// consulted, mirroring the website's `CACHE_TTL_MS` of two hours.
const Duration kQuoteCacheTtl = Duration(hours: 2);

/// Whether a quotation published at [publishedAt] is still inside that window.
///
/// [now] is injectable so the boundary is testable.
bool isQuoteFresh(DateTime? publishedAt, {DateTime? now}) {
  if (publishedAt == null) return false;
  return (now ?? DateTime.now()).difference(publishedAt) < kQuoteCacheTtl;
}

/// A participating microfinance institution (MFI) and the on-chain wallet that
/// receives borrower repayments on its behalf.
///
/// Only institutions with a countersigned MOU are listed in
/// [WalletState.availableMfis]; anything else must stay out of the registry so
/// the repayment sheet can never route funds to an unvetted address.
@immutable
class MfiConfig {
  const MfiConfig({
    required this.name,
    required this.activeAddress,
    this.isLive = false,
  });

  /// Display name shown in the institution selector.
  final String name;

  /// Active on-chain settlement address; repayments are bound to this value.
  final String activeAddress;

  /// Whether the MOU is executed (mainnet) or the partner is still on testnet.
  final bool isLive;

  @override
  bool operator ==(Object other) =>
      other is MfiConfig &&
      other.name == name &&
      other.activeAddress == activeAddress &&
      other.isLive == isLive;

  @override
  int get hashCode => Object.hash(name, activeAddress, isLive);
}

/// Category of a settled transaction, used for the ledger icon and receipt copy.
enum TxnKind { buy, charge, sell, send, loan }

/// An immutable, display-ready proof of a completed transaction.
@immutable
class TxnReceipt {
  const TxnReceipt({
    required this.kind,
    required this.title,
    required this.htdAmount,
    required this.timestamp,
    required this.txHash,
    required this.counterparty,
    required this.isLive,
    this.feeHtd = 0,
    this.loanId,
  });

  final TxnKind kind;

  /// Headline shown on the receipt, e.g. `Cash-out to MonCash`.
  final String title;

  /// Amount in HTD that moved.
  final double htdAmount;

  final DateTime timestamp;

  /// Transaction hash as broadcast (live) or as simulated by the sandbox.
  final String txHash;

  /// Sanitised counterparty: institution, merchant, or masked MSISDN.
  final String counterparty;

  /// True when the settlement was broadcast to mainnet.
  final bool isLive;

  /// Fee retained in HTD, if any.
  final double feeHtd;

  /// Loan account / borrower ID, present only on [TxnKind.loan] receipts.
  final String? loanId;

  /// Gourde principal equivalent at the fixed 5:1 invariant.
  double get htgEquivalent => htdAmount * kHtgPerHtd;

  /// Gourdes released after the retained fee (e.g. 100 HTD → 485 HTG).
  double get netHtgPayout => (htdAmount - feeHtd) * kHtgPerHtd;

  /// `3%` or `0.5%` — the effective rate the retained fee represents.
  String get feeRateLabel {
    if (feeHtd <= 0 || htdAmount <= 0) return '';
    final pct = feeHtd / htdAmount * 100;
    return '${pct.toStringAsFixed(pct >= 1 ? 0 : 1)}%';
  }

  /// `Oct 3, 2026 · 9:37 AM`
  String get formattedTimestamp {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = timestamp.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final meridiem = local.hour < 12 ? 'AM' : 'PM';
    return '${months[local.month - 1]} ${local.day}, ${local.year} '
        '· $hour12:$minute $meridiem';
  }
}

/// Core domain and state for the HTD wallet.
///
/// Holds the pilot MFI registry, the fixed-parity economics, the daily BRH
/// quotation, and the local ledger. Every mutation returns the [TxnReceipt] it
/// produced so the UI can present proof of settlement.
class WalletState extends ChangeNotifier {
  static const String defaultWalletAddress =
      '0x71C8394A84e52514d7a9bA7879e604f323B049B2';

  WalletState({
    double openingBalance = 128.50,
    this.walletAddress = defaultWalletAddress,
  }) : _balance = openingBalance,
       _htgPerUsd = kOfflineBaselineHtgPerUsd;

  /// Active on-chain wallet address for this terminal or user.
  final String walletAddress;

  /// Protocol invariant: 1 HTD is redeemable for 5 HTG (see [kHtgPerHtd]).
  static const double invariantRate = kHtgPerHtd;

  /// Fee retained on cash-out settlement (see [kBridgeFeeRate]).
  static const double bridgeFeeRate = kBridgeFeeRate;

  /// Scoped partner registry.
  ///
  /// `availableMfis.first` is the default selection in the repayment sheet, so
  /// the first slot may only ever hold an institution with an executed
  /// agreement.
  ///
  /// The public materials name exactly one institutional rail — Digicel
  /// MonCash, which also custodies the HTG reserve — and state that the pilot
  /// has not launched. No microfinance MOU is documented, so no prospective
  /// lender may appear here: a selectable entry would silently route a
  /// borrower's repayment to an unvetted address. Candidates live in
  /// [pendingMfis] until their MOU is countersigned, at which point they move
  /// into this list, with the live pilot anchor first.
  static const List<MfiConfig> availableMfis = <MfiConfig>[
    MfiConfig(
      name: 'MonCash merchant depot — pilot anchor',
      activeAddress: '0x9f2c4e1b7a5d3f80c1e6b4a29d7f058e3c1a6b24',
      isLive: true,
    ),
  ];

  /// Institutions in discussion. Never selectable in a payment flow.
  static const List<MfiConfig> pendingMfis = <MfiConfig>[
    MfiConfig(
      name: 'Microfinance partner — MOU pending',
      activeAddress: '',
      isLive: false,
    ),
  ];

  AppMode _mode = AppMode.consumer;
  double _balance;
  final List<TxnReceipt> _ledger = <TxnReceipt>[];

  double _htgPerUsd;
  bool _isRefreshing = false;
  bool _fetchedFromNetwork = false;
  bool _quoteScrapedLive = false;

  /// Names the fallback that supplied the current figure, or null when it came
  /// from the published BRH quotation (or nothing has been read yet).
  String? _rateOriginLabel;
  String _quoteSource = 'Banque de la République d\'Haïti (BRH)';
  DateTime? _ratesUpdatedAt;
  String? _quoteDate;

  // ---------------------------------------------------------------- shell

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// [refreshRates] resolves asynchronously, so a listener that goes away
  /// mid-flight must not be notified after disposal.
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  AppMode get mode => _mode;

  void setMode(AppMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _safeNotify();
  }

  void toggleMode() =>
      setMode(_mode == AppMode.consumer ? AppMode.kiosk : AppMode.consumer);

  // ------------------------------------------------------------- balances

  /// Spendable HTD balance.
  double get balance => _balance;

  /// Newest-first transaction history.
  List<TxnReceipt> get ledger => List<TxnReceipt>.unmodifiable(_ledger);

  /// Gourde principal a holder receives for [htd] at the fixed invariant.
  double htgFor(double htd) => htd * kHtgPerHtd;

  /// Fee retained on an off-ramp of [htd].
  double bridgeFeeFor(double htd) => htd * kBridgeFeeRate;

  /// Net gourde a holder receives after the bridge fee.
  double netHtgPayoutFor(double htd) => htgFor(htd - bridgeFeeFor(htd));

  // ---------------------------------------------------------------- rates

  /// Whether this build actually broadcasts to the Base deployment.
  bool get _settlesLive => !kSandboxSettlement;

  /// Daily BRH reference: gourdes per US dollar.
  double get htgPerUsd => _htgPerUsd;

  /// Daily BRH reference rate (alias for [htgPerUsd]).
  double get brhRate => _htgPerUsd;

  /// Derived from the invariant: `5 / htgPerUsd`.
  double get usdPerHtd => kHtgPerHtd / _htgPerUsd;

  /// USD value of [htd].
  double usdFor(double htd) => htd * usdPerHtd;

  bool get isRefreshing => _isRefreshing;

  /// True when the held quote was fetched over the network in this session,
  /// rather than read from the snapshot bundled with the build.
  bool get quoteIsLive => _fetchedFromNetwork;

  /// True when the upstream scraper reported a successful BRH read for the
  /// quotation being held. False means the figure itself is stale.
  bool get quoteScrapedLive => _quoteScrapedLive;

  String get quoteSource => _quoteSource;

  /// When the held quotation was published, or null when nothing has been read.
  DateTime? get ratesUpdatedAt => _ratesUpdatedAt;

  /// Provenance line for the rate card, e.g. `Updated 12 min ago · live`.
  ///
  /// Never fabricates a timestamp: a quotation that has not been read reports an
  /// explicitly unverified state instead of appearing to have just arrived.
  String get rateStatusLabel {
    final stamp = _ratesUpdatedAt;
    if (stamp == null) {
      final origin = _rateOriginLabel;
      return origin == null
          ? 'Not yet read · unverified'
          : 'Unverified · $origin';
    }
    final provenance = _fetchedFromNetwork ? 'live' : 'cached';
    // Only a BRH-pipeline quotation can be a stale scrape. A freshly fetched
    // forex rate is current; it is simply not the published BRH figure.
    final freshness = (_rateOriginLabel == null && !_quoteScrapedLive)
        ? ' · stale'
        : '';
    return 'Updated ${formatRateAge(stamp)} · $provenance$freshness';
  }

  /// Headline for the rate card. Names the fallback whenever the displayed figure
  /// did not come from the published BRH quotation, so a forex or offline value
  /// is never presented as the BRH reference.
  String get rateCardTitle => _rateOriginLabel ?? 'BRH Reference Rate';

  /// Source label for the terminal panel: the published BRH quotation unless a
  /// fallback supplied the figure.
  String get quoteSourceLabel => _rateOriginLabel ?? 'BRH Taux du Jour';

  String? get quoteDate => _quoteDate;

  /// Loads the daily BRH quotation through the same source chain the website
  /// uses, then its own bundled snapshot.
  ///
  /// The order mirrors `index.html` / `htd.html`: the published
  /// `/htd-quote.json` first; then the cached figure — for the app, the snapshot
  /// bundled at build time — while it is still inside the website's two-hour
  /// window; then the same open forex endpoints (`open.er-api.com`, then
  /// `exchangerate-api.com`, reading `rates.HTG`); and finally the landing page's
  /// guarded constant. Every source is parsed and plausibility-checked
  /// independently, and the origin is recorded so the card can name whatever
  /// actually supplied the number.
  Future<void> refreshRates() async {
    _isRefreshing = true;
    _safeNotify();
    try {
      // 1. The published quotation from official endpoints.
      _Quote? quote;
      for (final url in _kQuoteUrls) {
        try {
          final res = await http
              .get(Uri.parse(url))
              .timeout(_kFetchTimeout);
          if (res.statusCode == 200) {
            quote = _parseQuote(
              jsonDecode(res.body),
              _quoteSource,
              fromNetwork: true,
            );
            if (quote != null) break;
          }
        } catch (e) {
          debugPrint('Rate refresh live fetch fallback ($url): $e');
        }
      }

      // 2. The official snapshot bundled with the build.
      _Quote? bundled;
      try {
        bundled = _parseQuote(
          jsonDecode(await rootBundle.loadString('htd-quote.json')),
          _quoteSource,
          fromNetwork: false,
        );
      } catch (e) {
        debugPrint('Rate refresh bundled asset fallback: $e');
      }

      // Prefer the official quotation (live or bundled) over generic forex rates.
      quote ??= bundled;

      // 3. Fallback to open forex endpoints only if no official Bank of Haiti
      //    quotation is available.
      quote ??= await _fetchForexQuote();

      if (quote == null) {
        _applyOfflineBaseline();
      } else {
        _htgPerUsd = quote.rate;
        _quoteSource = quote.source;
        _quoteDate = quote.date;
        _rateOriginLabel = quote.origin;
        _fetchedFromNetwork = quote.fromNetwork;
        _quoteScrapedLive = quote.scrapedLive;
        _ratesUpdatedAt = quote.updatedAt;
      }
    } catch (e) {
      debugPrint('Rate refresh fallback: $e');
      _applyOfflineBaseline();
    } finally {
      _isRefreshing = false;
      _safeNotify();
    }
  }

  /// Falls back to the official Bank of Haiti baseline constant.
  void _applyOfflineBaseline() {
    _htgPerUsd = kOfflineBaselineHtgPerUsd;
    _rateOriginLabel = 'Official baseline';
    _fetchedFromNetwork = false;
    _quoteScrapedLive = false;
    _ratesUpdatedAt = null;
  }

  /// Tries the website's open forex fallbacks in order and returns the first
  /// plausible `rates.HTG`.
  Future<_Quote?> _fetchForexQuote() async {
    for (final url in _kForexEndpoints) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(_kFetchTimeout);
        if (res.statusCode != 200) continue;
        final rate = _forexRate(jsonDecode(res.body));
        if (rate == null || !isPlausibleBrhRate(rate)) continue;
        final label = 'Forex reference · ${Uri.parse(url).host}';
        return _Quote(
          rate: rate,
          source: label,
          date: null,
          // The retrieval time is a real fact for a value fetched just now. Only
          // an unread or unavailable figure must never carry a fabricated stamp.
          updatedAt: DateTime.now(),
          scrapedLive: false,
          fromNetwork: true,
          origin: label,
        );
      } catch (e) {
        debugPrint('Rate refresh forex fallback ($url): $e');
      }
    }
    return null;
  }

  /// `{"rates": {"HTG": 131.3052}}`, as published by the open forex endpoints.
  static double? _forexRate(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final rates = decoded['rates'];
    if (rates is! Map<String, dynamic>) return null;
    return _asDouble(rates['HTG']);
  }

  /// Parses one quotation payload, returning null when its shape is wrong or its
  /// rate is missing or implausible.
  ///
  /// Field choice follows the landing page, which displays `reference.raw`; the
  /// equivalent `reference.htgPerUsd` and `banking.htgPerUsd` are accepted too.
  /// Numeric fields are read leniently, because a publisher may emit them as
  /// strings.
  static _Quote? _parseQuote(
    Object? decoded,
    String fallbackSource, {
    required bool fromNetwork,
  }) {
    if (decoded is! Map<String, dynamic>) return null;

    final reference = decoded['reference'];
    final banking = decoded['banking'];
    final rate =
        _asDouble(
          reference is Map<String, dynamic> ? reference['raw'] : null,
        ) ??
        _asDouble(
          reference is Map<String, dynamic> ? reference['htgPerUsd'] : null,
        ) ??
        _asDouble(
          banking is Map<String, dynamic> ? banking['htgPerUsd'] : null,
        );

    if (rate == null || !isPlausibleBrhRate(rate)) return null;

    return _Quote(
      rate: rate,
      source: sanitizeText(
        (decoded['source'] as String?) ?? fallbackSource,
        maxLength: 96,
      ),
      date: decoded['date'] as String?,
      updatedAt: DateTime.tryParse((decoded['updatedAt'] as String?) ?? ''),
      scrapedLive: decoded['liveScraped'] == true,
      fromNetwork: fromNetwork,
      origin: null,
    );
  }

  /// Reads a numeric field that a payload may publish as a number or a string.
  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  // ------------------------------------------------------------ mutations

  /// Credits an inbound deposit (minted HTD) and returns its receipt.
  ///
  /// [htdAmount] must be strictly positive; the sheet validates before calling.
  TxnReceipt applyBuy(double htdAmount, {String method = 'Bank transfer'}) {
    final amount = _requirePositive(htdAmount);
    _balance += amount;
    return _record(
      kind: TxnKind.buy,
      title: 'Deposit confirmed',
      htdAmount: amount,
      counterparty: sanitizeText(method, maxLength: 32),
      isLive: _settlesLive,
    );
  }

  /// Burns HTD for a cash-out and returns its receipt, including the 3% fee.
  TxnReceipt applySell({
    required double htdAmount,
    required String msisdn,
    String channel = 'MonCash',
  }) {
    final amount = _requireSpendable(htdAmount);
    final fee = bridgeFeeFor(amount);
    _balance -= amount;
    return _record(
      kind: TxnKind.sell,
      title: 'Cash-out to $channel',
      htdAmount: amount,
      counterparty: maskMsisdn(sanitizeText(msisdn, maxLength: 24)),
      feeHtd: fee,
      isLive: _settlesLive,
    );
  }

  /// Debits a peer-to-peer transfer and returns its receipt.
  ///
  /// P2P carries no protocol fee; the recipient is identified by phone number
  /// and does not need an account to be notified.
  TxnReceipt applySend({required double htdAmount, required String recipient}) {
    final amount = _requireSpendable(htdAmount);
    _balance -= amount;
    return _record(
      kind: TxnKind.send,
      title: 'Payment sent',
      htdAmount: amount,
      // An address is displayed compacted but still passes through sanitizeText,
      // so directional overrides cannot reorder the one value the payer is asked
      // to verify.
      counterparty: recipient.startsWith('0x')
          ? compactAddress(sanitizeText(recipient, maxLength: 96))
          : maskMsisdn(sanitizeText(recipient, maxLength: 24)),
      isLive: _settlesLive,
    );
  }

  /// Credits a merchant QR charge and returns its receipt.
  ///
  /// Merchant processing is 0.5% and is withheld from the credit, so the balance
  /// rises by exactly the amount the terminal promises under "You receive". The
  /// receipt keeps the gross charge and the fee, which reconciles all three
  /// surfaces: gross H$ 100.00, fee H$ 0.50, net H$ 99.50 / 497.50 HTG.
  TxnReceipt applyMerchantCharge({
    required double htdAmount,
    String memo = 'Dynamic QR invoice',
  }) {
    final amount = _requirePositive(htdAmount);
    final fee = amount * kMerchantFeeRate;
    _balance += amount - fee;
    return _record(
      kind: TxnKind.charge,
      title: 'Merchant payment received',
      htdAmount: amount,
      counterparty: sanitizeText(memo, maxLength: 48),
      feeHtd: fee,
      isLive: _settlesLive,
    );
  }

  /// Debits an MFI loan repayment and returns its receipt.
  ///
  /// The counterparty is the partner's [MfiConfig.activeAddress], and the
  /// borrower's [loanId] is preserved on the receipt as proof of allocation.
  TxnReceipt applyLoanRepayment({
    required double htdAmount,
    required String mfiName,
    required String mfiWallet,
    required String loanId,
  }) {
    final amount = _requireSpendable(htdAmount);
    final id = sanitizeText(loanId, maxLength: 32);
    if (id.isEmpty) {
      throw ArgumentError.value(loanId, 'loanId', 'Loan ID is required');
    }
    if (mfiWallet.trim().isEmpty) {
      throw ArgumentError.value(
        mfiWallet,
        'mfiWallet',
        'Partner has no active settlement wallet',
      );
    }
    _balance -= amount;
    return _record(
      kind: TxnKind.loan,
      title: 'Loan repayment',
      htdAmount: amount,
      counterparty:
          '${sanitizeText(mfiName, maxLength: 48)} · '
          '${compactAddress(mfiWallet)}',
      loanId: id,
      isLive:
          _settlesLive &&
          availableMfis.any(
            (mfi) => mfi.activeAddress == mfiWallet && mfi.isLive,
          ),
    );
  }

  TxnReceipt _record({
    required TxnKind kind,
    required String title,
    required double htdAmount,
    required String counterparty,
    required bool isLive,
    double feeHtd = 0,
    String? loanId,
  }) {
    final receipt = TxnReceipt(
      kind: kind,
      title: title,
      htdAmount: htdAmount,
      timestamp: DateTime.now(),
      txHash: _mockTxHash(),
      counterparty: counterparty.isEmpty ? '—' : counterparty,
      isLive: isLive,
      feeHtd: feeHtd,
      loanId: loanId,
    );
    _ledger.insert(0, receipt);
    _safeNotify();
    return receipt;
  }

  double _requirePositive(double amount) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(amount, 'htdAmount', 'Must be greater than 0');
    }
    return amount;
  }

  double _requireSpendable(double amount) {
    _requirePositive(amount);
    if (amount > _balance + 1e-9) {
      throw ArgumentError.value(
        amount,
        'htdAmount',
        'Exceeds available balance',
      );
    }
    return amount;
  }

  /// Deterministic-length hash for sandbox settlement; a live build swaps this
  /// for the hash returned by the settlement service.
  String _mockTxHash() {
    final random = Random();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '0x$hex';
  }
}

// ------------------------------------------------------------- utilities

/// Strips control characters and directional overrides, collapses runs of
/// whitespace, and truncates.
///
/// Applied to every user-supplied string that is persisted or displayed, so a
/// pasted or scanned payload cannot break layout, reorder the characters a user
/// is asked to verify, or smuggle terminal control codes into a receipt. The set
/// covers C0/C1 controls plus the bidirectional and zero-width controls a QR
/// payload can carry: U+200B–U+200F, U+202A–U+202E, U+2066–U+2069, U+FEFF.
String sanitizeText(String raw, {int maxLength = 64}) {
  if (raw.isEmpty) return '';
  final stripped = raw
      .replaceAll(
        RegExp(
          r'[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u202A-\u202E'
          r'\u2066-\u2069\uFEFF]',
        ),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (stripped.length <= maxLength) return stripped;
  return stripped.substring(0, maxLength).trimRight();
}

/// `0x9f2c4e1b…c1a6b24` for wallet addresses and transaction hashes.
String compactAddress(String value, {int lead = 8, int tail = 6}) {
  final trimmed = value.trim();
  if (trimmed.length <= lead + tail + 1) return trimmed;
  return '${trimmed.substring(0, lead)}…'
      '${trimmed.substring(trimmed.length - tail)}';
}

/// `+509 3712 3456` for an eight-digit Haitian MSISDN.
String maskMsisdn(String raw) {
  final digits = normalizeMsisdn(raw);
  if (digits.length != 8) return sanitizeText(raw, maxLength: 24);
  return '+509 ${digits.substring(0, 4)} ${digits.substring(4)}';
}

/// Last four digits only, for display on a public receipt.
String maskMsisdnTail(String raw) {
  final digits = normalizeMsisdn(raw);
  if (digits.length < 4) return '••••';
  return '•••• ${digits.substring(digits.length - 4)}';
}

/// Reduces a typed number to its eight national digits, dropping `+509`/`509`.
String normalizeMsisdn(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length > 8 && digits.startsWith('509')) {
    digits = digits.substring(3);
  } else if (digits.length > 8 && digits.startsWith('1')) {
    digits = digits.substring(1);
  }
  if (digits.length > 8) digits = digits.substring(digits.length - 8);
  return digits;
}

/// Validates a Haitian mobile number for cash-out and P2P destinations.
///
/// Returns `null` when acceptable, otherwise the message to show the user.
/// Requires eight digits on a mobile prefix (3 = MonCash, 4 = NatCash, 5).
String? validateHaitianMsisdn(String raw) {
  if (raw.trim().isEmpty) return 'Mobile number required';
  final digits = normalizeMsisdn(raw);
  if (digits.length != 8) return 'Enter 8 digits (e.g. 3712 3456)';
  if (!RegExp(r'^[345]').hasMatch(digits)) {
    return 'Prefix must be 3, 4, or 5';
  }
  return null;
}

/// `12,480.00` — grouped to two decimals without pulling in `intl`.
String formatAmount(double value, {int decimals = 2}) {
  // toStringAsFixed returns 'Infinity'/'NaN' for non-finite values and switches
  // to exponential notation for very large magnitudes. Grouping those digits
  // renders nonsense like `In,fin,ity` or `1e,+25`, so pass them through.
  if (!value.isFinite) {
    return value.isNaN ? 'NaN' : (value.isNegative ? '-∞' : '∞');
  }
  final fixed = value.toStringAsFixed(decimals);
  if (fixed.contains('e')) return fixed;
  final dot = fixed.indexOf('.');
  final whole = dot == -1 ? fixed : fixed.substring(0, dot);
  final fraction = dot == -1 ? '' : fixed.substring(dot);
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    if (i > 0 && remaining % 3 == 0 && whole[i] != '-') buffer.write(',');
    buffer.write(whole[i]);
  }
  return '$buffer$fraction';
}

/// `H$ 12,480.00`
String formatHtd(double value, {int decimals = 2}) =>
    'H\$ ${formatAmount(value, decimals: decimals)}';

/// Relative age of a quotation: `just now`, `12 min ago`, `16:12`, or `10/3`.
String formatRateAge(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }
  return '${timestamp.month}/${timestamp.day}';
}

/// A parsed, plausibility-checked BRH quotation.
@immutable
class _Quote {
  const _Quote({
    required this.rate,
    required this.source,
    required this.date,
    required this.updatedAt,
    required this.scrapedLive,
    required this.fromNetwork,
    required this.origin,
  });

  /// Gourdes per US dollar.
  final double rate;

  /// Publisher of the figure, as declared by the payload.
  final String source;

  /// Human-readable publication date from the payload, e.g. `Oct 3, 2026`.
  final String? date;

  /// When the payload was published; null when it carries no usable timestamp.
  final DateTime? updatedAt;

  /// Whether the upstream scraper reported a successful BRH read.
  final bool scrapedLive;

  /// Whether this quotation came from the network rather than the bundle.
  final bool fromNetwork;

  /// Names the fallback that supplied this figure, or null when it came from the
  /// published BRH quotation.
  final String? origin;
}
