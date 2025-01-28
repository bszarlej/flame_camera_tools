import 'package:flame/camera.dart';
import 'package:flame/components.dart';

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
    if (_tempDelta.x != 0 || _tempDelta.y != 0) {
      owner.position = _tempDelta..add(owner.position);
    }
  }
}
