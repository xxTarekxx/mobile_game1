// lib/game/components/background.dart

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';

class Background extends ParallaxComponent {
  Background() : super(priority: -10);

  @override
  Future<void> onLoad() async {
    parallax = await Parallax.load(
      [
        ParallaxImageData('tiles/Mossy Tileset/Mossy - BackgroundDecoration.png'),
        ParallaxImageData('tiles/Mossy Tileset/Mossy - Decorations&Hazards.png'),
        ParallaxImageData('tiles/Mossy Tileset/Mossy - MossyHills.png'),
        ParallaxImageData('tiles/Mossy Tileset/Mossy - Hanging Plants.png'),
      ],
      baseVelocity: Vector2(20, 0),
      velocityMultiplierDelta: Vector2(1.2, 1.0),
      fill: LayerFill.height,
    );
  }
}
