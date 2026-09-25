import 'package:flame/components.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flutter_test/flutter_test.dart';

const epsilon = 1e-9;

/// Returns a group of components at the given positions.
TargetGroup groupAt(List<Vector2> positions) => TargetGroup([
      for (final position in positions) PositionComponent(position: position),
    ]);

void main() {
  group('ZoomToFit.zoomFor', () {
    final viewport = Vector2(800, 600);

    /// The zoom for targets at [positions], with the camera at [camera] or,
    /// by default, at the center of the group.
    double? fit(
      ZoomToFit zoomToFit,
      List<Vector2> positions, {
      Vector2? camera,
    }) {
      final group = groupAt(positions);
      return zoomToFit.zoomFor(group, camera ?? group.position, viewport);
    }

    test('fits the width when that is the tighter side', () {
      expect(
        fit(const ZoomToFit(), [Vector2(0, 0), Vector2(1600, 0)]),
        closeTo(0.5, epsilon),
      );
    });

    test('fits the height when that is the tighter side', () {
      expect(
        fit(const ZoomToFit(), [Vector2(0, 0), Vector2(0, 1200)]),
        closeTo(0.5, epsilon),
      );
    });

    test('keeps padding around the outermost targets', () {
      expect(
        fit(const ZoomToFit(padding: 200), [Vector2(0, 0), Vector2(1200, 0)]),
        closeTo(0.5, epsilon),
      );
    });

    test('keeps whole components in view without padding', () {
      final group = TargetGroup([
        for (final x in [0.0, 1500.0])
          PositionComponent(
            position: Vector2(x, 0),
            size: Vector2.all(100),
            anchor: Anchor.center,
          ),
      ]);

      // The components reach from -50 to 1550, so 1600 has to fit.
      expect(
        const ZoomToFit().zoomFor(group, group.position, viewport),
        closeTo(0.5, epsilon),
      );
    });

    test('fits from the camera position when it is off center', () {
      // The farthest target is 1200 away, so half the viewport has to
      // reach 1200.
      expect(
        fit(
          const ZoomToFit(),
          [Vector2(0, 0), Vector2(1600, 0)],
          camera: Vector2(400, 0),
        ),
        closeTo(400 / 1200, epsilon),
      );
      expect(
        fit(
          const ZoomToFit(padding: 100),
          [Vector2(0, 0), Vector2(0, 1200)],
          camera: Vector2(0, -200),
        ),
        closeTo(300 / 1500, epsilon),
      );
    });

    test('does not zoom in past maxZoom', () {
      final positions = [Vector2(0, 0), Vector2(200, 0)];

      expect(fit(const ZoomToFit(), positions), closeTo(1, epsilon));
      expect(fit(const ZoomToFit(maxZoom: 2), positions), closeTo(2, epsilon));
    });

    test('does not zoom out past minZoom', () {
      final positions = [Vector2(0, 0), Vector2(8000, 0)];

      expect(fit(const ZoomToFit(), positions), closeTo(0.1, epsilon));
      expect(
        fit(const ZoomToFit(minZoom: 0.5), positions),
        closeTo(0.5, epsilon),
      );
    });

    test('with a single target under the camera, uses maxZoom', () {
      expect(fit(const ZoomToFit(), [Vector2(300, 200)]), closeTo(1, epsilon));
    });

    test('is null for an empty group or a viewport without size', () {
      expect(
        const ZoomToFit().zoomFor(TargetGroup(), Vector2.zero(), viewport),
        isNull,
      );
      expect(
        const ZoomToFit().zoomFor(
          groupAt([Vector2.zero()]),
          Vector2.zero(),
          Vector2.zero(),
        ),
        isNull,
      );
    });

    test('asserts valid padding and zoom limits', () {
      expect(() => ZoomToFit(padding: -1), throwsAssertionError);
      expect(() => ZoomToFit(minZoom: -1), throwsAssertionError);
      expect(() => ZoomToFit(maxZoom: 0), throwsAssertionError);
      expect(() => ZoomToFit(minZoom: 2, maxZoom: 1), throwsAssertionError);
    });
  });
}
