import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    GameWidget.controlled(
      gameFactory: FlameCameraToolsExampleGame.new,
    ),
  );
}

class FlameCameraToolsExampleGame extends FlameGame
    with HasKeyboardHandlerComponents {
  final player = Player(position: Vector2.all(0), size: Vector2.all(50));

  @override
  FutureOr<void> onLoad() {
    world.add(player);

    final someComponent = RectangleComponent(
      position: Vector2.all(200),
      size: Vector2.all(100),
    );
    world.add(someComponent);

    // Smoothly follow the player around
    camera.smoothFollow(player, stiffness: 0.5);

    // Shake the camera for 5 seconds with a intensity of 20
    camera.shake(duration: 5, intensity: 20).then(
          //after that focus the camera on 'someComponent' over a duration of 3 seconds with an easing curve
          (_) => camera.focusOnComponent(
            someComponent,
            duration: 3,
            curve: Curves.easeInOut,
          ),
        );
    // Zoom the camera in while the shake effect is applied
    camera.zoomTo(2, duration: 2);

    return super.onLoad();
  }
}

class Player extends RectangleComponent with KeyboardHandler {
  Player({super.position, super.size})
      : super(paint: Paint()..color = Colors.red);

  Set<LogicalKeyboardKey> _keys = {};
  final double _movementSpeed = 300;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keys = keysPressed;
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final direction = Vector2.zero();

    if (_keys.contains(LogicalKeyboardKey.keyW)) {
      direction.y = -1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyA)) {
      direction.x = -1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyS)) {
      direction.y = 1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyD)) {
      direction.x = 1;
    }

    if (!direction.isZero()) {
      direction.normalize();
      position += direction * _movementSpeed * dt;
    }
  }
}
