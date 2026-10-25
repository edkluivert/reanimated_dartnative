import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';
import '../components/airplane_painter.dart';
import '../components/contrail_dot.dart';
import '../components/sky_cloud.dart';
import '../components/tilt_mapping.dart';

/// An airplane you fly by tilting the phone (useAnimatedSensor, gravity),
/// or by dragging where there is no sensor.
///
/// * The plane eases toward where you steer with a spring, and banks in 3D
///   into the turn by how far behind its target it is.
/// * Three cloud layers scroll at different speeds (useFrameCallback) for
///   depth; climbing toward the top of the screen flies faster.
/// * The contrail is a chain of springs, each chasing the one ahead.
/// * The ground shadow drifts with the bank.
class AirplaneScreen extends StatefulWidget {
  const AirplaneScreen({super.key});

  @override
  State<AirplaneScreen> createState() => _AirplaneScreenState();
}

class _AirplaneScreenState extends State<AirplaneScreen> with ReanimatedStateMixin {
  static const planeWidth = 110.0;
  static const planeHeight = 121.0;
  static const trailLength = 9;
  static final random = math.Random(7);

  late final area = useSharedValue(const Size(390, 700));
  late final gravity = useAnimatedSensor(SensorType.gravity);

  /// Where you are steering, from -1 to 1 on each axis.
  late final steer = useSharedValue(const Offset(0, 0.4));

  /// Where the plane is, following [steer] on a spring.
  late final position = useDerivedAnimation(
    const Offset(0, 0.4),
    () => withSpring(steer.value, dampingRatio: 0.75, duration: const Duration(milliseconds: 900)),
  );

  /// Bank angle: leaning into the turn by how far the plane lags its target.
  late final bank = useDerivedValue(() => clamp((steer.value.dx - position.value.dx) * 2.6, -1.1, 1.1));
  late final pitch = useDerivedValue(() => clamp((position.value.dy - steer.value.dy) * 1.2, -0.5, 0.5));

  /// Flying speed: faster near the top.
  late final speed = useDerivedValue(() => interpolate(position.value.dy, [-1, 1], [2.4, 0.7]));

  late final planeOrigin = useDerivedValue(() {
    final a = area.value;
    return Offset(
      (a.width - planeWidth) / 2 * (1 + position.value.dx * 0.85),
      (a.height - planeHeight) / 2 * (1 + position.value.dy * 0.8),
    );
  });

  late final planeStyle = useAnimatedStyle(() => AnimatedStyle(
        translateX: planeOrigin.value.dx,
        translateY: planeOrigin.value.dy,
        rotateY: bank.value,
        rotateX: pitch.value,
        rotate: bank.value * 0.45,
        perspective: 500,
      ));

  late final shadowStyle = useAnimatedStyle(() => AnimatedStyle(
        translateX: planeOrigin.value.dx + 30 + bank.value * 18,
        translateY: planeOrigin.value.dy + 46,
        scaleX: 0.75 * math.cos(bank.value),
        scaleY: 0.75,
      ));

  // Three cloud layers: far, middle and near. Farther layers move more
  // slowly, which is what gives the sky its depth.
  static const layerSpeeds = [30.0, 70.0, 140.0];
  late final layers = [for (final _ in layerSpeeds) useSharedValue(0.0)];
  late final clouds = [
    for (var layer = 0; layer < 3; layer++)
      for (var i = 0; i < 5; i++)
        (layer: layer, x: 0.15 + random.nextDouble() * 0.7, y: random.nextDouble(), width: [70.0, 110.0, 170.0][layer] * (0.8 + random.nextDouble() * 0.5)),
  ];

  /// The contrail: dot 0 chases the tail, each later dot the one before.
  late final List<SharedValue<Offset>> trail = _buildTrail();

  List<SharedValue<Offset>> _buildTrail() {
    final dots = <SharedValue<Offset>>[];
    for (var i = 0; i < trailLength; i++) {
      final ahead = i == 0 ? null : dots[i - 1];
      dots.add(useDerivedAnimation(
        planeOrigin.value + Offset(planeWidth / 2, planeHeight - 8 + i * 9.0),
        () {
          final target = ahead == null
              ? planeOrigin.value + const Offset(planeWidth / 2, planeHeight - 8)
              : ahead.value + Offset(0, 6 * speed.value);
          return withSpring(target, dampingRatio: 1, duration: const Duration(milliseconds: 90));
        },
      ));
    }
    return dots;
  }

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    if (Capture.enabled) {
      Capture.drive(this, 9, (t) {
        dragging = true;
        steer.value = Offset(math.sin(t * 1.3) * 0.85, 0.35 - 0.95 * math.sin(t * 0.7));
      });
    }
    useFrameCallback((frame) {
      final dt = (frame.timeSincePreviousFrame?.inMicroseconds ?? 0) / 1e6;
      for (var i = 0; i < layers.length; i++) {
        layers[i].value += layerSpeeds[i] * speed.value * dt;
      }
    });
    // Tilt to steer: rolling the phone moves the plane sideways, and tipping
    // the top of the phone away from you makes it climb.
    useAnimatedReaction(() => gravity.sensor.value, (g, _) {
      if (!gravity.isAvailable || dragging) return;
      steer.value = gravityToSteer(g);
    });
  }

  bool dragging = false;

  void onPan(DragUpdateDetails d) {
    final a = area.value;
    steer.value = Offset(
      clamp(steer.value.dx + d.delta.dx / (a.width / 2), -1, 1),
      clamp(steer.value.dy + d.delta.dy / (a.height / 2), -1, 1),
    );
  }

  Widget _cloud(({int layer, double x, double y, double width}) c) => Positioned(
        left: 0,
        top: 0,
        child: SkyCloud(
          scroll: layers[c.layer],
          area: area,
          x: c.x,
          y: c.y,
          width: c.width,
          opacity: [0.45, 0.7, 0.85][c.layer],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Airplane')),
      body: LayoutBuilder(builder: (context, constraints) {
        // Explicit sizes: a Stack of positioned children collapses without one.
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => dragging = true,
        onPanUpdate: onPan,
        onPanEnd: (_) => dragging = false,
        child: AnimatedView(
          onLayout: (s) => area.value = s,
          child: Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3D7BE0), Color(0xFF7FB8F5), Color(0xFFCFE6FB)],
              ),
            ),
            child: Stack(
              children: [
                SizedBox(width: size.width, height: size.height),
                for (final c in clouds.where((c) => c.layer < 2)) _cloud(c),
                Positioned(
                  left: 0,
                  top: 0,
                  child: AnimatedView(
                    style: shadowStyle,
                    child: const CustomPaint(
                      size: Size(planeWidth, planeHeight),
                      painter: AirplanePainter(shadow: true),
                    ),
                  ),
                ),
                for (var i = 0; i < trailLength; i++)
                  Positioned(left: 0, top: 0, child: ContrailDot(position: trail[i], index: i, length: trailLength)),
                Positioned(
                  left: 0,
                  top: 0,
                  child: AnimatedView(
                    style: planeStyle,
                    child: const CustomPaint(
                      size: Size(planeWidth, planeHeight),
                      painter: AirplanePainter(),
                    ),
                  ),
                ),
                // The near layer passes over the plane.
                for (final c in clouds.where((c) => c.layer == 2)) _cloud(c),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0x66001A72), borderRadius: BorderRadius.circular(14)),
                    child: Text(
                      gravity.isAvailable
                          ? 'Tilt to steer · tip the top away to climb and speed up'
                          : 'No motion sensor here: drag anywhere to steer',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Palette.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      }),
    );
  }
}
