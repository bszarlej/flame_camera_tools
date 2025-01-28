import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_camera_tools/behaviors/smooth_follow_behavior.dart';
import 'package:flame_camera_tools/effects/shake_effect.dart';
import 'package:flutter/widgets.dart';

extension FlameCameraTools on CameraComponent {
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

  Future<void> shake({
    required Duration duration,
    required double intensity,
    Curve curve = Curves.linear,
  }) {
    viewfinder.children.toList().forEach((child) {
      if (child is ShakeEffect) child.removeFromParent();
    });

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

  Future<void> zoomTo(
    double value, {
    Duration duration = const Duration(seconds: 0),
    Curve curve = Curves.linear,
  }) {
    assert(value > 0, 'zoom level must be positive: $value');

    viewfinder.children.toList().forEach((child) {
      if (child is ScaleEffect) child.removeFromParent();
    });

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

  Future<void> focusOn(
    Vector2 targetPosition, {
    Duration duration = const Duration(seconds: 0),
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

  Future<void> focusOnComponent(
    ReadOnlyPositionProvider target, {
    Duration duration = const Duration(seconds: 0),
    Curve curve = Curves.linear,
  }) {
    return focusOn(
      target.position,
      duration: duration,
      curve: curve,
    );
  }
}
