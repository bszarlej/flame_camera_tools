import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';

/// This behavior causes the [owner] to smoothly follow the [target] when the
/// [target] moves outside the defined [deadZone]. Typically, you would apply
/// this behavior to [CameraComponent]'s [Viewfinder], but it can be utilized
/// with any [PositionProvider].
///
/// The [deadZone] represents a "dead zone" within which the [owner] will
/// not follow the [target]. The [owner] will only start to track the [target]
/// once it attempts to exit the boundaries of this defined area.
///
/// The [stiffness] parameter controls how quickly the [owner] follows the
/// [target]. A higher stiffness results in faster following, while a lower
/// stiffness creates a smoother, slower movement. If [stiffness] is set to
/// `double.infinity` which is the default,
/// the [owner] will follow the [target] instantly.
///
/// The [horizontalOnly] and [verticalOnly] parameters restrict the behavior
/// to only follow the [target] along the specified axis.
class SmoothFollowBehavior extends FollowBehavior {
  final double stiffness;
  final Rect deadZone;

  SmoothFollowBehavior({
    this.stiffness = double.infinity,
    this.deadZone = Rect.zero,
    required super.target,
    super.owner,
    super.horizontalOnly,
    super.verticalOnly,
    super.key,
    super.priority,
  }) {
    assert(
      deadZone.left >= 0 &&
          deadZone.top >= 0 &&
          deadZone.right >= 0 &&
          deadZone.bottom >= 0,
      'Invalid Bounds: All values must be non-negative.',
    );
  }

  final _tempDelta = Vector2.zero();

  @override
  void update(double dt) {
    _tempDelta.setValues(0, 0);

    if (!verticalOnly) {
      final deltaX = target.position.x - owner.position.x;
      if (deltaX > deadZone.right) {
        _tempDelta.x = deltaX - deadZone.right;
      } else if (deltaX < -deadZone.left) {
        _tempDelta.x = deltaX + deadZone.left;
      }
    }

    if (!horizontalOnly) {
      final deltaY = target.position.y - owner.position.y;
      if (deltaY > deadZone.bottom) {
        _tempDelta.y = deltaY - deadZone.bottom;
      } else if (deltaY < -deadZone.top) {
        _tempDelta.y = deltaY + deadZone.top;
      }
    }

    final distance = _tempDelta.length;
    final deltaOffset = distance * stiffness * dt;

    if (distance > deltaOffset) {
      _tempDelta.scale(deltaOffset / distance);
    }
    if (!_tempDelta.isZero()) owner.position += _tempDelta;
  }
}
