import 'package:flame/components.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vector2 stores 32-bit floats, so results are only accurate to ~1e-6.
const epsilon = 1e-4;

void main() {
  group('RectangularDeadZone', () {
    final owner = Vector2(100, 200);

    test('returns zero while the target is inside', () {
      final deadZone = RectangularDeadZone.all(50);

      expect(
        deadZone.computeDelta(owner, Vector2(120, 170)),
        closeToVector(Vector2.zero()),
      );
    });

    test('returns zero while the target is exactly on an edge', () {
      final deadZone = RectangularDeadZone.all(50);

      expect(
        deadZone.computeDelta(owner, Vector2(150, 250)),
        closeToVector(Vector2.zero()),
      );
      expect(
        deadZone.computeDelta(owner, Vector2(50, 150)),
        closeToVector(Vector2.zero()),
      );
    });

    test('returns the overshoot past each edge', () {
      final deadZone = RectangularDeadZone.all(50);

      // right
      expect(
        deadZone.computeDelta(owner, Vector2(160, 200)),
        closeToVector(Vector2(10, 0)),
      );
      // left
      expect(
        deadZone.computeDelta(owner, Vector2(40, 200)),
        closeToVector(Vector2(-10, 0)),
      );
      // bottom
      expect(
        deadZone.computeDelta(owner, Vector2(100, 260)),
        closeToVector(Vector2(0, 10)),
      );
      // top
      expect(
        deadZone.computeDelta(owner, Vector2(100, 140)),
        closeToVector(Vector2(0, -10)),
      );
    });

    test('handles both axes independently', () {
      final deadZone = RectangularDeadZone.all(50);

      expect(
        deadZone.computeDelta(owner, Vector2(170, 120)),
        closeToVector(Vector2(20, -30)),
      );
    });

    test('respects asymmetric edges', () {
      final deadZone = RectangularDeadZone(
        left: 10,
        top: 20,
        right: 30,
        bottom: 40,
      );

      expect(
        deadZone.computeDelta(owner, Vector2(135, 245)),
        closeToVector(Vector2(5, 5)),
      );
      expect(
        deadZone.computeDelta(owner, Vector2(85, 175)),
        closeToVector(Vector2(-5, -5)),
      );
    });

    test('places the target on the boundary once the delta is applied', () {
      final deadZone = RectangularDeadZone.all(50);
      final target = Vector2(300, -100);

      final moved = owner + deadZone.computeDelta(owner, target);

      expect(target.x - moved.x, closeTo(50, epsilon));
      expect(target.y - moved.y, closeTo(-50, epsilon));
    });

    test('with no size, returns the full distance to the target', () {
      final deadZone = RectangularDeadZone();

      expect(
        deadZone.computeDelta(owner, Vector2(130, 160)),
        closeToVector(Vector2(30, -40)),
      );
    });

    test('does not carry over state between calls', () {
      final deadZone = RectangularDeadZone.all(50);

      deadZone.computeDelta(owner, Vector2(500, 500));

      expect(
        deadZone.computeDelta(owner, owner),
        closeToVector(Vector2.zero()),
      );
    });

    test('.all sets every edge to the same value', () {
      final deadZone = RectangularDeadZone.all(25);

      expect(deadZone.left, 25);
      expect(deadZone.top, 25);
      expect(deadZone.right, 25);
      expect(deadZone.bottom, 25);
    });

    test('.symmetric sets horizontal and vertical edges', () {
      final deadZone = RectangularDeadZone.symmetric(
        horizontal: 10,
        vertical: 20,
      );

      expect(deadZone.left, 10);
      expect(deadZone.right, 10);
      expect(deadZone.top, 20);
      expect(deadZone.bottom, 20);
    });

    test('asserts that edges are non-negative', () {
      expect(() => RectangularDeadZone(left: -1), throwsAssertionError);
      expect(() => RectangularDeadZone.all(-1), throwsAssertionError);
    });
  });

  group('CircularDeadZone', () {
    final owner = Vector2(100, 200);

    test('returns zero while the target is inside', () {
      final deadZone = CircularDeadZone(radius: 50);

      expect(
        deadZone.computeDelta(owner, Vector2(120, 230)),
        closeToVector(Vector2.zero()),
      );
    });

    test('returns zero while the target is exactly on the edge', () {
      final deadZone = CircularDeadZone(radius: 50);

      expect(
        deadZone.computeDelta(owner, Vector2(130, 240)),
        closeToVector(Vector2.zero()),
      );
    });

    test('returns the overshoot along the direction to the target', () {
      final deadZone = CircularDeadZone(radius: 25);

      // Distance is 50 along (0.6, 0.8), so the overshoot is 25.
      expect(
        deadZone.computeDelta(owner, Vector2(130, 240)),
        closeToVector(Vector2(15, 20), epsilon),
      );
    });

    test('places the target on the boundary once the delta is applied', () {
      final deadZone = CircularDeadZone(radius: 50);
      final target = Vector2(-300, 700);

      final moved = owner + deadZone.computeDelta(owner, target);

      expect(target.distanceTo(moved), closeTo(50, epsilon));
    });

    test('with no radius, returns the full distance to the target', () {
      final deadZone = CircularDeadZone();

      expect(
        deadZone.computeDelta(owner, Vector2(130, 160)),
        closeToVector(Vector2(30, -40), epsilon),
      );
    });

    test('with no radius, returns zero when on top of the target', () {
      final deadZone = CircularDeadZone();
      final delta = deadZone.computeDelta(owner, owner.clone());

      expect(delta, closeToVector(Vector2.zero()));
      expect(delta.x.isNaN || delta.y.isNaN, isFalse);
    });

    test('does not carry over state between calls', () {
      final deadZone = CircularDeadZone(radius: 50);

      deadZone.computeDelta(owner, Vector2(500, 500));

      expect(
        deadZone.computeDelta(owner, owner),
        closeToVector(Vector2.zero()),
      );
    });

    test('asserts that the radius is non-negative', () {
      expect(() => CircularDeadZone(radius: -1), throwsAssertionError);
    });
  });
}
