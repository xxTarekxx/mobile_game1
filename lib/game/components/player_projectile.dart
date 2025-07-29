import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../tower_up_game.dart';
import 'slime_orange.dart';

class PlayerProjectile extends SpriteComponent
    with HasGameReference<TowerUpGame>, CollisionCallbacks {
  static const double speed = 600;
  PlayerProjectile({required Vector2 position})
    : super(
        size: Vector2(32, 32),
        position: position,
        anchor: Anchor.center,
        priority: 3,
      );

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load(
      'wizard/BlueWizard/2BlueWizardIdle/Chara - BlueIdle00000.webp',
    ); // Placeholder, use a better asset if available
    add(RectangleHitbox()..collisionType = CollisionType.active);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += speed * dt;
    if (position.x > game.size.x + size.x) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is SlimeOrange) {
      other.removeFromParent();
      removeFromParent();
    }
  }
}
