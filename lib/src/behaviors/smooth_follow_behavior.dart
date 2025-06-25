import 'dart:math';

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
/// [target]. The value should be between 0.0 and 1.0, where 0.0 means no movement
/// and 1.0 means immediate following.
///
/// The [horizontalOnly] and [verticalOnly] parameters restrict the behavior
/// to only follow the [target] along the specified axis.
class SmoothFollowBehavior extends FollowBehavior {
  late final double stiffness;
  final Rect deadZone;

  SmoothFollowBehavior({
    double stiffness = 1.0,
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

    this.stiffness = stiffness.clamp(0.0, 1.0);
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

    final lerpFactor = 1 - pow(1 - stiffness, dt);
    final distance = _tempDelta.length;
    final deltaOffset = distance * lerpFactor;

    if (distance > deltaOffset) {
      _tempDelta.scale(deltaOffset / distance);
    }
    if (!_tempDelta.isZero()) owner.position += _tempDelta;
  }
}
