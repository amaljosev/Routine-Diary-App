import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.title,
    this.onPressed,
    this.color,
    this.foregroundColor,
    this.icon,
    this.onlyIcon = false,
    this.textColor,
    this.iconColor,
  });

  final String title;
  final Color? color;
  final Color? foregroundColor;
  final Color? textColor;
  final Color? iconColor;
  final IconData? icon;
  final bool onlyIcon;

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ElevatedButton.icon(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            color ?? Theme.of(context).primaryColor,
          ),
          foregroundColor: WidgetStatePropertyAll(
            foregroundColor ?? Colors.white,
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
        onPressed: onPressed,
        label: onlyIcon
            ? const SizedBox.shrink()
            : Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: textColor ?? Colors.white,
                ),
              ),
        icon: icon != null
            ? Icon(icon, color: iconColor ?? Colors.white)
            : const SizedBox.shrink(),
      ),
    );
  }
}
