import 'package:dartnative/dartnative.dart';

/// A row of buttons.
class Buttons extends StatelessWidget {
  const Buttons(this.buttons, {super.key});

  final Map<String, VoidCallback> buttons;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in buttons.entries)
            ElevatedButton(onPressed: e.value, child: Text(e.key)),
        ],
      );
}
