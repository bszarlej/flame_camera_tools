import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart';

/// This behavior causes the [owner] to follow the [target] only when the
/// [target] moves outside the defined [areaBounds]. Typically, this behavior
/// is applied to the [CameraComponent]'s [Viewfinder], but it can be utilized
/// with any [PositionProvider].
///
/// The [areaBounds] represent a "dead zone" within which the [owner] will
/// not follow the [target]. The camera or component will only start to track
/// the [target] once it attempts to exit the boundaries of this defined area.
class AreaFollowBehavior extends FollowBehavior {
  final Rect areaBounds;

  AreaFollowBehavior({
    required super.target,
    required this.areaBounds,
    super.owner,
    super.maxSpeed,
    super.horizontalOnly,
    super.verticalOnly,
    super.key,
    super.priority,
  }) {
    assert(
      areaBounds.left >= 0 &&
          areaBounds.top >= 0 &&
          areaBounds.right >= 0 &&
          areaBounds.bottom >= 0,
      'Bounds must define a valid rectangular region.',
    );
  }

  final _tempDelta = Vector2.zero();

  @override
  void update(double dt) {
    _tempDelta.setValues(0, 0);

    if (!verticalOnly) {
      if (target.position.x > owner.position.x + areaBounds.right) {
        _tempDelta.x = target.position.x - owner.position.x - areaBounds.right;
      } else if (target.position.x < owner.position.x - areaBounds.left) {
        _tempDelta.x = target.position.x - owner.position.x + areaBounds.left;
      }
    }

    if (!horizontalOnly) {
      if (target.position.y > owner.position.y + areaBounds.bottom) {
        _tempDelta.y = target.position.y - owner.position.y - areaBounds.bottom;
      } else if (target.position.y < owner.position.y - areaBounds.top) {
        _tempDelta.y = target.position.y - owner.position.y + areaBounds.top;
      }
    }

    final distance = _tempDelta.length;
    final deltaOffset = maxSpeed * dt;

    if (distance > deltaOffset) {
      _tempDelta.scale(deltaOffset / distance);
    }
    if (!_tempDelta.isZero()) owner.position += _tempDelta;
  }
}
