import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen image viewer with:
///   • Hero animation from the thumbnail
///   • Pinch-to-zoom + pan (InteractiveViewer)
///   • Double-tap to toggle zoom
///   • Swipe-down to dismiss
///   • Frosted-glass top bar with close button
class FullScreenImageViewer extends StatefulWidget {
  final String imagePath;
  final String heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    required this.heroTag,
  });

  static Future<void> show(
    BuildContext context, {
    required String imagePath,
    required String heroTag,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => FullScreenImageViewer(
          imagePath: imagePath,
          heroTag:   heroTag,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child:   child,
        ),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformCtrl = TransformationController();

  // Background opacity — animates on swipe-down
  double _bgOpacity = 1.0;

  // Swipe-to-dismiss tracking
  double _dragOffset    = 0.0;
  bool   _isDismissing  = false;

  // Double-tap zoom animation
  late AnimationController _doubleTapAnim;
  Animation<Matrix4>? _doubleTapMatrix;
  bool _isZoomedIn = false;

  // Controls bar visibility
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _doubleTapAnim = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        if (_doubleTapMatrix != null) {
          _transformCtrl.value = _doubleTapMatrix!.value;
        }
      });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _transformCtrl.dispose();
    _doubleTapAnim.dispose();
    super.dispose();
  }

  // ── Double-tap zoom ────────────────────────────────────────────────────────

  void _onDoubleTapDown(TapDownDetails details) {
  if (_isZoomedIn) {
    // Zoom back out to identity
    _animateMatrix(Matrix4.identity());
    _isZoomedIn = false;
  } else {
    // Zoom 2.5× centred on the tap point
    final position = details.localPosition;

    // FIX: Multiply the identity matrix directly using built-in constructors 
    // to avoid the 4D math bugs of translateByDouble / scaleByDouble
    final Matrix4 zoomed = Matrix4.identity()
      ..multiply(Matrix4.translationValues(-position.dx * 1.5, -position.dy * 1.5, 0.0))
      ..multiply(Matrix4.diagonal3Values(2.5, 2.5, 1.0));

    _animateMatrix(zoomed);
    _isZoomedIn = true;
  }
}

  void _animateMatrix(Matrix4 end) {
    _doubleTapMatrix = Matrix4Tween(
      begin: _transformCtrl.value,
      end:   end,
    ).animate(CurvedAnimation(
      parent: _doubleTapAnim,
      curve:  Curves.easeInOutCubic,
    ));
    _doubleTapAnim
      ..reset()
      ..forward();
  }

  // ── Swipe-down to dismiss ──────────────────────────────────────────────────

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if (_transformCtrl.value != Matrix4.identity()) return; // only when not zoomed
    setState(() {
      _dragOffset += d.delta.dy;
      _bgOpacity   = (1.0 - (_dragOffset.abs() / 300)).clamp(0.0, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    if (_dragOffset.abs() > 120 || velocity.abs() > 600) {
      _dismiss();
    } else {
      // Snap back
      setState(() {
        _dragOffset = 0;
        _bgOpacity  = 1.0;
      });
    }
  }

  void _dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    Navigator.of(context).pop();
  }

  // ── Controls toggle ────────────────────────────────────────────────────────

  void _toggleControls() => setState(() => _showControls = !_showControls);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap:                _toggleControls,
        onDoubleTapDown:      _onDoubleTapDown,
        onDoubleTap:          () {}, // required for onDoubleTapDown to fire
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd:    _onVerticalDragEnd,
        child: AnimatedContainer(
          duration:   const Duration(milliseconds: 80),
          color:      Colors.black.withValues(alpha: _bgOpacity * 0.92),
          child: Stack(
            children: [
              // ── Image ─────────────────────────────────────────────────────
              Center(
                child: Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: Hero(
                    tag:           widget.heroTag,
                    flightShuttleBuilder: _heroShuttleBuilder,
                    child: InteractiveViewer(
                      transformationController: _transformCtrl,
                      minScale:                 0.5,
                      maxScale:                 6.0,
                      clipBehavior:             Clip.none,
                      child: Image.file(
                        File(widget.imagePath),
                        fit:    BoxFit.contain,
                        width:  size.width,
                        height: size.height,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white38,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Top controls bar ──────────────────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve:    Curves.easeInOut,
                top:      _showControls ? 0 : -120,
                left:     0,
                right:    0,
                child: _TopBar(onClose: _dismiss),
              ),

              // ── Bottom hint ───────────────────────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve:    Curves.easeInOut,
                bottom:   _showControls ? 0 : -80,
                left:     0,
                right:    0,
                child: const _BottomHint(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Keeps the image crisp during the Hero flight
  Widget _heroShuttleBuilder(
    BuildContext _,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromCtx,
    BuildContext toCtx,
  ) {
    return FadeTransition(
      opacity: animation,
      child:   toCtx.widget,
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top:    MediaQuery.of(context).padding.top + 8,
            bottom: 12,
            left:   8,
            right:  16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              // Close
              _GlassButton(
                onTap: onClose,
                icon:  Icons.close_rounded,
              ),
              const Spacer(),
              // Hint text
              Text(
                'Double-tap to zoom  •  Swipe down to close',
                style: TextStyle(
                  color:     Colors.white.withValues(alpha: 0.55),
                  fontSize:  11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom hint ────────────────────────────────────────────────────────────────

class _BottomHint extends StatelessWidget {
  const _BottomHint();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            top:    16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end:   Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Container(
              width:  48,
              height: 4,
              decoration: BoxDecoration(
                color:         Colors.white.withValues(alpha: 0.35),
                borderRadius:  BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass icon button ──────────────────────────────────────────────────────────

class _GlassButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData     icon;
  const _GlassButton({required this.onTap, required this.icon});

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                color:         Colors.white.withValues(alpha: 0.15),
                borderRadius:  BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: Icon(widget.icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}