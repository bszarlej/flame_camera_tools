import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vector2 stores 32-bit floats, so results are only accurate to ~1e-6.
const epsilon = 1e-4;

/// Advances [game] by [dt], then lets pending lifecycle events settle.
Future<void> tick(FlameGame game, double dt) async {
  game.update(dt);
  await game.ready();
}

void main() {
  group('ShakeEffect', () {
    testWithFlameGame('returns the target to where it started', (game) async {
      final component = PositionComponent(position: Vector2(10, 20));
      await game.ensureAdd(component);

      component.add(ShakeEffect(10, EffectController(duration: 1)));
      for (var i = 0; i < 12; i++) {
        await tick(game, 0.1);
      }

      expect(component.children.whereType<ShakeEffect>(), isEmpty);
      expect(component.position, closeToVector(Vector2(10, 20), epsilon));
    });

    testWithFlameGame('never moves further than the amplitude', (game) async {
      final component = PositionComponent(position: Vector2(10, 20));
      await game.ensureAdd(component);

      component.add(ShakeEffect(10, EffectController(duration: 1)));
      for (var i = 0; i < 100; i++) {
        await tick(game, 0.01);

        expect((component.x - 10).abs(), lessThanOrEqualTo(10 + epsilon));
        expect((component.y - 20).abs(), lessThanOrEqualTo(10 + epsilon));
      }
    });

    testWithFlameGame('uses the full amplitude', (game) async {
      final component = PositionComponent(position: Vector2(10, 20));
      await game.ensureAdd(component);

      component.add(ShakeEffect(10, EffectController(duration: 1)));
      var furthest = 0.0;
      // Early on the amplitude is still >= 9, so an offset past 5 on either
      // axis is near-certain within these samples, yet impossible at half.
      for (var i = 0; i < 100; i++) {
        await tick(game, 0.001);
        furthest = max(furthest, (component.x - 10).abs());
        furthest = max(furthest, (component.y - 20).abs());
      }

      expect(furthest, greaterThan(5));
    });

    testWithFlameGame('keeps movement from other sources', (game) async {
      final component = PositionComponent(position: Vector2(10, 20));
      await game.ensureAdd(component);

      component.add(ShakeEffect(10, EffectController(duration: 1)));
      for (var i = 0; i < 12; i++) {
        // Stands in for anything else moving the target, like following.
        component.position += Vector2(5, 0);
        await tick(game, 0.1);
      }

      expect(component.position, closeToVector(Vector2(70, 20), epsilon));
    });

    testWithFlameGame('undoes its offset when removed early', (game) async {
      final component = PositionComponent(position: Vector2(10, 20));
      await game.ensureAdd(component);

      final shake = ShakeEffect(10, EffectController(duration: 1));
      component.add(shake);
      await tick(game, 0.3);

      shake.removeFromParent();
      await tick(game, 0);

      expect(component.position, closeToVector(Vector2(10, 20), epsilon));
    });

    testWithFlameGame('can be reset and played again', (game) async {
      final component = PositionComponent(position: Vector2(10, 20));
      await game.ensureAdd(component);

      final shake = ShakeEffect(10, EffectController(duration: 1))
        ..removeOnFinish = false;
      component.add(shake);
      await tick(game, 0.5);

      shake.reset();
      for (var i = 0; i < 12; i++) {
        await tick(game, 0.1);
      }

      expect(shake.isMounted, isTrue);
      expect(component.position, closeToVector(Vector2(10, 20), epsilon));
    });
  });

  group('camera shake', () {
    testWithFlameGame('keeps following the target mid-shake', (game) async {
      final camera = game.camera;
      final target = PositionComponent();
      camera.chase(target);
      camera.shake(10, EffectController(duration: 1));

      for (var i = 0; i < 5; i++) {
        target.position += Vector2(50, 0);
        await tick(game, 0.1);
      }

      // Halfway through, the camera is at the target plus the shake offset.
      expect(
        camera.viewfinder.position.distanceTo(target.position),
        lessThanOrEqualTo(10 * 1.5),
      );
    });

    testWithFlameGame('is not cancelled by chase or lookAt', (game) async {
      final camera = game.camera;
      var done = false;
      camera.shake(10, EffectController(duration: 1)).then((_) => done = true);
      await tick(game, 0.1);

      camera.chase(PositionComponent());
      camera.lookAt(Vector2(100, 100), EffectController(duration: 0.1));
      await tick(game, 0.1);
      await pumpEventQueue();

      expect(done, isFalse);
      expect(camera.viewfinder.children.whereType<ShakeEffect>(), hasLength(1));
    });
  });
}
