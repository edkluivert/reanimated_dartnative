import 'package:dartnative/dartnative.dart';

import 'palette.dart';

/// A row of options, one selected. Every chip always gets explicit colors:
/// a native button keeps the last color it was given when told `null`, so a
/// "selected" color set with `styleFrom(backgroundColor: selected ? c : null)`
/// would never go away.
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.label,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T option)? label;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final option in options)
            GestureDetector(
              onTap: () => onSelected(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: option == selected ? Palette.purple : const Color(0xFFEDEEF4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  label?.call(option) ?? '$option',
                  style: TextStyle(
                    fontSize: 14,
                    color: option == selected ? const Color(0xFFFFFFFF) : Palette.navy,
                  ),
                ),
              ),
            ),
        ],
      );
}
