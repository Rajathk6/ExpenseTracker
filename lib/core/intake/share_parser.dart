/// Offline parsers for shared payment text / OCR output. Pure functions.
///
/// The hard part is *which* number is the amount. A payment screenshot is
/// full of numbers: the amount, a UTR, a date, a time, a phone number, the
/// last four digits of a phone number, a balance. Picking the first (or the
/// largest) number is how a UTR or a phone tail ended up as the "amount".
///
/// So every number is **scored** on how much it looks like money:
///
/// | signal | effect |
/// |---|---|
/// | `₹` / `Rs` / `INR` right next to it | almost certainly the amount |
/// | two decimal places (`450.00`) | payment apps show the amount like this |
/// | it is the only thing on its line | payment apps show the amount alone |
/// | the line says *paid / sent / amount / debited / total* | likely the amount |
/// | the line says *mobile / phone / aadhaar / ending / XXXX* | not the amount |
/// | it is part of a spaced digit group (`9876 5432 3210`) | a phone number |
/// | more than seven digits | a reference, not money |
///
/// The highest score wins; ties go to the first one seen.
///
/// Never auto-saves — the caller must show the confirm screen (PLAN Phase 9).
library;

class SharedPayment {
  final double? amount;
  final String? merchant;
  final String? upiRef;

  /// 'in' when the text reads like money received, else 'out'.
  final String kindHint;
  const SharedPayment({this.amount, this.merchant, this.upiRef, this.kindHint = 'out'});
}

/// A number found in the text, with the reasons it might (or might not) be
/// the amount.
class _Candidate {
  final double value;
  final int score;
  final String line;
  const _Candidate(this.value, this.score, this.line);
}

/// A number token. The look-behind only rules out a *digit* before it, so
/// "Rs.450" still matches (a dot before a number is part of "Rs.", not part
/// of the number).
final _numberRe = RegExp(r'(?<!\d)\d[\d,]*(?:\.\d+)?(?!\d)');

/// Words that mean the number next to them is money.
final _moneyWordsRe = RegExp(
  r'\b(paid|pay|send|sent|amount|amt|total|debited|debiting|charged|charge|bill|'
  r'to\s+pay|payment|value|spent)\b',
  caseSensitive: false,
);

/// A date, so the first line of a screenshot is not a shop name.
final _dateRe = RegExp(r'\b\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}\b');
final _timeRe = RegExp(r'\b\d{1,2}:\d{2}(:\d{2})?\s*(?:am|pm)?\b', caseSensitive: false);

/// Words that mean the number next to them is NOT the amount.
final _notMoneyWordsRe = RegExp(
  r'\b(mobile|phone|ph\.?no|contact|aadhaar|aadhar|account\s*(no|number)|acct|'
  r'ending|ends\s+with|reference|ref\s*no|utr|upi|rrn|txn|order|'
  r'invoice|receipt|date|on)\b',
  caseSensitive: false,
);

/// A masked number: "XXXXX3210", "••••3210", "***3210".
final _maskedRe = RegExp(r'[xX•*]{2,}\s*\d{2,}');

/// A phone number written in groups: "98765 43210", "9876 5432 3210".
final _spacedDigitsRe = RegExp(r'\b\d{2,5}(?:\s+\d{2,5}){1,4}\b');

/// Currency markers, with the number they are attached to.
final _currencyRe = RegExp(
  r'(?:₹|Rs\.?|INR)\s?(\d[\d,]*\.?\d*)|(\d[\d,]*\.?\d*)\s?(?:₹|Rs\.?|INR)',
  caseSensitive: false,
);

final _upiRe = RegExp(r'UPI[/:\s]*([A-Za-z0-9]{6,})', caseSensitive: false);

/// `Paid Rs.450 to Swiggy` → `Swiggy`. Merchants usually follow "to".
final _toMerchantRe = RegExp(r'\bto\s+([A-Za-z][A-Za-z0-9 .&\-]{1,40})', caseSensitive: false);

/// Received / credited / cashback / refund phrasing → money in.
final _inHintRe = RegExp(r'\b(received|credited|cashback|refund|got|collected)\b', caseSensitive: false);

/// The most a rupee amount can plausibly be, and the most digits a *number*
/// can have before it stops being an amount (a 12-digit UTR, a phone number).
const _maxAmount = 10000000; // one crore
const _maxAmountDigits = 7;

/// OCR output is plain text once recognized — same extractor applies.
SharedPayment parseOcrText(String text) => parseSharedText(text);

SharedPayment parseSharedText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const SharedPayment();

  final amount = _findAmount(trimmed);
  final upi = _upiRe.firstMatch(trimmed)?.group(1);
  final toMerchant = _toMerchantRe.firstMatch(trimmed)?.group(1)?.trim();
  final firstLine = trimmed.split('\n').first.trim();
  // The merchant is the name after "to", or failing that the first line —
  // but never a line that is only money, a date or a label ("Amount 450",
  // "12/09/2026 14:35"), because that becomes the category suggestion.
  final firstLineIsUsable = firstLine.isNotEmpty &&
      firstLine.contains(RegExp(r'[A-Za-z]')) &&
      !_moneyWordsRe.hasMatch(firstLine) &&
      !_dateRe.hasMatch(firstLine) &&
      !_timeRe.hasMatch(firstLine) &&
      !(amount != null && firstLine.contains(amount.toStringAsFixed(0)) && firstLine.replaceAll(RegExp(r'[^A-Za-z]'), '').length <= 3);
  final merchant = (toMerchant != null && toMerchant.isNotEmpty)
      ? toMerchant.substring(0, toMerchant.length.clamp(0, 40))
      : (firstLineIsUsable ? firstLine.substring(0, firstLine.length.clamp(0, 80)) : null);
  final kindHint = _inHintRe.hasMatch(trimmed) ? 'in' : 'out';
  return SharedPayment(amount: amount, merchant: merchant, upiRef: upi, kindHint: kindHint);
}

/// The number that looks most like money.
double? _findAmount(String text) {
  final candidates = <_Candidate>[];
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    // Lines that are mostly a phone number / reference are not money.
    final masked = _maskedRe.hasMatch(trimmed);
    final spaced = _spacedDigitsRe.hasMatch(trimmed);
    final notMoney = _notMoneyWordsRe.hasMatch(trimmed);
    final moneyWord = _moneyWordsRe.hasMatch(trimmed);
    final currency = _currencyRe.hasMatch(trimmed);
    final onlyNumber = _numberRe.allMatches(trimmed).length == 1 &&
        trimmed.replaceAll(_numberRe, '').trim().isEmpty;

    for (final match in _numberRe.allMatches(trimmed)) {
      final raw = match.group(0)!.replaceAll(',', '');
      final value = double.tryParse(raw);
      if (value == null || value <= 0 || value > _maxAmount) continue;
      final digits = raw.split('.').first;
      if (digits.length > _maxAmountDigits) continue; // a UTR / phone / account no.

      var score = 0;
      if (currency) score += 100;
      if (raw.contains('.')) score += 60; // 450.00 — how apps show money
      if (onlyNumber) score += 40; // the amount alone on its line
      if (moneyWord) score += 20;
      if (masked) score -= 90; // XXXXX3210
      if (spaced) score -= 70; // 9876 5432 3210
      if (notMoney) score -= 60; // "mobile 9876543210"
      candidates.add(_Candidate(value, score, trimmed));
    }
  }
  if (candidates.isEmpty) return null;

  // The best score wins; the earliest one breaks a tie (payment apps put the
  // amount above the rest).
  var best = candidates.first;
  for (final candidate in candidates.skip(1)) {
    if (candidate.score > best.score) best = candidate;
  }
  // A negative score means everything looked wrong — better to show nothing
  // than a phone number.
  if (best.score <= 0) return null;
  return best.value;
}
