// widgets/step_indicator.dart
import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final Color color;

  const StepIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
