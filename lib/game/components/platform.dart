import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class Platform extends SpriteComponent with CollisionCallbacks {
  // Platform properties
  static const double platformWidth = 236;
  static const double platformHeight = 72;
  
  Platform() : super(size: Vector2(platformWidth, platformHeight)) {
    add(RectangleHitbox());
    debugMode = true;
    anchor = Anchor.topLeft;
  }
  
  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load(
      'tiles/Mossy Tileset/Mossy - FloatingPlatforms.png',
      srcPosition: Vector2(148, 152),
      srcSize: Vector2(platformWidth, platformHeight),
    );
    return super.onLoad();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    final game = findGame();
    if (game != null && position.x < game.camera.viewport.position.x - 200) {
      removeFromParent();
    }
  }
} 