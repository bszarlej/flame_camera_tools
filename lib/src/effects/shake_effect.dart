import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'shake_offsets.dart';

/// An effect that shakes a [PositionComponent] by randomly offsetting its position.
///
/// The shake amplitude decreases over time according to the [EffectController]'s progress,
/// creating a damping effect. This is commonly used for camera shake or object hit reactions.
///
/// The offset is applied on top of the target's position, so the target can
/// keep moving while it shakes, for example while a camera follows a player.
/// The offset is undone when the effect finishes or is removed.
///
/// `ChaseBehavior`, which `camera.chase()` uses, and `camera.lookAt()` work
/// from where the target would be without the shake, so the shake keeps its
/// amplitude and moves end where they should. Flame's own followers and move
/// effects, such as `camera.follow()` and [MoveToEffect], don't know about
/// the shake: following can make it up to twice as strong, and a move that
/// starts during a shake ends off by the shake offset at that moment.
///
/// Speed-based controllers such as `EffectController(speed: ...)` are not
/// supported, since a shake has no distance to cover. Use a duration instead.
///
/// Example usage:
/// ```dart
/// final shake = ShakeEffect(
///   20.0, // amplitude in pixels
///   LinearEffectController(0.5), // duration 0.5 seconds
/// );
/// player.add(shake);
/// ```
class ShakeEffect extends Effect with EffectTarget<PositionProvider> {
  /// Maximum displacement along each axis at the start of the effect.
  final double amplitude;

  /// The offset currently applied to the target's position.
  final _offset = Vector2.zero();

  /// Random number generator used to generate the shake offsets.
  final _rng = Random();

  /// Creates a [ShakeEffect].
  ///
  /// - [amplitude]: The maximum shake displacement along each axis in pixels.
  /// - [controller]: Controls the duration and timing of the effect.
  /// - [target]: Optional custom target to apply the effect to (defaults to the component this effect is added to).
  /// - [onComplete]: Optional callback invoked when the effect finishes.
  ShakeEffect(
    this.amplitude,
    super.controller, {
    PositionProvider? target,
    super.onComplete,
    super.key,
  }) {
    this.target = target;
  }

  @override
  void apply(double progress) {
    // Amplitude decreases over time for a damping effect
    final currentAmp = amplitude * (1.0 - progress);

    // Generate a random offset between -currentAmp and currentAmp on each axis
    final dx = (_rng.nextDouble() * 2 - 1) * currentAmp;
    final dy = (_rng.nextDouble() * 2 - 1) * currentAmp;

    // Replace the previous offset with the new one
    _move(Vector2(dx - _offset.x, dy - _offset.y));
    _offset.setValues(dx, dy);
  }

  @override
  void onRemove() {
    if (!_offset.isZero()) {
      _move(-_offset);
      _offset.setZero();
    }
    super.onRemove();
  }

  /// Moves the target by [delta] and records it in [shakeOffsets], so that
  /// followers can tell the shake apart from other movement.
  void _move(Vector2 delta) {
    target.position += delta;
    (shakeOffsets[target] ??= Vector2.zero()).add(delta);
  }
}
