import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dao/postvitamdao.dart';
import 'models/pet_status.dart';
import 'shop_page.dart';
import 'skins_shop_page.dart';
import 'inventory_page.dart';
import 'package:flame/flame.dart';

void main() {
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
  int coins = 20000; // Exemplo de moedas
  
  // Inventário global
  List<Map<String, dynamic>> inventoryPotions = [];
  List<Map<String, dynamic>> inventorySkins = [
    {
      'img': 'assets/Penitente_1.png',
      'name': 'Skin Padrão',
      'desc': 'O visual padrão do Penitente.',
      'quantity': 1,
      'type': 'skin',
      'equipped': true,
    },
  ];
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  late AnimationController _penitenteController;
  late Animation<int> _penitenteAnimation;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = true;
  
  // Timer para degradação automática
  Timer? _degradationTimer;
  
  // Timer para atualizar relógio
  Timer? _clockTimer;
  
  // Hora atual
  String _currentTime = '';

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

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('=== INICIANDO APLICATIVO ===');
    try {
      await _applyDegradationOnline();
      await _loadInventory();
      _startDegradationTimer();
      _startClockTimer();
      _updateCurrentTime();
      // Forçar salvamento inicial para garantir que os dados estão no banco
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

  Future<void> _applyDegradationOffline() async {
    try {
      final status = await _dbHelper.calculateDegradationOffline();
      setState(() {
        hunger = status.hunger;
        happiness = status.happiness;
        energy = status.energy;
        vitality = status.vitality;
        coins = status.coins;
      });
    } catch (e) {
      print('Erro ao aplicar degradação offline: $e');
    }
    setState(() {
      _isLoading = false;
    });
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

  // Iniciar timer para degradação automática
  void _startDegradationTimer() {
    // Aplicar degradação a cada 5 segundos (teste rápido)
    _degradationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _applyDegradationOnline();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _penitenteController.dispose();
    _degradationTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  // Aplicar degradação apenas nos status (preservar moedas)
  Future<void> _applyStatusDegradation() async {
    try {
      final status = await _dbHelper.applyDegradationAndGetStatus();
      setState(() {
        hunger = status.hunger;
        happiness = status.happiness;
        energy = status.energy;
        vitality = status.vitality;
        // Não alterar as moedas aqui
      });
    } catch (e) {
      print('Erro ao aplicar degradação de status: $e');
    }
  }

  // Iniciar timer para atualizar relógio
  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
    });
  }

  // Atualizar hora atual
  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  // Formatar números de dinheiro (1000+ vira X.XK)
  String _formatMoney(int amount) {
    if (amount >= 1000) {
      double kValue = amount / 1000.0;
      if (kValue == kValue.toInt()) {
        // Se for número inteiro (ex: 5000 -> 5K)
        return '${kValue.toInt()}K';
      } else {
        // Se tiver decimais (ex: 1250 -> 1.25K)
        return '${kValue.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}K';
      }
    }
    return amount.toString();
  }

  // Comprar frasco
  bool buyPotion(Map<String, dynamic> potion) {
    final price = potion['price'] as int;
    if (coins >= price) {
      setState(() {
        coins -= price;
        
        // Verificar se já existe no inventário
        final existingIndex = inventoryPotions.indexWhere(
          (item) => item['name'] == potion['name']
        );
        
        if (existingIndex != -1) {
          // Aumentar quantidade
          inventoryPotions[existingIndex]['quantity'] += 1;
        } else {
          // Adicionar novo item
          inventoryPotions.add({
            'img': potion['img'],
            'name': potion['name'],
            'desc': potion['desc'],
            'quantity': 1,
            'type': 'potion',
          });
        }
      });
      
      // Salvar moedas e inventário no banco de dados
      _savePetStatus();
      _saveInventory();
      return true;
    }
    return false;
  }

  // Comprar skin
  bool buySkin(Map<String, dynamic> skin) {
    final price = skin['price'] as int;
    if (coins >= price) {
      setState(() {
        coins -= price;
        // Verificar se já existe no inventário
        final existingIndex = inventorySkins.indexWhere(
          (item) => item['name'] == skin['name']
        );
        if (existingIndex == -1) {
          // Adicionar nova skin
          inventorySkins.add({
            'img': skin['img'],
            'name': skin['name'],
            'desc': skin['desc'],
            'quantity': 1,
            'type': 'skin',
            'equipped': false,
          });
        }
      });
      // Salvar moedas e inventário no banco de dados
      _savePetStatus();
      _saveInventory();
      return true;
    }
    return false;
  }

  // Usar frasco
  void usePotion(int index) {
    if (index < inventoryPotions.length && inventoryPotions[index]['quantity'] > 0) {
      final potion = inventoryPotions[index];
      final potionName = potion['name'] as String;
      
      setState(() {
        // Aplicar efeito do frasco baseado no nome
        if (potionName.contains('Pequeno')) {
          // Restaura 15 pontos de vitalidade (nerfado)
          vitality = (vitality + 15).clamp(0, 100);
        } else if (potionName.contains('Médio')) {
          // Restaura 25 pontos de vitalidade (nerfado)
          vitality = (vitality + 25).clamp(0, 100);
        } else if (potionName.contains('Grande')) {
          // Restaura 40 pontos de vitalidade (nerfado)
          vitality = (vitality + 40).clamp(0, 100);
        } else if (potionName.contains('Milagre')) {
          // Aumenta o máximo de vitalidade em 10% (único que pode ultrapassar 100)
          vitality = (vitality * 1.10).round();
        }
        
        // Diminuir quantidade
        inventoryPotions[index]['quantity'] -= 1;
        
        // Se quantidade chegar a 0, remover do inventário
        if (inventoryPotions[index]['quantity'] <= 0) {
          inventoryPotions.removeAt(index);
        }
      });
      
      // Salvar status e inventário atualizados
      _savePetStatus();
      _saveInventory();
    }
  }

  // Função para atualizar inventário
  void updateInventory() {
    setState(() {});
  }

  // Remover função equipSkin e qualquer chamada relacionada

  // Detecta quando o app vai para background ou é fechado
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _savePetStatus();
      _saveInventory();
    } else if (state == AppLifecycleState.resumed) {
      // Quando o app retorna do background, aplicar degradação apenas nos status
      _applyStatusDegradation();
    }
  }

  Future<void> _loadPetStatus() async {
    try {
      print('=== INICIANDO CARREGAMENTO DE STATUS ===');
      
      // Verificar integridade do banco
      await _dbHelper.checkDatabaseIntegrity();
      
      // Carregar status atual sem aplicar degradação
      final status = await _dbHelper.loadPetStatusWithoutDegradation();
      print('Carregando status - Moedas: ${status.coins}');
      
      setState(() {
        hunger = status.hunger;
        happiness = status.happiness;
        energy = status.energy;
        vitality = status.vitality;
        coins = status.coins;
        _isLoading = false;
      });
      
      print('Status carregado com sucesso - Moedas: $coins');
      print('=== CARREGAMENTO CONCLUÍDO ===');
    } catch (e) {
      print('Erro ao carregar status do pet: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePetStatus() async {
    try {
      print('=== INICIANDO SALVAMENTO DE STATUS ===');
      print('Salvando status - Hunger: $hunger, Happiness: $happiness, Energy: $energy, Vitality: $vitality, Coins: $coins');
      
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
        if (inventorySkins.isEmpty || inventorySkins.every((skin) => skin['name'] != 'Skin Padrão')) {
          inventorySkins.insert(0, {
            'img': 'assets/Penitente_1.png',
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
      print('Inventário carregado - Poções:  [33m${inventoryPotions.length} [0m, Skins:  [33m${inventorySkins.length} [0m');
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

  // Botão personalizado estilo do Blasphemous
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
        gradient: LinearGradient(
          colors: [Color(0xFF2C1810), Color(0xFF4A2C1A), Color(0xFF6B3E2A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFb29c48), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.all(8),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: Color(0xFFb29c48),
                  fontSize: width < 120 ? 12 : 16,
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
      ),
    );
  }

  // Setas de navegação estilo do Blasphemous
  Widget _buildNavigationArrow({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF6B3E2A), Color(0xFF2C1810)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Color(0xFFb29c48), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(),
        child: InkWell(
          customBorder: CircleBorder(),
          onTap: onPressed,
          child: Icon(
            icon,
            color: Color(0xFFb29c48),
            size: size * 0.6,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
            ],
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
        
        final iconSize = isVerySmallScreen ? 36.0 : (isSmallScreen ? 44.0 : 56.0);
        final barWidth = isVerySmallScreen ? 40.0 : (isSmallScreen ? 50.0 : 60.0);
        final barHeight = isVerySmallScreen ? 6.0 : (isSmallScreen ? 8.0 : 10.0);
        final fontSize = isVerySmallScreen ? 8.0 : (isSmallScreen ? 10.0 : 12.0);
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
              // Contador de pontos
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
              // Background image
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
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
                      child: isVerySmallScreen 
                        ? Column(
                            children: [
                              // Primeira linha - Fé e Entretenimento
                              Row(
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
                                ],
                              ),
                              SizedBox(height: 8),
                              // Segunda linha - Fervor e Vitalidade
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

              // Navegação e título
              Positioned(
                top: screenHeight * 0.25,
                left: 0,
                right: 0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final navScreenWidth = constraints.maxWidth;
                    final isSmallScreen = navScreenWidth < 600;
                    final isVerySmallScreen = navScreenWidth < 400;
                    
                    final navArrowSize = isVerySmallScreen ? 40.0 : (isSmallScreen ? 45.0 : arrowSize);
                    final titleFontSize = isVerySmallScreen ? 14.0 : (isSmallScreen ? 18.0 : 24.0);
                    final titlePadding = isVerySmallScreen ? 12.0 : (isSmallScreen ? 16.0 : 20.0);
                    final spacing = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 24.0);
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNavigationArrow(
                          icon: Icons.arrow_left,
                          size: navArrowSize,
                          onPressed: () {
                            setState(() {
                              _selectedIndex =
                                  (_selectedIndex - 1 + _pages.length) %
                                  _pages.length;
                              _pageController.jumpToPage(_selectedIndex);
                            });
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
                            border: Border.all(color: Color(0xFFb29c48), width: 2),
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
                            setState(() {
                              _selectedIndex = (_selectedIndex + 1) % _pages.length;
                              _pageController.jumpToPage(_selectedIndex);
                            });
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
                        return Image.asset(
                          'assets/Penitente_${_penitenteAnimation.value}.png',
                          width: characterWidth,
                          height: characterHeight,
                        );
                      },
                    ),
                    SizedBox(height: isVerySmallScreen ? 12 : 20),
                    // Botão de ação estilo do Blasphemous
                    _buildBlasphemousButton(
                      text: buttonText,
                      onPressed: onPressed,
                      width: buttonWidth,
                      height: buttonHeight,
                    ),
                  ],
                ),
              ),

              // Ícones nos cantos
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
                          onPressed: feed,
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
                            // Mostra o ícone do frasco 0 apenas na área da Albero (índice 3)
                            _selectedIndex == 3 ? 'assets/Frasco_0.png' : 'assets/Icon_espada.png',
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
                                  settings: RouteSettings(arguments: inventorySkins),
                                ),
                              );
                            }
                            // Caso contrário, mantém a ação da espada (vazio por enquanto)
                          },
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
      buttonText: 'Orar',
      onPressed: feed,
    ),
    _buildResponsivePage(
      backgroundAsset: 'assets/background_cav.png',
      buttonText: 'Explorar',
      onPressed: play,
    ),
    _buildResponsivePage(
      backgroundAsset: 'assets/background_mon.png',
      buttonText: 'Descansar',
      onPressed: sleep,
    ),
    _buildResponsivePage(
      backgroundAsset: 'assets/background_alb.png',
      buttonText: 'Meditar',
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
                      // Botão do Inventário
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFFb29c48), width: 1),
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
                                  onEquipSkin: (index) {}, // Remover ação de equipar
                                  onUpdate: updateInventory,
                                ),
                              ),
                            );
                          },
                          tooltip: 'Inventário',
                        ),
                      ),
                      SizedBox(width: 8),
                      // Contador de moedas
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
                      // Botão de reset
                      IconButton(
                        icon: Icon(Icons.refresh, color: Color(0xFFb29c48)),
                        tooltip: 'Resetar progresso',
                        onPressed: () async {
                          await _dbHelper.resetDatabase();
                          await _applyDegradationOnline();
                          await _loadInventory();
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
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: _pages,
        ),
      ),
    );
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

//  aaaa
