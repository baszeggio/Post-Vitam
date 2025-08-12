import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:pou_application_1/faith_shop_page.dart';
import 'package:pou_application_1/fervor_shop_page.dart';
import 'dart:async';
import 'dao/postvitamdao.dart';
import 'potions_shop_page.dart';
import 'skins_shop_page.dart';
import 'package:flame/game.dart';
import 'games/cave_hunt_game.dart';
import 'inventory_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  runApp(const MyApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: const AppScrollBehavior(),
      title: 'Post Vitam',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final bool isDesktop = !kIsWeb && (
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS
        );
        final double targetScale = isDesktop ? mq.textScaleFactor : (mq.textScaleFactor * 1.5);
        return MediaQuery(
          data: mq.copyWith(textScaleFactor: targetScale.clamp(1.0, 1.5)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Pixel',
      ),
      home: const MyHomePage(title: 'Post Vitam Pet'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int hunger = 50;
  int happiness = 50;
  int energy = 50;
  int vitality = 50;
  int coins = 20000;

  List<Map<String, dynamic>> inventoryPotions = [];
  List<Map<String, dynamic>> inventorySkins = [
    {
      'img': 'assets/Penitente_1.png',
      'img2': 'assets/Penitente_2.png',
      'name': 'Skin Padrão',
      'desc': 'O visual padrão do Penitente.',
      'quantity': 1,
      'type': 'skin',
      'equipped': true,
    },
  ];
  late final PageController _pageController;
  int _selectedIndex = 0;
  late int _rawPageIndex;
  static const int _infiniteLoopBaseMultiplier = 1000;

  late AnimationController _penitenteController;
  late Animation<int> _penitenteAnimation;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = true;

  static const Duration _notificationCooldown = Duration(minutes: 30);
  final Map<String, DateTime> _lastNotificationTimes = {};
  bool _isInForeground = true;

  Timer? _degradationTimer;

  bool _canSendNotification(String key) {
    final last = _lastNotificationTimes[key];
    if (last == null) return true;
    return DateTime.now().difference(last) >= _notificationCooldown;
  }

  void _markNotificationSent(String key) {
    _lastNotificationTimes[key] = DateTime.now();
  }

  void _checkAndSendNotifications() {

    if (_isInForeground) return;

    if (hunger <= 20 && _canSendNotification('low_hunger')) {
      NotificationService.showGameNotification(
        title: 'Sua Fé está baixa!',
        body: 'Seu Penitente precisa orar na Ecclesia para restaurar sua Fé.',
      );
      _markNotificationSent('low_hunger');
    }

    if (energy <= 20 && _canSendNotification('low_energy')) {
      NotificationService.showGameNotification(
        title: 'Seu Fervor está baixo!',
        body: 'Seu Penitente precisa descansar nos Montes para recuperar o Fervor.',
      );
      _markNotificationSent('low_energy');
    }

    if (vitality <= 15 && _canSendNotification('critical_vitality')) {
      NotificationService.showGameNotification(
        title: 'Vitalidade Crítica!',
        body: 'Use um frasco ou medite em Albero para restaurar a Vitalidade do seu Penitente.',
      );
      _markNotificationSent('critical_vitality');
    }

    if (hunger <= 30 && happiness <= 30 && energy <= 30 && _canSendNotification('multi_low')) {
      NotificationService.showGameNotification(
        title: 'Seu Penitente precisa de atenção!',
        body: 'Múltiplos status estão baixos. Cuide do seu Penitente!',
      );
      _markNotificationSent('multi_low');
    }
  }

  void _scheduleDailyReminders() {
    print('Sistema de lembretes inicializado (modo simplificado)');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _penitenteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _penitenteAnimation = IntTween(
      begin: 1,
      end: 2,
    ).animate(_penitenteController);

    _rawPageIndex = _pages.length * _infiniteLoopBaseMultiplier;
    _selectedIndex = 0;
    _pageController = PageController(initialPage: _rawPageIndex);

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('=== INICIANDO APLICATIVO ===');
    try {

      await _applyDegradationOnline();
      await _loadInventory();
      _startDegradationTimer();

      _scheduleDailyReminders();

      await Future.delayed(Duration(seconds: 2));
      await _savePetStatus();
      await _saveInventory();
      print('=== APLICATIVO INICIALIZADO ===');
    } catch (e, s) {
      print('Erro ao inicializar app: $e');
      print(s);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyDegradationOnline() async {
    try {
      final status = await _dbHelper.calculateDegradationOnline();
      setState(() {
        hunger = status.hunger;
        happiness = status.happiness;
        energy = status.energy;
        vitality = status.vitality;
        coins = status.coins;
      });
    } catch (e) {
      print('Erro ao aplicar degradação online: $e');
    }
  }

  void _startDegradationTimer() {
    _degradationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _applyDegradationOnline();

      _checkAndSendNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _penitenteController.dispose();
    _pageController.dispose();
    _degradationTimer?.cancel();
    super.dispose();
  }

  Future<void> _applyStatusDegradation() async {
    try {
      final status = await _dbHelper.applyDegradationAndGetStatus();
      setState(() {
        hunger = status.hunger;
        happiness = status.happiness;
        energy = status.energy;
        vitality = status.vitality;
      });
    } catch (e) {
      print('Erro ao aplicar degradação de status: $e');
    }
  }

  String _formatMoney(int amount) {
    if (amount >= 1000) {
      double kValue = amount / 1000.0;
      if (kValue == kValue.toInt()) {
        return '${kValue.toInt()}K';
      } else {
        return '${kValue.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}K';
      }
    }
    return amount.toString();
  }

  bool buyPotion(Map<String, dynamic> potion) {
    final price = potion['price'] as int;
    if (coins >= price) {
      setState(() {
        coins -= price;

        final existingIndex = inventoryPotions.indexWhere(
          (item) => item['name'] == potion['name'],
        );

        if (existingIndex != -1) {
          inventoryPotions[existingIndex]['quantity'] += 1;
        } else {
          inventoryPotions.add({
            'img': potion['img'],
            'name': potion['name'],
            'desc': potion['desc'],
            'quantity': 1,
            'type': 'potion',
          });
        }
      });

      _savePetStatus();
      _saveInventory();
      return true;
    }
    return false;
  }

  bool buyFaithPotion(Map<String, dynamic> potion) {
    final price = potion['price'] as int;
    if (coins >= price) {
      setState(() {
        coins -= price;
        final existingIndex = inventoryPotions.indexWhere(
          (item) => item['name'] == potion['name'],
        );
        if (existingIndex != -1) {
          inventoryPotions[existingIndex]['quantity'] += 1;
        } else {
          inventoryPotions.add({
            'img': potion['img'],
            'name': potion['name'],
            'desc': potion['desc'],
            'quantity': 1,
            'type': 'faith',
          });
        }
      });
      _savePetStatus();
      _saveInventory();
      return true;
    }
    return false;
  }

  bool buyFervorPotion(Map<String, dynamic> potion) {
    final price = potion['price'] as int;
    if (coins >= price) {
      setState(() {
        coins -= price;
        final existingIndex = inventoryPotions.indexWhere(
          (item) => item['name'] == potion['name'],
        );
        if (existingIndex != -1) {
          inventoryPotions[existingIndex]['quantity'] += 1;
        } else {
          inventoryPotions.add({
            'img': potion['img'],
            'name': potion['name'],
            'desc': potion['desc'],
            'quantity': 1,
            'type': 'fervor',
          });
        }
      });
      _savePetStatus();
      _saveInventory();
      return true;
    }
    return false;
  }

  Future<bool> buySkin(Map<String, dynamic> skin) async {
    final price = skin['price'] as int;
    if (coins >= price) {
      setState(() {
        coins -= price;
        final existingIndex = inventorySkins.indexWhere(
          (item) => item['name'] == skin['name'],
        );
        if (existingIndex == -1) {
          final baseName = skin['img'].toString().replaceAll('_1.png', '');
          inventorySkins.add({
            'img': '${baseName}_1.png',
            'img2': '${baseName}_2.png',
            'name': skin['name'],
            'desc': skin['desc'],
            'quantity': 1,
            'type': 'skin',
            'equipped': false,
          });
        }
      });
      await _savePetStatus();
      await _saveInventory();
      return true;
    }
    return false;
  }

  void equipSkin(int index) {
    if (index < inventorySkins.length) {
      setState(() {
        for (var skin in inventorySkins) {
          skin['equipped'] = false;
        }

        inventorySkins[index]['equipped'] = true;
      });

      _saveInventory();
    }
  }

  void usePotion(int index) {
    if (index < inventoryPotions.length &&
        inventoryPotions[index]['quantity'] > 0) {
      final potion = inventoryPotions[index];
      final potionName = potion['name'] as String;
      final potionType = (potion['type'] as String?) ?? 'potion';
      final potionDesc = (potion['desc'] as String?) ?? '';

      setState(() {
        int extractAmountFromDesc() {
          final match = RegExp(r"(\d+)").firstMatch(potionDesc);
          if (match != null) {
            return int.tryParse(match.group(1)!) ?? 0;
          }
          if (potionName.contains('Pequeno')) return 15;
          if (potionName.contains('Médio')) return 25;
          if (potionName.contains('Grande')) return 40;
          if (potionName.contains('100')) return 100;
          return 0;
        }

        if (potionType == 'faith') {
          final amount = extractAmountFromDesc();
          hunger = (hunger + amount).clamp(0, 100);
        } else if (potionType == 'fervor') {
          final amount = extractAmountFromDesc();
          energy = (energy + amount).clamp(0, 100);
        } else {
          // Vitalidade (frascos)
          if (potionName.contains('Milagre')) {
            vitality = (vitality + 100).clamp(0, 100);
          } else if (potionName.contains('Pequeno')) {
            vitality = (vitality + 15).clamp(0, 100);
          } else if (potionName.contains('Médio')) {
            vitality = (vitality + 25).clamp(0, 100);
          } else if (potionName.contains('Grande')) {
            vitality = (vitality + 40).clamp(0, 100);
          } else {
            final amount = extractAmountFromDesc();
            if (amount > 0) {
              vitality = (vitality + amount).clamp(0, 100);
            }
          }
        }

        inventoryPotions[index]['quantity'] -= 1;

        if (inventoryPotions[index]['quantity'] <= 0) {
          inventoryPotions.removeAt(index);
        }
      });

      _savePetStatus();
      _saveInventory();
    }
  }

  void updateInventory() {
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _isInForeground = false;
      await _savePetStatus();
      await _saveInventory();
    } else if (state == AppLifecycleState.resumed) {
      _isInForeground = true;
      _applyStatusDegradation();
    }
  }

  Future<void> _savePetStatus() async {
    try {
      print('=== INICIANDO SALVAMENTO DE STATUS ===');
      print(
        'Salvando status - Hunger: $hunger, Happiness: $happiness, Energy: $energy, Vitality: $vitality, Coins: $coins',
      );

      await _dbHelper.savePetStatus(
        hunger: hunger,
        happiness: happiness,
        energy: energy,
        vitality: vitality,
        coins: coins,
      );

      print('Status salvo com sucesso!');
      print('=== SALVAMENTO CONCLUÍDO ===');
    } catch (e) {
      print('Erro ao salvar status do pet: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadInventory() async {
    try {
      print('=== CARREGANDO INVENTÁRIO ===');
      final inventory = await _dbHelper.getInventory();
      setState(() {
        inventoryPotions.clear();
        inventorySkins.clear();
        for (var item in inventory) {
          if (item['type'] == 'potion') {
            inventoryPotions.add(item);
          } else if (item['type'] == 'skin') {
            inventorySkins.add(item);
          }
        }

        if (inventorySkins.isEmpty ||
            inventorySkins.every((skin) => skin['name'] != 'Skin Padrão')) {
          inventorySkins.insert(0, {
            'img': 'assets/Penitente_1.png',
            'img2': 'assets/Penitente_2.png',
            'name': 'Skin Padrão',
            'desc': 'O visual padrão do Penitente.',
            'quantity': 1,
            'type': 'skin',
            'equipped': true,
          });
        }

        bool anyEquipped = false;
        for (var skin in inventorySkins) {
          if (skin['equipped'] == true && !anyEquipped) {
            anyEquipped = true;
          } else {
            skin['equipped'] = false;
          }
        }
        if (!anyEquipped) {
          inventorySkins[0]['equipped'] = true;
        }
      });
      print(
        'Inventário carregado - Poções:  [33m${inventoryPotions.length} [0m, Skins:  [33m${inventorySkins.length} [0m',
      );
    } catch (e) {
      print('Erro ao carregar inventário: $e');
    }
  }

  Future<void> _saveInventory() async {
    try {
      print('=== SALVANDO INVENTÁRIO ===');
      await _dbHelper.saveInventory(inventoryPotions, inventorySkins);
      print('Inventário salvo com sucesso!');
    } catch (e) {
      print('Erro ao salvar inventário: $e');
    }
  }

  void feed() {
    setState(() {
      hunger = (hunger + 10).clamp(0, 100);
      vitality = (vitality + 2).clamp(0, 100);
    });
    _savePetStatus();
  }

  void play() {
    setState(() {
      happiness = (happiness + 10).clamp(0, 100);
      energy = (energy - 5).clamp(0, 100);
      vitality = (vitality + 3).clamp(0, 100);
    });
    _savePetStatus();
  }

  void sleep() {
    setState(() {
      energy = (energy + 15).clamp(0, 100);
      hunger = (hunger - 5).clamp(0, 100);
      happiness = (happiness - 10).clamp(0, 100);
      vitality = (vitality + 5).clamp(0, 100);
    });
    _savePetStatus();
  }

  void increaseVitality() {
    setState(() {
      vitality = (vitality + 10).clamp(0, 100);
    });
    _savePetStatus();
  }

  Widget _buildBlasphemousButton({
    required String text,
    required VoidCallback onPressed,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFb29c48), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Color(0xFFb29c48),
                fontFamily: 'Pixel',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationArrow({
    required IconData icon,
    required double size,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Color(0xFFb29c48), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size),
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            child: Icon(icon, color: Color(0xFFb29c48), size: size * 0.6),
          ),
        ),
      ),
    );
  }

  Widget needIndicator({
    required String iconPath,
    required int value,
    Color color = const Color(0xFFb29c48),
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        final isVerySmallScreen = screenWidth < 400;

        final iconSize = isVerySmallScreen
            ? 36.0
            : (isSmallScreen ? 44.0 : 56.0);
        final barWidth = isVerySmallScreen
            ? 40.0
            : (isSmallScreen ? 50.0 : 60.0);
        final barHeight = isVerySmallScreen
            ? 6.0
            : (isSmallScreen ? 8.0 : 10.0);
        final fontSize = isVerySmallScreen
            ? 8.0
            : (isSmallScreen ? 10.0 : 12.0);
        final padding = isVerySmallScreen ? 4.0 : (isSmallScreen ? 6.0 : 8.0);

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(0xFFb29c48).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(iconPath, width: iconSize, height: iconSize),
              SizedBox(height: isVerySmallScreen ? 4 : 6),
              Container(
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: value > 100 ? 1.0 : value / 100,
                    backgroundColor: Color(0xFF2C1810),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              SizedBox(height: isVerySmallScreen ? 2 : 4),

              Text(
                value > 100 ? '$value' : '$value/100',
                style: TextStyle(
                  color: Color(0xFFb29c48),
                  fontSize: fontSize,
                  fontFamily: 'Pixel',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsivePage({
    required String backgroundAsset,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isPortrait = screenHeight > screenWidth;

        final isVerySmallScreen = screenWidth < 400;

        final baseCharacterWidth = isPortrait
            ? screenWidth * 0.4
            : screenHeight * 0.3;
        final characterWidth = baseCharacterWidth * 1.6;
        final characterHeight = characterWidth * 1.8;

        final buttonWidth = screenWidth < 600 ? 120.0 : 160.0;
        final buttonHeight = screenWidth < 600 ? 45.0 : 55.0;
        final arrowSize = screenWidth < 600 ? 50.0 : 60.0;

        return Container(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  backgroundAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              Positioned(
                top: screenHeight * 0.11,
                left: 12,
                child: Row(
                  children: [
                    needIndicator(iconPath: 'assets/Icon_fé.png', value: hunger),
                    SizedBox(width: 8),
                    needIndicator(iconPath: 'assets/Icon_entretenimento.png', value: happiness),
                    SizedBox(width: 8),
                    needIndicator(iconPath: 'assets/Icon_fervor.png', value: energy),
                    SizedBox(width: 8),
                    needIndicator(iconPath: 'assets/Icon_vitalidade.png', value: vitality),
                  ],
                ),
              ),

              Positioned(
                top: screenHeight * 0.23,
                left: 0,
                right: 0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final navScreenWidth = constraints.maxWidth;
                    final isSmallScreen = navScreenWidth < 600;
                    final isVerySmallScreen = navScreenWidth < 400;

                    final navArrowSize = isVerySmallScreen
                        ? 40.0
                        : (isSmallScreen ? 45.0 : arrowSize);
                    final titleFontSize = isVerySmallScreen
                        ? 14.0
                        : (isSmallScreen ? 18.0 : 24.0);
                    final titlePadding = isVerySmallScreen
                        ? 12.0
                        : (isSmallScreen ? 16.0 : 20.0);
                    final spacing = isVerySmallScreen
                        ? 16.0
                        : (isSmallScreen ? 20.0 : 24.0);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNavigationArrow(
                          icon: Icons.arrow_left,
                          size: navArrowSize,
                          onPressed: () {
                            _navigateToPage(_selectedIndex - 1);
                          },
                        ),
                        SizedBox(width: spacing),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: titlePadding,
                            vertical: isVerySmallScreen ? 6 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(0xFFb29c48),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _getPageTitle(_selectedIndex),
                            style: TextStyle(
                              fontSize: titleFontSize,
                              color: Color(0xFFb29c48),
                              fontFamily: 'Pixel',
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: spacing),
                        _buildNavigationArrow(
                          icon: Icons.arrow_right,
                          size: navArrowSize,
                          onPressed: () {
                            _navigateToPage(_selectedIndex + 1);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.38),
                    AnimatedBuilder(
                      animation: _penitenteAnimation,
                      builder: (context, child) {
                        final equippedSkin = inventorySkins.firstWhere(
                          (skin) => skin['equipped'] == true,
                          orElse: () => inventorySkins[0],
                        );
                        return Image.asset(
                          _penitenteAnimation.value == 1
                              ? equippedSkin['img']
                              : equippedSkin['img2'] ?? equippedSkin['img'],
                          width: characterWidth,
                          height: characterHeight,
                        );
                      },
                    ),
                    if (buttonText.isNotEmpty) ...[
                      SizedBox(height: isVerySmallScreen ? 12 : 20),

                      _buildBlasphemousButton(
                        text: buttonText,
                        onPressed: onPressed,
                        width: buttonWidth,
                        height: buttonHeight,
                      ),
                    ],
                  ],
                ),
              ),

              Positioned(
                left: screenWidth * 0.05,
                bottom: screenHeight * 0.05,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Image.asset(
                          _selectedIndex == 0
                              ? 'assets/Icon_confessar.png' // Ecclesia
                              : _selectedIndex == 1
                                  ? 'assets/Icon_vaso_fervor.png' // Montes
                                  : _selectedIndex == 2
                                      ? 'assets/Frasco_0.png' // Albero
                                      : 'assets/Icon_espada.png', // Spelunca
                          width: screenWidth < 600 ? 48 : 64,
                          height: screenWidth < 600 ? 48 : 64,
                        ),
                        onPressed: () {
                          if (_selectedIndex == 2) { // Albero
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ShopPage(
                                  onBuyPotion: buyPotion,
                                  currentCoins: coins,
                                ),
                              ),
                            );
                          } else if (_selectedIndex == 1) { // Montes
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FervorShopPage(
                                  currentCoins: coins,
                                  onBuyPotion: buyFervorPotion,
                                ),
                              ),
                            );
                          } else if (_selectedIndex == 0) { // Ecclesia
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FaithShopPage(
                                  currentCoins: coins,
                                  onBuyPotion: buyFaithPotion,
                                ),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                builder: (context) => GameWidget(
                  game: CaveHuntGame(
                    onFinish: (coinsEarned) {
                      setState(() {
                        coins += coinsEarned;
                      });
                      _savePetStatus();
                    },
                    onCoinCollected: () {
                      setState(() {
                        happiness = (happiness + 1).clamp(0, 100);
                      });
                      _savePetStatus();
                    },
                  ),
                                  overlayBuilderMap: {
                                    'end': (ctx, game) {
                                      final g = game as CaveHuntGame;
                                      return AlertDialog(
                                        backgroundColor: const Color(0xFF2C1810),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: const BorderSide(color: Color(0xFFb29c48), width: 2),
                                        ),
                                        title: const Text(
                                          'Fim da Caça',
                                          style: TextStyle(color: Color(0xFFb29c48), fontFamily: 'Pixel'),
                                        ),
                        content: Text(
                          'Você ganhou ${g.score * 30} moedas.\nEntretenimento +${g.score}',
                                          style: const TextStyle(color: Colors.white, fontFamily: 'Pixel'),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(),
                                            child: const Text('OK', style: TextStyle(color: Color(0xFFb29c48), fontFamily: 'Pixel')),
                                          ),
                                        ],
                                      );
                                    },
                                    'hud': (ctx, game) {
                                      final g = game as CaveHuntGame;
                                      return SafeArea(
                                        child: Align(
                                          alignment: Alignment.topRight,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2C1810),
                                                foregroundColor: const Color(0xFFb29c48),
                                              ),
                                              onPressed: () {
                                                g.pauseEngine();
                                                showDialog(
                                                  context: ctx,
                                                  builder: (c) => AlertDialog(
                                                    backgroundColor: const Color(0xFF2C1810),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      side: const BorderSide(color: Color(0xFFb29c48), width: 2),
                                                    ),
                                                    title: const Text(
                                                      'Sair do jogo',
                                                      style: TextStyle(color: Color(0xFFb29c48), fontFamily: 'Pixel'),
                                                    ),
                                                    content: const Text(
                                                      'Tem certeza que deseja sair? Seu progresso nesta rodada não será contado.',
                                                      style: TextStyle(color: Colors.white, fontFamily: 'Pixel'),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(c).pop();
                                                          g.resumeEngine();
                                                        },
                                                        child: const Text('Continuar', style: TextStyle(color: Color(0xFFb29c48), fontFamily: 'Pixel')),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(c).pop();
                                                          Navigator.of(ctx).pop();
                                                        },
                                                        child: const Text('Sair', style: TextStyle(color: Color(0xFFb29c48), fontFamily: 'Pixel')),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.exit_to_app),
                                              label: const Text('Sair', style: TextStyle(fontFamily: 'Pixel')),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  },
                                  initialActiveOverlays: const ['hud'],
                                ),
                              ),
                            );
                          }
                        },
                        tooltip: _selectedIndex == 2
                            ? 'Alambique Sagrado'
                            : _selectedIndex == 1
                                ? 'Descansar'
                                : _selectedIndex == 0
                                    ? 'Orar'
                                    : 'Espada',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedIndex == 0
                          ? 'Absolvo'
                          : _selectedIndex == 1
                              ? 'Fervor'
                              : _selectedIndex == 2
                                  ? 'Vitale'
                                  : 'Laminate',
                      style: TextStyle(
                        color: const Color(0xFFb29c48),
                        fontFamily: 'Pixel',
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth < 600 ? 14 : 16,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: screenHeight * 0.05,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFFb29c48), width: 1),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.inventory, color: Color(0xFFb29c48)),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => InventoryPage(
                                  potions: inventoryPotions,
                                  skins: inventorySkins,
                                  onUsePotion: usePotion,
                                  onEquipSkin: equipSkin,
                                  onUpdate: updateInventory,
                                ),
                              ),
                            );
                          },
                          tooltip: 'Inventário',
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Inventário',
                        style: TextStyle(
                          color: Color(0xFFb29c48),
                          fontFamily: 'Pixel',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: screenHeight * 0.11,
                right: screenWidth * 0.05,
                child: Container(
                  width: 110,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/contador_moedas.png',
                        width: 110,
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                      Positioned(
                        left: 28,
                        top: 14,
                        child: Text(
                          _formatMoney(coins),
                          style: const TextStyle(
                            color: Color(0xFFb29c48),
                            fontSize: 18,
                            fontFamily: 'Pixel',
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                right: screenWidth * 0.05,
                bottom: screenHeight * 0.05,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Image.asset(
                          'assets/Icon_loja.png',
                          width: screenWidth < 600 ? 48 : 64,
                          height: screenWidth < 600 ? 48 : 64,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SkinsShopPage(
                                onBuySkin: buySkin,
                                currentCoins: coins,
                              ),
                              settings: RouteSettings(arguments: inventorySkins),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nundinae',
                      style: TextStyle(
                        color: const Color(0xFFb29c48),
                        fontFamily: 'Pixel',
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth < 600 ? 14 : 16,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> get _pages => [
    // Ecclesia (Igreja)
    _buildResponsivePage(
      backgroundAsset: 'assets/background_igr.png',
      buttonText: '',
      onPressed: feed,
    ),
    // Montes (Montanhas)
    _buildResponsivePage(
      backgroundAsset: 'assets/background_mon.png',
      buttonText: '',
      onPressed: sleep,
    ),
    // Albero
    _buildResponsivePage(
      backgroundAsset: 'assets/background_alb.png',
      buttonText: '',
      onPressed: increaseVitality,
    ),
    // Spelunca (Caverna)
    _buildResponsivePage(
      backgroundAsset: 'assets/background_cav.png',
      buttonText: '',
      onPressed: play,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF2C1810),
        body: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final double titleFontSize = (screenWidth * 0.16).clamp(42.0, 96.0);
              final double outlineWidth = (screenWidth * 0.008).clamp(2.0, 6.0);
              final double glowBlur = (screenWidth * 0.03).clamp(6.0, 22.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [

                      Text(
                        'post vitam.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BadBoys',
                          fontSize: titleFontSize,
                          color: const Color(0xFFb29c48),
                          shadows: [
                            Shadow(
                              color: const Color(0xFFb29c48).withOpacity(0.55),
                              blurRadius: glowBlur,
                              offset: const Offset(0, 0),
                            ),
                            Shadow(
                              color: const Color(0xFFb29c48).withOpacity(0.35),
                              blurRadius: glowBlur * 0.6,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        'post vitam.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BadBoys',
                          fontSize: titleFontSize,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = outlineWidth
                            ..color = Colors.black,
                        ),
                      ),

                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFF7E27E), 
                              Color(0xFFE6CC77),
                              Color(0xFFb29c48), 
                              Color(0xFF8C6F1D), 
                            ],
                          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
                        },
                        child: Text(
                          'post vitam.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'BadBoys',
                            fontSize: titleFontSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFb29c48)),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          Container(
            color: Color(0xFF2C1810),
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                final pagesLen = _pages.length;
                setState(() {
                  _rawPageIndex = index;
                  _selectedIndex = ((index % pagesLen) + pagesLen) % pagesLen;
                });
              },
              itemBuilder: (context, index) {
                final pages = _pages;
                final pagesLen = pages.length;
                final page = pages[((index % pagesLen) + pagesLen) % pagesLen];
                return page;
              },
            ),
          ),
          // Botão de Configurações
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _openSettingsPanel,
                    child: Ink(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A2C1A).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFb29c48), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(Icons.settings, color: Color(0xFFb29c48), size: 22),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPage(int logicalTargetIndex) {

    final pagesLen = _pages.length;
    if (pagesLen == 0) return;

    final normalizedTarget = ((logicalTargetIndex % pagesLen) + pagesLen) % pagesLen;

    int base = _rawPageIndex - (_rawPageIndex % pagesLen);
    int candidate = base + normalizedTarget;

    if ((candidate - _rawPageIndex).abs() > (candidate + pagesLen - _rawPageIndex).abs()) {
      candidate += pagesLen;
    } else if ((candidate - _rawPageIndex).abs() > (candidate - pagesLen - _rawPageIndex).abs()) {
      candidate -= pagesLen;
    }

    if (candidate != _rawPageIndex) {
      _pageController.animateToPage(
        candidate,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Ecclesia';
      case 1:
        return 'Montes';
      case 2:
        return 'Albero';
      case 3:
        return 'Spelunca';
      default:
        return '';
    }
  }

  void _openSettingsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C1810),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFb29c48), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.settings, color: Color(0xFFb29c48)),
                    SizedBox(width: 8),
                    Text(
                      'Configurações',
                      style: TextStyle(
                        fontFamily: 'Pixel',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFb29c48),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A2C1A).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFb29c48).withOpacity(0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug: Resetar Progresso',
                        style: TextStyle(
                          fontFamily: 'Pixel',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFb29c48),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Zera o inventário e restaura os status para o início (100/100/100/100) com 20.000 moedas. Use para testes.',
                        style: TextStyle(
                          fontFamily: 'Pixel',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFb29c48),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: const Color(0xFF2C1810),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: const Text(
                                    'Tem certeza?',
                                    style: TextStyle(
                                      fontFamily: 'Pixel',
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFb29c48),
                                    ),
                                  ),
                                  content: const Text(
                                    'Essa ação vai resetar todo o progresso: inventário será limpo e os status voltarão ao início com 20.000 moedas.',
                                    style: TextStyle(
                                      fontFamily: 'Pixel',
                                      color: Colors.white70,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text(
                                        'Cancelar',
                                        style: TextStyle(fontFamily: 'Pixel'),
                                      ),
                                      onPressed: () => Navigator.of(context).pop(false),
                                    ),
                                    TextButton(
                                      child: const Text(
                                        'Confirmar',
                                        style: TextStyle(fontFamily: 'Pixel', color: Color(0xFFb29c48)),
                                      ),
                                      onPressed: () => Navigator.of(context).pop(true),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {

                              await _dbHelper.resetDatabase();
                              await _applyDegradationOnline();
                              await _loadInventory();
                              if (mounted) Navigator.of(context).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Progresso resetado para o início.',
                                      style: TextStyle(fontFamily: 'Pixel', fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: Color(0xFFb29c48),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.restore),
                          label: const Text('Resetar (Debug)', style: TextStyle(fontFamily: 'Pixel')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
