import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'shake_offsets.dart';

/// An effect that shakes a [PositionComponent] by randomly offsetting its position.
///
/// The shake amplitude decreases over time according to the [EffectController]'s progress,
/// creating a damping effect. This is commonly used for camera shake or object hit reactions.
///
/// By default, the shake jumps to a new random offset every frame, so it
/// shakes faster at higher frame rates. With a [frequency], it glides
/// smoothly between random offsets instead, at the same speed at any frame
/// rate.
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
///   frequency: 15, // glide between 15 random offsets per second
/// );
/// player.add(shake);
/// ```
class ShakeEffect extends Effect with EffectTarget<PositionProvider> {
  /// Maximum displacement along each axis at the start of the effect.
  final double amplitude;

  /// How many random offsets per second the shake glides between, or `null`
  /// to jump to a new random offset every frame.
  ///
  /// Low values like `5` give a slow, heavy rumble, high values like `30` a
  /// fast, sharp shake. A shake with a frequency can't be used inside a
  /// [SequenceEffect].
  final double? frequency;

  /// The offset currently applied to the target's position.
  final _offset = Vector2.zero();

  /// Random number generator used to generate the shake offsets.
  final _rng = Random();

  /// The random point, from -1 to 1 on each axis, that a shake with a
  /// [frequency] glides away from.
  final _from = Vector2.zero();

  /// The random point that a shake with a [frequency] glides towards.
  final _to = Vector2.zero();

  /// How far the shake has glided from [_from] to [_to], from 0 to 1.
  double _phase = 0;

  /// The time passed in the current frame, which [apply] doesn't get.
  double _dt = 0;

  /// Creates a [ShakeEffect].
  ///
  /// - [amplitude]: The maximum shake displacement along each axis in pixels.
  /// - [controller]: Controls the duration and timing of the effect.
  /// - [frequency]: Optional number of random offsets per second to glide between.
  /// - [target]: Optional custom target to apply the effect to (defaults to the component this effect is added to).
  /// - [onComplete]: Optional callback invoked when the effect finishes.
  ShakeEffect(
    this.amplitude,
    super.controller, {
    this.frequency,
    PositionProvider? target,
    super.onComplete,
    super.key,
  }) : assert(
          frequency == null || frequency > 0,
          'frequency must be positive: $frequency',
        ) {
    this.target = target;
    // Glide from rest towards the first random point.
    if (frequency != null) _to.setValues(_random(), _random());
  }

  @override
  void onMount() {
    super.onMount();
    // A SequenceEffect advances its effects without calling update, so
    // gliding would never move on.
    assert(
      frequency == null || parent is! SequenceEffect,
      'A ShakeEffect with a frequency cannot be used in a SequenceEffect',
    );
  }

  @override
  void update(double dt) {
    _dt = dt;
    super.update(dt);
  }

  @override
  void apply(double progress) {
    // Amplitude decreases over time for a damping effect
    final currentAmp = amplitude * (1.0 - progress);

    // Pick a point between -1 and 1 on each axis
    final double x;
    final double y;
    final frequency = this.frequency;
    if (frequency == null) {
      x = _random();
      y = _random();
    } else {
      _glide(_dt * frequency);
      // Smoothstep, so that the shake eases in and out of each point
      final t = _phase * _phase * (3 - 2 * _phase);
      x = _from.x + (_to.x - _from.x) * t;
      y = _from.y + (_to.y - _from.y) * t;
    }

    // Replace the previous offset with the new one
    final dx = x * currentAmp;
    final dy = y * currentAmp;
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

  /// Glides on by [points] random points, heading for a new random point
  /// whenever the shake reaches one.
  void _glide(double points) {
    _phase += points;
    if (_phase < 1) return;

    // After a long frame that passed several points, carry on from the last
    // one rather than jumping.
    _phase -= _phase.floor();
    _from.setFrom(_to);
    _to.setValues(_random(), _random());
  }

  /// A random number between -1 and 1.
  double _random() => _rng.nextDouble() * 2 - 1;
}
