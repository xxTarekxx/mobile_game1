// lib/game/components/player.dart

import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../tower_up_game.dart';
import 'platform.dart';

enum PlayerState { idle, walk, jump }

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameReference<TowerUpGame>, CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  final double gravity = 950;
  final double jumpForce = 460;

  bool isOnGround = false;
  bool isGameActive = false;
  bool _isCollidingWithPlatform = false;

  Player()
    : super(size: Vector2(96, 128), anchor: Anchor.bottomCenter, priority: 1);

  @override
  Future<void> onLoad() async {
    final idleAnim = await _loadAnimation(
      'wizard/BlueWizard/2BlueWizardIdle/Chara - BlueIdle',
      20,
    );
    final walkAnim = await _loadAnimation(
      'wizard/BlueWizard/2BlueWizardWalk/Chara_BlueWalk',
      20,
    );
    final jumpAnim = await _loadAnimation(
      'wizard/BlueWizard/2BlueWizardJump/CharaWizardJump_',
      8,
    );

    animations = {
      PlayerState.idle: idleAnim,
      PlayerState.walk: walkAnim,
      PlayerState.jump: jumpAnim,
    };
    current = PlayerState.idle;

    add(
      RectangleHitbox(
        position: Vector2(size.x * 0.2, size.y * 0.85),
        size: Vector2(size.x * 0.6, size.y * 0.15),
      ),
    );

    return super.onLoad();
  }

  Future<SpriteAnimation> _loadAnimation(
    String baseName,
    int frameCount,
  ) async {
    final frames = <ui.Image>[];
    final useWebp =
        baseName.contains('BlueIdle') ||
        baseName.contains('CharaWizardJump') ||
        baseName.contains('DashBlue') ||
        baseName.contains('Dash3') ||
        baseName.contains('BlueWizardDash') ||
        baseName.contains('Chara_BlueWalk');
    for (int i = 0; i < frameCount; i++) {
      if (useWebp) {
        final webpPath = '$baseName${i.toString().padLeft(5, '0')}.webp';
        final pngPath = '$baseName${i.toString().padLeft(5, '0')}.png';
        try {
          frames.add(await Flame.images.load(webpPath));
        } catch (_) {
          frames.add(await Flame.images.load(pngPath));
        }
      } else {
        final pngPath = '$baseName${i.toString().padLeft(5, '0')}.png';
        frames.add(await Flame.images.load(pngPath));
      }
    }
    return SpriteAnimation.spriteList(
      [for (final img in frames) Sprite(img)],
      stepTime: 0.1,
      loop: true,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    isOnGround = _isCollidingWithPlatform;
    _isCollidingWithPlatform = false;

    // Lock player's x-position to stay visually in place
    position.x = game.playerFixedX;

    // Prevent falling at the start if visually on the platform
    if (!isGameActive || game.gameState != GameState.playing) {
      velocity = Vector2.zero();
      current = PlayerState.idle;
      return;
    }

    // If player is visually on the platform at the start, keep them grounded
    if (isOnGround && velocity.y > 0) {
      velocity.y = 0;
    }

    velocity.x = 0;

    // Apply gravity
    if (!isOnGround) {
      velocity.y += gravity * dt;
    }

    position.y += velocity.y * dt;

    // Animate
    current = isOnGround ? PlayerState.walk : PlayerState.jump;
  }

  void jump() {
    if (isOnGround && isGameActive && game.gameState == GameState.playing) {
      velocity.y = -jumpForce;
      isOnGround = false;
      _isCollidingWithPlatform = false;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Platform && velocity.y >= 0) {
      // Check if player is above the platform
      final playerBottom = position.y;
      final platformTop = other.position.y;

      if (playerBottom >= platformTop && playerBottom <= platformTop + 10) {
        velocity.y = 0;
        position.y = platformTop;
        _isCollidingWithPlatform = true;
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Platform && velocity.y >= 0) {
      _isCollidingWithPlatform = true;
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    if (other is Platform) {
      // Only set to false if we're not colliding with any other platforms
      _isCollidingWithPlatform = false;
    }
  }
}
