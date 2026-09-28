import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_camera_tools/flame_camera_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const GameWidget.controlled(gameFactory: GroupChaseExampleGame.new));
}

/// Bots wander around while the camera keeps all of them in view.
///
/// Press B to add a bot, R to remove one and Space to shake the camera.
class GroupChaseExampleGame extends FlameGame with KeyboardEvents {
  final random = Random();
  final bots = TargetGroup();

  /// How far from the origin the bots wander. It grows and shrinks over time,
  /// so the camera zooms out and back in.
  double spread = 200;
  double _time = 0;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    world.add(Grid());
    for (var i = 0; i < 10; i++) {
      _addBot();
    }

    camera.chase(
      bots,
      stiffness: 0.3,
      zoomToFit: const ZoomToFit(padding: 100, minZoom: 0.2),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;
    spread = 700 - 550 * cos(_time / 4);
  }

  void _addBot() {
    final bot = Bot();
    world.add(bot);
    bots.add(bot);
  }

  void _removeBot() {
    if (bots.isEmpty) return;

    final bot = bots.targets.last as Bot;
    bots.remove(bot);
    bot.removeFromParent();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyB:
        _addBot();
      case LogicalKeyboardKey.keyR:
        _removeBot();
      case LogicalKeyboardKey.space:
        camera.shake(10, EffectController(duration: 0.4));
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}

/// A circle that keeps walking to random points within the game's spread.
class Bot extends CircleComponent with HasGameReference<GroupChaseExampleGame> {
  Bot() : super(radius: 20, anchor: Anchor.center);

  final _destination = Vector2.zero();
  double _speed = 0;

  @override
  FutureOr<void> onLoad() {
    final random = game.random;
    paint = Paint()
      ..color =
          HSVColor.fromAHSV(1, random.nextDouble() * 360, 0.7, 0.9).toColor();

    _pickDestination();
    position.setFrom(_destination);
    _pickDestination();
  }

  void _pickDestination() {
    final random = game.random;
    final angle = random.nextDouble() * 2 * pi;
    final distance = sqrt(random.nextDouble()) * game.spread;

    _destination.setValues(cos(angle) * distance, sin(angle) * distance);
    _speed = 100 + random.nextDouble() * 200;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final toDestination = _destination - position;
    final step = _speed * dt;

    if (toDestination.length <= step) {
      position.setFrom(_destination);
      _pickDestination();
    } else {
      position.addScaled(toDestination.normalized(), step);
    }
  }
}

/// Lines every 200 units, so the camera's movement and zoom are visible.
class Grid extends Component {
  final _paint = Paint()
    ..color = const Color(0x33FFFFFF)
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    for (var i = -3000.0; i <= 3000; i += 200) {
      canvas.drawLine(Offset(i, -3000), Offset(i, 3000), _paint);
      canvas.drawLine(Offset(-3000, i), Offset(3000, i), _paint);
    }
  }
}
