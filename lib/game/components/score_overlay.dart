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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Distance: ${game.score.toStringAsFixed(0)}m',
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