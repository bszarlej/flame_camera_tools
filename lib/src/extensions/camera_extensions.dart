import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../behaviors/advanced_follow_behavior.dart';
import '../behaviors/deadzone.dart';
import '../effects/shake_effect.dart';

extension FlameCameraTools on CameraComponent {
  /// Smoothly follows a target [ReadOnlyPositionProvider] using [AdvancedFollowBehavior].
  ///
  /// - [stiffness]: How quickly the camera follows the target (0.0–1.0).
  /// - [deadZone]: Optional deadzone to prevent minor movements from moving the camera.
  /// - [offset]: Optional positional offset applied to the target.
  /// - [horizontalOnly]: If true, only follows in the horizontal direction.
  /// - [verticalOnly]: If true, only follows in the vertical direction.
  /// - [snap]: If true, immediately moves the camera to the target's position.
  ///
  /// Returns the [AdvancedFollowBehavior] instance, allowing later adjustments to its settings.
  AdvancedFollowBehavior chase(
    ReadOnlyPositionProvider target, {
    double stiffness = 1.0,
    Deadzone? deadZone,
    Vector2? offset,
    bool horizontalOnly = false,
    bool verticalOnly = false,
    bool snap = false,
  }) {
    stop();

    final advancedFollowBehavior = AdvancedFollowBehavior(
      target: target,
      stiffness: stiffness,
      deadZone: deadZone,
      offset: offset,
      horizontalOnly: horizontalOnly,
      verticalOnly: verticalOnly,
    );

    viewfinder.add(advancedFollowBehavior);

    if (snap) viewfinder.position = target.position;

    return advancedFollowBehavior;
  }

  /// Shakes the camera using a [ShakeEffect].
  ///
  /// - [amplitude]: Maximum shake offset in pixels.
  /// - [controller]: Defines the duration, progression curve, and damping of the shake effect.
  ///
  /// Returns a [Future] that completes when the shake finishes.
  Future<void> shake(double amplitude, EffectController controller) {
    _removeEffects<ShakeEffect>();

    final completer = Completer();

    viewfinder.add(
      ShakeEffect(
        amplitude,
        controller,
        onComplete: completer.complete,
      ),
    );

    return completer.future;
  }

  /// Smoothly zooms the camera by a relative [value].
  ///
  /// - [value]: The relative change in zoom. For example, `0.5` increases the zoom by 50%, while `-0.5` decreases it by 50%.
  /// - [controller]: Controls the duration, interpolation curve, and smoothing of the zoom effect.
  ///
  /// Returns a [Future] that completes when the zoom finishes.
  Future<void> zoomBy(double value, EffectController controller) {
    _removeEffects<ScaleEffect>();

    final completer = Completer();

    viewfinder.add(
      ScaleEffect.by(
        Vector2.all(1 + value),
        controller,
        onComplete: completer.complete,
      ),
    );

    return completer.future;
  }

  /// Smoothly zooms the camera to an absolute zoom level [value].
  ///
  /// - [value]: Target zoom level (must be positive).
  /// - [controller]: Controls the duration, interpolation curve, and smoothing of the zoom effect.
  ///
  /// Returns a [Future] that completes when the zoom finishes.
  Future<void> zoomTo(double value, EffectController controller) {
    assert(value > 0, 'zoom level must be positive: $value');

    _removeEffects<ScaleEffect>();

    final completer = Completer();

    viewfinder.add(
      ScaleEffect.to(
        Vector2.all(value),
        controller,
        onComplete: completer.complete,
      ),
    );

    return completer.future;
  }

  /// Rotates the camera by a relative [angle] in radians.
  ///
  /// - [angle]: Amount to rotate the camera by in radians.
  /// - [controller]: Controls the duration, interpolation curve, and smoothing of the rotation.
  ///
  /// Returns a [Future] that completes when the rotation finishes.
  Future<void> rotateBy(double angle, EffectController controller) {
    _removeEffects<RotateEffect>();

    final completer = Completer();

    viewfinder.add(
      RotateEffect.by(
        radians(angle),
        controller,
        onComplete: completer.complete,
      ),
    );

    return completer.future;
  }

  /// Moves the camera directly to a [targetPosition].
  ///
  /// - [targetPosition]: The position to move the camera to.
  /// - [controller]: Controls the duration, interpolation curve, and smoothing of the movement.
  ///
  /// Returns a [Future] that completes when the movement finishes.
  Future<void> lookAt(Vector2 targetPosition, EffectController controller) {
    stop();

    final completer = Completer();

    viewfinder.add(
      MoveToEffect(
        targetPosition,
        controller,
        onComplete: completer.complete,
      ),
    );

    return completer.future;
  }

  /// Plays a sequence of camera effects in order.
  ///
  /// - [effects]: A list of functions that return [Future]s for each effect.
  /// Each effect will start only after the previous one completes.
  ///
  /// Example usage:
  /// ```dart
  /// await camera.effectSequence([
  ///   () => camera.shake(20.0, LinearEffectController(0.5)),
  ///   () => camera.zoomTo(2.0, LinearEffectController(0.5)),
  ///   () => camera.rotateBy(45, LinearEffectController(0.5)),
  /// ]);
  /// ```
  Future<void> effectSequence(List<Future<void> Function()> effects) async {
    for (final effect in effects) {
      await effect();
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
