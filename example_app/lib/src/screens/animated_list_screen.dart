import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';

/// docs/layout-animations/entering-exiting-animations and
/// layout-transitions, together: rows spring in one after another, fly out
/// when removed, and the rest glide into the gap.
class AnimatedListScreen extends StatefulWidget {
  const AnimatedListScreen({super.key});

  @override
  State<AnimatedListScreen> createState() => _AnimatedListScreenState();
}

class _Item {
  _Item(this.id) : color = _colors[id % _colors.length];
  final int id;
  final Color color;
  static const _colors = [Palette.purple, Palette.blue, Palette.pink, Palette.yellow, Color(0xFF7FD1FA)];
}

class _AnimatedListScreenState extends State<AnimatedListScreen> {
  final random = math.Random();
  int nextId = 0;
  late final List<_Item> items = [for (var i = 0; i < 5; i++) _Item(nextId++)];

  /// The rows of the first build enter one after another.
  bool _firstBuild = true;

  LayoutAnimation _entering(int index) => SlideInRight()
      .springify()
      .dampingRatio(0.75)
      .delay(Duration(milliseconds: _firstBuild ? 80 * index : 0));

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [
      (1400, add),
      (900, add),
      (1100, () => remove(items[1])),
      (1200, () => setState(() => items.shuffle(random))),
      (1400, () => setState(() => items.sort((a, b) => a.id.compareTo(b.id)))),
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstBuild = false);
  }

  void add() => setState(() => items.insert(random.nextInt(items.length + 1), _Item(nextId++)));

  void remove(_Item item) => setState(() => items.remove(item));

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Animated list',
        docs: 'layout-animations/layout-transitions',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('entering: SlideInRight.springify() with a stagger · '
                'exiting: LightSpeedOutRight · layout: LinearTransition.springify(). '
                'Tap a row to remove it.'),
            const SizedBox(height: 12),
            Buttons({
              'Add': add,
              'Shuffle': () => setState(() => items.shuffle(random)),
              'Sort': () => setState(() => items.sort((a, b) => a.id.compareTo(b.id))),
            }),
            const SizedBox(height: 16),
            AnimatedPresence(
              builder: (context, children) =>
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              children: [
                for (final (index, item) in items.indexed)
                  AnimatedView(
                    key: ValueKey(item.id),
                    entering: _entering(index),
                    exiting: LightSpeedOutRight().duration(const Duration(milliseconds: 400)),
                    layout: LinearTransition()..springify().dampingRatio(0.8),
                    child: GestureDetector(
                      onTap: () => remove(item),
                      child: Container(
                        height: 64,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(18)),
                            alignment: Alignment.center,
                            child: Text('${item.id}', style: const TextStyle(color: Palette.navy)),
                          ),
                          const SizedBox(width: 12),
                          Text('Row ${item.id}', style: const TextStyle(color: Palette.navy, fontSize: 16)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}
