import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'components/player.dart';
import 'components/platform.dart';
import 'components/background.dart';

enum GameState { waitingToStart, countdown, playing, gameOver }

class TowerUpGame extends FlameGame with TapDetector, HasCollisionDetection {
  late Player player;
  late Background background;
  final List<Platform> platforms = [];

  // Game state
  double gameDistance = 0;
  double score = 0;
  bool isGameOver = false;
  GameState gameState = GameState.waitingToStart;
  int countdownValue = 3;
  double countdownTimer = 0;
  TextComponent? overlayText;

  // Platform generation
  final double minPlatformGapX = 220;
  final double maxPlatformGapX = 340;
  final double minPlatformGapY = -60;
  final double maxPlatformGapY = 60;
  final double platformMinY = 440;
  final double platformMaxY = 520;
  final int initialPlatforms = 10;
  final double worldSpeed = 200; // pixels per second

  // Player X position (fixed, 20% from left)
  double get playerFixedX => size.x * 0.2;

  @override
  Future<void> onLoad() async {
    // Add parallax background
    background = Background();
    add(background);

    // Generate initial platforms
    generateInitialPlatforms();
    
    // Wait for all platforms to load
    for (final platform in platforms) {
      await platform.loaded;
    }

    // Create player, set anchor and position on first platform
    player = Player();
    player.anchor = Anchor.bottomLeft;
    await add(player);
    await player.loaded;

    final firstPlatform = platforms.first;
    // Position player on top of the first platform
    final playerY = firstPlatform.position.y - player.size.y;
    player.position = Vector2(
      firstPlatform.position.x,
      playerY,
    );
    player.velocity.y = 0;
    
    print('Platform position: ${firstPlatform.position}');
    print('Player size: ${player.size}');
    print('Player position: ${player.position}');

    // Add "Tap to Start" overlay
    overlayText = TextComponent(
      text: 'Tap To Start',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
      priority: 100,
    );
    add(overlayText!);

    return super.onLoad();
  }

  void showOverlay([String? text]) {
    if (overlayText == null) return;
    if (text != null) overlayText!.text = text;
    if (overlayText!.parent == null) add(overlayText!);
  }

  void hideOverlay() {
    overlayText?.removeFromParent();
  }

  void startCountdown() {
    gameState = GameState.countdown;
    countdownValue = 3;
    countdownTimer = 1.0;
    showOverlay('3');
  }

  void startGame() {
    gameState = GameState.playing;
    hideOverlay();
  }

  void generateInitialPlatforms() {
    platforms.clear();
    double x = 100; // Fixed left margin for the first platform
    double y = 500; // Start lower on the screen
    final rand = math.Random();
    for (int i = 0; i < initialPlatforms; i++) {
      final platform = Platform()..position = Vector2(x, y);
      add(platform);
      platforms.add(platform);

      // Randomize gaps
      x += minPlatformGapX + rand.nextDouble() * (maxPlatformGapX - minPlatformGapX);
      y += minPlatformGapY + rand.nextDouble() * (maxPlatformGapY - minPlatformGapY);
      y = y.clamp(platformMinY, platformMaxY);
    }
  }

  void generateNewPlatform() {
    final last = platforms.last;
    final rand = math.Random();
    double x = last.position.x + minPlatformGapX + rand.nextDouble() * (maxPlatformGapX - minPlatformGapX);
    double y = last.position.y + minPlatformGapY + rand.nextDouble() * (maxPlatformGapY - minPlatformGapY);
    y = y.clamp(platformMinY, platformMaxY);
    final platform = Platform()..position = Vector2(x, y);
    add(platform);
    platforms.add(platform);

    if (platforms.length > initialPlatforms + 2) {
      final old = platforms.removeAt(0);
      old.removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    const double playerYOffset = 8; // Lower the player by 8 pixels for visual alignment
    final firstPlatform = platforms.first;

    player.isGameActive = (gameState == GameState.playing && !isGameOver);

    if (gameState == GameState.waitingToStart) {
      showOverlay('Tap To Start');
      player.position = Vector2(
        firstPlatform.position.x,
        firstPlatform.position.y + playerYOffset,
      );
      return;
    }

    if (gameState == GameState.countdown) {
      countdownTimer -= dt;
      if (countdownTimer <= 0) {
        countdownValue--;
        if (countdownValue > 0) {
          showOverlay(countdownValue.toString());
          countdownTimer = 1.0;
        } else {
          showOverlay('Go!');
          countdownTimer = 0.7;
          gameState = GameState.playing;
        }
      }

      if (gameState == GameState.playing && countdownTimer <= 0) {
        hideOverlay();
      }

      player.position = Vector2(
        firstPlatform.position.x,
        firstPlatform.position.y + playerYOffset,
      );
      return;
    }

    if (gameState != GameState.playing || isGameOver) return;

    // Move platforms
    for (final platform in platforms) {
      platform.position.x -= worldSpeed * dt;
    }

    // Scroll background
    background.parallax?.baseVelocity = Vector2(worldSpeed * 0.3, 0);

    // Do NOT lock player's X position during gameplay
    // player.position.x = playerFixedX;

    // Increase score based on world movement
    gameDistance += worldSpeed * dt;
    score = gameDistance;

    // Generate more platforms
    if (platforms.last.position.x < size.x) {
      generateNewPlatform();
    }

    // Game over if player falls
    if (player.position.y > size.y + 100) {
      gameOver();
    }
  }

  @override
  void onTap() {
    if (gameState == GameState.waitingToStart) {
      startCountdown();
      return;
    }

    if (gameState == GameState.countdown) return;

    if (isGameOver) {
      restart();
      return;
    }

    if (gameState == GameState.playing) {
      player.jump();
    }
  }

  void gameOver() {
    isGameOver = true;
    showOverlay('Game Over!\nScore: ${score.toStringAsFixed(0)}\nTap to Restart');
    print('Game Over! Score: ${score.toStringAsFixed(0)}');
  }

  void restart() async {
    removeAll(children.where((component) => component != background).toList());

    score = 0;
    gameDistance = 0;
    isGameOver = false;
    gameState = GameState.waitingToStart;

    generateInitialPlatforms();

    player = Player();
    player.anchor = Anchor.bottomLeft;
    await add(player);
    await player.loaded;

    final firstPlatform = platforms.first;
    // Position player on top of the first platform
    final playerY = firstPlatform.position.y - player.size.y;
    player.position = Vector2(
      firstPlatform.position.x,
      playerY,
    );
    
    print('Platform position: ${firstPlatform.position}');
    print('Player size: ${player.size}');
    print('Player position: ${player.position}');

    player.velocity.y = 0;

    showOverlay('Tap To Start');
  }
}
