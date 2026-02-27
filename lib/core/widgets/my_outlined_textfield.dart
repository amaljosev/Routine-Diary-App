import 'package:flutter/material.dart';

class MyOutlinedTextField extends StatelessWidget {
  const MyOutlinedTextField(
      {super.key,
      this.suffixIcon,
      required this.hint,
      this.radius = 15,
      this.prefix,
      this.readOnly = false,
      this.controller,
      this.myKeyboardType});
  final Widget? suffixIcon;
  final Widget? prefix;
  final String hint;
  final double radius;
  final TextEditingController? controller;
  final bool readOnly;
  final TextInputType? myKeyboardType;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: readOnly,
      controller: controller,
      keyboardType: myKeyboardType,
      decoration: InputDecoration(
        suffixIcon: suffixIcon,
        prefixIcon: prefix,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 0.0, horizontal: 15.0),
        hintText: hint,
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 1.5)),
      ),
    );
  }
}
