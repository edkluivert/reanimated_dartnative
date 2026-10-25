import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';
import '../components/accordion_entry.dart';

/// examples/accordion: sections open and close with a smooth height
/// animation; the chevron turns with them.
class AccordionScreen extends StatefulWidget {
  const AccordionScreen({super.key});

  @override
  State<AccordionScreen> createState() => _AccordionScreenState();
}

class _AccordionScreenState extends State<AccordionScreen> with ReanimatedStateMixin {
  static const entries = [
    ('What is Reanimated?',
        'A library for smooth animations and interactions that run at the '
            'display\'s frame rate. Shared values hold the state; animated styles '
            'read it; nothing else re-renders.'),
    ('How does this accordion work?',
        'The body is laid out at its natural height and measured. Its visible '
            'height is a derived value: withTiming(height × isExpanded). Toggling '
            'isExpanded animates it.'),
    ('Can several be open at once?',
        'Yes. Each item has its own isExpanded shared value. Try opening all '
            'three, then closing them in a different order: each animation '
            'continues from wherever the previous one left off.'),
  ];

  late final expanded = [for (var i = 0; i < entries.length; i++) useSharedValue(i == 0)];

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [
      (900, () => expanded[1].value = true),
      (1300, () => expanded[0].value = false),
      (1100, () => expanded[2].value = true),
      (1300, () => expanded[1].value = false),
      (1100, () => expanded[0].value = true),
    ]);
  }

  @override
  Widget build(BuildContext context) => DemoPage(
        title: 'Accordion',
        docs: 'examples/accordion',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < entries.length; i++)
              AccordionEntry(title: entries[i].$1, body: entries[i].$2, isExpanded: expanded[i]),
          ],
        ),
      );
}
