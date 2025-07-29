import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../tower_up_game.dart';

class SlimeOrange extends SpriteAnimationComponent
    with HasGameReference<TowerUpGame>, CollisionCallbacks {
  SlimeOrange({required Vector2 position})
    : super(
        size: Vector2(80, 60),
        position: position,
        anchor: Anchor.bottomCenter,
        priority: 10,
      );

  @override
  Future<void> onLoad() async {
    debugPrint('SlimeOrange onLoad called at position $position');
    add(
      RectangleComponent(
        size: Vector2(100, 100),
        paint: Paint()..color = const Color(0xFFFF0000),
      ),
    );
    final frames = <Sprite>[];
    for (int i = 0; i < 29; i++) {
      final assetPath =
          'slimes/SlimeOrange/SlimeOrange_${i.toString().padLeft(5, '0')}.png';
      debugPrint('Attempting to load asset: $assetPath');
      try {
        final img = await Flame.images.load(assetPath);
        frames.add(Sprite(img));
      } catch (e) {
        debugPrint('Warning: Could not load SlimeOrange frame $i: $e');
      }
    }
    if (frames.isEmpty) {
      debugPrint('No SlimeOrange frames could be loaded!');
      return;
    }
    animation = SpriteAnimation.spriteList(frames, stepTime: 0.08, loop: true);
    add(RectangleHitbox()..collisionType = CollisionType.active);
    return super.onLoad();
  }
}
