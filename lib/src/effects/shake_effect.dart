import 'dart:math';

import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

/// An effect that causes the [target] to shake with a specified intensity.
///
/// The [ShakeEffect] applies a shaking movement to the [target],
/// producing a random offset in its position. The intensity of the shake is
/// controlled by the [intensity] parameter, and the effect can optionally
/// weaken over time based on the [weakenOverTime] flag. When enabled,
/// the intensity decreases as the effect progresses,
/// giving a natural fading effect.
/// This effect can be applied to any [PositionProvider].
///
/// The shaking behavior is achieved by randomly altering the [target]'s
/// position within the bounds of the specified intensity.
/// The [ShakeEffect] can be used to add dynamic,
/// jittery animations to a component, often used for camera shakes
/// or impact effects in games.
class ShakeEffect extends MoveEffect {
  final double intensity;
  final bool weakenOverTime;

  ShakeEffect(
    EffectController controller, {
    PositionProvider? target,
    required this.intensity,
    this.weakenOverTime = true,
    super.onComplete,
    super.key,
  }) : super(controller, target);

  final _random = Random();

  @override
  void apply(double progress) {
    if (isShaking) {
      final finalIntensity =
          weakenOverTime ? intensity * (1.0 - progress) : intensity;

      final offset = Vector2(
        _random.nextDouble() * finalIntensity - finalIntensity / 2,
        _random.nextDouble() * finalIntensity - finalIntensity / 2,
      );

      target.position = offset..add(target.position);
    }
  }

  @override
  double measure() {
    return controller.progress;
  }

  bool get isShaking => controller.progress > 0;
}
