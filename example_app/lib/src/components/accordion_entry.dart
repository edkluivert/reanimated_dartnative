import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';
import 'accordion_item.dart';

/// One accordion section: a header that toggles [isExpanded] and turns its
/// chevron, over an [AccordionItem] body.
class AccordionEntry extends StatefulWidget {
  const AccordionEntry({super.key, required this.title, required this.body, required this.isExpanded});
  final String title;
  final String body;
  final SharedValue<bool> isExpanded;

  @override
  State<AccordionEntry> createState() => _AccordionEntryState();
}

class _AccordionEntryState extends State<AccordionEntry> with ReanimatedStateMixin {
  late final chevron = useDerivedAnimation(
    0.0,
    () => withTiming(widget.isExpanded.value ? math.pi : 0.0, duration: const Duration(milliseconds: 500)),
  );
  late final chevronStyle = useAnimatedStyle(() => AnimatedStyle(rotate: chevron.value));

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Palette.grey, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => widget.isExpanded.value = !widget.isExpanded.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  AnimatedView(
                    style: chevronStyle,
                    child: const Icon(Icons.expand_more, color: Palette.navy),
                  ),
                ]),
              ),
            ),
            AccordionItem(
              isExpanded: widget.isExpanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(widget.body, style: const TextStyle(color: Color(0xFF4A4F63))),
              ),
            ),
          ],
        ),
      );
}
