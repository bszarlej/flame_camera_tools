import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import 'deadzone.dart';

/// A behavior that allows a component to follow a target smoothly with configurable constraints.
///
/// This behavior calculates a delta between the follower and the target, applying:
/// - A deadzone that prevents movement until the target moves beyond a certain threshold.
/// - Optional horizontal-only or vertical-only following.
/// - Smooth interpolation using a configurable stiffness factor.
/// - An optional offset to adjust the following position.
///
/// While often used for camera components, this behavior can be applied to any [PositionComponent].
///
/// Example usage with a camera:
/// ```dart
/// final followBehavior = AdvancedFollowBehavior(
///   target: player,
///   stiffness: 0.8,
///   deadZone: CircularDeadzone(radius: 50),
///   offset: Vector2(0, -100),
/// );
/// camera.viewfinder.add(followBehavior);
/// ```
class AdvancedFollowBehavior extends FollowBehavior {
  /// The area around the target within which the follower does not move.
  /// Defaults to a [CircularDeadzone] with a radius of `0` if not provided.
  late Deadzone deadZone;

  /// The positional offset applied to the target when following.
  late Vector2 offset;

  late bool _horizontalOnly;
  late bool _verticalOnly;
  late double _stiffness;

  /// Temporary vector used for delta calculations during update.
  final _tempDelta = Vector2.zero();

  /// Creates an [AdvancedFollowBehavior].
  ///
  /// - [stiffness]: Controls how quickly the follower moves towards the target. Clamped between 0.0 and 1.0.
  /// - [deadZone]: Optional deadzone area; defaults to a [CircularDeadzone] with a radius of 0.
  /// - [offset]: Optional offset applied to the target's position.
  /// - [target]: The [PositionComponent] to follow.
  /// - [horizontalOnly]: If true, only follows in the horizontal direction.
  /// - [verticalOnly]: If true, only follows in the vertical direction.
  AdvancedFollowBehavior({
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
    _horizontalOnly = super.horizontalOnly;
    _verticalOnly = super.verticalOnly;

    this.stiffness = stiffness;
    this.deadZone = deadZone ?? CircularDeadzone();
    this.offset = offset ?? Vector2.zero();
  }

  @override
  get horizontalOnly => _horizontalOnly;
  set horizontalOnly(bool value) => _horizontalOnly = value;

  @override
  get verticalOnly => _verticalOnly;
  set verticalOnly(bool value) => _verticalOnly = value;

  /// How quickly the follower moves towards the target.
  double get stiffness => _stiffness;
  set stiffness(double value) {
    _stiffness = value.clamp(0.0, 1.0);
  }

  /// Updates the follower's position based on the target, deadzone, offset, and stiffness.
  @override
  void update(double dt) {
    _tempDelta.setFrom(
        deadZone.computeDelta(owner.position, target.position + offset));

    if (_horizontalOnly) _tempDelta.y = 0;
    if (_verticalOnly) _tempDelta.x = 0;

    final lerpFactor = 1 - pow(1 - stiffness, dt);
    final distance = _tempDelta.length;
    final deltaOffset = distance * lerpFactor;

    if (distance > deltaOffset) {
      _tempDelta.scale(deltaOffset / distance);
    }
    if (!_tempDelta.isZero()) owner.position += _tempDelta;
  }
}
