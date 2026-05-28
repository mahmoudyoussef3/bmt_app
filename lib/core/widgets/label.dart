import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const Label({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style ?? Theme.of(context).textTheme.bodySmall);
  }
}
