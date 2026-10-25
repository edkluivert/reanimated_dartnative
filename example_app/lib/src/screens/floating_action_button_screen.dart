import 'package:dartnative/dartnative.dart';

import '../common/common.dart';
import '../components/floating_action_button.dart';

/// examples/floatingactionbutton: the "+" turns into an × and three buttons
/// spring out above it, each scaling in a little after the one below.
class FloatingActionButtonScreen extends StatefulWidget {
  const FloatingActionButtonScreen({super.key});

  @override
  State<FloatingActionButtonScreen> createState() => _FloatingActionButtonScreenState();
}

class _FloatingActionButtonScreenState extends State<FloatingActionButtonScreen> {
  String selected = 'Tap the + button';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Floating action button')),
        body: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('docs: examples/floatingactionbutton',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
                  const SizedBox(height: 12),
                  Text(selected, style: const TextStyle(fontSize: 18)),
                ]),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 40,
              child: ExpandingFab(
                items: const [('M', Palette.purple), ('W', Palette.blue), ('S', Palette.pink)],
                onSelected: (label) => setState(() => selected = 'Pressed $label'),
              ),
            ),
          ],
        ),
      );
}
