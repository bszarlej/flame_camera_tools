import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a function that reports whether [future] has completed.
bool Function() track(Future<void> future) {
  var done = false;
  future.then((_) => done = true);
  return () => done;
}

/// Advances [game] by [dt], then lets pending removals and futures settle.
Future<void> tick(FlameGame game, double dt) async {
  game.update(dt);
  await game.ready();
  await pumpEventQueue();
}

void main() {
  group('effect futures', () {
    final effects = <String, Future<void> Function(CameraComponent camera)>{
      'shake': (camera) => camera.shake(10, EffectController(duration: 1)),
      'zoomBy': (camera) => camera.zoomBy(0.5, EffectController(duration: 1)),
      'zoomTo': (camera) => camera.zoomTo(2, EffectController(duration: 1)),
      'rotateBy': (camera) =>
          camera.rotateBy(45, EffectController(duration: 1)),
      'rotateTo': (camera) =>
          camera.rotateTo(45, EffectController(duration: 1)),
      'lookAt': (camera) =>
          camera.lookAt(Vector2(100, 100), EffectController(duration: 1)),
    };

    for (final MapEntry(key: name, value: play) in effects.entries) {
      testWithFlameGame('$name completes when the effect finishes',
          (game) async {
        final done = track(play(game.camera));

        await tick(game, 0.5);
        expect(done(), isFalse);

        await tick(game, 0.6);
        expect(done(), isTrue);
      });

      testWithFlameGame('$name completes when replaced by another $name',
          (game) async {
        final first = track(play(game.camera));
        await tick(game, 0.1);

        final second = track(play(game.camera));
        await tick(game, 0.1);

        expect(first(), isTrue);
        expect(second(), isFalse);
      });

      testWithFlameGame('$name replaces a $name started in the same frame',
          (game) async {
        final first = track(play(game.camera));
        final second = track(play(game.camera));
        await tick(game, 0.1);

        expect(first(), isTrue);
        expect(second(), isFalse);
      });
    }

    testWithFlameGame('only the last zoomTo in a frame takes effect',
        (game) async {
      final camera = game.camera;
      camera.zoomTo(2, EffectController(duration: 1));
      camera.zoomTo(3, EffectController(duration: 1));

      // Several steps, so that two stacked effects would both be mid-way.
      for (var i = 0; i < 4; i++) {
        await tick(game, 0.3);
      }

      expect(camera.viewfinder.zoom, closeTo(3, 1e-4));
    });

    testWithFlameGame('lookAt completes when chase starts in the same frame',
        (game) async {
      final camera = game.camera;
      final done = track(
        camera.lookAt(Vector2(100, 100), EffectController(duration: 1)),
      );
      camera.chase(PositionComponent());
      await tick(game, 0.1);

      expect(done(), isTrue);
      expect(camera.viewfinder.children.whereType<MoveEffect>(), isEmpty);
    });
  });

  group('zoomBy', () {
    testWithFlameGame('asserts that the zoom stays positive', (game) async {
      final camera = game.camera;

      expect(
        () => camera.zoomBy(-1, EffectController(duration: 1)),
        throwsAssertionError,
      );
      expect(
        () => camera.zoomBy(-1.5, EffectController(duration: 1)),
        throwsAssertionError,
      );
    });

    testWithFlameGame('zooms out by a fraction', (game) async {
      final camera = game.camera;
      camera.zoomBy(-0.5, EffectController(duration: 1));
      await tick(game, 1.1);

      expect(camera.viewfinder.zoom, closeTo(0.5, 1e-4));
    });
  });

  group('rotateBy', () {
    testWithFlameGame('takes the angle in degrees', (game) async {
      final camera = game.camera;
      camera.rotateBy(90, EffectController(duration: 1));
      await tick(game, 1.1);

      expect(camera.viewfinder.angle, closeTo(pi / 2, 1e-4));
    });
  });

  group('rotateTo', () {
    testWithFlameGame('ends at the given angle in degrees', (game) async {
      final camera = game.camera;
      camera.rotateBy(30, EffectController(duration: 0.1));
      await tick(game, 0.2);

      camera.rotateTo(90, EffectController(duration: 1));
      await tick(game, 1.1);

      expect(camera.viewfinder.angle, closeTo(pi / 2, 1e-4));
    });

    testWithFlameGame('replaces a running rotateBy', (game) async {
      final camera = game.camera;
      camera.rotateBy(90, EffectController(duration: 10));
      await tick(game, 1);

      camera.rotateTo(0, EffectController(duration: 1));
      await tick(game, 1.1);
      await tick(game, 1);

      expect(camera.viewfinder.angle, closeTo(0, 1e-4));
    });

    testWithFlameGame('does not take the shortest way round', (game) async {
      final camera = game.camera;
      camera.rotateBy(350, EffectController(duration: 0.1));
      await tick(game, 0.2);

      camera.rotateTo(0, EffectController(duration: 1));
      await tick(game, 0.5);

      // Halfway back from 350 is 175, not 355.
      expect(camera.viewfinder.angle, closeTo(radians(175), 1e-4));
    });
  });

  group('chase', () {
    testWithFlameGame('keeps only the last follow behavior of a frame',
        (game) async {
      final camera = game.camera;
      camera.chase(PositionComponent());
      final last = camera.chase(PositionComponent());
      await tick(game, 0.1);

      expect(
        camera.viewfinder.children.whereType<FollowBehavior>(),
        [last],
      );
    });

    testWithFlameGame('snap moves straight to the target', (game) async {
      final camera = game.camera;
      camera.chase(
        PositionComponent(position: Vector2(100, 50)),
        stiffness: 0,
        snap: true,
      );

      expect(camera.viewfinder.position, closeToVector(Vector2(100, 50)));
    });

    testWithFlameGame('snap includes the offset', (game) async {
      final camera = game.camera;
      camera.chase(
        PositionComponent(position: Vector2(100, 50)),
        stiffness: 0,
        offset: Vector2(0, -30),
        snap: true,
      );

      expect(camera.viewfinder.position, closeToVector(Vector2(100, 20)));
    });

    testWithFlameGame('lookAt completes when chase takes over', (game) async {
      final camera = game.camera;
      final done = track(
        camera.lookAt(Vector2(100, 100), EffectController(duration: 1)),
      );
      await tick(game, 0.1);

      camera.chase(PositionComponent());
      await tick(game, 0.1);

      expect(done(), isTrue);
    });
  });

  group('effectSequence', () {
    testWithFlameGame('runs each effect after the previous one', (game) async {
      final camera = game.camera;
      final started = <String>[];
      final done = track(
        camera.effectSequence([
          () {
            started.add('zoom');
            return camera.zoomTo(2, EffectController(duration: 1));
          },
          () {
            started.add('rotate');
            return camera.rotateBy(45, EffectController(duration: 1));
          },
        ]),
      );

      await tick(game, 0.5);
      expect(started, ['zoom']);

      await tick(game, 0.6);
      expect(started, ['zoom', 'rotate']);
      expect(done(), isFalse);

      await tick(game, 1.1);
      expect(done(), isTrue);
    });

    testWithFlameGame('moves on when an effect is cancelled', (game) async {
      final camera = game.camera;
      var rotateStarted = false;
      final done = track(
        camera.effectSequence([
          () => camera.zoomTo(2, EffectController(duration: 10)),
          () {
            rotateStarted = true;
            return camera.rotateBy(45, EffectController(duration: 1));
          },
        ]),
      );
      await tick(game, 0.1);

      // Replaces the sequence's zoom, which is still running.
      camera.zoomTo(1, EffectController(duration: 1));
      await tick(game, 0.1);
      expect(rotateStarted, isTrue);

      await tick(game, 1.1);
      expect(done(), isTrue);
    });
  });
}
