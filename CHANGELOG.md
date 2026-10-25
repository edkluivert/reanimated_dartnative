# Changelog

## 0.1.0

A rewrite that follows Reanimated 4's documented behaviour. Breaking changes
throughout.

### Engine
- During a frame, shared values written by animations notify their
  listeners only after every animation has stepped, as Reanimated runs
  mappers after the frame. Before this, a derived animation chasing a
  moving animated value (a contrail, chained springs) was restarted before
  it could step and froze until its target stopped.
- Animations run on DartNative's `Ticker` (display refresh, real frame
  time, paused in the background) instead of a 16 ms `Timer`. `manualStep`,
  `runUntilIdle` and `AnimationClock.manual` drive it in tests.
- `SharedValue` is a `ValueListenable`, gains `get`/`set`/`modify`, and
  animates `Color`, `Offset`, `Size` and `List<double>` as well as numbers.
- `useDerivedValue`, `useAnimatedStyle`, `useAnimatedProps` and
  `useAnimatedReaction` track the shared values they read; dependency
  lists are gone.
- `ReanimatedStateMixin` provides the `use*` hooks on a `State` and
  disposes what they create.

### Animations
- `withSpring`: Reanimated 4 defaults (mass 4, stiffness 900, damping 120),
  perceptual duration-based springs, `energyThreshold`, `clamp`, and
  velocity inherited from the interrupted animation.
- `withRepeat`: `reverse` works (it previously did not move);
  `numberOfReps` defaults to 2, and zero or less repeats forever.
- `withDecay`: Reanimated's rigid and rubber-band decay; `Offset` velocity.
- `withClamp` reports cancellation to its callback.
- `reduceMotion` on every animation, with the accessibility guide's rules;
  `useReducedMotion` reads the device setting natively and follows changes.
- `Easing` matches Reanimated (`Easing.cubic` is t³, `Easing.ease` is
  `bezier(0.42, 0, 1, 1)`, `steps(n, roundToNextStep)`).

### Views and layout
- `useDerivedAnimation`: a value that animates to whatever its updater
  returns, the Dart form of `useDerivedValue(() => withTiming(...))`.
- `AnimatedView.onLayout` and `AnimatedView.backfaceVisibility`.
- New `AnimatedView` renders styles, entering/exiting animations, layout
  transitions, CSS animations and transitions, and shared element tags.
- Every entering/exiting preset family plays for real; `AnimatedPresence`
  keeps exiting children on screen until their animation ends.
- `Keyframe` validates like Reanimated and supports per-step easing.
- Layout transitions (Linear, Sequenced, Fading, Jumping, Curved,
  EntryExit) animate measured position and size changes.
- CSS animations (iteration count, direction, fill mode, play state, per
  keyframe timing, events) and CSS transitions (per-property, delay,
  events) run in `AnimatedView`.
- `measure` and `getRelativeCoords` read real layout through
  `AnimatedRef`, a `GlobalKey`.
- Scroll APIs take the scroll view's `ScrollController`.

### Native
- Sensor axis and unit conversions moved to `ReanimatedSensorMath` (Swift
  and Kotlin), tested on the Mac by `tool/test_native_math.sh` against
  simulated device poses.
- Android: the missing `ReanimatedDartNativeBridge` is implemented
  (`SensorManager` for all five sensors, interface-orientation remapping,
  reduce motion via `ANIMATOR_DURATION_SCALE`). Sensors previously never
  reported on Android.
- iOS: one shared `CMMotionManager` fans out to every subscriber (gravity
  and rotation no longer stop each other), readings use Android's axes and
  units, `adjustToInterfaceOrientation` is applied, availability is
  reported, and Reduce Motion changes are observed.
- Readings travel as compact number lists instead of JSON.

### Removed
- `setNativeProps`, `dispatchCommand`, `useEvent`, `useHandler`,
  `useComposedEventHandler`, `MutableValue` (`makeMutable` returns a
  `SharedValue`), `AnimatedSensor.updateReading` (use `debugEmit` in tests).

### Docs
- `doc/EXAMPLES.md` and `doc/examples/*.md`: every example with its GIF,
  what to look at, and its full code, generated from `example_app/lib` by
  `tool/gen_examples_docs.py`.
- README rewritten as a full guide; GIFs of the examples in `doc/gifs/`,
  regenerated with `tool/make_gifs.sh`.
