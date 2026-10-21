/// Offline parsers for shared payment text / OCR output. Pure functions.
///
/// Extracts the amount + merchant hint + UPI ref from a shared message or an
/// OCR'd screenshot. Never auto-saves — the caller must show the confirm
/// screen (see PLAN Phase 9).
///
/// The hard part is *which* number is the amount: a payment screenshot is full
/// of numbers — the amount, a UTR, a date, a time, an account number. A UTR
/// is a long digit string, so it must never be mistaken for money.
library;

class SharedPayment {
  final double? amount;
  final String? merchant;
  final String? upiRef;

  /// 'in' when the text reads like money received, else 'out'.
  final String kindHint;
  const SharedPayment({this.amount, this.merchant, this.upiRef, this.kindHint = 'out'});
}

final _amountRe = RegExp(
  r'(?:₹|Rs\.?|INR)\s?(\d[\d,]*\.?\d*)|(\d[\d,]*\.?\d*)\s?(?:₹|Rs\.?|INR)',
  caseSensitive: false,
);
final _plainAmountRe = RegExp(r'(?<![\d.])\d[\d,]*\.?\d*(?![\d.])');

/// "UPI: 431623789012", "UTR 431623789012", "Transaction ID 123", "Ref: ABC" —
/// these are references, not money. The number is removed before the amount is
/// looked for, which is what stopped a 12-digit UTR being read as ₹1,23,45,67,890.
final _refLabelRe = RegExp(
  r'\b(?:utr|upi|rrn|txn|txn\s*id|transaction\s*id|transaction\s*no|ref(?:erence)?\s*(?:no|id)?|order\s*id|'
  r'invoice\s*(?:no|id)?|receipt\s*no)\b\s*[:#\-]?\s*([A-Za-z0-9\-]+)',
  caseSensitive: false,
);

/// Dates and times are numbers too, and never money.
final _dateRe = RegExp(r'\b\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}\b');
final _timeRe = RegExp(r'\b\d{1,2}:\d{2}(:\d{2})?\s*(?:am|pm)?\b', caseSensitive: false);
final _monthDateRe = RegExp(r'\b\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4}\b');

final _upiRe = RegExp(r'UPI[/:\s]*([A-Za-z0-9]{6,})', caseSensitive: false);

/// `Paid Rs.450 to Swiggy` → `Swiggy`. Merchants usually follow "to".
final _toMerchantRe = RegExp(r'\bto\s+([A-Za-z][A-Za-z0-9 .&\-]{1,40})', caseSensitive: false);

/// Received / credited / cashback / refund phrasing → money in.
final _inHintRe = RegExp(r'\b(received|credited|cashback|refund|got|collected)\b', caseSensitive: false);

/// The most a rupee amount can plausibly be here — and the most digits a
/// *number* can have before it stops being an amount and starts being a
/// reference (a 12-digit UTR, a phone number, an account number).
const _maxAmount = 10000000; // one crore
const _maxAmountDigits = 7;

/// OCR output is plain text once recognized — same extractor applies.
SharedPayment parseOcrText(String text) => parseSharedText(text);

SharedPayment parseSharedText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const SharedPayment();

  // 1. Take the references, dates and times out of the way first.
  final working = trimmed
      .replaceAll(_refLabelRe, ' ')
      .replaceAll(_dateRe, ' ')
      .replaceAll(_monthDateRe, ' ')
      .replaceAll(_timeRe, ' ');

  // 2. The amount: a currency-marked number wins, then the first number that
  //    could plausibly be money.
  double? amount;
  final marked = _amountRe.firstMatch(working);
  if (marked != null) {
    final raw = (marked.group(1) ?? marked.group(2) ?? '').replaceAll(',', '');
    final value = double.tryParse(raw);
    if (value != null && value > 0 && value <= _maxAmount) amount = value;
  }
  amount ??= _firstPlausibleAmount(working);

  final upi = _upiRe.firstMatch(trimmed)?.group(1);
  final toMerchant = _toMerchantRe.firstMatch(working)?.group(1)?.trim();
  final firstLine = working.split('\n').first.trim();
  final merchant = (toMerchant != null && toMerchant.isNotEmpty)
      ? toMerchant.substring(0, toMerchant.length.clamp(0, 40))
      : (firstLine.isEmpty ? null : firstLine.substring(0, firstLine.length.clamp(0, 80)));
  final kindHint = _inHintRe.hasMatch(working) ? 'in' : 'out';
  return SharedPayment(amount: amount, merchant: merchant, upiRef: upi, kindHint: kindHint);
}

/// The first number that could be money: positive, small enough, and not a
/// long digit string (which is a reference, not an amount).
double? _firstPlausibleAmount(String text) {
  for (final match in _plainAmountRe.allMatches(text)) {
    final raw = match.group(0)!.replaceAll(',', '');
    final value = double.tryParse(raw);
    if (value == null || value <= 0 || value > _maxAmount) continue;
    final digits = raw.split('.').first;
    if (digits.length > _maxAmountDigits) continue; // a UTR / phone / account no.
    return value;
  }
  return null;
}
