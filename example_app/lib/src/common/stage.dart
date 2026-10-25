import 'package:dartnative/dartnative.dart';

import 'palette.dart';

/// A centered stage for an animated view.
class Stage extends StatelessWidget {
  const Stage({super.key, required this.child, this.height = 180});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(color: Palette.grey, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: child,
      );
}
