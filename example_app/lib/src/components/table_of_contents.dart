import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../common/common.dart';

/// The section list's table of contents: a horizontal row of section names
/// with an underline that springs to the visible section and stretches to
/// its name's width. Names are measured, so any text works.
class TableOfContents extends StatefulWidget {
  const TableOfContents({
    super.key,
    required this.names,
    required this.visibleIndex,
    required this.onSelect,
    required this.controller,
  });

  final List<String> names;
  final SharedValue<int> visibleIndex;
  final void Function(int index) onSelect;
  final ScrollController controller;

  @override
  State<TableOfContents> createState() => _TableOfContentsState();
}

class _TableOfContentsState extends State<TableOfContents> with ReanimatedStateMixin {
  static const gap = 8.0;
  static const padding = 16.0;

  late final widths = useSharedValue(List<double>.filled(widget.names.length, 0));

  double _left(List<double> w, int index) {
    var x = 0.0;
    for (var i = 0; i < index; i++) {
      x += w[i] + gap;
    }
    return x;
  }

  late final indicatorX = useDerivedAnimation(
    0.0,
    () => withSpring(_left(widths.value, widget.visibleIndex.value), dampingRatio: 0.75, duration: const Duration(milliseconds: 450)),
  );
  late final indicatorWidth = useDerivedAnimation(
    0.0,
    () => withSpring(widths.value[widget.visibleIndex.value], dampingRatio: 0.75, duration: const Duration(milliseconds: 450)),
  );
  late final indicatorStyle = useAnimatedStyle(() => AnimatedStyle(
        translateX: indicatorX.value,
        width: indicatorWidth.value,
      ));

  @override
  void initState() {
    super.initState();
    // Keep the visible section's name in view.
    useAnimatedReaction(() => widget.visibleIndex.value, (index, previous) {
      if (previous == null || !widget.controller.hasClients) return;
      final x = _left(widths.value, index) - 80;
      scrollTo(widget.controller, x < 0 ? 0 : x, 0, true);
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        controller: widget.controller,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 4),
          child: Stack(
            children: [
              Row(
                children: [
                  for (var i = 0; i < widget.names.length; i++)
                    Padding(
                      padding: EdgeInsets.only(right: i == widget.names.length - 1 ? 0 : gap),
                      child: GestureDetector(
                        onTap: () => widget.onSelect(i),
                        child: AnimatedView(
                          onLayout: (size) => widths.modify((w) => w..[i] = size.width),
                          child: _Label(name: widget.names[i], index: i, visibleIndex: widget.visibleIndex),
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: AnimatedView(
                  style: Styles([const AnimatedStyle(height: 3, backgroundColor: Palette.purple, borderRadius: 2), indicatorStyle]),
                ),
              ),
            ],
          ),
        ),
      );
}

/// A section name whose color follows whether it is the visible one.
class _Label extends StatefulWidget {
  const _Label({required this.name, required this.index, required this.visibleIndex});
  final String name;
  final int index;
  final SharedValue<int> visibleIndex;

  @override
  State<_Label> createState() => _LabelState();
}

class _LabelState extends State<_Label> with ReanimatedStateMixin {
  late final selected = useDerivedValue(() => widget.visibleIndex.value == widget.index);

  @override
  Widget build(BuildContext context) => AnimatedPropsBuilder(
        props: selected,
        builder: (context, isSelected) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            widget.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Palette.navy : const Color(0xFF8A8FA3),
            ),
          ),
        ),
      );
}
