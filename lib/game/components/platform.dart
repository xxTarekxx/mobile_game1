// lib/game/components/platform.dart

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class Platform extends SpriteComponent with CollisionCallbacks {
  bool hasBeenPassed = false;

  Platform({required Vector2 position})
      : super(
          position: position,
          size: Vector2(236, 72),
          anchor: Anchor.topLeft,
          priority: -1,
        );

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load(
      'tiles/Mossy Tileset/Mossy - FloatingPlatforms.png',
      srcPosition: Vector2(148, 152),
      srcSize: Vector2(size.x, size.y),
    );

    // Add collision hitbox
    final hitbox = RectangleHitbox()
      ..collisionType = CollisionType.passive
      ..size = size
      ..position = Vector2.zero();
    
    add(hitbox);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(
    PositionComponent other,
  ) {
    super.onCollisionEnd(other);
  }
}
