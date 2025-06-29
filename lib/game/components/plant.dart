// lib/game/components/plant.dart
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

class Plant extends SpriteAnimationComponent {
  final String plantType;
  final int frameCount;

  Plant({
    required this.plantType,
    required this.frameCount,
    required Vector2 position,
  }) : super(
         position: position,
         size: Vector2.all(64),
         anchor: Anchor.bottomCenter,
       );

  @override
  Future<void> onLoad() async {
    final frames = await Flame.images.loadAll([
      for (int i = 0; i < frameCount; i++)
        'plants/Plant Animations/$plantType/${plantType}_${i.toString().padLeft(5, '0')}.png',
    ]);

    animation = SpriteAnimation.spriteList(
      [for (final img in frames) Sprite(img)],
      stepTime: 0.1,
      loop: true,
    );
  }
}
