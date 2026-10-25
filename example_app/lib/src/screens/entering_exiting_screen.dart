import 'package:dartnative/dartnative.dart';
import 'package:reanimated_dartnative/reanimated_dartnative.dart';

import '../capture/capture.dart';
import '../common/common.dart';

/// docs/layout-animations/entering-exiting-animations: every preset family,
/// with and without springify, and LayoutAnimationConfig.
class EnteringExitingScreen extends StatefulWidget {
  const EnteringExitingScreen({super.key});

  @override
  State<EnteringExitingScreen> createState() => _EnteringExitingScreenState();
}

typedef _Pair = (EntryAnimation Function(), ExitAnimation Function());

class _EnteringExitingScreenState extends State<EnteringExitingScreen> {
  static final presets = <String, _Pair>{
    'Fade': (FadeIn.new, FadeOut.new),
    'FadeRight': (FadeInRight.new, FadeOutRight.new),
    'FadeUp': (FadeInUp.new, FadeOutUp.new),
    'Slide L/R': (SlideInLeft.new, SlideOutRight.new),
    'SlideUp/Down': (SlideInUp.new, SlideOutDown.new),
    'Zoom': (ZoomIn.new, ZoomOut.new),
    'ZoomRotate': (ZoomInRotate.new, ZoomOutRotate.new),
    'ZoomEasyUp': (ZoomInEasyUp.new, ZoomOutEasyUp.new),
    'Bounce': (BounceIn.new, BounceOut.new),
    'BounceDown': (BounceInDown.new, BounceOutDown.new),
    'FlipXUp': (FlipInXUp.new, FlipOutXUp.new),
    'FlipEasyY': (FlipInEasyY.new, FlipOutEasyY.new),
    'LightSpeed': (LightSpeedInLeft.new, LightSpeedOutRight.new),
    'Pinwheel': (PinwheelIn.new, PinwheelOut.new),
    'Roll': (RollInLeft.new, RollOutRight.new),
    'Rotate': (RotateInDownLeft.new, RotateOutDownRight.new),
    'Stretch': (StretchInX.new, StretchOutY.new),
  };

  String selected = 'Fade';
  bool visible = true;
  bool springify = false;

  void toggle() => setState(() => visible = !visible);

  @override
  void initState() {
    super.initState();
    // Only used when recording the README's GIFs (capture mode). It replays
    // taps and drags automatically; skip it when reading the example.
    Capture.play(this, [
      (700, toggle),
      (900, () => setState(() {
            selected = 'Bounce';
            visible = true;
          })),
      (1300, toggle),
      (900, () => setState(() {
            selected = 'FlipXUp';
            visible = true;
          })),
      (1300, toggle),
      (900, () => setState(() {
            selected = 'Pinwheel';
            springify = true;
            visible = true;
          })),
      (1500, toggle),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pair = presets[selected]!;
    LayoutAnimation configure(LayoutAnimation a) => springify ? a.springify().dampingRatio(0.6) : a;
    return DemoPage(
      title: 'Entering / exiting',
      docs: 'layout-animations/entering-exiting-animations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Section(
            title: 'Presets',
            note: 'Pick a preset, then toggle the box.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChoiceChips<String>(
                  options: presets.keys.toList(),
                  selected: selected,
                  onSelected: (name) => setState(() => selected = name),
                ),
                const SizedBox(height: 8),
                ChoiceChips<bool>(
                  options: const [false, true],
                  selected: springify,
                  label: (spring) => spring ? '.springify()' : 'timing (default)',
                  onSelected: (spring) => setState(() => springify = spring),
                ),
                Stage(
                  height: 220,
                  child: AnimatedPresence(
                    children: [
                      if (visible)
                        AnimatedView(
                          key: ValueKey('box-$selected'),
                          entering: configure(pair.$1()),
                          exiting: configure(pair.$2()),
                          style: const AnimatedStyle(
                              width: 120, height: 120, backgroundColor: Palette.purple, borderRadius: 20),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: toggle, child: Text(visible ? 'Hide' : 'Show')),
              ],
            ),
          ),
          Section(
            title: 'LayoutAnimationConfig',
            note: 'skipEntering: these rows mount without animating; rows '
                'added later still fade in.',
            child: LayoutAnimationConfig(
              skipEntering: true,
              child: Column(children: [
                for (final i in [1, 2])
                  AnimatedView(
                    key: ValueKey('skip-$i'),
                    entering: FadeIn(),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('Mounted without entering animation $i'),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
