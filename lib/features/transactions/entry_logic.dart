/// Pure entry-form logic: draft + validation. No widgets — fully unit-testable.
/// UI in entry_sheet.dart only renders this and calls TransactionRepository.
library;

/// What the entry form collects. Amount is the raw text so validation owns parsing.
class EntryDraft {
  final String kind; // 'in' or 'out'
  final String amountText;
  final String categoryRaw;
  final String? accountId;
  final DateTime dateTime;
  final String note;

  const EntryDraft({
    required this.kind,
    required this.amountText,
    required this.categoryRaw,
    required this.accountId,
    required this.dateTime,
    this.note = '',
  });

  double? get amount => double.tryParse(amountText.trim());
}

/// Returns an error message when invalid, null when valid.
String? validateEntry(EntryDraft draft, {required bool hasAccounts}) {
  if (draft.kind != 'in' && draft.kind != 'out') return 'Pick In or Out';
  final amount = draft.amount;
  if (amount == null) return 'Enter a valid amount';
  if (amount <= 0) return 'Amount must be above zero';
  if (amount >= 1000000000) return 'Amount looks too large';
  if (draft.categoryRaw.trim().isEmpty) return 'Enter a category (e.g. food junk gobi-65)';
  if (hasAccounts && (draft.accountId == null || draft.accountId!.isEmpty)) {
    return 'Pick a source account';
  }
  return null;
}
