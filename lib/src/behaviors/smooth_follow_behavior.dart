import 'package:flame/camera.dart';
import 'package:flame/components.dart';

/// This behavior enables smooth following of the [target] by the [owner]
/// with adjustable stiffness.
///
/// The [SmoothFollowBehavior] allows the [owner] to gradually follow the
/// [target] by applying a smooth, spring-like effect. The movement is
/// controlled by the [stiffness] parameter, which dictates how quickly the
/// [owner] reaches the [target]. A higher stiffness value results in a faster
/// response, while a lower stiffness results in a slower,
/// more fluid follow motion.
///
/// The behavior operates based on the distance between the [target] and the
/// [owner], and the movement is scaled to ensure smooth transitions.
/// The following behavior can be applied to both horizontal and vertical axes
/// independently by setting the [horizontalOnly] and [verticalOnly] flags.
///
/// The [stiffness] value must be positive, with larger values causing quicker
/// follow behavior.
class SmoothFollowBehavior extends FollowBehavior {
  final double stiffness;

  SmoothFollowBehavior({
    this.stiffness = double.infinity,
    required super.target,
    super.owner,
    super.horizontalOnly,
    super.verticalOnly,
    super.key,
    super.priority,
  }) {
    assert(stiffness > 0, 'stiffness must be positive: $stiffness');
  }

  final _tempDelta = Vector2.zero();

  @override
  void update(double dt) {
    _tempDelta.setValues(
      verticalOnly ? 0 : target.position.x - owner.position.x,
      horizontalOnly ? 0 : target.position.y - owner.position.y,
    );

    final distance = _tempDelta.length;
    final deltaOffset = distance * stiffness * dt;
    if (distance > deltaOffset) {
      _tempDelta.scale(deltaOffset / distance);
    }

    if (!_tempDelta.isZero()) owner.position += _tempDelta;
  }
}
