// lib/game/components/background.dart

import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class Background extends ParallaxComponent {
  Background() : super(priority: -10);

  @override
  Future<void> onLoad() async {
    try {
      // Use a single webp background if it exists
      final webpBackground = File('assets/images/background.webp');
      if (await webpBackground.exists()) {
        parallax = await Parallax.load(
          [ParallaxImageData('background.webp')],
          baseVelocity: Vector2(8, 0),
          velocityMultiplierDelta: Vector2(1.3, 1.0),
          fill: LayerFill.height,
          filterQuality: FilterQuality.none,
        );
      } else {
        parallax = await Parallax.load(
          [
            ParallaxImageData(
              'tiles/Mossy Tileset/Mossy - BackgroundDecoration.png',
            ),
            ParallaxImageData('tiles/Mossy Tileset/Mossy - MossyHills.png'),
            ParallaxImageData(
              'tiles/Mossy Tileset/Mossy - Decorations&Hazards.png',
            ),
            ParallaxImageData('tiles/Mossy Tileset/Mossy - Hanging Plants.png'),
          ],
          baseVelocity: Vector2(8, 0),
          velocityMultiplierDelta: Vector2(1.3, 1.0),
          fill: LayerFill.height,
          filterQuality: FilterQuality.none,
        );
      }

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
