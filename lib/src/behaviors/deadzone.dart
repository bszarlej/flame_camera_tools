import 'package:flame/components.dart';

/// An interface representing a deadzone used in smooth follow behavior.
///
/// A deadzone defines a spatial threshold in which a target can move freely
/// without triggering a response from the follower (typically the viewfinder).
/// Once the target moves outside this area, the `computeDelta` method calculates
/// the positional delta the follower should apply to track the target.
abstract class Deadzone {
  /// Computes the delta by which the follower (owner) should move
  /// to bring the target back within the defined deadzone.
  ///
  /// [ownerPosition] is the current position of the follower.
  /// [targetPosition] is the current position of the target being followed.
  ///
  /// Returns a [Vector2] delta that, when applied to the owner, moves it
  /// toward the target to maintain the deadzone constraints.
  Vector2 computeDelta(Vector2 ownerPosition, Vector2 targetPosition);
}

/// A rectangular deadzone that defines axis-aligned bounds around the owner.
///
/// The deadzone is specified using four distances from the center point
/// of the owner: [left], [top], [right], and [bottom]. If the target moves
/// beyond any of these boundaries, the `computeDelta` method returns a delta
/// to move the owner back toward the target just enough to restore containment.
class RectangularDeadzone implements Deadzone {
  /// Distance from the center to the left boundary.
  final double left;

  /// Distance from the center to the top boundary.
  final double top;

  /// Distance from the center to the right boundary.
  final double right;

  /// Distance from the center to the bottom boundary.
  final double bottom;

  /// Creates a rectangular deadzone with the specified edge distances.
  ///
  /// All values must be non-negative. A value of `0` disables the deadzone
  /// in that direction, causing the owner to immediately track the target.
  RectangularDeadzone({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  }) : assert(
          left >= 0 && top >= 0 && right >= 0 && bottom >= 0,
          'All values must be non-negative.',
        );

  final _delta = Vector2.zero();

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

/// A circular deadzone that defines a radius around the owner.
///
/// As long as the target remains within the specified [radius] from the
/// owner's center, the follower will not move. Once the target exits
/// the radius, the `computeDelta` method returns a vector that moves
/// the owner just enough to keep the target at the edge of the deadzone.
class CircularDeadzone implements Deadzone {
  /// The radius of the circular deadzone.
  ///
  /// Must be non-negative. A value of `0` disables the deadzone entirely.
  final double radius;

  /// Creates a circular deadzone with the given [radius].
  CircularDeadzone({this.radius = 0})
      : assert(radius >= 0, 'Radius must be non-negative.');

  final _delta = Vector2.zero();
  final _offset = Vector2.zero();

  @override
  Vector2 computeDelta(Vector2 ownerPosition, Vector2 targetPosition) {
    _delta.setValues(0, 0);

    _offset
      ..setFrom(targetPosition)
      ..sub(ownerPosition);

    final distance = _offset.length;

    if (distance <= radius) return _delta;

    final deltaDistance = distance - radius;

    _delta.setFrom(_offset..normalize());
    _delta.scale(deltaDistance);

    return _delta;
  }
}
