import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flutter/widgets.dart';

extension FlameCameraTools on CameraComponent {
  /// Smoothly follows the [target] with adjustable stiffness,
  /// allowing for control over the following behavior.
  ///
  /// The camera will gradually follow the [target]
  /// based on the [stiffness] parameter,
  /// with the option to follow only horizontally or vertically.
  /// The [snap] parameter allows the camera to instantly align with the target's position.
  ///
  /// Parameters:
  /// - [target]: The position provider to follow.
  /// - [stiffness]: The responsiveness of the camera's movement. A higher value results in faster following.
  /// - [horizontalOnly]: If true, restricts the following behavior to the horizontal axis.
  /// - [verticalOnly]: If true, restricts the following behavior to the vertical axis.
  /// - [snap]: If true, the camera will immediately align with the target's position before following.
  void smoothFollow(
    ReadOnlyPositionProvider target, {
    double stiffness = double.infinity,
    bool horizontalOnly = false,
    bool verticalOnly = false,
    bool snap = false,
  }) {
    stop();
    viewfinder.add(
      SmoothFollowBehavior(
        target: target,
        stiffness: stiffness,
        horizontalOnly: horizontalOnly,
        verticalOnly: verticalOnly,
      ),
    );
    if (snap) viewfinder.position = target.position;
  }

  /// Follows the [target] within a specified rectangular area,
  /// only tracking the target once it leaves the area.
  ///
  /// The camera will follow the target only when it exceeds the bounds
  /// defined by [areaBounds]. This can be restricted to horizontal or vertical movement.
  ///
  /// Parameters:
  /// - [target]: The position provider to follow.
  /// - [areaBounds]: The rectangular area that defines when the camera should follow the target.
  /// - [maxSpeed]: Maximum speed of the camera.
  /// - [horizontalOnly]: If true, restricts the following behavior to the horizontal axis.
  /// - [verticalOnly]: If true, restricts the following behavior to the vertical axis.
  /// - [snap]: If true, the camera will immediately align with the target's position before following.
  void areaFollow(
    ReadOnlyPositionProvider target, {
    required Rect areaBounds,
    double maxSpeed = double.infinity,
    bool horizontalOnly = false,
    bool verticalOnly = false,
    bool snap = false,
  }) {
    stop();
    viewfinder.add(
      AreaFollowBehavior(
        target: target,
        areaBounds: areaBounds,
        maxSpeed: maxSpeed,
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
    required Duration duration,
    required double intensity,
    Curve curve = Curves.linear,
  }) {
    _removeEffects<ShakeEffect>();

    final completer = Completer();

    viewfinder.add(
      ShakeEffect(
        EffectController(
          duration: duration.inMicroseconds / 1000000,
          curve: curve,
        ),
        intensity: intensity,
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
    Duration duration = Duration.zero,
    Curve curve = Curves.linear,
  }) {
    assert(value > 0, 'zoom level must be positive: $value');

    _removeEffects<ScaleEffect>();

    final completer = Completer();

    if (duration == Duration.zero) {
      viewfinder.zoom = value;
    } else {
      viewfinder.add(
        ScaleEffect.to(
          Vector2.all(value),
          EffectController(
            duration: duration.inMicroseconds / 1000000,
            curve: curve,
          ),
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
    Duration duration = Duration.zero,
    Curve curve = Curves.linear,
  }) {
    _removeEffects<RotateEffect>();

    final completer = Completer();

    if (duration == Duration.zero) {
      viewfinder.angle = radians(angle);
    } else {
      viewfinder.add(
        RotateEffect.by(
          radians(angle),
          EffectController(
            duration: duration.inMicroseconds / 1000000,
            curve: curve,
          ),
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
    Duration duration = Duration.zero,
    Curve curve = Curves.linear,
  }) {
    stop();

    final completer = Completer();

    if (duration == Duration.zero) {
      viewfinder.position = targetPosition;
    } else {
      viewfinder.add(
        MoveToEffect(
          targetPosition,
          EffectController(
            duration: duration.inMicroseconds / 1000000,
            curve: curve,
          ),
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
    Duration duration = Duration.zero,
    Curve curve = Curves.linear,
  }) {
    return focusOn(
      target.position,
      duration: duration,
      curve: curve,
    );
  }

  void _removeEffects<T>() {
    viewfinder.children.toList().forEach(
      (child) {
        if (child is T) child.removeFromParent();
      },
    );
  }
}
