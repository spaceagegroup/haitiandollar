/// Parser and encoder for HTD QR payloads.
///
/// Encodes payment requests adhering to EIP-681 with the custom `htd:` scheme:
/// `htd:<wallet_address>?amount=<htd_amount>&ref=<reference>`
///
/// Also handles raw wallet addresses (`0x...`) and simple `htd:<address>`
/// URIs for peer-to-peer transfers where no invoice amount or reference is preset.
class QrPayload {
  const QrPayload({
    required this.walletAddress,
    required this.amount,
    required this.reference,
  });

  /// Destination on-chain wallet address (e.g. `0x71C8394A...49B2`).
  final String walletAddress;

  /// Amount in HTD requested by the invoice (0.0 if not specified).
  final double amount;

  /// Merchant invoice reference (e.g. `INV-1728403200`).
  final String reference;

  /// Whether this payload carries an invoice amount (> 0).
  bool get hasAmount => amount > 0;

  /// Encode this payload into an HTD payment URI.
  String encode() {
    // The reference is escaped: unescaped, a reference containing `&amount=`
    // would inject an extra query parameter and override the invoice amount on
    // the reading side.
    final encodedRef = Uri.encodeQueryComponent(reference);
    if (amount > 0 && reference.isNotEmpty) {
      return 'htd:$walletAddress?amount=${amount.toStringAsFixed(2)}&ref=$encodedRef';
    } else if (amount > 0) {
      return 'htd:$walletAddress?amount=${amount.toStringAsFixed(2)}';
    } else {
      return 'htd:$walletAddress';
    }
  }

  /// Parse a QR string into a [QrPayload].
  ///
  /// Returns `null` if the string cannot be parsed as a valid HTD URI or wallet
  /// address, or if it carries an `amount` that is not a finite, non-negative
  /// number. A present-but-broken amount must not be collapsed into "no amount
  /// requested": doing so lets a payer send an arbitrary default while believing
  /// they are settling the displayed invoice.
  static QrPayload? decode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Case 1: Standard htd: scheme
    if (trimmed.startsWith('htd:')) {
      final withoutScheme = trimmed.substring(4);
      final split = withoutScheme.split('?');
      final address = split[0].trim();
      if (address.isEmpty) return null;

      if (split.length == 1) {
        return QrPayload(walletAddress: address, amount: 0.0, reference: '');
      }

      final query = _parseQuery(split[1]);
      final amountStr = query['amount'];
      final ref = query['ref'] ?? '';

      var parsedAmount = 0.0;
      if (amountStr != null && amountStr.trim().isNotEmpty) {
        final value = double.tryParse(amountStr.trim());
        if (value == null || !value.isFinite || value < 0) return null;
        parsedAmount = value;
      }

      return QrPayload(
        walletAddress: address,
        amount: parsedAmount,
        reference: ref,
      );
    }

    // Case 2: Direct Base/Ethereum hex address (e.g. 0x...)
    if (trimmed.startsWith('0x') && trimmed.length >= 10) {
      return QrPayload(walletAddress: trimmed, amount: 0.0, reference: '');
    }

    return null;
  }

  /// Splits a query string into a map, tolerating segments that are not valid
  /// percent-encoding.
  ///
  /// `Uri.splitQueryString` throws on any raw code unit above 127, so a Creole or
  /// French reference such as `ref=Café-12` would otherwise make an otherwise
  /// valid invoice unscannable. Later duplicates win, matching the SDK.
  static Map<String, String> _parseQuery(String query) {
    final result = <String, String>{};
    for (final segment in query.split('&')) {
      if (segment.isEmpty) continue;
      final separator = segment.indexOf('=');
      final key = separator == -1 ? segment : segment.substring(0, separator);
      final value = separator == -1 ? '' : segment.substring(separator + 1);
      result[_decode(key)] = _decode(value);
    }
    return result;
  }

  static String _decode(String value) {
    try {
      return Uri.decodeQueryComponent(value);
    } catch (_) {
      // Keep the raw text rather than discarding the whole invoice.
      return value;
    }
  }
}
