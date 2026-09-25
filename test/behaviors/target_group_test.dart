import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// A target that is not a component and has no size.
class _Point implements ReadOnlyPositionProvider {
  _Point(this.position);

  @override
  final Vector2 position;
}

void main() {
  group('TargetGroup', () {
    test('is empty without targets', () {
      final group = TargetGroup();

      expect(group.isEmpty, isTrue);
      expect(group.bounds, isNull);
      expect(group.position, closeToVector(Vector2.zero()));
    });

    test('bounds is the rectangle around all targets', () {
      final group = TargetGroup([
        PositionComponent(position: Vector2(0, 10)),
        PositionComponent(position: Vector2(40, -20)),
        PositionComponent(position: Vector2(100, 50)),
      ]);

      expect(group.bounds, const Rect.fromLTRB(0, -20, 100, 50));
    });

    test('is positioned at the center of the bounds, not the average', () {
      final group = TargetGroup([
        PositionComponent(position: Vector2(0, 0)),
        PositionComponent(position: Vector2(10, 0)),
        PositionComponent(position: Vector2(100, 50)),
      ]);

      expect(group.position, closeToVector(Vector2(50, 25)));
    });

    test('includes the whole area of components', () {
      final group = TargetGroup([
        PositionComponent(
          position: Vector2(0, 0),
          size: Vector2(100, 50),
          anchor: Anchor.center,
        ),
        PositionComponent(
          position: Vector2(500, 0),
          size: Vector2(100, 50),
          anchor: Anchor.center,
        ),
      ]);

      expect(group.bounds, const Rect.fromLTRB(-50, -25, 550, 25));
      expect(group.position, closeToVector(Vector2(250, 0)));
    });

    test('respects the anchor and scale of components', () {
      final group = TargetGroup([
        PositionComponent(size: Vector2.all(100)),
        PositionComponent(
          position: Vector2(500, 0),
          size: Vector2.all(100),
          scale: Vector2.all(2),
          anchor: Anchor.bottomRight,
        ),
      ]);

      expect(group.bounds, const Rect.fromLTRB(0, -200, 500, 100));
    });

    test('counts other targets as a point', () {
      final group = TargetGroup([
        _Point(Vector2(-100, 0)),
        PositionComponent(size: Vector2.all(100)),
      ]);

      expect(group.bounds, const Rect.fromLTRB(-100, 0, 100, 100));
    });

    test('picks up target movement', () {
      final target = PositionComponent(position: Vector2(100, 0));
      final group = TargetGroup([PositionComponent(), target]);

      target.position = Vector2(200, 100);

      expect(group.position, closeToVector(Vector2(100, 50)));
    });

    test('adds and removes targets', () {
      final first = PositionComponent();
      final second = PositionComponent(position: Vector2(100, 0));
      final group = TargetGroup([first]);

      group.add(second);
      expect(group.targets, [first, second]);
      expect(group.position, closeToVector(Vector2(50, 0)));

      expect(group.remove(first), isTrue);
      expect(group.remove(first), isFalse);
      expect(group.targets, [second]);
      expect(group.position, closeToVector(Vector2(100, 0)));
    });

    test('keeps the last center once emptied', () {
      final target = PositionComponent(position: Vector2(30, 40));
      final group = TargetGroup([target]);
      group.position;

      group.remove(target);

      expect(group.position, closeToVector(Vector2(30, 40)));
    });

    test('does not change with the list it was created from', () {
      final targets = [PositionComponent()];
      final group = TargetGroup(targets);

      targets.add(PositionComponent());

      expect(group.targets, hasLength(1));
    });

    test('does not allow changing targets directly', () {
      final group = TargetGroup();

      expect(
        () => group.targets.add(PositionComponent()),
        throwsUnsupportedError,
      );
    });
  });
}
