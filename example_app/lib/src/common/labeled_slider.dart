import 'package:dartnative/dartnative.dart';

/// A labelled slider.
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.digits = 0,
  });

  final String label;
  final double value, min, max;
  final int digits;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(width: 110, child: Text('$label ${value.toStringAsFixed(digits)}')),
          Expanded(child: Slider(value: value, min: min, max: max, onChanged: onChanged)),
        ],
      );
}
