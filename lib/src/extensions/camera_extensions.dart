import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../behaviors/advanced_follow_behavior.dart';
import '../behaviors/dead_zone.dart';
import '../effects/shake_effect.dart';

/// Components added by [FlameCameraTools] that are not mounted yet, with the
/// completers of the futures returned for them.
///
/// Flame only lists a child in `children` once it is mounted, so a component
/// added in the current frame has to be tracked here to be replaceable.
final _pending = Expando<Map<Component, Completer<void>>>();

/// Camera helpers for Flame's [CameraComponent].
///
/// Adds smooth following with [chase], camera effects with [shake], [zoomBy],
/// [zoomTo], [rotateBy] and [lookAt], and chaining with [effectSequence].
///
/// Starting an effect replaces a running effect of the same kind: a new zoom
/// replaces the current zoom, a new shake the current shake, and so on.
/// [chase] and [lookAt] also stop any active following or camera movement.
///
/// Each effect method returns a [Future] that completes when the effect
/// finishes or is cancelled, so effects can be awaited or chained:
///
/// ```dart
/// camera.chase(player, stiffness: 0.9);
/// await camera.zoomTo(1.5, EffectController(duration: 1));
/// await camera.shake(10, EffectController(duration: 0.5));
/// ```
extension FlameCameraTools on CameraComponent {
  /// Smoothly follows a target [ReadOnlyPositionProvider] using [AdvancedFollowBehavior].
  ///
  /// - [stiffness]: How quickly the camera follows the target (0.0–1.0).
  /// - [deadZone]: Optional dead zone to prevent camera movements within a defined area.
  /// - [offset]: Optional positional offset applied to the target.
  /// - [horizontalOnly]: If true, only follows in the horizontal direction.
  /// - [verticalOnly]: If true, only follows in the vertical direction.
  /// - [snap]: If true, immediately moves the camera to the target's position plus [offset].
  ///
  /// Returns the [AdvancedFollowBehavior] instance, allowing later adjustments to its settings.
  AdvancedFollowBehavior chase(
    ReadOnlyPositionProvider target, {
    double stiffness = 1.0,
    DeadZone? deadZone,
    Vector2? offset,
    bool horizontalOnly = false,
    bool verticalOnly = false,
    bool snap = false,
  }) {
    _stop();

    final advancedFollowBehavior = AdvancedFollowBehavior(
      target: target,
      stiffness: stiffness,
      deadZone: deadZone,
      offset: offset,
      horizontalOnly: horizontalOnly,
      verticalOnly: verticalOnly,
    );

    _add(advancedFollowBehavior);

    if (snap) {
      viewfinder.position = target.position + advancedFollowBehavior.offset;
    }

    return advancedFollowBehavior;
  }

  /// Shakes the camera using a [ShakeEffect].
  ///
  /// - [amplitude]: Maximum shake offset in pixels.
  /// - [controller]: Defines the duration, progression curve, and damping of the shake effect.
  ///
  /// Returns a [Future] that completes when the shake finishes or is cancelled.
  Future<void> shake(double amplitude, EffectController controller) {
    _removeEffects<ShakeEffect>();

    return _add(ShakeEffect(amplitude, controller));
  }

  /// Smoothly zooms the camera by a relative [value].
  ///
  /// - [value]: The relative change in zoom. For example, `0.5` increases the zoom by 50%, while `-0.5` decreases it by 50%.
  ///   Must be greater than `-1`, since the zoom has to stay positive.
  /// - [controller]: Controls the duration, interpolation curve, and smoothing of the zoom effect.
  ///
  /// Returns a [Future] that completes when the zoom finishes or is cancelled.
  Future<void> zoomBy(double value, EffectController controller) {
    assert(value > -1, 'zoomBy value must be greater than -1: $value');

    _removeEffects<ScaleEffect>();

    return _add(ScaleEffect.by(Vector2.all(1 + value), controller));
  }

  /// Smoothly zooms the camera to an absolute zoom level [value].
  ///
  /// - [value]: Target zoom level (must be positive).
  /// - [controller]: Controls the duration, interpolation curve, and smoothing of the zoom effect.
  ///
  /// Returns a [Future] that completes when the zoom finishes or is cancelled.
  Future<void> zoomTo(double value, EffectController controller) {
    assert(value > 0, 'zoom level must be positive: $value');

    _removeEffects<ScaleEffect>();

    return _add(ScaleEffect.to(Vector2.all(value), controller));
  }

  /// Rotates the camera by a relative [angle] in degrees.
  ///
  /// - [angle]: Amount to rotate the camera by in degrees.
  /// - [controller]: Controls the duration, interpolation curve, and smoothing of the rotation.
  ///
  /// Returns a [Future] that completes when the rotation finishes or is cancelled.
  Future<void> rotateBy(double angle, EffectController controller) {
    _removeEffects<RotateEffect>();

    return _add(RotateEffect.by(radians(angle), controller));
  }

  /// Moves the camera directly to a [targetPosition].
  ///
  /// - [targetPosition]: The position to move the camera to.
  /// - [controller]: Controls the duration, interpolation curve, and smoothing of the movement.
  ///
  /// Returns a [Future] that completes when the movement finishes or is cancelled.
  Future<void> lookAt(Vector2 targetPosition, EffectController controller) {
    _stop();

    return _add(MoveToEffect(targetPosition, controller));
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

  /// Adds [component] to the viewfinder and returns a [Future] that completes
  /// once it is removed, whether it finished or was cancelled.
  Future<void> _add(Component component) {
    final completer = Completer<void>();
    final pending = _pending[this] ??= {};

    pending[component] = completer;
    component.mounted.then((_) => pending.remove(component));
    component.removed.then((_) {
      if (!completer.isCompleted) completer.complete();
    });

    viewfinder.add(component);
    return completer.future;
  }

  /// Like [CameraComponent.stop], but also cancels follow behaviors and move
  /// effects added in the current frame.
  void _stop() {
    stop();
    _cancelPending(
        (component) => component is FollowBehavior || component is MoveEffect);
  }

  /// Removes every [T] from the viewfinder, including ones added in the
  /// current frame.
  void _removeEffects<T>() {
    viewfinder.children.toList().forEach(
      (child) {
        if (child is T) child.removeFromParent();
      },
    );
    _cancelPending((component) => component is T);
  }

  /// Cancels the not yet mounted components matching [test].
  ///
  /// Flame never marks such a component as removed, so its future is
  /// completed here instead.
  void _cancelPending(bool Function(Component component) test) {
    _pending[this]?.removeWhere((component, completer) {
      if (!test(component)) return false;

      component.removeFromParent();
      if (!completer.isCompleted) completer.complete();
      return true;
    });
  }
}
