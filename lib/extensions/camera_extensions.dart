import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_camera_tools/behaviors/smooth_follow_behavior.dart';
import 'package:flame_camera_tools/effects/shake_effect.dart';
import 'package:flutter/widgets.dart';

extension CameraComponentTools on CameraComponent {
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

  void shake({required double duration, required double intensity}) {
    for (final child in viewfinder.children) {
      if (child is ShakeEffect) child.removeFromParent();
    }
    viewfinder.add(
      ShakeEffect(
        EffectController(duration: duration),
        intensity: intensity,
      ),
    );
  }

  void zoomTo(
    double value, {
    double duration = 0,
    Curve curve = Curves.linear,
  }) {
    assert(value > 0, 'zoom level must be positive: $value');

    for (final child in viewfinder.children) {
      if (child is ScaleEffect) child.removeFromParent();
    }

    if (duration == 0) {
      viewfinder.zoom = value;
    } else {
      viewfinder.add(
        ScaleEffect.to(
          Vector2.all(value),
          EffectController(duration: duration, curve: curve),
        ),
      );
    }
  }

  void focusOn(
    Vector2 targetPosition, {
    double duration = 0,
    Curve curve = Curves.linear,
  }) {
    stop();
    if (duration == 0) {
      viewfinder.position = targetPosition;
    } else {
      viewfinder.add(
        MoveToEffect(
          targetPosition,
          EffectController(duration: duration, curve: curve),
        ),
      );
    }
  }

  void focusOnComponent(
    ReadOnlyPositionProvider target, {
    double duration = 0,
    Curve curve = Curves.linear,
  }) {
    focusOn(target.position, duration: duration, curve: curve);
  }
}
