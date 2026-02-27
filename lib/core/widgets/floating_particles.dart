import 'package:flutter/material.dart';

class FloatingParticles extends StatelessWidget {
  final Color color;

  const FloatingParticles({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return IgnorePointer(
      child: Stack(
        children: List.generate(50, (index) { // Increased from 20 to 50 particles
          // More varied particle sizes
          final particleSize = 2.0 + (index % 8) * 4.0;
          
          // Distribute particles more evenly across screen
          final left = (index * 13.0 * (index % 3)) % size.width;
          final top = (index * 17.0 * (index % 2 + 1)) % size.height;
          
          // Faster animation durations (reduced from 4000+ to 1500-3000ms)
          final duration = Duration(milliseconds: 5000 + (index * 30) % 1500);
          
          // Varied delays for more organic movement
          final delay = Duration(milliseconds: (index * 50) % 2000);
          
          // Create different movement patterns
          final movementPattern = index % 3;
          
          return Positioned(
            left: left,
            top: top,
            child: _FloatingParticle(
              size: particleSize,
              color: color.withValues(alpha:0.05 + (index % 8) * 0.03),
              duration: duration,
              delay: delay,
              movementPattern: movementPattern,
            ),
          );
        }),
      ),
    );
  }
}

class _FloatingParticle extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final Duration delay;
  final int movementPattern; 

  const _FloatingParticle({
    required this.size,
    required this.color,
    required this.duration,
    required this.delay,
    required this.movementPattern,
  });

  @override
  State<_FloatingParticle> createState() => FloatingParticleState();
}

class FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    // Create different movement patterns for variety
    Offset endOffset;
    switch (widget.movementPattern) {
      case 0: // Vertical movement
        endOffset = Offset(0, widget.size * 6);
        break;
      case 1: // Horizontal movement
        endOffset = Offset(widget.size * 5, 0);
        break;
      case 2: // Diagonal movement
        endOffset = Offset(widget.size * 4, widget.size * 4);
        break;
      default:
        endOffset = Offset(widget.size * 3, widget.size * 3);
    }
    
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: endOffset,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
    
    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}