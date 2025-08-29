import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

/// An effect that shakes a [PositionComponent] by randomly offsetting its position.
///
/// The shake amplitude decreases over time according to the [EffectController]'s progress,
/// creating a damping effect. This is commonly used for camera shake or object hit reactions.
///
/// Example usage:
/// ```dart
/// final shake = ShakeEffect(
///   20.0, // amplitude in pixels
///   LinearEffectController(0.5), // duration 0.5 seconds
/// );
/// player.add(shake);
/// ```
class ShakeEffect extends MoveEffect {
  /// Maximum displacement applied to the target's position at the start of the effect.
  final double amplitude;

  /// The original position of the target before the shake started.
  late final Vector2 _origin;

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
    EffectController controller, {
    PositionProvider? target,
    super.onComplete,
    super.key,
  }) : super(controller, target);

  @override
  void onStart() {
    super.onStart();
    // Store the original position to offset from during the shake
    _origin = target.position.clone();
  }

  @override
  void apply(double progress) {
    // Amplitude decreases over time for a damping effect
    final currentAmp = amplitude * (1.0 - progress);

    // Generate a random offset in both x and y directions
    final offset = Vector2(
      _rng.nextDouble() * currentAmp - currentAmp / 2,
      _rng.nextDouble() * currentAmp - currentAmp / 2,
    );

    // Apply the offset relative to the original position
    target.position = _origin + offset;
  }

  @override
  double measure() => controller.progress;
}
