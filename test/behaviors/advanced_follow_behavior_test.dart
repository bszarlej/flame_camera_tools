import 'package:flame/components.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vector2 stores 32-bit floats, so results are only accurate to ~1e-6.
const epsilon = 1e-4;

void main() {
  group('AdvancedFollowBehavior axis locks', () {
    testWithFlameGame(
        'horizontalOnly ignores the vertical distance to a circular dead zone',
        (game) async {
      final owner = PositionComponent();
      final target = PositionComponent(position: Vector2(10, 100));
      owner.add(
        AdvancedFollowBehavior(
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
        AdvancedFollowBehavior(
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
        AdvancedFollowBehavior(
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
        AdvancedFollowBehavior(
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
