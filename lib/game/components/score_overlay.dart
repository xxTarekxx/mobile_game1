// lib/game/components/score_overlay.dart
import 'package:flutter/material.dart';
import '../tower_up_game.dart';

class ScoreOverlay extends StatelessWidget {
  final TowerUpGame game;

  const ScoreOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Platforms: ${game.platformsPassed}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
