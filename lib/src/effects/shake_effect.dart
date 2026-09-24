import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

/// An effect that shakes a [PositionComponent] by randomly offsetting its position.
///
/// The shake amplitude decreases over time according to the [EffectController]'s progress,
/// creating a damping effect. This is commonly used for camera shake or object hit reactions.
///
/// The offset is applied on top of the target's position, so the target can
/// keep moving while it shakes, for example while a camera follows a player.
/// The offset is undone when the effect finishes or is removed.
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
  /// Maximum displacement applied to the target's position at the start of the effect.
  final double amplitude;

  /// The offset currently applied to the target's position.
  final _offset = Vector2.zero();

  /// Random number generator used to generate the shake offsets.
  final _rng = Random();

  /// Creates a [ShakeEffect].
  ///
  /// - [amplitude]: The maximum shake displacement in pixels.
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

    // Generate a random offset in both x and y directions
    final dx = _rng.nextDouble() * currentAmp - currentAmp / 2;
    final dy = _rng.nextDouble() * currentAmp - currentAmp / 2;

    // Replace the previous offset with the new one
    target.position += Vector2(dx - _offset.x, dy - _offset.y);
    _offset.setValues(dx, dy);
  }

  @override
  void onRemove() {
    if (!_offset.isZero()) {
      target.position -= _offset;
      _offset.setZero();
    }
    super.onRemove();
  }
}
