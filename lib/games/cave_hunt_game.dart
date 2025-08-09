import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Minigame da Caverna: bolinhas caem do topo e você deve tocar nelas
/// antes que atinjam o chão. Cada bola coletada vale 1 ponto. A
/// recompensa final é calculada externamente como score * 5.
class CaveHuntGame extends FlameGame with TapDetector {
  CaveHuntGame({required this.onFinish});

  /// Callback disparado ao fim do jogo, informando as moedas ganhas
  /// (normalmente score * 5).
  final void Function(int coinsEarned) onFinish;

  /// Pontuação do jogador (número de moedas coletadas)
  int score = 0;

  /// Duração da partida (segundos)
  final double _matchDurationSeconds = 30;

  /// Temporizador da partida
  late Timer _matchTimer;

  /// Temporizador para spawn de moedas
  late Timer _spawnTimer;

  /// Random para posições/valores
  final Random _random = Random();

  /// Tamanho da moeda em pixels
  static const double _coinRadius = 22.0;

  /// Limite máximo simultâneo de moedas em tela
  static const int _maxCoinsOnScreen = 8;

  SpriteComponent? _background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Background da Caverna (com fallback caso o asset não seja encontrado)
    try {
      final sprite = await Sprite.load('assets/background_cav.png');
      _background = SpriteComponent(
        sprite: sprite,
        position: Vector2.zero(),
        size: size,
        priority: -100,
        anchor: Anchor.topLeft,
      );
      add(_background!);
    } catch (_) {
      final rect = RectangleComponent()
        ..position = Vector2.zero()
        ..size = size
        ..priority = -100;
      rect.paint = ui.Paint()..color = const Color(0xFF2C1810);
      add(rect);
    }

    // HUD básico: placar e tempo restante
    add(_ScoreText(this)
      ..position = Vector2(10, 10)
      ..priority = 10);
    add(_TimerText(this)
      ..position = Vector2(10, 34)
      ..priority = 10);

    // Timer principal da partida
    _matchTimer = Timer(_matchDurationSeconds, onTick: _endMatch);
    _matchTimer.start();

    // Timer de spawn de moedas
    _spawnTimer = Timer(0.8, repeat: true, onTick: _spawnCoin);
    _spawnTimer.start();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    final bg = _background;
    if (bg != null) {
      bg.size = newSize;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _matchTimer.update(dt);
    _spawnTimer.update(dt);
  }

  void _spawnCoin() {
    // Limite de itens simultâneos
    final currentCoins = children.whereType<_Coin>().length;
    if (currentCoins >= _maxCoinsOnScreen) return;

    // Janela disponível
    final bounds = size;
    const double margin = _coinRadius + 8;
    if (bounds.x <= margin * 2 || bounds.y <= margin * 2) return;

    // Spawna no topo, em X aleatório, ligeiramente abaixo do HUD
    final double x = _random.nextDouble() * (bounds.x - margin * 2) + margin;
    final double y = 60 + margin; // 60px reservados ao HUD

    // Velocidade vertical aleatória (px/s)
    final double speedY = 120 + _random.nextDouble() * 160; // 120-280 px/s

    add(_Coin(onCollected: _onCollect, speedY: speedY)
      ..position = Vector2(x, y)
      ..size = Vector2.all(_coinRadius * 2)
      ..anchor = Anchor.center);
  }

  void _onCollect(_Coin coin) {
    score += 1;
    coin.removeFromParent();
  }

  void _endMatch() {
    // Calcula recompensa (mesma regra exibida no overlay em main.dart)
    final int coinsEarned = score * 5;

    // Pausa e mostra overlay de fim (mapeado no GameWidget em main.dart)
    pauseEngine();
    overlays.add('end');

    // Informa o app para creditar moedas
    onFinish(coinsEarned);
  }

  // Tratamento de toque fica no próprio componente _Coin via TapCallbacks
}

class _Coin extends PositionComponent with TapCallbacks, HasGameRef<CaveHuntGame> {
  _Coin({required this.onCollected, required this.speedY});

  final void Function(_Coin) onCollected;
  final double speedY;

  static final ui.Paint _paint = ui.Paint()..color = const Color(0xFFd4af37);
  static final ui.Paint _edge = ui.Paint()
    ..color = const Color(0xFF8a6f2a)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2;

  bool containsPoint(Vector2 p) {
    final center = absoluteCenter;
    return center.distanceTo(p) <= CaveHuntGame._coinRadius;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final r = CaveHuntGame._coinRadius;
    canvas.drawCircle(ui.Offset(r, r), r, _paint);
    canvas.drawCircle(ui.Offset(r, r), r, _edge);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    onCollected(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Queda vertical
    position = Vector2(position.x, position.y + speedY * dt);

    // Verifica chão (com pequena margem)
    final double groundY = gameRef.size.y - CaveHuntGame._coinRadius - 8;
    if (position.y >= groundY) {
      removeFromParent(); // perdeu a chance de coletar
    }
  }
}

class _ScoreText extends TextComponent with HasGameRef<CaveHuntGame> {
  _ScoreText(this._game)
      : super(text: 'Moedas: 0',
            textRenderer: TextPaint(
              style: const TextStyle(
                color: Color(0xFFb29c48),
                fontFamily: 'Pixel',
                fontSize: 14,
              ),
            ));

  final CaveHuntGame _game;

  @override
  void update(double dt) {
    super.update(dt);
    text = 'Moedas: ${_game.score}';
  }
}

class _TimerText extends TextComponent with HasGameRef<CaveHuntGame> {
  _TimerText(this._game)
      : super(text: 'Tempo: 30',
            textRenderer: TextPaint(
              style: const TextStyle(
                color: Color(0xFFb29c48),
                fontFamily: 'Pixel',
                fontSize: 14,
              ),
            ));

  final CaveHuntGame _game;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final remaining = max(0, (_game._matchDurationSeconds - _elapsed)).ceil();
    text = 'Tempo: $remaining';
  }
}

