/// Offline parsers for shared payment text / OCR output. Pure functions.
///
/// Extracts first plausible amount + merchant hint + UPI ref + direction.
/// Never auto-saves — caller must show confirm screen (see PLAN Phase 9).
/// OCR screenshots feed here as recognized text once the on-device OCR
/// plugin is re-added on the dev machine (native step, documented in
/// PROGRESS); the parser itself is plugin-agnostic.
class SharedPayment {
  final double? amount;
  final String? merchant;
  final String? upiRef;

  /// 'in' when the text reads like money received, else 'out'.
  final String kindHint;
  const SharedPayment({this.amount, this.merchant, this.upiRef, this.kindHint = 'out'});
}

final _amountRe = RegExp(r'(?:₹|Rs\.?|INR)\s?([\d,]+\.?\d*)|([\d,]+\.?\d*)\s?(?:₹|Rs\.?|INR)', caseSensitive: false);
final _plainAmountRe = RegExp(r'\b\d[\d,]*\.?\d*\b');
final _upiRe = RegExp(r'UPI[/:\s]*([A-Za-z0-9]{6,})', caseSensitive: false);

/// `Paid Rs.450 to Swiggy` → `Swiggy`. Merchants usually follow "to".
final _toMerchantRe = RegExp(r'\bto\s+([A-Za-z][A-Za-z0-9 .&\-]{1,40})', caseSensitive: false);

/// Received / credited / cashback / refund phrasing → money in.
final _inHintRe = RegExp(r'\b(received|credited|cashback|refund|got|collected)\b', caseSensitive: false);

/// OCR output is plain text once recognized — same extractor applies.
SharedPayment parseOcrText(String text) => parseSharedText(text);

SharedPayment parseSharedText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const SharedPayment();
  double? amount;
  final m = _amountRe.firstMatch(trimmed);
  if (m != null) {
    final raw = (m.group(1) ?? m.group(2) ?? '').replaceAll(',', '');
    amount = double.tryParse(raw);
  }
  amount ??= () {
    // Fallback: largest number that looks like money (heuristic for `Paid 450 to Swiggy`).
    double? best;
    for (final n in _plainAmountRe.allMatches(trimmed)) {
      final v = double.tryParse(n.group(0)!.replaceAll(',', ''));
      if (v != null && v > 0 && (best == null || v > best)) best = v;
    }
    return best;
  }();
  final upi = _upiRe.firstMatch(trimmed)?.group(1);
  final toMerchant = _toMerchantRe.firstMatch(trimmed)?.group(1)?.trim();
  final firstLine = trimmed.split('\n').first.trim();
  final merchant = (toMerchant != null && toMerchant.isNotEmpty)
      ? toMerchant.substring(0, toMerchant.length.clamp(0, 40))
      : (firstLine.isEmpty ? null : firstLine.substring(0, firstLine.length.clamp(0, 80)));
  final kindHint = _inHintRe.hasMatch(trimmed) ? 'in' : 'out';
  return SharedPayment(amount: amount, merchant: merchant, upiRef: upi, kindHint: kindHint);
}
