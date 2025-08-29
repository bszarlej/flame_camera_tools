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

class FlameCameraToolsExampleGame extends FlameGame
    with HasKeyboardHandlerComponents {
  late final Player player;
  late final AdvancedFollowBehavior followBehavior;
  late final RectangleComponent targetBox;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    // Add player to the world
    player = Player(size: Vector2.all(50));
    world.add(player);

    // Add a target component to demonstrate focus
    targetBox = RectangleComponent(
      position: Vector2(500, 300),
      size: Vector2.all(100),
      paint: Paint()..color = Colors.blue,
      anchor: Anchor.center,
    );
    world.add(targetBox);

    // Start following the player with adjustable stiffness and deadzone
    followBehavior = camera.chase(player, stiffness: 0.97);

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

  Player({super.position, super.size})
      : super(anchor: Anchor.center, paint: Paint()..color = Colors.red);

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keys = keysPressed;
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final direction = Vector2.zero();

    if (_keys.contains(LogicalKeyboardKey.keyW)) direction.y = -1;
    if (_keys.contains(LogicalKeyboardKey.keyA)) direction.x = -1;
    if (_keys.contains(LogicalKeyboardKey.keyS)) direction.y = 1;
    if (_keys.contains(LogicalKeyboardKey.keyD)) direction.x = 1;

    // Update camera follow offset dynamically based on movement
    if (!direction.isZero()) {
      direction.normalize();
      position += direction * _movementSpeed * dt;
    }

    // Adjust camera offset based on the players direction
    game.followBehavior.offset = direction.normalized().scaled(192);
  }
}
