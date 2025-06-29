// lib/game/components/player.dart

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
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
      : super(
          size: Vector2(96, 128),
          anchor: Anchor.bottomCenter,
          priority: 1,
        );

  @override
  Future<void> onLoad() async {
    final idleAnim = await _createAnimation(
        'wizard/BlueWizard/2BlueWizardIdle/Chara - BlueIdle', 20);
    final walkAnim = await _createAnimation(
        'wizard/BlueWizard/2BlueWizardWalk/Chara_BlueWalk', 20);
    final jumpAnim = await _createAnimation(
        'wizard/BlueWizard/2BlueWizardJump/CharaWizardJump_', 8);

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

  Future<SpriteAnimation> _createAnimation(String baseName, int frameCount) async {
    final frames = await Flame.images.loadAll([
      for (int i = 0; i < frameCount; i++)
        '${baseName}${i.toString().padLeft(5, '0')}.png',
    ]);
    return SpriteAnimation.spriteList(
      [for (final img in frames) Sprite(img)],
      stepTime: 0.08,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    isOnGround = _isCollidingWithPlatform;
    _isCollidingWithPlatform = false;

    // Lock player's x-position to stay visually in place
    position.x = game.playerFixedX;

    if (!isGameActive || game.gameState != GameState.playing) {
      velocity = Vector2.zero();
      current = PlayerState.idle;
      return;
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
