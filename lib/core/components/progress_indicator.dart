import 'package:flutter/material.dart';

class AnimatedProgressIndicator extends StatefulWidget {
  const AnimatedProgressIndicator({
    super.key,
    this.progressValue = 1.0,
    required this.beginColor,
    required this.endColor,
  });

  final double progressValue;
  final Color beginColor;
  final Color endColor;

  @override
  AnimatedProgressIndicatorState createState() =>
      AnimatedProgressIndicatorState();
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _setupAnimations();
    _controller.forward();
  }

  void _setupAnimations() {
    _valueAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progressValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _colorAnimation = ColorTween(
      begin: widget.beginColor,
      end: widget.endColor,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.progressValue != widget.progressValue) {
      _controller.reset();
      _setupAnimations();
      _controller.forward();
    }
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
        year2023: false,
        strokeWidth: 15,
        backgroundColor: widget.beginColor.withValues(alpha: 0.1),
        value: _valueAnimation.value,
        valueColor: _colorAnimation,
      ),
    );
  }
}
