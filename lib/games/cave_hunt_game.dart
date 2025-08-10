import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Minigame da Caverna: bolinhas caem do topo e você deve tocar nelas
/// antes que atinjam o chão. Cada bola coletada vale 1 ponto. A
/// recompensa final é calculada externamente como score * 30.
class CaveHuntGame extends FlameGame with TapDetector {
  CaveHuntGame({required this.onFinish, this.onCoinCollected});

  /// Callback disparado ao fim do jogo, informando as moedas ganhas
  /// (normalmente score * 30).
  final void Function(int coinsEarned) onFinish;
  /// Callback por moeda coletada (para aumentar entretenimento no app)
  final VoidCallback? onCoinCollected;

  /// Pontuação do jogador (número de moedas coletadas)
  int score = 0;

  /// Sistema de vidas: a partida termina ao perder 3 moedas
  int livesLeft = 3;
  final int maxLives = 3;

  /// Temporizador para spawn de moedas
  late Timer _spawnTimer;

  /// Random para posições/valores
  final Random _random = Random();

  /// Tamanho da moeda em pixels
  static const double _coinRadius = 26.0;

  /// Limite máximo simultâneo de moedas em tela
  static const int _maxCoinsOnScreen = 8;

  SpriteComponent? _background;
  bool _isFinished = false;

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

    // Vinheta suave nas bordas para estética Blasphemous
    add(_VignetteOverlay()
      ..priority = -10);

    // HUD agrupado: moldura dinâmica envolvendo placar + vidas
    add(_HudGroup(this)
      ..position = Vector2(8, 40)
      ..priority = 9);

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
    _spawnTimer.update(dt);
  }

  void _spawnCoin() {
    if (_isFinished) return;
    // Limite de itens simultâneos
    final currentCoins = children.whereType<_Coin>().length;
    if (currentCoins >= _maxCoinsOnScreen) return;

    // Janela disponível
    final bounds = size;
    const double margin = _coinRadius + 8;
    if (bounds.x <= margin * 2 || bounds.y <= margin * 2) return;

    final double x = _random.nextDouble() * (bounds.x - margin * 2) + margin;
    final double y = 140 + margin;

    // Velocidade vertical aleatória (px/s)
    final double speedY = 120 + _random.nextDouble() * 160; // 120-280 px/s

    add(_Coin(onCollected: _onCollect, speedY: speedY, initialX: x)
      ..position = Vector2(x, y)
      ..size = Vector2.all(_coinRadius * 2)
      ..anchor = Anchor.center);
  }

  void _onCollect(_Coin coin) {
    if (_isFinished) return;
    score += 1;
    coin.removeFromParent();
    onCoinCollected?.call();
  }

  void _onMissed() {
    livesLeft -= 1;
    if (livesLeft <= 0) {
      _endMatch();
    }
  }

  void _endMatch() {
    if (_isFinished) return;
    _isFinished = true;
    // Calcula recompensa (mesma regra exibida no overlay em main.dart)
    final int coinsEarned = score * 30;

    // Pausa e mostra overlay de fim (mapeado no GameWidget em main.dart)
    pauseEngine();
    overlays.add('end');

    // Informa o app para creditar moedas
    onFinish(coinsEarned);
  }

  // Tratamento de toque fica no próprio componente _Coin via TapCallbacks
}

class _Coin extends PositionComponent with TapCallbacks, HasGameRef<CaveHuntGame> {
  _Coin({required this.onCollected, required this.speedY, required this.initialX});

  final void Function(_Coin) onCollected;
  final double speedY;
  final double initialX;
  double _age = 0;

  static final ui.Paint _edge = ui.Paint()
    ..color = const Color(0xFF8a6f2a)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2;
  static final ui.Paint _shadow = ui.Paint()
    ..color = Colors.black.withOpacity(0.5)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
  static final ui.Paint _glow = ui.Paint()
    ..color = const Color(0x80d4af37)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);

  bool containsPoint(Vector2 p) {
    final center = absoluteCenter;
    return center.distanceTo(p) <= CaveHuntGame._coinRadius;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final r = CaveHuntGame._coinRadius;
    final center = ui.Offset(r, r);

    // Glow suave ao redor
    canvas.drawCircle(center, r * 1.25, _glow);
    // Sombra projetada
    canvas.drawCircle(center.translate(2, 4), r, _shadow);

    // Preenchimento com um leve gradiente radial
    final gradient = ui.Gradient.radial(
      center,
      r,
      [const Color(0xFFffe08a), const Color(0xFFd4af37), const Color(0xFFb58f2c)],
      [0.0, 0.6, 1.0],
    );
    final fill = ui.Paint()..shader = gradient;
    canvas.drawCircle(center, r, fill);
    // Borda
    canvas.drawCircle(center, r, _edge);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // Efeito de partículas douradas ao coletar
    final worldPos = absoluteCenter;
    final particle = Particle.generate(
      count: 14,
      lifespan: 0.35,
      generator: (i) {
        final rnd = Random();
        final speed = 80 + rnd.nextDouble() * 120;
        final angle = rnd.nextDouble() * 2 * pi;
        return AcceleratedParticle(
          position: worldPos.clone(),
          speed: Vector2(cos(angle), sin(angle)) * speed,
          child: CircleParticle(
            radius: 2 + rnd.nextDouble() * 2,
            paint: ui.Paint()..color = const Color(0xFFffe08a),
          ),
        );
      },
    );
    gameRef.add(ParticleSystemComponent(particle: particle)..priority = 20);

    onCollected(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    // Queda vertical com leve oscilação horizontal para dar vida
    final sway = sin(_age * 2.2) * 10; // ±10 px
    position = Vector2(initialX + sway, position.y + speedY * dt);

    // Verifica chão
    final double groundY = gameRef.size.y - CaveHuntGame._coinRadius - 8;
    if (position.y >= groundY) {
      gameRef._onMissed();
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
                fontSize: 20,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                ],
              ),
            ));

  final CaveHuntGame _game;

  @override
  void update(double dt) {
    super.update(dt);
    text = 'Moedas: ${_game.score}';
  }
}

class _HudFrame extends PositionComponent with HasGameRef<CaveHuntGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(260, 72);
    anchor = Anchor.topLeft;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    // Painel escuro translúcido
    final bg = ui.Paint()..color = const Color(0xAA000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      bg,
    );
    // Borda dourada
    final border = ui.Paint()
      ..color = const Color(0xFFb29c48)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      border,
    );
  }
}

class _HudGroup extends PositionComponent with HasGameRef<CaveHuntGame> {
  _HudGroup(this._game);

  final CaveHuntGame _game;

  late final _ScoreText _scoreText;
  late final _LivesHud _livesHud;
  late final _HudFrame _frame;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _scoreText = _ScoreText(_game)
      ..position = Vector2(12, 8)
      ..priority = 10;
    _livesHud = _LivesHud(_game)
      ..position = Vector2(12, 32)
      ..priority = 10;

    add(_scoreText);
    add(_livesHud);

    // Calcula largura baseada em expectativas (score até 3 dígitos + label) e largura fixa para vidas
    const double estimatedScoreWidth = 160; // margem segura
    const double livesWidth = 200;
    final double contentWidth = (estimatedScoreWidth > livesWidth ? estimatedScoreWidth : livesWidth) + 16;

    _frame = _HudFrame()
      ..size = Vector2(contentWidth, 64)
      ..priority = 9;
    add(_frame);
  }
}

class _VignetteOverlay extends Component with HasGameRef<CaveHuntGame> {
  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final size = gameRef.size;
    if (size.x <= 0 || size.y <= 0) return;
    final center = ui.Offset(size.x / 2, size.y / 2);
    final radius = size.length / 2;
    final shader = ui.Gradient.radial(
      center,
      radius,
      [const Color(0x00000000), const Color(0xDD000000)],
      [0.6, 1.0],
    );
    final paint = ui.Paint()..shader = shader;
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}

class _LivesHud extends PositionComponent with HasGameRef<CaveHuntGame> {
  _LivesHud(this._game);

  final CaveHuntGame _game;

  static const double iconSize = 18;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(200, iconSize + 4);
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    const int total = 3;
    final int left = _game.livesLeft.clamp(0, total);
    for (int i = 0; i < total; i++) {
      final dx = i * (iconSize + 10);
      final center = ui.Offset(dx + iconSize / 2, iconSize / 2);
      final bool isAlive = i < left;

      final ui.Path path = ui.Path();
      final double w = iconSize;
      final double h = iconSize;
      path.moveTo(center.dx, center.dy - h * 0.5);
      path.lineTo(center.dx + w * 0.5, center.dy - h * 0.15);
      path.lineTo(center.dx, center.dy + h * 0.55);
      path.lineTo(center.dx - w * 0.5, center.dy - h * 0.15);
      path.close();

      final ui.Paint fill = ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(center.dx, center.dy - h * 0.5),
          ui.Offset(center.dx, center.dy + h * 0.55),
          isAlive
              ? const [Color(0xFFffe08a), Color(0xFFd4af37)]
              : const [Color(0xFF5a4b1f), Color(0xFF3b3116)],
        );
      final ui.Paint border = ui.Paint()
        ..color = const Color(0xFF8a6f2a)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;

      // Sombra leve para destacar
      final ui.Paint shadow = ui.Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
      canvas.save();
      canvas.translate(2, 2);
      canvas.drawPath(path, shadow);
      canvas.restore();

      canvas.drawPath(path, fill);
      canvas.drawPath(path, border);
    }
  }
}

