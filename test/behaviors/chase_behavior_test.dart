import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vector2 stores 32-bit floats, so results are only accurate to ~1e-6.
const epsilon = 1e-4;

/// Adds a component at the origin to [game] that is driven by [behavior].
Future<PositionComponent> addFollower(
  FlameGame game,
  ChaseBehavior behavior,
) async {
  final owner = PositionComponent()..add(behavior);
  await game.ensureAdd(owner);
  return owner;
}

void main() {
  group('ChaseBehavior', () {
    testWithFlameGame('with stiffness 1, reaches the target in one update',
        (game) async {
      final target = PositionComponent(position: Vector2(100, 50));
      final owner = await addFollower(
        game,
        ChaseBehavior(target: target),
      );

      game.update(1 / 60);

      expect(owner.position, closeToVector(Vector2(100, 50), epsilon));
    });

    testWithFlameGame('with stiffness 0, never moves', (game) async {
      final target = PositionComponent(position: Vector2(100, 50));
      final owner = await addFollower(
        game,
        ChaseBehavior(target: target, stiffness: 0),
      );

      for (var i = 0; i < 60; i++) {
        game.update(1 / 60);
      }

      expect(owner.position, closeToVector(Vector2.zero(), epsilon));
    });

    test('clamps stiffness between 0 and 1', () {
      final target = PositionComponent();

      expect(
        ChaseBehavior(target: target, stiffness: 1.5).stiffness,
        1,
      );
      expect(
        ChaseBehavior(target: target, stiffness: -0.5).stiffness,
        0,
      );

      final behavior = ChaseBehavior(target: target)..stiffness = 2;
      expect(behavior.stiffness, 1);
      behavior.stiffness = -1;
      expect(behavior.stiffness, 0);
    });

    testWithFlameGame('moves the same distance at any frame rate',
        (game) async {
      final target = PositionComponent(position: Vector2(100, 0));
      final at60fps = await addFollower(
        game,
        ChaseBehavior(target: target, stiffness: 0.5),
      );
      final at10fps = await addFollower(
        game,
        ChaseBehavior(target: target, stiffness: 0.5),
      );

      // Both followers get 0.2 seconds in total, split into different steps.
      for (var i = 0; i < 12; i++) {
        at60fps.children.first.update(1 / 60);
      }
      for (var i = 0; i < 2; i++) {
        at10fps.children.first.update(1 / 10);
      }

      // A stiffness of 0.5 closes half the distance in 0.2 seconds.
      expect(at60fps.position, closeToVector(Vector2(50, 0), epsilon));
      expect(at10fps.position, closeToVector(Vector2(50, 0), epsilon));
    });

    testWithFlameGame('closes half the distance in the documented times',
        (game) async {
      final halfLives = {
        0.1: 1.8,
        0.3: 0.2 * 7 / 3,
        0.7: 0.2 * 3 / 7,
        0.9: 0.2 / 9
      };

      for (final MapEntry(key: stiffness, value: halfLife)
          in halfLives.entries) {
        final target = PositionComponent(position: Vector2(100, 0));
        final owner = await addFollower(
          game,
          ChaseBehavior(target: target, stiffness: stiffness),
        );

        owner.children.first.update(halfLife);

        expect(
          owner.position,
          closeToVector(Vector2(50, 0), epsilon),
          reason: 'stiffness $stiffness',
        );
      }
    });

    testWithFlameGame('follows the target plus the offset', (game) async {
      final target = PositionComponent(position: Vector2(100, 50));
      final owner = await addFollower(
        game,
        ChaseBehavior(target: target, offset: Vector2(0, -30)),
      );

      game.update(1 / 60);

      expect(owner.position, closeToVector(Vector2(100, 20), epsilon));
    });

    testWithFlameGame('picks up offset changes', (game) async {
      final target = PositionComponent(position: Vector2(100, 50));
      final behavior = ChaseBehavior(target: target);
      final owner = await addFollower(game, behavior);

      behavior.offset = Vector2(10, 0);
      game.update(1 / 60);

      expect(owner.position, closeToVector(Vector2(110, 50), epsilon));
    });

    testWithFlameGame('stays still while the target is in the dead zone',
        (game) async {
      final target = PositionComponent(position: Vector2(30, -40));
      final owner = await addFollower(
        game,
        ChaseBehavior(
          target: target,
          deadZone: RectangularDeadZone.all(50),
        ),
      );

      game.update(1 / 60);

      expect(owner.position, closeToVector(Vector2.zero(), epsilon));
    });

    testWithFlameGame('picks up dead zone changes', (game) async {
      final target = PositionComponent(position: Vector2(30, -40));
      final behavior = ChaseBehavior(target: target);
      final owner = await addFollower(game, behavior);

      behavior.deadZone = CircularDeadZone(radius: 100);
      game.update(1 / 60);

      expect(owner.position, closeToVector(Vector2.zero(), epsilon));
    });
  });

  group('ChaseBehavior axis locks', () {
    testWithFlameGame('horizontalOnly only moves horizontally', (game) async {
      final target = PositionComponent(position: Vector2(100, 50));
      final owner = await addFollower(
        game,
        ChaseBehavior(target: target, horizontalOnly: true),
      );

      game.update(1 / 60);

      expect(owner.position, closeToVector(Vector2(100, 0), epsilon));
    });

    testWithFlameGame('verticalOnly only moves vertically', (game) async {
      final target = PositionComponent(position: Vector2(100, 50));
      final owner = await addFollower(
        game,
        ChaseBehavior(target: target, verticalOnly: true),
      );

      game.update(1 / 60);

      expect(owner.position, closeToVector(Vector2(0, 50), epsilon));
    });

    test('cannot lock both axes', () {
      final target = PositionComponent();

      expect(
        () => ChaseBehavior(
          target: target,
          horizontalOnly: true,
          verticalOnly: true,
        ),
        throwsAssertionError,
      );
      expect(
        () => ChaseBehavior(target: target, horizontalOnly: true)
          ..verticalOnly = true,
        throwsAssertionError,
      );
      expect(
        () => ChaseBehavior(target: target, verticalOnly: true)
          ..horizontalOnly = true,
        throwsAssertionError,
      );
    });

    testWithFlameGame('can switch axes at runtime', (game) async {
      final target = PositionComponent(position: Vector2(100, 50));
      final behavior = ChaseBehavior(
        target: target,
        horizontalOnly: true,
      );
      final owner = await addFollower(game, behavior);

      behavior
        ..horizontalOnly = false
        ..verticalOnly = true;
      game.update(1 / 60);

      expect(owner.position, closeToVector(Vector2(0, 50), epsilon));
    });

    testWithFlameGame(
        'horizontalOnly ignores the vertical distance to a circular dead zone',
        (game) async {
      final owner = PositionComponent();
      final target = PositionComponent(position: Vector2(10, 100));
      owner.add(
        ChaseBehavior(
          target: target,
          deadZone: CircularDeadZone(radius: 50),
          horizontalOnly: true,
        ),
      );
      await game.ensureAdd(owner);

      game.update(0.1);

      expect(owner.position, closeToVector(Vector2.zero(), epsilon));
    });

    testWithFlameGame(
        'verticalOnly ignores the horizontal distance to a circular dead zone',
        (game) async {
      final owner = PositionComponent();
      final target = PositionComponent(position: Vector2(100, 10));
      owner.add(
        ChaseBehavior(
          target: target,
          deadZone: CircularDeadZone(radius: 50),
          verticalOnly: true,
        ),
      );
      await game.ensureAdd(owner);

      game.update(0.1);

      expect(owner.position, closeToVector(Vector2.zero(), epsilon));
    });

    testWithFlameGame(
        'horizontalOnly keeps the target on the edge of a circular dead zone',
        (game) async {
      final owner = PositionComponent();
      final target = PositionComponent(position: Vector2(80, 100));
      owner.add(
        ChaseBehavior(
          target: target,
          deadZone: CircularDeadZone(radius: 50),
          horizontalOnly: true,
        ),
      );
      await game.ensureAdd(owner);

      game.update(0.1);

      expect(owner.position, closeToVector(Vector2(30, 0), epsilon));
    });

    testWithFlameGame(
        'verticalOnly keeps the target on the edge of a circular dead zone',
        (game) async {
      final owner = PositionComponent();
      final target = PositionComponent(position: Vector2(100, 80));
      owner.add(
        ChaseBehavior(
          target: target,
          deadZone: CircularDeadZone(radius: 50),
          verticalOnly: true,
        ),
      );
      await game.ensureAdd(owner);

      game.update(0.1);

      expect(owner.position, closeToVector(Vector2(0, 30), epsilon));
    });
  });
}
