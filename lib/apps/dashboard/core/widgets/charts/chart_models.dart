import 'package:flutter/widgets.dart';

/// A single labelled, coloured value used by the dashboard chart widgets.
class ChartDatum {
  final String label;
  final double value;
  final Color color;

  const ChartDatum({
    required this.label,
    required this.value,
    required this.color,
  });
}
