# flame\_camera\_tools

[![Pub](https://img.shields.io/pub/v/flame_camera_tools.svg?style=popout)](https://pub.dev/packages/flame_camera_tools)
[![Pub Points](https://img.shields.io/pub/points/flame_camera_tools.svg?style=popout)](https://pub.dev/packages/flame_camera_tools/score)
[![Pub Likes](https://img.shields.io/pub/likes/flame_camera_tools.svg?style=popout)](https://pub.dev/packages/flame_camera_tools/score)
[![Pub Downloads](https://img.shields.io/pub/dm/flame_camera_tools.svg?style=popout)](https://pub.dev/packages/flame_camera_tools)

`flame_camera_tools` is a Flutter package that enhances camera functionality for games built with [Flame](https://flame-engine.org/).
It provides a set of convenient extensions for `CameraComponent` to handle smooth following, camera shake, zooming, rotating, moving and effect sequencing. This makes it easier to create dynamic and immersive 2D game experiences.

---

## Features

* **Smooth Follow:** The camera can smoothly follow any target with adjustable stiffness. Supports configurable dead zones and offsets.
* **Group Follow:** Follow several targets at once, zooming out as they spread apart so that all of them stay in view.
* **Shake Effect:** Apply a randomized shake effect to the camera or any `PositionProvider`. The shake works on top of following, so the camera keeps tracking its target while it shakes.
* **Zooming:** Zoom in and out, either relative to the current zoom or to an absolute zoom level.
* **Rotating:** Rotate the camera by a specified angle or to an absolute angle.
* **Moving:** Move the camera to a specific position.
* **Customizable Effects:** Every effect takes an `EffectController`, which controls its duration and easing curve.
* **Chaining Effects:** Sequence multiple effects using `Future`s for smooth transitions.
* **Simultaneous Effects:** Apply multiple effects at once for dynamic interactions.
* **Not Only for Cameras:** The shake effect and the follow behavior can be added to any component.

See [`example/main.dart`](example/main.dart) for a runnable demo: move with WASD and press Space to shake the camera. [`example/group_chase.dart`](example/group_chase.dart) shows the camera following a group of wandering bots.


## Usage

You can use your own `CameraComponent` or access the camera provided by `FlameGame`:

```dart
// Directly instantiate the CameraComponent
final camera = CameraComponent();
```

```dart
// Accessing the camera from FlameGame
final camera = game.camera;
```

Starting an effect replaces a running effect of the same kind, so a new zoom replaces the current zoom, a new shake the current shake, and so on. Every effect returns a `Future` that completes when the effect finishes or is cancelled.

---

### Smoothly Follow a Component

**Smooth follow**

![Camera smoothly following a player](https://raw.githubusercontent.com/bszarlej/flame_camera_tools/master/assets/chase.gif)

**Dead zone**

![Camera following a player that moves freely inside a dead zone](https://raw.githubusercontent.com/bszarlej/flame_camera_tools/master/assets/dead_zone.gif)

Use `chase()` to make the camera chase a target with adjustable stiffness and an optional dead zone. The target can be a component or any other `ReadOnlyPositionProvider`. It returns a `ChaseBehavior` instance, which allows you to tweak options like `offset`, `deadZone`, and `stiffness` later on:

```dart
final chase = camera.chase(component, stiffness: 0.5);

// Later, you can adjust settings
chase.offset = Vector2(0, -50);
chase.deadZone = CircularDeadZone(radius: 80);
chase.stiffness = 0.7;
```

`CameraComponent.chase` parameters:

```dart
camera.chase(
  component,
  stiffness: 0.5,
  deadZone: RectangularDeadZone.all(100),
  offset: Vector2(0, -50),
  horizontalOnly: false,
  verticalOnly: false,
  snap: true, // immediately move the camera to the target plus offset
);
```

* `stiffness`: How quickly the camera catches up, from `0.0` (never moves) to `1.0` (follows instantly). At `0.5` it closes half the distance to the target in 0.2 seconds; lower values are floatier, higher values tighter. It behaves the same at any frame rate.
* `deadZone`: An area around the camera in which the target can move without the camera following. Use `CircularDeadZone`, `RectangularDeadZone` or your own `DeadZone` implementation.
* `offset`: Follows a point offset from the target, for example to look ahead of a moving player.
* `horizontalOnly` / `verticalOnly`: Only follow along one axis.

To stop following, call Flame's `stop()`:

```dart
camera.stop();
```

#### Following Several Targets

**Group follow with zoom to fit**

![Camera zooming out and in to keep a group of wandering bots in view](https://raw.githubusercontent.com/bszarlej/flame_camera_tools/master/assets/group_chase.gif)

To keep several targets in view, for example in local multiplayer, chase a `TargetGroup`. The camera follows the center of the group, and with `zoomToFit` it also zooms out as the targets spread apart:

```dart
final players = TargetGroup([player1, player2]);

camera.chase(
  players,
  stiffness: 0.5,
  zoomToFit: const ZoomToFit(
    padding: 100, // space to keep around the outermost targets
    minZoom: 0.5, // never zoom out further than this
    maxZoom: 1, // never zoom in further than this
  ),
);

// Players can join and leave at any time
players.add(player3);
players.remove(player1);
```

* `padding`: Extra space in world units between the outermost targets and the edge of the screen. Components are always kept fully in view, whatever their size and anchor, so padding is only needed for breathing room.
* `minZoom` / `maxZoom`: Limits for the zoom. With the default `maxZoom` of `1`, the camera keeps its normal zoom while the targets are close together and only zooms out when they spread apart. The default `minZoom` of `0` never stops zooming out.

`deadZone`, `offset` and the axis locks work with groups too. A small dead zone keeps the camera calm while single targets move around. The fit is measured from where the camera actually is, so the targets stay in view even when an offset or dead zone keeps the camera away from the center of the group, or while it catches up with a fast group.

The zoom follows with the same `stiffness` as the movement, and `snap` sets it right away. Chasing with `zoomToFit` cancels running zoom effects, and zooming with `zoomTo()` or `zoomBy()` while it runs makes them fight over the zoom. While the group is empty, the camera stays where it is.

#### Custom Dead Zones

Implement `DeadZone` to define your own shape. `computeDelta` returns how far the camera has to move to bring the target back inside, or zero while the target is inside:

```dart
/// Lets the target move freely left and right within [distance], but always
/// follows it vertically.
class HorizontalDeadZone implements DeadZone {
  HorizontalDeadZone(this.distance);

  final double distance;
  final _delta = Vector2.zero();

  @override
  Vector2 computeDelta(Vector2 ownerPosition, Vector2 targetPosition) {
    final dx = targetPosition.x - ownerPosition.x;
    _delta.setValues(
      dx.abs() > distance ? dx - distance * dx.sign : 0,
      targetPosition.y - ownerPosition.y,
    );
    return _delta;
  }
}
```

`computeDelta` is called every frame, so reusing one vector like above avoids allocating a new one each time.

---

### Apply camera shake

Create a shake effect with specific amplitude and duration:

```dart
await camera.shake(10.0, LinearEffectController(0.5));
```

* `amplitude`: Maximum displacement in pixels along each axis at the start of the effect.
* `controller`: Defines the duration and progression curve of the shake. Speed-based controllers are not supported.

The shake weakens over time and returns the camera to where it would have been without it.

---

### Zooming

Zoom in or out relative to the current zoom:

```dart
await camera.zoomBy(0.5, LinearEffectController(1.0)); // zoom in by 50%
await camera.zoomBy(-0.5, LinearEffectController(1.0)); // zoom out by 50%
```

Or zoom to an absolute zoom level:

```dart
await camera.zoomTo(2.0, LinearEffectController(1.0));
```

* `value`: Relative change (greater than `-1`) or absolute zoom level (greater than `0`).
* `controller`: Controls duration, curve, and smoothing.

---

### Rotating

Rotate the camera by a relative angle:

```dart
await camera.rotateBy(pi / 4, LinearEffectController(1.0)); // rotate 45 degrees
```

Or rotate to an absolute angle:

```dart
await camera.rotateTo(0, LinearEffectController(1.0)); // back to upright
```

* `angle`: Relative rotation or absolute angle in radians, like everywhere else in Flame. To use degrees, convert them with `radians()`, for example `radians(45)`.
* `controller`: Controls duration, curve, and smoothing.

`rotateTo` rotates by the difference to the current angle, without taking the shortest way round: from `radians(350)` to `0` it turns back 350 degrees rather than forward 10.

---

### Moving the Camera

Move the camera to a specific position:

```dart
await camera.lookAt(Vector2(200, 200), LinearEffectController(1.0));
```

This stops following, so call `chase()` again afterwards to resume.

---

### Chaining Multiple Effects

Chain multiple effects in sequence:

```dart
await camera.effectSequence([
  () => camera.shake(10.0, LinearEffectController(0.5)),
  () => camera.zoomTo(1.5, LinearEffectController(1.0)),
  () => camera.rotateBy(pi / 4, LinearEffectController(0.5)),
]);
```

If an effect in the sequence gets cancelled, the sequence moves on to the next one.

---

### Applying Multiple Effects Simultaneously

You can apply multiple effects at the same time:

```dart
camera
  ..shake(7.0, LinearEffectController(4))
  ..zoomTo(0.75, LinearEffectController(1.0))
  ..rotateBy(pi / 4, LinearEffectController(1.0));
```

---

### Using It Without a Camera

`ShakeEffect` and `ChaseBehavior` work on any component, not just the camera:

```dart
// Shake an enemy that got hit
enemy.add(ShakeEffect(5, EffectController(duration: 0.3)));

// Make a pet follow the player
pet.add(
  ChaseBehavior(
    target: player,
    stiffness: 0.4,
    offset: Vector2(-40, 0),
  ),
);
```

---

## License

MIT License. See `LICENSE` for details.
