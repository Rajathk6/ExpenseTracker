/// Offline parsers for shared payment text / OCR output. Pure functions.
///
/// Extracts first plausible amount + merchant hint + UPI ref.
/// Never auto-saves — caller must show confirm screen (see PLAN Phase 9).
class SharedPayment {
  final double? amount;
  final String? merchant;
  final String? upiRef;
  const SharedPayment({this.amount, this.merchant, this.upiRef});
}

final _amountRe = RegExp(r'(?:₹|Rs\.?|INR)\s?([\d,]+\.?\d*)|([\d,]+\.?\d*)\s?(?:₹|Rs\.?|INR)', caseSensitive: false);
final _plainAmountRe = RegExp(r'\b\d[\d,]*\.?\d*\b');
final _upiRe = RegExp(r'UPI[/:\s]*([A-Za-z0-9]{6,})', caseSensitive: false);

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
  final merchant = trimmed.split('\n').first.trim().substring(0, trimmed.split('\n').first.trim().length.clamp(0, 80));
  return SharedPayment(amount: amount, merchant: merchant.isEmpty ? null : merchant, upiRef: upi);
}
