import 'package:flame/components.dart';

/// An interface representing a dead zone used in smooth follow behavior.
///
/// A dead zone defines a spatial threshold in which a target can move freely
/// without triggering a response from the follower (typically the viewfinder).
/// Once the target moves outside this area, the `computeDelta` method calculates
/// the positional delta the follower should apply to track the target.
abstract interface class DeadZone {
  /// Computes the delta by which the follower (owner) should move
  /// to bring the target back within the defined dead zone.
  ///
  /// [ownerPosition] is the current position of the follower.
  /// [targetPosition] is the current position of the target being followed.
  ///
  /// Returns a [Vector2] delta that, when applied to the owner, moves it
  /// toward the target to maintain the dead zone constraints. The delta is
  /// zero while the target is inside the dead zone.
  ///
  /// This is called every frame, so the built-in dead zones return the same
  /// vector from every call to avoid allocating a new one, and overwrite it
  /// on the next call. Copy the result with [Vector2.clone] if you need to
  /// keep it. Custom implementations may do the same, but must not modify
  /// [ownerPosition] or [targetPosition].
  Vector2 computeDelta(Vector2 ownerPosition, Vector2 targetPosition);
}

/// A rectangular dead zone that defines axis-aligned bounds around the owner.
///
/// The dead zone is specified using four distances from the center point
/// of the owner: [left], [top], [right], and [bottom]. If the target moves
/// beyond any of these boundaries, the `computeDelta` method returns a delta
/// to move the owner back toward the target just enough to restore containment.
class RectangularDeadZone implements DeadZone {
  /// Distance from the center to the left boundary.
  final double left;

  /// Distance from the center to the top boundary.
  final double top;

  /// Distance from the center to the right boundary.
  final double right;

  /// Distance from the center to the bottom boundary.
  final double bottom;

  final _delta = Vector2.zero();

  /// Creates a rectangular dead zone with the specified edge distances.
  ///
  /// All values must be non-negative. A value of `0` disables the dead zone
  /// in that direction, causing the owner to immediately track the target.
  RectangularDeadZone({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  }) : assert(
          left >= 0 && top >= 0 && right >= 0 && bottom >= 0,
          'All values must be non-negative.',
        );

  /// Creates a rectangular dead zone with identical offset on all sides.
  factory RectangularDeadZone.all(double value) =>
      RectangularDeadZone(left: value, top: value, right: value, bottom: value);

  /// Creates a rectangular dead zone with symmetrical vertical and horizontal offsets.
  factory RectangularDeadZone.symmetric({
    double vertical = 0.0,
    double horizontal = 0.0,
  }) =>
      RectangularDeadZone(
        left: horizontal,
        top: vertical,
        right: horizontal,
        bottom: vertical,
      );

  @override
  Vector2 computeDelta(Vector2 ownerPosition, Vector2 targetPosition) {
    _delta.setValues(0, 0);

    final dx = targetPosition.x - ownerPosition.x;
    if (dx > right) {
      _delta.x = dx - right;
    } else if (dx < -left) {
      _delta.x = dx + left;
    }

    final dy = targetPosition.y - ownerPosition.y;
    if (dy > bottom) {
      _delta.y = dy - bottom;
    } else if (dy < -top) {
      _delta.y = dy + top;
    }

    return _delta;
  }
}

/// A circular dead zone that defines a radius around the owner.
///
/// As long as the target remains within the specified [radius] from the
/// owner's center, the follower will not move. Once the target exits
/// the radius, the `computeDelta` method returns a vector that moves
/// the owner just enough to keep the target at the edge of the dead zone.
class CircularDeadZone implements DeadZone {
  /// The radius of the circular dead zone.
  ///
  /// Must be non-negative. A value of `0` disables the dead zone entirely.
  final double radius;

  final _delta = Vector2.zero();
  final _offset = Vector2.zero();

  /// Creates a circular dead zone with the given [radius].
  CircularDeadZone({this.radius = 0})
      : assert(radius >= 0, 'Radius must be non-negative.');

  @override
  Vector2 computeDelta(Vector2 ownerPosition, Vector2 targetPosition) {
    _delta.setValues(0, 0);

    _offset
      ..setFrom(targetPosition)
      ..sub(ownerPosition);

    final distance = _offset.length;

    if (distance <= radius) return _delta;

    final deltaDistance = distance - radius;

    _delta
      ..setFrom(_offset..normalize())
      ..scale(deltaDistance);

    return _delta;
  }
}

/// Deprecated alias for [DeadZone].
@Deprecated('Use DeadZone instead. Will be removed in 6.0.0.')
typedef Deadzone = DeadZone;

/// Deprecated alias for [RectangularDeadZone].
@Deprecated('Use RectangularDeadZone instead. Will be removed in 6.0.0.')
typedef RectangularDeadzone = RectangularDeadZone;

/// Deprecated alias for [CircularDeadZone].
@Deprecated('Use CircularDeadZone instead. Will be removed in 6.0.0.')
typedef CircularDeadzone = CircularDeadZone;
