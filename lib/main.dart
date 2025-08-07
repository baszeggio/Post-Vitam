import 'package:flutter/material.dart';
import 'package:pou_application_1/faith_shop_page.dart';
import 'package:pou_application_1/fervor_shop_page.dart';
import 'dart:async';
import 'dao/postvitamdao.dart';
import 'potions_shop_page.dart';
import 'skins_shop_page.dart';
import 'inventory_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Vitam',
      debugShowCheckedModeBanner: false,
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
  
  

  Timer? _degradationTimer;

  void _checkAndSendNotifications() {
    if (hunger <= 20) {
      NotificationService.showGameNotification(
        title: 'Sua Fé está baixa!',
        body: 'Seu Penitente precisa orar na Igreja para restaurar sua Fé.',
      );
    }

    if (energy <= 20) {
      NotificationService.showGameNotification(
        title: 'Seu Fervor está baixo!',
        body:
            'Seu Penitente precisa descansar nas Montanhas para recuperar o Fervor.',
      );
    }

    if (vitality <= 15) {
      NotificationService.showGameNotification(
        title: 'Vitalidade Crítica!',
        body:
            'Use um frasco ou medite em Albero para restaurar a Vitalidade do seu Penitente.',
      );
    }

    if (hunger <= 30 && happiness <= 30 && energy <= 30) {
      NotificationService.showGameNotification(
        title: 'Seu Penitente precisa de atenção!',
        body: 'Múltiplos status estão baixos. Cuide do seu Penitente!',
      );
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

    // Inicializa PageController para loop infinito
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

  bool buySkin(Map<String, dynamic> skin) {
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
      _savePetStatus();
      _saveInventory();
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

      setState(() {
        if (potionName.contains('Pequeno')) {
          vitality = (vitality + 15).clamp(0, 100);
        } else if (potionName.contains('Médio')) {
          vitality = (vitality + 25).clamp(0, 100);
        } else if (potionName.contains('Grande')) {
          vitality = (vitality + 40).clamp(0, 100);
        } else if (potionName.contains('Milagre')) {
          vitality = (vitality * 1.10).round();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _savePetStatus();
      _saveInventory();
    } else if (state == AppLifecycleState.resumed) {
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
        // Garante que a skin padrão sempre está presente e equipada na primeira vez
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
        // Garante que só uma skin está equipada
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
        final characterWidth = isPortrait
            ? screenWidth * 0.4
            : screenHeight * 0.3;
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
                top: 20,
                left: 0,
                right: 0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isSmallScreen = screenWidth < 600;
                    final isVerySmallScreen = screenWidth < 400;

                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 16,
                      ),
                      child: isVerySmallScreen
                          ? Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    needIndicator(
                                      iconPath: 'assets/Icon_fé.png',
                                      value: hunger,
                                    ),
                                    needIndicator(
                                      iconPath:
                                          'assets/Icon_entretenimento.png',
                                      value: happiness,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    needIndicator(
                                      iconPath: 'assets/Icon_fervor.png',
                                      value: energy,
                                    ),
                                    needIndicator(
                                      iconPath: 'assets/Icon_vitalidade.png',
                                      value: vitality,
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                needIndicator(
                                  iconPath: 'assets/Icon_fé.png',
                                  value: hunger,
                                ),
                                needIndicator(
                                  iconPath: 'assets/Icon_entretenimento.png',
                                  value: happiness,
                                ),
                                needIndicator(
                                  iconPath: 'assets/Icon_fervor.png',
                                  value: energy,
                                ),
                                needIndicator(
                                  iconPath: 'assets/Icon_vitalidade.png',
                                  value: vitality,
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),

              Positioned(
                top: screenHeight * 0.25,
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
                    SizedBox(height: screenHeight * 0.35),
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
                child: _selectedIndex == 0
                    ? Container(
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
                            'assets/Icon_confessar.png',
                            width: screenWidth < 600 ? 48 : 64,
                            height: screenWidth < 600 ? 48 : 64,
                          ),
                          onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => FaithShopPage(
                                        currentCoins: coins,
                                        onBuyPotion: (item) {
                                          setState(() {
                                            coins -= item['price'] as int;
                                            inventoryPotions.add({
                                              'name': item['name'],
                                              'desc': item['desc'],
                                              'img': item['img'],
                                              'quantity': 1,
                                              'type': 'faith',
                                            });
                                          });
                                          _savePetStatus();
                                          _saveInventory();
                                        },
                                      ),
                                    ),
                                  );
                                },

                          tooltip: 'Orar',
                        ),
                      )
                    : Container(
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
                            _selectedIndex == 3
                                ? 'assets/Frasco_0.png'
                                : _selectedIndex == 2
                                ? 'assets/Icon_vaso_fervor.png'
                                : 'assets/Icon_espada.png',
                            width: screenWidth < 600 ? 48 : 64,
                            height: screenWidth < 600 ? 48 : 64,
                          ),
                          onPressed: () {
                            if (_selectedIndex == 3) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ShopPage(
                                    onBuyPotion: buyPotion,
                                    currentCoins: coins,
                                  ),
                                ),
                              );
                                      } else if (_selectedIndex == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FervorShopPage(
                  currentCoins: coins,
                  onBuyPotion: (item) {
                    setState(() {
                      coins -= item['price'] as int;
                      inventoryPotions.add({
                        'name': item['name'],
                        'desc': item['desc'],
                        'img': item['img'],
                        'quantity': 1,
                        'type': 'fervor',
                      });
                    });
                    _savePetStatus();
                    _saveInventory();
                  },
                ),
              ),
            );
          } else {
                                    play();

                            }
                          },
                          tooltip: _selectedIndex == 3
                              ? 'Loja de Frascos'
                              : _selectedIndex == 2
                              ? 'Descansar'
                              : 'Espada',
                        ),
                      ),
              ),

              Positioned(
                right: screenWidth * 0.05,
                bottom: screenHeight * 0.05,
                child: Container(
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
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> get _pages => [
    _buildResponsivePage(
      backgroundAsset: 'assets/background_igr.png',
      buttonText: '',
      onPressed: feed,
    ),
    _buildResponsivePage(
      backgroundAsset: 'assets/background_cav.png',
      buttonText: 'Explorar',
      onPressed: play,
    ),
    _buildResponsivePage(
      backgroundAsset: 'assets/background_mon.png',
      buttonText: '',
      onPressed: sleep,
    ),
    _buildResponsivePage(
      backgroundAsset: 'assets/background_alb.png',
      buttonText: '',
      onPressed: increaseVitality,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2C1810),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFb29c48)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2C1810),
        elevation: 0,
        leading: null,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isSmallScreen = screenWidth < 600;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _getPageTitle(_selectedIndex),
                    style: TextStyle(
                      color: Color(0xFFb29c48),
                      fontFamily: 'Pixel',
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 22,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFb29c48),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.inventory,
                            color: Color(0xFFb29c48),
                            size: isSmallScreen ? 20 : 24,
                          ),
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
                      SizedBox(width: 8),

                      Container(
                        width: isSmallScreen ? 80 : 100,
                        height: isSmallScreen ? 48 : 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/contador_moedas.png',
                              width: isSmallScreen ? 80 : 100,
                              height: isSmallScreen ? 48 : 60,
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              left: isSmallScreen ? 20 : 25,
                              top: isSmallScreen ? 15 : 20,
                              child: Text(
                                _formatMoney(coins),
                                style: TextStyle(
                                  color: Color(0xFFb29c48),
                                  fontSize: isSmallScreen ? 14 : 18,
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
                          ],
                        ),
                      ),
                      SizedBox(width: 8),

                      IconButton(
                        icon: Icon(Icons.refresh, color: Color(0xFFb29c48)),
                        tooltip: 'Resetar progresso',
                        onPressed: () async {
                          await _dbHelper.resetDatabase();

                          setState(() {
                            hunger = 50;
                            happiness = 50;
                            energy = 50;
                            vitality = 50;
                            coins = 20000;
                            inventoryPotions.clear();
                            inventorySkins = [
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
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Progresso resetado!'),
                                backgroundColor: Color(0xFFb29c48),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Container(
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
    );
  }

  void _navigateToPage(int logicalTargetIndex) {
    // Com PageView.builder infinito, navegamos ajustando o índice bruto
    final pagesLen = _pages.length;
    if (pagesLen == 0) return;

    final normalizedTarget = ((logicalTargetIndex % pagesLen) + pagesLen) % pagesLen;

    // Encontrar um índice bruto próximo que mostre a página desejada
    int base = _rawPageIndex - (_rawPageIndex % pagesLen);
    int candidate = base + normalizedTarget;

    // Escolhe o candidato mais próximo do índice atual
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
        return 'Igreja';
      case 1:
        return 'Caverna';
      case 2:
        return 'Montanhas';
      case 3:
        return 'Albero';
      default:
        return '';
    }
  }
}
