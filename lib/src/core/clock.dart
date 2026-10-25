import 'package:dartnative/dartnative.dart' show Ticker;

/// Something the [AnimationClock] advances once per display frame.
abstract interface class FrameDriven {
  /// Advances by [dt] seconds (already scaled by [AnimationClock.timeScale]).
  /// Returns `false` once it no longer needs frames.
  bool onFrame(double dt, Duration timestamp);
}

/// The frame loop every animation, frame callback and timestamp runs on.
///
/// It is driven by DartNative's [Ticker], which fires once per display
/// refresh (`CADisplayLink` on iOS, `Choreographer` on Android), so motion
/// keeps pace with 60 and 120 Hz screens and pauses while the app is in the
/// background. The ticker only runs while something is registered.
///
/// Frame callbacks ([useFrameCallback]) run before animations in each frame,
/// as in Reanimated.
class AnimationClock {
  AnimationClock._();

  static final AnimationClock instance = AnimationClock._();

  final List<FrameDriven> _callbacks = [];
  final List<FrameDriven> _animations = [];

  Ticker? _ticker;

  /// Values whose animations wrote during the current frame. Their
  /// listeners run once every animation has stepped, so a derived animation
  /// restarted by one of them still advances this frame (as Reanimated runs
  /// mappers after the frame's animations).
  final List<void Function()> _pendingNotifications = [];
  bool _steppingAnimations = false;

  /// Defers [notify] until the frame's animations have all stepped, or runs
  /// it now outside that phase.
  void notifyAfterFrame(void Function() notify) {
    if (_steppingAnimations) {
      _pendingNotifications.add(notify);
    } else {
      notify();
    }
  }

  Duration _lastElapsed = Duration.zero;
  Duration _timestamp = Duration.zero;

  /// When true, nothing starts the [Ticker]; frames come only from
  /// [manualStep]. Set it in unit tests for deterministic stepping.
  bool manual = false;

  /// Multiplies every frame's delta. `0.1` plays all animations ten times
  /// slower, like Reanimated's "Toggle slow animations" debug option.
  double timeScale = 1.0;

  /// Longest frame delta passed on, in seconds. A frame after a long stall
  /// (a breakpoint, a slow build) would otherwise make springs and decays
  /// jump.
  static const double maxFrameDelta = 0.064;

  /// Time of the current frame since the clock first started.
  Duration get timestamp => _timestamp;

  /// Whether the clock has anything to drive.
  bool get isActive => _callbacks.isNotEmpty || _animations.isNotEmpty;

  /// Adds an animation driver; it is removed once [FrameDriven.onFrame]
  /// returns false or [remove] is called.
  void add(FrameDriven driver) {
    if (!_animations.contains(driver)) _animations.add(driver);
    _ensureRunning();
  }

  /// Adds a frame callback driver. These run before animations each frame.
  void addCallback(FrameDriven driver) {
    if (!_callbacks.contains(driver)) _callbacks.add(driver);
    _ensureRunning();
  }

  void remove(FrameDriven driver) {
    _animations.remove(driver);
    _callbacks.remove(driver);
    if (!isActive) _stop();
  }

  void _ensureRunning() {
    if (manual) return;
    final ticker = _ticker ??= Ticker(_onTick, debugLabel: 'reanimated');
    if (!ticker.isActive) {
      _lastElapsed = Duration.zero;
      ticker.start();
    }
  }

  void _stop() {
    final ticker = _ticker;
    if (ticker != null && ticker.isActive) ticker.stop();
  }

  void _onTick(Duration elapsed) {
    final dtMicros = (elapsed - _lastElapsed).inMicroseconds;
    _lastElapsed = elapsed;
    _advance(dtMicros / Duration.microsecondsPerSecond);
  }

  /// Advances every driver by [seconds] of wall time, in 60 Hz frames. Used
  /// by tests, with [manual] set.
  void manualStep(double seconds) {
    var remaining = seconds;
    while (remaining > 1e-9) {
      final step = remaining < 1 / 60 ? remaining : 1 / 60;
      _advance(step);
      remaining -= step;
    }
  }

  void _advance(double seconds) {
    final dt = (seconds.clamp(0.0, maxFrameDelta)) * timeScale;
    _timestamp += Duration(microseconds: (dt * 1e6).round());
    for (final cb in List<FrameDriven>.of(_callbacks)) {
      if (!cb.onFrame(dt, _timestamp)) _callbacks.remove(cb);
    }
    _steppingAnimations = true;
    try {
      for (final anim in List<FrameDriven>.of(_animations)) {
        if (!anim.onFrame(dt, _timestamp)) _animations.remove(anim);
      }
    } finally {
      _steppingAnimations = false;
    }
    final pending = List<void Function()>.of(_pendingNotifications);
    _pendingNotifications.clear();
    for (final notify in pending) {
      notify();
    }
    if (!isActive) _stop();
  }

  /// Runs frames of [frameSeconds] until nothing is animating or [maxSeconds]
  /// pass. Test helper.
  void runUntilIdle({double frameSeconds = 1 / 60, double maxSeconds = 30}) {
    var t = 0.0;
    while (_animations.isNotEmpty && t < maxSeconds) {
      _advance(frameSeconds);
      t += frameSeconds;
    }
  }
}
