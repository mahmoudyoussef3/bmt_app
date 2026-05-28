import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final Widget? prefix;

  const InputField({super.key, this.hint, this.controller, this.prefix});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(hintText: hint, prefixIcon: prefix),
    );
  }
}
