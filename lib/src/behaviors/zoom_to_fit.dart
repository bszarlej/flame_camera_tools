import 'dart:math';

import 'package:flame/components.dart';

import 'target_group.dart';

/// Settings for zooming the camera so that a whole [TargetGroup] stays in
/// view while it is chased.
///
/// ```dart
/// camera.chase(
///   players,
///   zoomToFit: const ZoomToFit(padding: 100, minZoom: 0.5),
/// );
/// ```
///
/// The camera zooms towards the level at which the group plus [padding] on
/// every side fits the viewport, kept between [minZoom] and [maxZoom].
///
/// The fit is measured from where the camera actually is, not from the
/// center of the group. So the targets stay in view even when an offset or a
/// dead zone keeps the camera away from the center, or while the camera
/// catches up with a fast group. The viewfinder's anchor counts too, so the
/// camera doesn't have to be in the middle of the screen. The zoom is
/// calculated as if the camera were not rotated.
class ZoomToFit {
  /// Extra space in world units to keep around the outermost targets.
  ///
  /// Components already count with their whole size, see
  /// [TargetGroup.bounds], so this is only needed for breathing room.
  final double padding;

  /// The lowest zoom, which limits how far the camera zooms out. `0` means
  /// no limit.
  final double minZoom;

  /// The highest zoom, which limits how far the camera zooms in while the
  /// targets are close together. The default of `1` keeps the normal zoom
  /// until the targets spread apart.
  final double maxZoom;

  /// Creates zoom settings for chasing a [TargetGroup].
  const ZoomToFit({this.padding = 0, this.minZoom = 0, this.maxZoom = 1})
      : assert(padding >= 0, 'padding must be non-negative: $padding'),
        assert(minZoom >= 0, 'minZoom must be non-negative: $minZoom'),
        assert(
          maxZoom > 0 && maxZoom >= minZoom,
          'maxZoom must be positive and at least minZoom: $maxZoom',
        );

  /// The zoom at which [group] plus [padding] fits a viewport of
  /// [viewportSize] that shows [cameraPosition] at [anchor], kept between
  /// [minZoom] and [maxZoom].
  ///
  /// The [anchor] splits the viewport into the space on each side of the
  /// camera, the way a viewfinder's anchor does. A side without any space,
  /// such as the left with [Anchor.topLeft], can't show targets at any zoom,
  /// so it is left out.
  ///
  /// Returns `null` while the group is empty or the viewport has no size.
  double? zoomFor(
    TargetGroup group,
    Vector2 cameraPosition,
    Vector2 viewportSize, {
    Anchor anchor = Anchor.center,
  }) {
    final bounds = group.bounds;
    if (bounds == null || viewportSize.x <= 0 || viewportSize.y <= 0) {
      return null;
    }

    // The highest zoom at which the space on each side of the camera still
    // reaches the outermost target on that side.
    final fit = min(
      min(
        _fit(anchor.x * viewportSize.x, cameraPosition.x - bounds.left),
        _fit((1 - anchor.x) * viewportSize.x, bounds.right - cameraPosition.x),
      ),
      min(
        _fit(anchor.y * viewportSize.y, cameraPosition.y - bounds.top),
        _fit((1 - anchor.y) * viewportSize.y, bounds.bottom - cameraPosition.y),
      ),
    );
    final zoom = min(max(fit, minZoom), maxZoom);

    return zoom.isFinite && zoom > 0 ? zoom : null;
  }

  /// The highest zoom at which [space] pixels of the viewport show
  /// [distance] world units plus [padding].
  ///
  /// Returns infinity when the side sets no limit: when nothing has to be
  /// shown there, or when there is no space to show it at any zoom.
  double _fit(double space, double distance) {
    final reach = distance + padding;
    return space > 0 && reach > 0 ? space / reach : double.infinity;
  }
}
