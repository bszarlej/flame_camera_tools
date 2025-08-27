import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';

/// A behavior that allows the [owner] to smoothly follow a [target] component
/// while respecting a specified [deadZone].
///
/// This behavior is typically applied to a [Viewfinder] (used by [CameraComponent])
/// but can be used with any [PositionProvider].
///
/// The [deadZone] defines an area around the owner where the target can move
/// freely without causing the owner to follow. Only when the target exits
/// this zone does the owner begin moving to follow it.
///
/// The [stiffness] parameter controls how quickly the owner moves toward
/// the target. It should be in the range `0.0` to `1.0`, where:
/// - `0.0` results in no movement at all,
/// - `1.0` causes the owner to immediately jump to follow the target,
/// - Intermediate values result in smooth, spring-like movement.
///
/// Set [horizontalOnly] or [verticalOnly] to restrict movement to a single axis.
class SmoothFollowBehavior extends FollowBehavior {
  /// Controls how quickly the owner moves toward the target.
  ///
  /// A value between `0.0` (no movement) and `1.0` (immediate snap).
  late final double stiffness;
  late Vector2 offset;

  /// Creates a [SmoothFollowBehavior].
  ///
  /// - [stiffness]: Controls follow responsiveness.
  /// - [deadZone]: Optional. If not provided, a [CircularDeadzone] with radius `0` is used.
  /// - [target]: The component to follow.
  /// - [owner]: The component this behavior is attached to (typically a [Viewfinder]).
  /// - [horizontalOnly]: Follow only along the x-axis.
  /// - [verticalOnly]: Follow only along the y-axis.
  SmoothFollowBehavior({
    double stiffness = 1.0,
    Deadzone? deadZone,
    Vector2? offset,
    required super.target,
    super.owner,
    super.horizontalOnly,
    super.verticalOnly,
    super.key,
    super.priority,
  }) {
    this.stiffness = stiffness.clamp(0.0, 1.0);
    _deadZone = deadZone ?? CircularDeadzone();
    this.offset = offset ?? Vector2.zero();
  }

  late final Deadzone _deadZone;
  final _tempDelta = Vector2.zero();

  @override
  void update(double dt) {
    _tempDelta.setFrom(
        _deadZone.computeDelta(owner.position, target.position + offset));

    if (horizontalOnly) _tempDelta.y = 0;
    if (verticalOnly) _tempDelta.x = 0;

    final lerpFactor = 1 - pow(1 - stiffness, dt);
    final distance = _tempDelta.length;
    final deltaOffset = distance * lerpFactor;

    if (distance > deltaOffset) {
      _tempDelta.scale(deltaOffset / distance);
    }
    if (!_tempDelta.isZero()) owner.position += _tempDelta;
  }
}
