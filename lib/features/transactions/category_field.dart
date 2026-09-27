/// Category field with search-as-you-type over everything typed before.
///
/// The entry form, intake confirm and quick-add all share this: type half a
/// word, tap the past category, done — no full re-typing. Ranking is
/// core/category_suggest.dart (pure); history comes from `categorySuggestProvider`.
///
/// The field itself stays a plain freeform TextField: suggestions are a
/// shortcut, never a constraint. A category with no history is saved as typed.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/category_suggest.dart';
import '../../core/providers.dart';

class CategoryField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? helperText;
  final bool autofocus;
  final int maxSuggestions;
  final double suggestionsHeight;

  const CategoryField({
    super.key,
    required this.controller,
    this.label = 'Category',
    this.hintText,
    this.helperText,
    this.autofocus = false,
    this.maxSuggestions = 6,
    this.suggestionsHeight = 168,
  });

  @override
  ConsumerState<CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends ConsumerState<CategoryField> {
  /// Long enough to skip keystrokes mid-word, short enough to feel live.
  static const _debounce = Duration(milliseconds: 150);

  Timer? _timer;
  late String _query;
  late String _seen;
  bool _picked = false;

  @override
  void initState() {
    super.initState();
    _query = widget.controller.text.trim();
    _seen = widget.controller.text;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  /// The controller is the single source of truth: parent code (merchant guess
  /// in intake, chips in quick-add) can set the text and suggestions follow.
  void _onTextChanged() {
    final text = widget.controller.text;
    if (text == _seen) return;
    _seen = text;
    _picked = false;
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (!mounted) return;
      setState(() => _query = text);
    });
  }

  void _pick(String value) {
    _timer?.cancel();
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {
      _query = value;
      _seen = value;
      _picked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final typed = _query.trim();
    final show = !_picked && typed.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            helperText: widget.helperText,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
          ),
        ),
        if (show)
          _Suggestions(
            query: typed,
            height: widget.suggestionsHeight,
            maxSuggestions: widget.maxSuggestions,
            onPick: _pick,
          ),
      ],
    );
  }
}

class _Suggestions extends ConsumerWidget {
  final String query;
  final double height;
  final int maxSuggestions;
  final ValueChanged<String> onPick;

  const _Suggestions({
    required this.query,
    required this.height,
    required this.maxSuggestions,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final options = ref.watch(categorySuggestProvider(query));
    return options.maybeWhen(
      data: (list) {
        // What you already typed is never worth a tap.
        final known = list.any((s) => s.value.toLowerCase() == query.toLowerCase());
        final shown = [
          for (final s in list)
            if (s.value.toLowerCase() != query.toLowerCase()) s,
        ].take(maxSuggestions).toList();
        if (shown.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              known ? 'Saved as typed — start a new level or item after a space' : 'New category — saved exactly as you type',
              style: theme.textTheme.bodySmall,
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.only(top: 6),
          constraints: BoxConstraints(maxHeight: height),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: height),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: shown.length,
                  itemBuilder: (_, i) => CategorySuggestionRow(suggestion: shown[i], onTap: () => onPick(shown[i].value)),
                ),
              ),
              if (!known)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '“$query” is new — tap a row above or keep typing',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// One tappable past category. Public so widget tests can address a row
/// without matching the field's own text.
class CategorySuggestionRow extends StatelessWidget {
  final CategorySuggestion suggestion;
  final VoidCallback onTap;

  const CategorySuggestionRow({super.key, required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Expanded(child: _highlighted(context, theme)),
            if (suggestion.uses > 1) ...[
              const SizedBox(width: 8),
              Text('${suggestion.uses}×', style: theme.textTheme.bodySmall),
            ],
            const SizedBox(width: 8),
            Text(suggestion.matchedOn, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  /// Bolds the token that matched, so "gob" → **gob**i-65 reads instantly.
  Widget _highlighted(BuildContext context, ThemeData theme) {
    final token = suggestion.matchedToken;
    final base = theme.textTheme.bodyMedium;
    if (token == null || token.isEmpty) {
      return Text(suggestion.value, style: base, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    final at = suggestion.value.toLowerCase().indexOf(token.toLowerCase());
    if (at < 0) {
      return Text(suggestion.value, style: base, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    final end = at + token.length;
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: suggestion.value.substring(0, at)),
          TextSpan(text: suggestion.value.substring(at, end), style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: suggestion.value.substring(end)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
