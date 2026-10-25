import 'clock.dart';
import 'shared_value.dart';

/// Timing of the current frame, passed to a [FrameCallback].
class FrameInfo {
  const FrameInfo({
    required this.timestamp,
    required this.timeSincePreviousFrame,
    required this.timeSinceFirstFrame,
  });

  /// The frame's time on the animation clock.
  final Duration timestamp;

  /// Time since the previous frame; null on the first frame.
  final Duration? timeSincePreviousFrame;

  /// Time since the callback's first frame.
  final Duration timeSinceFirstFrame;
}

/// Runs a function on every frame, as Reanimated's `useFrameCallback`.
/// Frame callbacks run before animations in each frame.
class FrameCallback implements FrameDriven {
  FrameCallback(this.callback, {bool autostart = true}) {
    if (autostart) setActive(true);
  }

  static int _ids = 0;

  final void Function(FrameInfo frameInfo) callback;

  /// A unique id for this callback.
  final int callbackId = ++_ids;

  bool _active = false;
  Duration? _first;
  Duration? _previous;

  /// Whether the callback runs every frame.
  bool get isActive => _active;

  /// Starts or stops the callback. Restarting resets
  /// [FrameInfo.timeSinceFirstFrame].
  void setActive(bool active) {
    if (active == _active) return;
    _active = active;
    if (active) {
      _first = null;
      _previous = null;
      AnimationClock.instance.addCallback(this);
    } else {
      AnimationClock.instance.remove(this);
    }
  }

  @override
  bool onFrame(double dt, Duration timestamp) {
    if (!_active) return false;
    final first = _first ??= timestamp;
    final info = FrameInfo(
      timestamp: timestamp,
      timeSincePreviousFrame:
          _previous == null ? null : timestamp - _previous!,
      timeSinceFirstFrame: timestamp - first,
    );
    _previous = timestamp;
    callback(info);
    return _active;
  }

  void dispose() => setActive(false);
}

/// Creates a [FrameCallback], as Reanimated's `useFrameCallback`.
///
/// ```dart
/// final frameCallback = useFrameCallback((frameInfo) {
///   final t = frameInfo.timeSinceFirstFrame.inMicroseconds / 1e6;
///   x.value = 100 * math.sin(t);
/// });
/// ...
/// frameCallback.setActive(!frameCallback.isActive);
/// ```
FrameCallback useFrameCallback(
  void Function(FrameInfo frameInfo) callback, {
  bool autostart = true,
}) =>
    FrameCallback(callback, autostart: autostart);

/// A shared value holding the milliseconds since it started, updated every
/// frame, as Reanimated's `useTimestamp`. Dispose it to stop it.
class TimestampValue extends SharedValue<double> {
  TimestampValue({bool isActive = true}) : super(0) {
    _callback = FrameCallback(
      (info) => value = info.timeSinceFirstFrame.inMicroseconds / 1000,
      autostart: isActive,
    );
  }

  late final FrameCallback _callback;

  bool get isActive => _callback.isActive;
  void setActive(bool active) => _callback.setActive(active);

  @override
  void dispose() {
    _callback.dispose();
    super.dispose();
  }
}

/// Creates a [TimestampValue], as Reanimated's `useTimestamp`.
TimestampValue useTimestamp({bool isActive = true}) =>
    TimestampValue(isActive: isActive);
