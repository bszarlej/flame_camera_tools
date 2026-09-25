import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    const GameWidget.controlled(gameFactory: FlameCameraToolsExampleGame.new),
  );
}

/// Move with WASD, press Space to shake the camera.
class FlameCameraToolsExampleGame extends FlameGame
    with HasKeyboardHandlerComponents {
  late final Player player;
  late final ChaseBehavior chase;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    // Add player to the world
    player = Player(size: Vector2.all(50));
    world.add(player);

    // Add a fixed landmark, so the camera movement is visible
    world.add(
      RectangleComponent(
        position: Vector2(100, 100),
        size: Vector2.all(100),
        paint: Paint()..color = Colors.blue,
        anchor: Anchor.center,
      ),
    );

    // Follow the player smoothly. The player can move freely inside the
    // dead zone before the camera starts following.
    chase = camera.chase(
      player,
      stiffness: 0.97,
      deadZone: RectangularDeadZone.symmetric(horizontal: 80, vertical: 48),
    );

    // Apply a sequence of camera effects
    camera.effectSequence([
      () => camera.shake(20, EffectController(duration: 1)),
      () => camera.zoomTo(
            1.5,
            EffectController(duration: 2, curve: Curves.easeInOut),
          ),
    ]);
  }
}

class Player extends RectangleComponent
    with KeyboardHandler, HasGameReference<FlameCameraToolsExampleGame> {
  Set<LogicalKeyboardKey> _keys = {};
  final double _movementSpeed = 300;
  final _direction = Vector2.zero();

  Player({super.position, super.size})
      : super(anchor: Anchor.center, paint: Paint()..color = Colors.red);

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keys = keysPressed;

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      game.camera.shake(10, EffectController(duration: 0.4));
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _direction.setZero();

    if (_keys.contains(LogicalKeyboardKey.keyW)) _direction.y = -1;
    if (_keys.contains(LogicalKeyboardKey.keyA)) _direction.x = -1;
    if (_keys.contains(LogicalKeyboardKey.keyS)) _direction.y = 1;
    if (_keys.contains(LogicalKeyboardKey.keyD)) _direction.x = 1;

    if (!_direction.isZero()) {
      _direction.normalize();
      position.addScaled(_direction, _movementSpeed * dt);
    }

    // Look ahead in the direction the player is moving
    game.chase.offset
      ..setFrom(_direction)
      ..scale(192);
  }
}
