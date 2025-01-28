import 'dart:math';

import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

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
