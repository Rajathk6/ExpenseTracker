/// Freeform category parser: space = new level, '-' continues the item.
///
/// `food junk gobi-65` -> levels [food, junk], item `gobi-65`
/// `food healthy sweet-potato` -> levels [food, healthy], item `sweet-potato`
/// `rent` -> levels [rent], item null
/// Everything is lowercase-trimmed; no hardcoded allow-list (flexibility rule).
class ParsedCategory {
  final List<String> levels;
  final String? item;
  final String raw;
  const ParsedCategory({required this.levels, required this.item, required this.raw});
}

ParsedCategory parseCategory(String input) {
  final raw = input.trim();
  if (raw.isEmpty) return const ParsedCategory(levels: [], item: null, raw: '');
  final tokens = raw.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.length == 1 && !tokens.first.contains('-')) {
    return ParsedCategory(levels: [tokens.first], item: null, raw: raw);
  }
  // Last token holds the item (part after first '-'), preceding tokens + head are levels.
  final last = tokens.last;
  final dash = last.indexOf('-');
  if (dash <= 0) {
    return ParsedCategory(levels: tokens, item: null, raw: raw);
  }
  final head = last.substring(0, dash);
  final item = last; // keep full `gobi-65` so search for exact item works
  final levels = [...tokens.sublist(0, tokens.length - 1), head];
  return ParsedCategory(levels: levels, item: item, raw: raw);
}
