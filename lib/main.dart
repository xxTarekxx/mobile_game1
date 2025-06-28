import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/tower_up_game.dart';
import 'game/components/score_overlay.dart';

void main() {
  runApp(const TowerUpApp());
}

class TowerUpApp extends StatelessWidget {
  const TowerUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tower Up',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<TowerUpGame>(
        game: TowerUpGame(),
        overlayBuilderMap: {
          'score': (context, game) => ScoreOverlay(game: game),
        },
        initialActiveOverlays: const ['score'],
      ),
    );
  }
}
