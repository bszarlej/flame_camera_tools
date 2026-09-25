import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import 'dead_zone.dart';
import 'target_group.dart';
import 'zoom_to_fit.dart';

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
///     stiffness: 0.4,
///     deadZone: CircularDeadZone(radius: 50),
///     offset: Vector2(-40, 0),
///   ),
/// );
/// ```
///
/// To chase several targets, pass a [TargetGroup] as the target. On a
/// camera's [Viewfinder], [zoomToFit] then also zooms so that the whole group
/// stays in view.
///
/// The inherited [maxSpeed] is not used; [stiffness] controls how fast the
/// follower catches up instead.
class ChaseBehavior extends FollowBehavior {
  /// The area around the target within which the follower does not move.
  /// Defaults to a [CircularDeadZone] with a radius of `0` if not provided.
  DeadZone deadZone;

  /// The positional offset applied to the target when following.
  Vector2 offset;

  /// If set, zooms the camera so that the whole [TargetGroup] stays in view,
  /// with the same [stiffness] as the movement.
  ///
  /// Only works when the target is a [TargetGroup] and the behavior is added
  /// to a camera's [Viewfinder].
  ZoomToFit? zoomToFit;

  bool _horizontalOnly;
  bool _verticalOnly;
  double _stiffness;

  /// Temporary vector used for delta calculations during update.
  final _tempDelta = Vector2.zero();

  /// Temporary vector holding the point being followed during update.
  final _tempTarget = Vector2.zero();

  /// Creates a [ChaseBehavior].
  ///
  /// - [stiffness]: Controls how quickly the follower moves towards the target. Clamped between 0.0 and 1.0; see [stiffness] for the scale.
  /// - [deadZone]: Optional dead zone area; defaults to a [CircularDeadZone] with a radius of 0.
  /// - [offset]: Optional offset applied to the target's position.
  /// - [target]: The [ReadOnlyPositionProvider] to follow, such as a component
  ///   or a [TargetGroup].
  /// - [horizontalOnly]: If true, only follows in the horizontal direction.
  /// - [verticalOnly]: If true, only follows in the vertical direction.
  /// - [zoomToFit]: Optional zoom settings to keep a [TargetGroup] in view.
  ChaseBehavior({
    double stiffness = 1.0,
    DeadZone? deadZone,
    Vector2? offset,
    this.zoomToFit,
    required super.target,
    super.owner,
    super.horizontalOnly,
    super.verticalOnly,
    super.key,
    super.priority,
  })  : assert(
          zoomToFit == null || target is TargetGroup,
          'zoomToFit needs a TargetGroup as the target',
        ),
        deadZone = deadZone ?? CircularDeadZone(),
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

  /// How quickly the follower moves towards the target, from `0.0` (never
  /// moves) to `1.0` (follows instantly).
  ///
  /// The follower closes half of the remaining distance in a fixed time,
  /// which gets shorter the higher the stiffness:
  ///
  /// | stiffness | time to close half the distance |
  /// |-----------|---------------------------------|
  /// | 0.1       | 1.8 s                           |
  /// | 0.3       | 0.47 s                          |
  /// | 0.5       | 0.2 s                           |
  /// | 0.7       | 0.086 s                         |
  /// | 0.9       | 0.022 s                         |
  ///
  /// This behaves the same at any frame rate.
  double get stiffness => _stiffness;
  set stiffness(double value) {
    _stiffness = value.clamp(0.0, 1.0);
  }

  /// Updates the follower's position based on the target, deadZone, offset, and stiffness.
  ///
  /// While the target is an empty [TargetGroup], the follower stays where it
  /// is.
  @override
  void update(double dt) {
    final target = this.target;

    if (target is TargetGroup && target.isEmpty) return;

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

    final lerpFactor = _lerpFactor(dt);
    final distance = _tempDelta.length;
    final deltaOffset = distance * lerpFactor;

    if (distance > deltaOffset) {
      _tempDelta.scale(deltaOffset / distance);
    }
    if (!_tempDelta.isZero()) owner.position += _tempDelta;

    final zoomToFit = this.zoomToFit;
    if (zoomToFit != null) _updateZoom(zoomToFit, lerpFactor);
  }

  /// Moves the zoom of the viewfinder towards the level [zoomToFit] asks for.
  void _updateZoom(ZoomToFit zoomToFit, double lerpFactor) {
    final target = this.target;
    final viewfinder = owner;
    assert(target is TargetGroup, 'zoomToFit needs a TargetGroup as target');
    assert(viewfinder is Viewfinder, 'zoomToFit only works on a Viewfinder');
    if (target is! TargetGroup || viewfinder is! Viewfinder) return;

    final zoom = zoomToFit.zoomFor(
      target,
      viewfinder.position,
      viewfinder.camera.viewport.virtualSize,
    );
    if (zoom == null) return;

    // Zoom is a scale, so move towards it by a share of the ratio rather than
    // the difference. This makes zooming in and out feel equally fast.
    viewfinder.zoom *= pow(zoom / viewfinder.zoom, lerpFactor).toDouble();
  }

  /// The share of the remaining distance to cover in a frame of [dt] seconds.
  double _lerpFactor(double dt) {
    if (_stiffness >= 1) return 1;
    if (_stiffness <= 0) return 0;

    // The time in seconds to close half the remaining distance. Scaling it
    // by (1 - stiffness) / stiffness spreads the useful speeds evenly over
    // the range, instead of squeezing them all close to 1.
    final halfLife = 0.2 * (1 - _stiffness) / _stiffness;
    return 1 - pow(0.5, dt / halfLife).toDouble();
  }
}
