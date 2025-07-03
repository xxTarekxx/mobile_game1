import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import 'components/background.dart';
import 'components/platform.dart';
import 'components/player.dart';

enum GameState { waitingToStart, countdown, playing, gameOver }

class TowerUpGame extends FlameGame with TapDetector, HasCollisionDetection {
  late Player player;
  late Background background;
  final List<Platform> platforms = [];
  int sessionSeed = 0;
  math.Random rand = math.Random();

  int platformsPassed = 0;
  GameState gameState = GameState.waitingToStart;
  int countdownValue = 3;
  Timer countdownTimer = Timer(1, repeat: true);
  TextComponent? overlayText;

  final double minPlatformGapX = 100;
  final double maxPlatformGapX = 280;
  final double minPlatformGapY = -80;
  double maxPlatformGapY = 120; // Will be set in onLoad based on jump height
  double lastPlatformY = 0;

  double baseSpeed = 220;
  double get currentSpeed {
    int milestone = platformsPassed ~/ 25;
    return baseSpeed * (1 + milestone * 0.2);
  }

  double get playerFixedX => size.x * 0.25;

  late TextComponent scoreText;

  @override
  Future<void> onLoad() async {
    // camera.viewport = FixedResolutionViewport(Vector2(800, 600));

    background = Background();
    add(background);

    // Generate a new session seed on app load
    sessionSeed = DateTime.now().millisecondsSinceEpoch;
    rand = math.Random(sessionSeed);

    // Calculate max jump height and set maxPlatformGapY
    final double jumpForce = 460; // Should match Player.jumpForce
    final double gravity = 950; // Should match Player.gravity
    final double maxJumpHeight = (jumpForce * jumpForce) / (2 * gravity);
    maxPlatformGapY = maxJumpHeight * 0.8; // 80% of max jump height for safety

    // Add score text
    scoreText = TextComponent(
      text: 'Platforms: 0',
      position: Vector2(20, 48),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
        ),
      ),
      priority: 100,
    );
    add(scoreText);

    await resetGame();
  }

  void _showOverlay(String text) {
    _hideOverlay();

    // Add a modern gradient background overlay
    final backgroundOverlay = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xCC000000),
      priority: 999,
    );
    add(backgroundOverlay);

    final isGameOver = text.contains('GAME OVER');
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    if (isGameOver) {
      // Render 'GAME OVER' and 'Tap to Retry' as separate components
      final gameOverText = TextComponent(
        text: 'GAME OVER',
        textRenderer: TextPaint(
          style: TextStyle(
            color: const Color(0xFFFF6B6B),
            fontSize: 56.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            shadows: [
              Shadow(blurRadius: 12, color: Colors.black.withOpacity(0.8)),
              Shadow(blurRadius: 6, color: Colors.black.withOpacity(0.6)),
            ],
          ),
        ),
        anchor: Anchor.center,
        position: Vector2(centerX, centerY - 40),
        priority: 1000,
      );
      add(gameOverText);

      final retryText = TextComponent(
        text: 'Tap to Retry',
        textRenderer: TextPaint(
          style: TextStyle(
            color: const Color(0xFFFF6B6B),
            fontSize: 36.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            shadows: [
              Shadow(blurRadius: 8, color: Colors.black.withOpacity(0.7)),
            ],
          ),
        ),
        anchor: Anchor.center,
        position: Vector2(centerX, centerY + 40),
        priority: 1000,
      );
      add(retryText);
    } else {
      // For other overlays, use the default style
      overlayText = TextComponent(
        text: text,
        textRenderer: TextPaint(
          style: TextStyle(
            color: const Color(0xFF4ECDC4),
            fontSize: 48.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            shadows: [
              Shadow(blurRadius: 12, color: Colors.black.withOpacity(0.8)),
              Shadow(blurRadius: 6, color: Colors.black.withOpacity(0.6)),
            ],
          ),
        ),
        anchor: Anchor.center,
        position: Vector2(centerX, centerY),
        priority: 1000,
      );
      add(overlayText!);
    }
    print(
      'Showing overlay: "$text" at center: ($centerX, $centerY), screen size: $size',
    );
  }

  void _hideOverlay() {
    if (overlayText != null) {
      remove(overlayText!);
      overlayText = null;
      print('Hiding overlay');
    }

    // Remove ALL overlay-related components (backgrounds, glows, shadows)
    final overlayComponents = children
        .where(
          (child) =>
              (child is RectangleComponent && child.priority == 999) ||
              (child is TextComponent && child.priority >= 999),
        )
        .toList();

    for (final component in overlayComponents) {
      remove(component);
    }

    print('Cleaned up ${overlayComponents.length} overlay components');
  }

  void _startCountdown() {
    gameState = GameState.countdown;
    countdownValue = 3;
    _showCountdownOverlay('$countdownValue');
    countdownTimer = Timer(
      1,
      repeat: true,
      onTick: () {
        countdownValue--;
        if (countdownValue > 0) {
          _showCountdownOverlay('$countdownValue');
        } else {
          _startGame();
          countdownTimer.stop();
        }
      },
    );
    countdownTimer.start();
  }

  void _showCountdownOverlay(String text) {
    _hideOverlay();

    // Add a subtle background for countdown
    final backgroundOverlay = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0x99000000), // Lighter background for countdown
      priority: 999,
    );
    add(backgroundOverlay);

    // Calculate perfect center position
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Create modern countdown text
    overlayText = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFD93D), // Bright yellow for countdown
          fontSize: 120.0, // Large and bold
          fontWeight: FontWeight.w900,
          letterSpacing: 4.0,
          shadows: [
            Shadow(blurRadius: 15, color: Colors.black.withOpacity(0.9)),
            Shadow(blurRadius: 8, color: Colors.black.withOpacity(0.7)),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(centerX, centerY), // Perfect center
      priority: 1000,
    );
    add(overlayText!);

    // Add a pulsing glow effect
    final glowText = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFD93D).withOpacity(0.4),
          fontSize: 140.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 4.0,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(centerX, centerY), // Same center position
      priority: 999,
    );
    add(glowText);

    print(
      'Showing countdown: "$text" at position: ${overlayText!.position}, screen size: $size',
    );
  }

  void _startGame() {
    gameState = GameState.playing;
    player.isGameActive = true;
    _hideOverlay();
    _forceCleanupOverlays(); // Force cleanup when starting game
  }

  void _forceCleanupOverlays() {
    // Force remove all overlay components regardless of priority
    final allOverlayComponents = children
        .where(
          (child) =>
              child is RectangleComponent ||
              (child is TextComponent && child != scoreText),
        )
        .toList();

    for (final component in allOverlayComponents) {
      if (component != background && component != scoreText) {
        remove(component);
      }
    }

    overlayText = null;
    print('Force cleaned up ${allOverlayComponents.length} components');
  }

  void _generatePlatform(Vector2 position) {
    final platform = Platform(position: position);
    add(platform);
    platforms.add(platform);
    lastPlatformY = position.y;
  }

  void _generateNextPlatform() {
    if (platforms.isEmpty) return;
    final lastPlatform = platforms.last;

    // Calculate the right edge (last possible jump point) of the previous platform
    final prevTopRight = Vector2(
      lastPlatform.position.x + lastPlatform.size.x,
      lastPlatform.position.y,
    );

    // Calculate max jump physics
    final double jumpForce = 460; // Should match Player.jumpForce
    final double gravity = 950; // Should match Player.gravity
    final double playerSpeed = currentSpeed; // Use current horizontal speed
    final double tUp = jumpForce / gravity;
    final double tTotal = 2 * tUp;
    final double maxDx = playerSpeed * tTotal;

    // Random horizontal gap within allowed range
    final dx =
        minPlatformGapX +
        rand.nextDouble() *
            (math.min(maxPlatformGapX, maxDx) - minPlatformGapX);
    final newX = prevTopRight.x + dx;

    // For this dx, calculate the max vertical difference the player can reach
    // The jump parabola: y = v0y * t - 0.5 * g * t^2
    // t = dx / playerSpeed
    final t = dx / playerSpeed;
    final maxDy = jumpForce * t - 0.5 * gravity * t * t;

    // Clamp newY so the vertical gap is always reachable
    double newY = lastPlatform.position.y - maxDy;
    // Optionally, clamp to screen bounds
    newY = newY.clamp(size.y * 0.3, size.y * 0.8);

    _generatePlatform(Vector2(newX, newY));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update score text
    scoreText.text = 'Platforms: $platformsPassed';

    if (gameState == GameState.countdown) {
      countdownTimer.update(dt);
      return;
    }

    if (gameState != GameState.playing || player.isRemoved) return;

    for (final platform in platforms) {
      platform.position.x -= currentSpeed * dt;
    }

    // Keep background at constant slow speed regardless of game progression
    background.parallax?.baseVelocity.setValues(6, 0);

    platforms
        .where(
          (p) => !p.hasBeenPassed && p.position.x + p.size.x < playerFixedX,
        )
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

    // Force cleanup any existing overlays first
    _forceCleanupOverlays();

    // Show game over text with a slight delay to ensure it appears
    Future.delayed(const Duration(milliseconds: 100), () {
      if (gameState == GameState.gameOver) {
        _showOverlay('GAME OVER\n\nTap to Restart');
      }
    });
  }

  Future<void> resetGame() async {
    // Re-initialize rand with the same session seed for consistent platform generation
    rand = math.Random(sessionSeed);

    // Ensure background and score text are present
    if (!children.contains(background)) {
      add(background);
    }
    if (!children.contains(scoreText)) {
      add(scoreText);
    }

    // Remove all children except background, score text, and overlay
    final childrenToRemove = children
        .where(
          (child) =>
              child != background &&
              child != scoreText &&
              child != overlayText &&
              child is! Background &&
              child is! TextComponent,
        )
        .toList();

    for (final child in childrenToRemove) {
      remove(child);
    }

    // Clear platforms list completely
    platforms.clear();
    debugPrint(
      'After selective removal: children = ${children.length}, platforms list = ${platforms.length}',
    );

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
      lastPlatformY =
          (last.position.y +
                  minPlatformGapY / 2 +
                  rand.nextDouble() * (maxPlatformGapY - minPlatformGapY / 2))
              .clamp(size.y * 0.3, size.y * 0.8);
    }

    // Wait a frame to ensure all platforms are properly loaded
    await Future.delayed(const Duration(milliseconds: 16));

    // Position player on the first platform
    if (platforms.isNotEmpty) {
      final firstPlatform = platforms.first;
      player.position = Vector2(playerFixedX, firstPlatform.position.y);
      player.isOnGround = true;
      player.velocity = Vector2.zero();
    }

    // Show the tap to start overlay
    _showOverlay('TAP TO START');
  }
}
