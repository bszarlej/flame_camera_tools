import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

/// Several targets that can be chased as if they were one.
///
/// The group's [position] is the center of [bounds], the smallest rectangle
/// around all targets. For a [PositionComponent] the rectangle includes the
/// whole component, so its size, anchor, scale and rotation count; for any
/// other target only its position does. Using the center of the rectangle
/// rather than the average position keeps the outermost targets equally far
/// from the middle, even when most targets are on one side.
///
/// ```dart
/// final players = TargetGroup([player1, player2]);
/// camera.chase(players, zoomToFit: const ZoomToFit(padding: 100));
///
/// players.add(player3);
/// ```
///
/// Targets can be added and removed at any time, for example when a player
/// joins or leaves. A target that is removed from the game stays in the group
/// until it is removed from the group too.
class TargetGroup implements ReadOnlyPositionProvider {
  /// Creates a group of the given [targets].
  TargetGroup([Iterable<ReadOnlyPositionProvider> targets = const []])
      : _targets = [...targets];

  final List<ReadOnlyPositionProvider> _targets;
  final _position = Vector2.zero();

  /// The targets in this group.
  List<ReadOnlyPositionProvider> get targets => UnmodifiableListView(_targets);

  /// Whether the group has no targets.
  bool get isEmpty => _targets.isEmpty;

  /// Adds [target] to the group.
  void add(ReadOnlyPositionProvider target) => _targets.add(target);

  /// Removes [target] from the group and returns whether it was in it.
  bool remove(ReadOnlyPositionProvider target) => _targets.remove(target);

  /// The smallest rectangle around all targets, or `null` while the group is
  /// empty.
  ///
  /// A [PositionComponent] counts with its whole bounding rectangle in its
  /// parent's coordinates, as given by [PositionComponent.toRect]. Any other
  /// target counts as a single point at its position.
  Rect? get bounds {
    if (_targets.isEmpty) return null;

    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;

    for (final target in _targets) {
      if (target is PositionComponent) {
        final rect = target.toRect();
        left = min(left, rect.left);
        top = min(top, rect.top);
        right = max(right, rect.right);
        bottom = max(bottom, rect.bottom);
      } else {
        final position = target.position;
        left = min(left, position.x);
        top = min(top, position.y);
        right = max(right, position.x);
        bottom = max(bottom, position.y);
      }
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// The center of [bounds].
  ///
  /// While the group is empty, this stays at the last center. A group that
  /// has never had targets is at the origin.
  @override
  Vector2 get position {
    final center = bounds?.center;
    if (center != null) _position.setValues(center.dx, center.dy);
    return _position;
  }
}
