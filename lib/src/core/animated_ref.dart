import 'package:dartnative/dartnative.dart'
    show GlobalKey, Offset, RenderBox, BuildContext;

/// A reference to a mounted widget, as Reanimated's `useAnimatedRef`.
///
/// It is a [GlobalKey]: pass it as a widget's `key`, then [measure] it or
/// convert coordinates with [getRelativeCoords]. Before the widget mounts,
/// and after it unmounts, those return null.
///
/// ```dart
/// final animatedRef = useAnimatedRef();
/// Container(key: animatedRef, ...)
/// ```
class AnimatedRef extends GlobalKey {
  AnimatedRef();

  /// The mounted element's context, or null.
  BuildContext? get current => currentContext;

  RenderBox? get _box {
    final ro = currentContext?.findRenderObject();
    return ro is RenderBox && ro.attached ? ro : null;
  }
}

/// Creates an [AnimatedRef], as Reanimated's `useAnimatedRef`.
AnimatedRef useAnimatedRef() => AnimatedRef();

/// A widget's size and position, as returned by [measure].
///
/// [pageX] and [pageY] are relative to the screen. In Reanimated [x] and [y]
/// are relative to the parent view; DartNative does not expose a widget's
/// parent view, so here they are relative to [measure]'s `relativeTo` ref
/// when given, and to the screen otherwise.
class MeasuredDimensions {
  const MeasuredDimensions({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.pageX,
    required this.pageY,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double pageX;
  final double pageY;

  @override
  String toString() =>
      'MeasuredDimensions(x: $x, y: $y, width: $width, height: $height, '
      'pageX: $pageX, pageY: $pageY)';
}

/// Measures the widget [ref] is attached to, as Reanimated's `measure`.
/// Returns null when it is not mounted. Pass [relativeTo] (the parent's ref)
/// to get `x`/`y` relative to it.
MeasuredDimensions? measure(AnimatedRef ref, {AnimatedRef? relativeTo}) {
  final box = ref._box;
  if (box == null) return null;
  final page = box.localToGlobal(Offset.zero);
  final parent = relativeTo?._box?.localToGlobal(Offset.zero) ?? Offset.zero;
  final size = box.size;
  return MeasuredDimensions(
    x: page.dx - parent.dx,
    y: page.dy - parent.dy,
    width: size.width,
    height: size.height,
    pageX: page.dx,
    pageY: page.dy,
  );
}

/// Converts screen coordinates ([absoluteX], [absoluteY]) to coordinates
/// relative to the widget [ref] is attached to, as Reanimated's
/// `getRelativeCoords`. Returns null when it is not mounted.
Offset? getRelativeCoords(AnimatedRef ref, double absoluteX, double absoluteY) {
  final box = ref._box;
  if (box == null) return null;
  final origin = box.localToGlobal(Offset.zero);
  return Offset(absoluteX - origin.dx, absoluteY - origin.dy);
}
