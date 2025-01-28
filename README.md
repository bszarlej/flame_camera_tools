# flame_camera_tools

flame_camera_tools is a Flutter package that enhances camera functionality for games built with Flame. It provides a intuitive way to manage camera behavior, making it easier to create dynamic and immersive experiences in 2D game worlds.

## Installation

At the moment you can add this package via [Github](https://github.com/Bartekdevv/flame_camera_tools.git) only by adding the following to your `pubspec.yaml` file:

```yaml
dependencies:
  flame_camera_tools:
    git:
      url: https://github.com/Bartekdevv/flame_camera_tools.git
      ref: master
```

And running the following command:

```sh
flutter pub get
```

In the future, this package will also be published on [pub.dev](https://pub.dev/), the official package repository for Dart and Flutter.

## Features

- Smooth follow behavior where the speed is dependent on the distance to the target
- Shake Effect which can be applied to any PositionProvider
- Zooming in/out
- Focusing on a position or a component
- Every effect can be customized with a duration and a curve
- Possibility to chain effects using futures

### CameraComponent Extension Methods
- smoothFollow() - Smoothly follows a ReadOnlyPositionProvider with a specified stiffness
- shake() - Shakes the camera
- zoomTo() - Zooms in or out
- focusOn() - Focuses on a certain position in the world
- focusOnComponent() - Focuses on the specified component

## Usage

Import the package like this:

```dart
import 'package:flame_camera_tools/flame_camera_tools.dart';
```

Instantiate you camera component:

```dart
final camera = CameraComponent();
```

Follow a component:

```dart
camera.smoothFollow(component, stiffness: 5);
```

Apply the shake effect:

```dart
camera.shake(
  duration: const Duration(seconds: 3),
  intensity: 5,
  curve: Curves.linear,
);
```

Zoom out:

```dart
camera.zoomTo(
  0.5,
  duration: const Duration(seconds: 3),
  curve: Curves.linear,
);
```
Focus on a component:

```dart
camera.focusOnComponent(
  component,
  duration: const Duration(seconds: 3),
  curve: Curves.linear,
);
```

Chaining effects:

```dart
camera
    .shake(duration: const Duration(seconds: 4), intensity: 10)
    .then((_) => camera.zoomTo(0.1, duration: const Duration(seconds: 3)))
    .then((_) => camera.focusOnComponent(component, duration: Duration(seconds: 3)))
    .then((_) => camera.zoomTo(1.0, duration: const Duration(seconds: 2)));
```

Multiple effects at once:

```dart
    camera.shake(duration: const Duration(seconds: 4), intensity:7);
    camera.zoomTo(0.75, duration: const Duration(seconds: 2));
```