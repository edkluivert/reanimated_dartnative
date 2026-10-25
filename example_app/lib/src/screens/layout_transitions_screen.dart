import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';

/// docs/layout-animations/layout-transitions: shuffle a grid and watch each
/// tile travel to its new place with the chosen transition.
class LayoutTransitionsScreen extends StatefulWidget {
  const LayoutTransitionsScreen({super.key});

  @override
  State<LayoutTransitionsScreen> createState() => _LayoutTransitionsScreenState();
}

class _LayoutTransitionsScreenState extends State<LayoutTransitionsScreen> {
  static final transitions = <String, LayoutTransition Function()>{
    'Linear': LinearTransition.new,
    'Linear springify': () => LinearTransition()..springify().dampingRatio(0.5),
    'Sequenced': SequencedTransition.new,
    'Fading': FadingTransition.new,
    'Jumping': JumpingTransition.new,
    'Curved': CurvedTransition.new,
    'EntryExit': () => EntryExitTransition()
      ..entering(FlipInEasyX())
      ..exiting(FadeOut()),
  };

  static const colors = [Palette.purple, Palette.blue, Palette.pink, Palette.yellow, Palette.navy, Color(0xFF7FD1FA)];

  String selected = 'Linear';
  List<int> order = List.generate(6, (i) => i);
  bool wide = false;
  final random = math.Random();

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [
      (900, () => setState(() => order.shuffle(random))),
      (1500, () => setState(() => order.shuffle(random))),
      (1500, () => setState(() => selected = 'Linear springify')),
      (300, () => setState(() => order.shuffle(random))),
      (1500, () => setState(() => wide = !wide)),
      (1500, () => setState(() => selected = 'Jumping')),
      (300, () => setState(() => order.shuffle(random))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final make = transitions[selected]!;
    final tile = wide ? 96.0 : 72.0;
    return DemoPage(
      title: 'Layout transitions',
      docs: 'layout-animations/layout-transitions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChoiceChips<String>(
            options: transitions.keys.toList(),
            selected: selected,
            onSelected: (name) => setState(() => selected = name),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final i in order)
                AnimatedView(
                  key: ValueKey(i),
                  layout: make(),
                  style: AnimatedStyle(width: tile, height: tile, backgroundColor: colors[i], borderRadius: 14),
                  child: Center(child: Text('${i + 1}', style: const TextStyle(color: Color(0xFFFFFFFF)))),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Buttons({
            'Shuffle': () => setState(() => order.shuffle(random)),
            'Resize': () => setState(() => wide = !wide),
          }),
        ],
      ),
    );
  }
}
