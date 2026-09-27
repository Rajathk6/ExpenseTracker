/// Category autocomplete engine — pure, no DB, no widgets.
///
/// Turns "what you have typed so far" into a ranked list of full category
/// strings you can tap, so half a word is enough: `gob` -> `food junk gobi-65`.
/// Matches the raw string, any level, or the item token (see category_parser),
/// because the parser is what gives items their `gobi-65` shape.
///
/// Ranking tiers (lower wins), then most-used, then alphabetical:
/// exact > raw-prefix > item-prefix > level-prefix (shallower level first) >
/// raw-contains > token-contains (shallowest first). An empty query is a
/// browse: usage order only.
library;

import 'category_parser.dart';

/// One row offered under a category field. Tapping it fills [value] verbatim.
class CategorySuggestion {
  /// The full raw category to drop into the field (e.g. `food junk gobi-65`).
  final String value;
  /// What the query hit: `whole`, `level`, `item`, or `recent` (empty query).
  final String matchedOn;
  /// The exact token that matched — for UI highlighting. Null on browse rows.
  final String? matchedToken;
  /// How many entries have used this category. Breaks rank ties.
  final int uses;

  const CategorySuggestion({
    required this.value,
    required this.matchedOn,
    required this.matchedToken,
    required this.uses,
  });

  @override
  String toString() => 'CategorySuggestion($value, $matchedOn, $matchedToken, $uses)';
}

const _tierExact = 0;
const _tierRawPrefix = 10;
const _tierItemPrefix = 20;
const _tierLevelPrefix = 30;
const _tierRawContains = 40;
const _tierTokenContains = 60;
const _tierBrowse = 90;

class _Candidate {
  final CategorySuggestion suggestion;
  final int tier;
  const _Candidate(this.suggestion, this.tier);
}

/// The slice of [value] that [q] reaches, widened to whole words — so the UI
/// can bold `food junk` for the query `food j`, not half a word. Null when the
/// query is not inside [value] at all.
String? _spanIn(String value, String q) {
  final low = value.toLowerCase();
  final ql = q.toLowerCase().trim();
  if (ql.isEmpty) return null;
  final at = low.indexOf(ql);
  if (at < 0) return null;
  var start = at;
  while (start > 0 && !_isSpace(low[start - 1])) {
    start--;
  }
  var end = at + ql.length;
  while (end < low.length && !_isSpace(low[end])) {
    end++;
  }
  return value.substring(start, end);
}

bool _isSpace(String c) => c == ' ' || c == '\t' || c == '\n' || c == '\r';

/// Ranked completions for [query] drawn from [past] raw category strings.
///
/// [uses] is the optional raw→count map (from `AppDatabase.categoryUsage`) so
/// frequent categories win ties. Case-insensitive; duplicates (case-insensitive)
/// collapse to their first spelling. Non-matching rows are dropped, never
/// padded — a freeform category is always allowed.
List<CategorySuggestion> suggestCategories(
  Iterable<String> past, {
  String query = '',
  Map<String, int> uses = const {},
  int limit = 6,
}) {
  final q = query.trim().toLowerCase();
  final seen = <String>{};
  final scored = <_Candidate>[];
  for (final raw in past) {
    final value = raw.trim();
    if (value.isEmpty) continue;
    final key = value.toLowerCase();
    if (!seen.add(key)) continue;
    final count = uses[value] ?? uses[key] ?? 0;
    final parsed = parseCategory(value);
    final item = parsed.item;
    var tier = _tierBrowse;
    var matchedOn = 'recent';
    String? matchedToken;
    if (q.isNotEmpty) {
      if (key == q) {
        tier = _tierExact;
        matchedOn = 'whole';
        matchedToken = value;
      } else if (key.startsWith(q)) {
        tier = _tierRawPrefix;
        matchedOn = 'whole';
        matchedToken = _spanIn(value, q);
      } else if (item != null && item.startsWith(q)) {
        tier = _tierItemPrefix;
        matchedOn = 'item';
        matchedToken = item;
      } else {
        var levelHit = -1;
        for (var i = 0; i < parsed.levels.length; i++) {
          if (parsed.levels[i].startsWith(q)) {
            levelHit = i;
            break;
          }
        }
        final tokens = [...parsed.levels, if (item != null) item];
        if (levelHit >= 0) {
          tier = _tierLevelPrefix + levelHit;
          matchedOn = 'level';
          matchedToken = parsed.levels[levelHit];
        } else if (key.contains(q)) {
          tier = _tierRawContains;
          matchedOn = 'whole';
          matchedToken = _spanIn(value, q);
        } else {
          var tokenHit = -1;
          for (var i = 0; i < tokens.length; i++) {
            if (tokens[i].contains(q)) {
              tokenHit = i;
              break;
            }
          }
          if (tokenHit < 0) continue; // no match at all — never shown
          tier = _tierTokenContains + tokenHit;
          final token = tokens[tokenHit];
          matchedOn = token == item ? 'item' : 'level';
          matchedToken = token;
        }
      }
    }
    scored.add(_Candidate(CategorySuggestion(value: value, matchedOn: matchedOn, matchedToken: matchedToken, uses: count), tier));
  }
  scored.sort((a, b) {
    final byTier = a.tier.compareTo(b.tier);
    if (byTier != 0) return byTier;
    final byUses = b.suggestion.uses.compareTo(a.suggestion.uses);
    if (byUses != 0) return byUses;
    return a.suggestion.value.compareTo(b.suggestion.value);
  });
  if (limit <= 0) return const [];
  return [for (final c in scored.take(limit)) c.suggestion];
}
