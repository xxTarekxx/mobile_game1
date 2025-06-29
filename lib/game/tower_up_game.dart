import 'package:flame/palette.dart'; // required for FixedResolutionViewport
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;


import 'components/player.dart';
import 'components/platform.dart';
import 'components/background.dart';
import 'components/plant.dart';

enum GameState { waitingToStart, countdown, playing, gameOver }

class TowerUpGame extends FlameGame with TapDetector, HasCollisionDetection {
  late Player player;
  late Background background;
  final List<Platform> platforms = [];
  final math.Random rand = math.Random();

  int platformsPassed = 0;
  GameState gameState = GameState.waitingToStart;
  int countdownValue = 3;
  Timer countdownTimer = Timer(1, repeat: true);
  TextComponent? overlayText;

  final double minPlatformGapX = 100;
  final double maxPlatformGapX = 280;
  final double minPlatformGapY = -80;
  final double maxPlatformGapY = 120;
  double lastPlatformY = 0;

  double baseSpeed = 220;
  double get currentSpeed {
    int milestone = platformsPassed ~/ 25;
    return baseSpeed * (1 + milestone * 0.2);
  }

  double get playerFixedX => size.x * 0.25;

@override
Future<void> onLoad() async {
  // camera.viewport = FixedResolutionViewport(Vector2(800, 600));

  background = Background();
  add(background);

  await resetGame();
}

  void _showOverlay(String text) {
    _hideOverlay();
    overlayText = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 64,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
        ),
      ),
      anchor: Anchor.center,
      position: camera.viewport.virtualSize / 2,
    );
    camera.viewport.add(overlayText!);
  }

  void _hideOverlay() {
    if (overlayText != null) {
      camera.viewport.remove(overlayText!);
      overlayText = null;
    }
  }

  void _startCountdown() {
    gameState = GameState.countdown;
    countdownValue = 3;
    _showOverlay('$countdownValue');
    countdownTimer = Timer(1, repeat: true, onTick: () {
      countdownValue--;
      if (countdownValue > 0) {
        _showOverlay('$countdownValue');
      } else {
        _startGame();
        countdownTimer.stop();
      }
    });
    countdownTimer.start();
  }

  void _startGame() {
    gameState = GameState.playing;
    player.isGameActive = true;
    _hideOverlay();
  }

  void _generatePlatform(Vector2 position) {
    final platform = Platform(position: position);
    add(platform);
    platforms.add(platform);
    lastPlatformY = position.y;

    if (platformsPassed > 1 && rand.nextDouble() < 0.4) {
      _addPlantToPlatform(platform);
    }
  }

  void _generateNextPlatform() {
    if (platforms.isEmpty) return;
    
    final lastPlatform = platforms.last;
    final newX = lastPlatform.position.x +
        lastPlatform.size.x +
        minPlatformGapX +
        rand.nextDouble() * (maxPlatformGapX - minPlatformGapX);
    final newY = (lastPlatformY +
            minPlatformGapY +
            rand.nextDouble() * (maxPlatformGapY - minPlatformGapY))
        .clamp(size.y * 0.3, size.y * 0.8);
    _generatePlatform(Vector2(newX, newY));
  }

  void _addPlantToPlatform(Platform platform) {
    final plantData = _getPlantDataForLevel();
    final plant = Plant(
      plantType: plantData['type']!,
      frameCount: plantData['frames']!,
      position: Vector2(platform.size.x / 2, 0),
    );
    platform.add(plant);
  }

  Map<String, dynamic> _getPlantDataForLevel() {
    int level = (platformsPassed ~/ 25) % 7 + 1;
    switch (level) {
      case 1:
        return {'type': 'Plant 1', 'frames': 90};
      case 2:
        return {'type': 'Plant 2', 'frames': 90};
      case 3:
        return {'type': 'Plant 3', 'frames': 90};
      case 4:
        return {'type': 'Plant 4', 'frames': 60};
      case 5:
        return {'type': 'Plant 5', 'frames': 60};
      case 6:
        return {'type': 'Plant 6', 'frames': 60};
      case 7:
        return {'type': 'Plant 7', 'frames': 60};
      default:
        return {'type': 'Plant 1', 'frames': 90};
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState == GameState.countdown) {
      countdownTimer.update(dt);
      return;
    }

    if (gameState != GameState.playing || player.isRemoved) return;

    for (final platform in platforms) {
      platform.position.x -= currentSpeed * dt;
    }

    background.parallax?.baseVelocity.setValues(currentSpeed * 0.3, 0);

    platforms
        .where((p) =>
            !p.hasBeenPassed && p.position.x + p.size.x < playerFixedX)
        .forEach((p) {
      p.hasBeenPassed = true;
      platformsPassed++;
    });

    platforms.removeWhere((p) {
      if (p.position.x + p.size.x < 0) {
        remove(p);
        return true;
      }
      return false;
    });

    if (platforms.isNotEmpty && platforms.last.position.x < size.x) {
      _generateNextPlatform();
    }

    if (player.position.y > size.y + player.size.y) {
      gameOver();
    }
  }

  @override
  void onTap() {
    switch (gameState) {
      case GameState.waitingToStart:
        _startCountdown();
        break;
      case GameState.playing:
        player.jump();
        break;
      case GameState.gameOver:
        resetGame();
        break;
      case GameState.countdown:
        break;
    }
  }

  void gameOver() {
    if (gameState == GameState.gameOver) return;
    gameState = GameState.gameOver;
    player.isGameActive = false;
    player.velocity = Vector2.zero();
    _hideOverlay();
    _showOverlay('Game Over\nTap to Restart');
  }

  Future<void> resetGame() async {
    // Remove all existing components
    children.whereType<Platform>().forEach(remove);
    children.whereType<Player>().forEach(remove);
    platforms.clear();

    platformsPassed = 0;
    gameState = GameState.waitingToStart;

    // Create player first
    player = Player();
    await add(player);

    double currentX = playerFixedX;
    lastPlatformY = size.y * 0.7;

    // Generate initial platforms
    for (int i = 0; i < 5; i++) {
      _generatePlatform(Vector2(currentX, lastPlatformY));
      final last = platforms.last;
      currentX = last.position.x + last.size.x + 150;
      lastPlatformY = (last.position.y +
              minPlatformGapY / 2 +
              rand.nextDouble() * (maxPlatformGapY - minPlatformGapY / 2))
          .clamp(size.y * 0.3, size.y * 0.8);
    }

    // Wait a frame to ensure all platforms are properly loaded
    await Future.delayed(const Duration(milliseconds: 16));

    // Position player on the first platform
    if (platforms.isNotEmpty) {
      final firstPlatform = platforms.first;
      player.position = Vector2(playerFixedX, firstPlatform.position.y - 1);
      player.isOnGround = true;
      player.velocity = Vector2.zero();
    }

    _showOverlay('Tap to Start');
  }
}
