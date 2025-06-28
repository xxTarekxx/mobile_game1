import 'package:flame/components.dart';
import 'package:flame/parallax.dart';

class Background extends ParallaxComponent {
  Background() : super(priority: -1);

  @override
  Future<void> onLoad() async {
    parallax = await Parallax.load([
      ParallaxImageData('tiles/Mossy Tileset/Mossy - BackgroundDecoration.png'),
      ParallaxImageData('tiles/Mossy Tileset/Mossy - MossyHills.png'),
    ],
      baseVelocity: Vector2(20, 0),
      velocityMultiplierDelta: Vector2(1.5, 1.0),
    );
    return super.onLoad();
  }
} 