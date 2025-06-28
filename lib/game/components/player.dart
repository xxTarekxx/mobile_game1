import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/flame.dart';
import 'platform.dart';

class Player extends SpriteAnimationComponent with CollisionCallbacks {
  // Physics
  Vector2 velocity = Vector2.zero();
  final double gravity = 800;
  final double jumpForce = -400;
  final double maxFallSpeed = 600;
  final double moveSpeed = 200; // pixels per second

  // State
  bool isOnGround = false;
  bool canJump = true;

  // Size (doubled for visibility)
  static const double playerWidth = 96;
  static const double playerHeight = 128;

  bool isGameActive = false;
  Platform? currentPlatform;
  double? lastPlatformX;

  Player() : super(size: Vector2(playerWidth, playerHeight)) {
    debugMode = true;
    anchor = Anchor.topLeft;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load idle animation
    final idleFrames = await Flame.images.loadAll([
      for (int i = 0; i < 20; i++)
        'wizard/BlueWizard/2BlueWizardIdle/Chara - BlueIdle${i.toString().padLeft(5, '0')}.png',
    ]);

    animation = SpriteAnimation.spriteList(
      [for (final img in idleFrames) Sprite(img)],
      stepTime: 0.08,
    );

    // Set size and anchor for correct alignment
    size = Vector2(playerWidth, playerHeight);
    anchor = Anchor.bottomLeft;

    // Add a hitbox at the feet
    add(RectangleHitbox(
      position: Vector2(16, playerHeight - 18),
      size: Vector2(playerWidth - 32, 18),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGameActive) {
      // Apply gravity
      velocity.y += gravity * dt;
      velocity.y = velocity.y.clamp(-double.infinity, maxFallSpeed);

      // Apply vertical movement
      position.y += velocity.y * dt;

      // Move with platform if standing on one
      if (isOnGround && currentPlatform != null) {
        if (lastPlatformX != null) {
          double dx = currentPlatform!.position.x - lastPlatformX!;
          position.x += dx;
        }
        lastPlatformX = currentPlatform!.position.x;
      } else {
        currentPlatform = null;
        lastPlatformX = null;
      }
    }

    isOnGround = false;
  }

  void jump() {
    if (canJump && isOnGround) {
      velocity.y = jumpForce;
      isOnGround = false;
      canJump = false;

      Future.delayed(const Duration(milliseconds: 100), () {
        canJump = true;
      });
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    // print('Collision with: $other');

    if (other is Platform && velocity.y > 0) {
      final double platformTop = other.position.y;
      final double platformLeft = other.position.x;
      final double platformRight = other.position.x + other.size.x;
      final double feetLeft = position.x + 8;
      final double feetRight = position.x + size.x - 8;

      final bool horizontallyOverlaps =
          feetRight > platformLeft && feetLeft < platformRight;

      if (horizontallyOverlaps && position.y + size.y <= platformTop + 40) {
        // Snap player to platform
        position.y = platformTop - size.y;
        velocity.y = 0;
        isOnGround = true;
        currentPlatform = other;
        lastPlatformX = other.position.x;
        // print('Player landed on platform!');
      }
    }
  }
}
