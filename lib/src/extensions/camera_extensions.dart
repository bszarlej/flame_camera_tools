import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flutter/widgets.dart';

extension FlameCameraTools on CameraComponent {
  /// Smoothly follows the [target] with adjustable [stiffness], allowing fine
  /// control over the following behavior.
  ///
  /// The camera gradually follows the [target] based on [stiffness], optionally
  /// restricting movement to horizontal or vertical axes. The [deadZone] defines
  /// an area around the camera where it won't follow the target.
  ///
  /// If [snap] is true, the camera immediately aligns with the target before
  /// starting smooth following.
  ///
  /// Parameters:
  /// - [target]: The position provider to follow.
  /// - [stiffness]: Responsiveness of the follow behavior, from 0.0 (no movement)
  ///   to 1.0 (instant snap).
  /// - [deadZone]: Area inside which the camera doesn't follow the target.
  ///   If not provided, a [CircularDeadzone] with radius `0` is used.
  /// - [horizontalOnly]: If true, follow only along the x-axis.
  /// - [verticalOnly]: If true, follow only along the y-axis.
  /// - [snap]: If true, immediately jump to the target's position.
  void smoothFollow(
    ReadOnlyPositionProvider target, {
    double stiffness = 1.0,
    Deadzone? deadZone,
    Vector2? offset,
    bool horizontalOnly = false,
    bool verticalOnly = false,
    bool snap = false,
  }) {
    stop();
    viewfinder.add(
      SmoothFollowBehavior(
        target: target,
        stiffness: stiffness,
        deadZone: deadZone,
        offset: offset,
        horizontalOnly: horizontalOnly,
        verticalOnly: verticalOnly,
      ),
    );
    if (snap) viewfinder.position = target.position;
  }

  /// Applies a shake effect to the camera,
  /// creating a random jittering movement.
  ///
  /// The shake effect can be customized with intensity, duration,
  /// and easing curve.
  ///
  /// Parameters:
  /// - [duration]: The duration for the shake effect.
  /// - [intensity]: The intensity of the shake effect.
  /// - [curve]: The easing curve to apply during the shake effect.
  Future<void> shake({
    required double duration,
    required double intensity,
    bool weakenOverTime = true,
    Curve curve = Curves.linear,
  }) {
    assert(duration >= 0, 'Invalid duration: Value must be non-negative');

    _removeEffects<ShakeEffect>();

    final completer = Completer();

    viewfinder.add(
      ShakeEffect(
        EffectController(duration: duration, curve: curve),
        intensity: intensity,
        weakenOverTime: weakenOverTime,
        onComplete: () => completer.complete(),
      ),
    );

    return completer.future;
  }

  /// Zooms the camera to a specific zoom level,
  /// with an optional duration and easing curve.
  ///
  /// Parameters:
  /// - [value]: The target zoom level, which must be positive.
  /// - [duration]: The duration over which the zoom effect should occur.
  /// - [curve]: The easing curve to apply during the zoom effect.
  Future<void> zoomTo(
    double value, {
    double duration = 1,
    Curve curve = Curves.linear,
  }) {
    assert(value > 0, 'zoom level must be positive: $value');
    assert(duration >= 0, 'Invalid duration: Value must be non-negative');

    _removeEffects<ScaleEffect>();

    final completer = Completer();

    if (duration == 0) {
      viewfinder.zoom = value;
      completer.complete();
    } else {
      viewfinder.add(
        ScaleEffect.to(
          Vector2.all(value),
          EffectController(duration: duration, curve: curve),
          onComplete: () => completer.complete(),
        ),
      );
    }

    return completer.future;
  }

  /// Rotates the camera by the given [angle],
  /// with an optional duration and easing curve.
  ///
  /// Parameters:
  /// - [angle]: The angle to rotate the camera to.
  /// - [duration]: The duration over which the rotation should occur.
  /// - [curve]: The easing curve to apply during the rotation.
  Future<void> rotateBy(
    double angle, {
    double duration = 1,
    Curve curve = Curves.linear,
  }) {
    assert(duration >= 0, 'Invalid duration: Value must be non-negative');
    _removeEffects<RotateEffect>();

    final completer = Completer();

    if (duration == 0) {
      viewfinder.angle = radians(angle);
      completer.complete();
    } else {
      viewfinder.add(
        RotateEffect.by(
          radians(angle),
          EffectController(duration: duration, curve: curve),
          onComplete: () => completer.complete(),
        ),
      );
    }
    return completer.future;
  }

  /// Moves the camera to focus on a specific target position.
  ///
  /// Parameters:
  /// - [targetPosition]: The target position to focus on.
  /// - [duration]: The duration for the camera to move to the target position.
  /// - [curve]: The easing curve to apply during the movement.
  Future<void> focusOn(
    Vector2 targetPosition, {
    double duration = 1,
    Curve curve = Curves.linear,
  }) {
    assert(duration >= 0, 'Invalid duration: Value must be non-negative');
    stop();

    final completer = Completer();

    if (duration == 0) {
      viewfinder.position = targetPosition;
      completer.complete();
    } else {
      viewfinder.add(
        MoveToEffect(
          targetPosition,
          EffectController(duration: duration, curve: curve),
          onComplete: () => completer.complete(),
        ),
      );
    }
    return completer.future;
  }

  /// Moves the camera to focus on a component's position.
  ///
  /// Parameters:
  /// - [target]: The [PositionProvider] to focus on.
  /// - [duration]: The duration for the camera to move to the component's position.
  /// - [curve]: The easing curve to apply during the movement.
  Future<void> focusOnComponent(
    ReadOnlyPositionProvider target, {
    double duration = 1,
    Curve curve = Curves.linear,
  }) {
    return focusOn(
      target.position,
      duration: duration,
      curve: curve,
    );
  }

  /// Moves the camera along a series of points in sequence.
  ///
  /// Parameters:
  /// - [points]: A list of [Vector2] positions for the camera to move through.
  /// - [durationPerPoint]: The duration (in seconds) for the camera to move between each point.
  /// - [curve]: The easing curve to apply during the movement.
  Future<void> moveAlongPath(
    List<Vector2> points, {
    double durationPerPoint = 1,
    Curve curve = Curves.linear,
  }) async {
    for (final point in points) {
      await focusOn(
        point,
        duration: durationPerPoint,
        curve: curve,
      );
    }
  }

  void _removeEffects<T>() {
    viewfinder.children.toList().forEach(
      (child) {
        if (child is T) child.removeFromParent();
      },
    );
  }
}
