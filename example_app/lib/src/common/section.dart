import 'package:dartnative/dartnative.dart';

/// A labelled section inside a demo.
class Section extends StatelessWidget {
  const Section({super.key, required this.title, required this.child, this.note});

  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(note!, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7085))),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}
