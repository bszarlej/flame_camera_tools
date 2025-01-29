# flame_camera_tools

flame_camera_tools is a Flutter package that enhances camera functionality for games built with Flame. It provides a intuitive way to manage camera behavior, making it easier to create dynamic and immersive experiences in 2D game worlds.

<a title="Pub" href="https://pub.dev/packages/flame_camera_tools" ><img src="https://img.shields.io/pub/v/flame_camera_tools.svg?style=popout" /></a>
<a title="Pub Points" href="https://pub.dev/packages/flame_camera_tools/score" ><img src="https://img.shields.io/pub/points/flame_camera_tools.svg?style=popout" /></a>

# Features
- Smooth Follow: The camera smoothly follows a target component, adjusting the speed based on the distance.
- Area Follow: The camera follows a target component only after the target moves outside a specified rectangular area. This is useful for creating "dead zones" where the camera does not immediately follow the target.
- Shake Effect: Apply a shake effect to any PositionProvider.
- Zooming: Zoom in or out with customizable durations.
- Focus Effects: Focus the camera on a position or component.
- Customizable Effects: Modify the duration and curve of each effect.
- Chaining Effects: Seamlessly chain multiple effects using Futures.

## Usage

You can either instantiate your own CameraComponent directly or use the camera provided by the FlameGame class:

```dart
// Directly instantiate the CameraComponent
final camera = CameraComponent();
```

```dart
// Accessing the camera from FlameGame
final camera = game.camera;
```

### Follow a Component
Use `smoothFollow()` to make the camera smoothly follow a component with adjustable stiffness:

```dart
camera.smoothFollow(component, stiffness: 5);
```

Use `areaFollow()` to make the camera follow a component only once it moves outside a defined rectangular area:

```dart
camera.areaFollow(component, areaBounds: const Rect.fromLTRB(100, 100, 100, 100));
```
### Apply a Shake Effect
Create a shake effect with a specific duration, intensity, and easing curve:

```dart
camera.shake(
  duration: const Duration(seconds: 3),
  intensity: 5,
  curve: Curves.linear,
);
```

### Zooming in/out

Zoom in/out with customizable zoom level, duration, and curve:

```dart
camera.zoomTo(
  0.5,
  duration: const Duration(seconds: 3),
  curve: Curves.linear,
);
```
### Focusing the Camera

Move the camera to focus on a position, with optional duration and easing:

```dart
camera.focusOn(
  Vector2(100, 100),
  duration: const Duration(seconds: 3),
  curve: Curves.linear,
);
```

Move the camera to focus on a component, with optional duration and easing:

```dart
camera.focusOnComponent(
  component,
  duration: const Duration(seconds: 3),
  curve: Curves.linear,
);
```

### Chaining Multiple Effects
You can chain multiple effects together for a sequence of camera movements:

```dart
camera
    .shake(duration: const Duration(seconds: 4), intensity: 10)
    .then((_) => camera.zoomTo(0.1, duration: const Duration(seconds: 3)))
    .then((_) => camera.focusOnComponent(component, duration: Duration(seconds: 3)))
    .then((_) => camera.zoomTo(1.0, duration: const Duration(seconds: 2)));
```

### Applying Multiple Effects at Once
You can also apply multiple effects simultaneously for more dynamic interactions:

```dart
camera
  ..shake(duration: const Duration(seconds: 4), intensity: 7)
  ..zoomTo(0.75, duration: const Duration(seconds: 2));
```

# Why Use This Package?

This package allows for easy and smooth camera transitions, such as when you want to zoom in on an action, create a shake effect for a hit or explosion, or follow a character smoothly as they move through a level. The effects are customizable and can be chained to create complex camera behaviors that enhance your game's dynamic visuals.
