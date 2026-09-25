import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import 'dead_zone.dart';

/// A behavior that makes its parent chase a target.
///
/// Each frame the follower moves towards the target, applying:
/// - A [deadZone] in which the target can move without the follower moving.
/// - Smooth, frame-rate-independent catching up controlled by [stiffness].
/// - An [offset] from the target, for example to look ahead of a player.
/// - Optional [horizontalOnly] or [verticalOnly] following.
///
/// This is the behavior that `camera.chase()` adds to the viewfinder, but it
/// works on any [PositionComponent]:
///
/// ```dart
/// pet.add(
///   ChaseBehavior(
///     target: player,
///     stiffness: 0.8,
///     deadZone: CircularDeadZone(radius: 50),
///     offset: Vector2(-40, 0),
///   ),
/// );
/// ```
///
/// The inherited [maxSpeed] is not used; [stiffness] controls how fast the
/// follower catches up instead.
class ChaseBehavior extends FollowBehavior {
  /// The area around the target within which the follower does not move.
  /// Defaults to a [CircularDeadZone] with a radius of `0` if not provided.
  DeadZone deadZone;

  /// The positional offset applied to the target when following.
  Vector2 offset;

  bool _horizontalOnly;
  bool _verticalOnly;
  double _stiffness;

  /// Temporary vector used for delta calculations during update.
  final _tempDelta = Vector2.zero();

  /// Temporary vector holding the point being followed during update.
  final _tempTarget = Vector2.zero();

  /// Creates a [ChaseBehavior].
  ///
  /// - [stiffness]: Controls how quickly the follower moves towards the target. Clamped between 0.0 and 1.0.
  /// - [deadZone]: Optional dead zone area; defaults to a [CircularDeadZone] with a radius of 0.
  /// - [offset]: Optional offset applied to the target's position.
  /// - [target]: The [ReadOnlyPositionProvider] to follow, such as a component.
  /// - [horizontalOnly]: If true, only follows in the horizontal direction.
  /// - [verticalOnly]: If true, only follows in the vertical direction.
  ChaseBehavior({
    double stiffness = 1.0,
    DeadZone? deadZone,
    Vector2? offset,
    required super.target,
    super.owner,
    super.horizontalOnly,
    super.verticalOnly,
    super.key,
    super.priority,
  })  : deadZone = deadZone ?? CircularDeadZone(),
        offset = offset ?? Vector2.zero(),
        _horizontalOnly = horizontalOnly,
        _verticalOnly = verticalOnly,
        _stiffness = stiffness.clamp(0.0, 1.0);

  /// If true, only follows in the horizontal direction.
  ///
  /// Cannot be true at the same time as [verticalOnly].
  @override
  bool get horizontalOnly => _horizontalOnly;
  set horizontalOnly(bool value) {
    assert(
      !(value && _verticalOnly),
      'The behavior cannot be both horizontalOnly and verticalOnly',
    );
    _horizontalOnly = value;
  }

  /// If true, only follows in the vertical direction.
  ///
  /// Cannot be true at the same time as [horizontalOnly].
  @override
  bool get verticalOnly => _verticalOnly;
  set verticalOnly(bool value) {
    assert(
      !(value && _horizontalOnly),
      'The behavior cannot be both horizontalOnly and verticalOnly',
    );
    _verticalOnly = value;
  }

  /// How quickly the follower moves towards the target.
  double get stiffness => _stiffness;
  set stiffness(double value) {
    _stiffness = value.clamp(0.0, 1.0);
  }

  /// Updates the follower's position based on the target, deadZone, offset, and stiffness.
  @override
  void update(double dt) {
    _tempTarget
      ..setFrom(target.position)
      ..add(offset);

    // Lock the ignored axis before the dead zone check, so the distance on
    // that axis can't count towards leaving the dead zone.
    if (_horizontalOnly) _tempTarget.y = owner.position.y;
    if (_verticalOnly) _tempTarget.x = owner.position.x;

    _tempDelta.setFrom(deadZone.computeDelta(owner.position, _tempTarget));

    // Custom dead zones may still return movement on a locked axis.
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
