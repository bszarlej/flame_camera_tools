# flame_camera_tools

flame_camera_tools is a Flutter package that enhances camera functionality for games built with Flame. It provides a intuitive way to manage camera behavior, making it easier to create dynamic and immersive experiences in 2D game worlds.

## Installation

At the moment you can add this package via [Github](https://github.com/bszarlej/flame_camera_tools.git) by adding the following to your `pubspec.yaml` file:

```yaml
dependencies:
  flame_camera_tools:
    git:
      url: https://github.com/bszarlej/flame_camera_tools.git
      ref: master
```

Or, if you prefer to clone the repository directly and use it locally, add it like this:
```yaml
dependencies:
  flame_camera_tools:
    path: /path/to/this/package/flame_camera_tools/
```
Then, run:

```sh
flutter pub get
```
---
In the future, this package will also be published on [pub.dev](https://pub.dev/), the official package repository for Dart and Flutter.

# Features
- Smooth Follow: The camera smoothly follows a target component, adjusting the speed based on the distance.
- Shake Effect: Apply a shake effect to any PositionProvider.
- Zooming: Zoom in or out with customizable durations.
- Focus Effects: Focus the camera on a position or component.
- Customizable Effects: Modify the duration and curve of each effect.
- Chaining Effects: Seamlessly chain multiple effects using Futures.
  
## CameraComponent Extension Methods
- smoothFollow() – Smoothly follows a ReadOnlyPositionProvider with adjustable stiffness.
- shake() – Apply a shake effect to the camera.
- zoomTo() – Zoom in or out with a customizable duration and curve.
- focusOn() – Focus on a particular position in the world.
- focusOnComponent() – Focus on a specific component.

## Usage

Import the package like this:

```dart
import 'package:flame_camera_tools/flame_camera_tools.dart';
```

Instantiate you camera component:

```dart
final camera = CameraComponent();
```

Follow a Component:

```dart
camera.smoothFollow(component, stiffness: 5);
```

Apply a Shake Effect:

```dart
camera.shake(
  duration: const Duration(seconds: 3),
  intensity: 5,
  curve: Curves.linear,
);
```

Zoom Out:

```dart
camera.zoomTo(
  0.5,
  duration: const Duration(seconds: 3),
  curve: Curves.linear,
);
```
Focus on a Component:

```dart
camera.focusOnComponent(
  component,
  duration: const Duration(seconds: 3),
  curve: Curves.linear,
);
```

Chaining Multiple Effects:

```dart
camera
    .shake(duration: const Duration(seconds: 4), intensity: 10)
    .then((_) => camera.zoomTo(0.1, duration: const Duration(seconds: 3)))
    .then((_) => camera.focusOnComponent(component, duration: Duration(seconds: 3)))
    .then((_) => camera.zoomTo(1.0, duration: const Duration(seconds: 2)));
```

Applying Multiple Effects at Once:

```dart
camera
  ..shake(duration: const Duration(seconds: 4), intensity: 7)
  ..zoomTo(0.75, duration: const Duration(seconds: 2));
```

# Why Use This Package?

This package allows for easy and smooth camera transitions, such as when you want to zoom in on an action, create a shake effect for a hit or explosion, or follow a character smoothly as they move through a level. The effects are customizable and can be chained to create complex camera behaviors that enhance your game's dynamic visuals.
