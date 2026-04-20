import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:routine/features/diary/presentation/widgets/dashed_border_painter.dart';

typedef ItemTransformUpdate = void Function({
  required String id,
  required double x,
  required double y,
  required double scale,
  required double rotation,
});

class TransformableItem extends StatefulWidget {
  final String id;
  final Widget child;
  final Offset initialPosition;
  final double initialScale;
  final double initialRotation;
  final bool isSelected;
  final ItemTransformUpdate onUpdate;
  final VoidCallback onRemove;
  final VoidCallback onSelect;
  final double? baseWidth;
  final double? baseHeight;
  final ValueGetter<Rect?>? getBounds;

  static const double stickerBaseSize = 100.0;
  static const double handlePadding = 20.0;

  const TransformableItem({
    super.key,
    required this.id,
    required this.child,
    required this.initialPosition,
    required this.initialScale,
    required this.initialRotation,
    required this.isSelected,
    required this.onUpdate,
    required this.onRemove,
    required this.onSelect,
    this.baseWidth,
    this.baseHeight,
    this.getBounds,
  });

  @override
  State<TransformableItem> createState() => _TransformableItemState();
}

class _TransformableItemState extends State<TransformableItem> {
  late Offset _position;
  late double _scale;
  late double _rotation;

  // ✅ Guard: prevents external rebuilds from overriding an active drag
  bool _isDragging = false;

  Offset? _lastFocalPoint;
  double _initialScaleOnGesture = 1.0;
  double _initialRotationOnGesture = 0.0;

  double get _visualWidth => widget.baseWidth != null
      ? widget.baseWidth! * _scale
      : TransformableItem.stickerBaseSize * _scale;

  double get _visualHeight => widget.baseHeight != null
      ? widget.baseHeight! * _scale
      : TransformableItem.stickerBaseSize * _scale;

  Offset _clampToBounds(Offset pos) {
    final bounds = widget.getBounds?.call();
    if (bounds == null) return pos;
    final maxX = math.max(0.0, bounds.width - _visualWidth);
    final maxY = math.max(0.0, bounds.height - _visualHeight);
    return Offset(pos.dx.clamp(0.0, maxX), pos.dy.clamp(0.0, maxY));
  }

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _scale = widget.initialScale;
    _rotation = widget.initialRotation;
  }

  // ✅ THE FIX: sync local state when the model changes externally,
  // but only when the user is not actively dragging this item.
  @override
  void didUpdateWidget(TransformableItem old) {
    super.didUpdateWidget(old);
    if (_isDragging) return;

    if (widget.initialPosition != old.initialPosition) {
      _position = widget.initialPosition;
    }
    if (widget.initialScale != old.initialScale) {
      _scale = widget.initialScale;
    }
    if (widget.initialRotation != old.initialRotation) {
      _rotation = widget.initialRotation;
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _isDragging = true; // ✅ Lock: block external syncs during gesture
    _lastFocalPoint = details.focalPoint;
    _initialScaleOnGesture = _scale;
    _initialRotationOnGesture = _rotation;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final delta = details.focalPoint - _lastFocalPoint!;

    if (details.pointerCount == 1) {
      setState(() {
        _position = _clampToBounds(_position + delta);
        _lastFocalPoint = details.focalPoint;
      });
    } else {
      final newScale =
          (_initialScaleOnGesture * details.scale).clamp(0.3, 5.0);
      final newRotation = _initialRotationOnGesture + details.rotation;
      setState(() {
        _scale = newScale;
        _rotation = newRotation;
        _position = _clampToBounds(_position + delta);
        _lastFocalPoint = details.focalPoint;
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isDragging = false; // ✅ Unlock: allow external syncs again
    widget.onUpdate(
      id: widget.id,
      x: _position.dx,
      y: _position.dy,
      scale: _scale,
      rotation: _rotation,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (widget.baseWidth != null && widget.baseHeight != null) {
      content = SizedBox(
        width: _visualWidth,
        height: _visualHeight,
        child: widget.child,
      );
    } else {
      content = Container(
        width: _visualWidth,
        height: _visualHeight,
        alignment: Alignment.center,
        child: FittedBox(fit: BoxFit.scaleDown, child: widget.child),
      );
    }
    content = Transform.rotate(angle: _rotation, child: content);

    final paddedChild = Padding(
      padding: const EdgeInsets.all(TransformableItem.handlePadding),
      child: content,
    );

    Widget displayChild = paddedChild;
    if (widget.isSelected) {
      displayChild = CustomPaint(
        painter: DashedBorderPainter(
          color: Theme.of(context).colorScheme.primary,
          strokeWidth: 2,
          gap: 4,
        ),
        child: paddedChild,
      );
    }

    final stackChildren = <Widget>[displayChild];
    if (widget.isSelected) {
      stackChildren.add(
        Positioned(
          top: 0,
          left: 0,
          child: GestureDetector(
            onTap: widget.onRemove,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: _position.dx - TransformableItem.handlePadding,
      top: _position.dy - TransformableItem.handlePadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelect,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: Stack(clipBehavior: Clip.none, children: stackChildren),
      ),
    );
  }
}