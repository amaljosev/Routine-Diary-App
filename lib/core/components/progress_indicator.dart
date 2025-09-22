import 'package:flutter/material.dart';

class AnimatedProgressIndicator extends StatefulWidget {
  const AnimatedProgressIndicator({
    super.key,
    this.progressValue = 1.0,
    required this.beginColor,
    required this.endColor,
  });

  @override
  AnimatedProgressIndicatorState createState() =>
      AnimatedProgressIndicatorState();
  final double progressValue;
  final Color beginColor;
  final Color endColor;
}

class AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _valueAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _valueAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progressValue,
    ).animate(_controller);

    // Animate the color between two colors
    _colorAnimation = ColorTween(
      begin: widget.beginColor,
      end: widget.endColor,
    ).animate(_controller);

    // Start the animation once
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CircularProgressIndicator(
        strokeWidth: 15,
        backgroundColor: widget.beginColor.withValues(alpha: 0.1),
        value: _valueAnimation.value,
        valueColor: _colorAnimation,
        // ignore: deprecated_member_use
        year2023: false,
      ),
    );
  }
}
