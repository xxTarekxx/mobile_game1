// lib/game/components/background.dart

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class Background extends ParallaxComponent {
  Background() : super(priority: -10);

  @override
  Future<void> onLoad() async {
    try {
      parallax = await Parallax.load(
        [
          // Background layers in order (back to front)
          ParallaxImageData(
            'tiles/Mossy Tileset/Mossy - BackgroundDecoration.png',
          ),
          ParallaxImageData('tiles/Mossy Tileset/Mossy - MossyHills.png'),
          ParallaxImageData(
            'tiles/Mossy Tileset/Mossy - Decorations&Hazards.png',
          ),
          ParallaxImageData('tiles/Mossy Tileset/Mossy - Hanging Plants.png'),
        ],
        baseVelocity: Vector2(8, 0), // Much slower for more atmospheric effect
        velocityMultiplierDelta: Vector2(
          1.3,
          1.0,
        ), // Slightly less dramatic parallax
        fill: LayerFill.height,
        filterQuality: FilterQuality.none, // Better performance
      );

      // Add a dark overlay for atmospheric effect
      final game = parent as FlameGame;
      final darkOverlay = RectangleComponent(
        size: game.size,
        paint: Paint()
          ..color = const Color(0x33000000), // Semi-transparent black
        priority: -5, // Above background but below other elements
      );
      game.add(darkOverlay);
    } catch (e) {
      print('Background loading failed: $e');
      // Create a dark jungle-like background as fallback
      final game = parent as FlameGame;
      final fallbackBackground = RectangleComponent(
        size: game.size,
        paint: Paint()..color = const Color(0xFF1B3D1B), // Dark jungle green
        priority: -10,
      );
      game.add(fallbackBackground);
    }
  }
}
