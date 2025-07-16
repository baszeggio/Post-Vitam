import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dao/postvitamdao.dart';
import 'models/pet_status.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Vitam',
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
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  late AnimationController _penitenteController;
  late Animation<int> _penitenteAnimation;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = true;

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

    _loadPetStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _penitenteController.dispose();
    super.dispose();
  }

  // Detecta quando o app vai para background ou é fechado
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _savePetStatus();
    }
  }

  Future<void> _loadPetStatus() async {
    try {
      final status = await _dbHelper.getPetStatus();
      if (status != null) {
        setState(() {
          hunger = status.hunger;
          happiness = status.happiness;
          energy = status.energy;
          vitality = status.vitality;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar status do pet: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePetStatus() async {
    try {
      await _dbHelper.savePetStatus(
        hunger: hunger,
        happiness: happiness,
        energy: energy,
        vitality: vitality,
      );
    } catch (e) {
      print('Erro ao salvar status do pet: $e');
    }
  }

  void feed() {
    setState(() {
      hunger = (hunger + 10).clamp(0, 100);
      vitality = (vitality + 2).clamp(0, 100);
    });
    _savePetStatus(); // Salva automaticamente após cada ação
  }

  void play() {
    setState(() {
      happiness = (happiness + 10).clamp(0, 100);
      energy = (energy - 5).clamp(0, 100);
      vitality = (vitality + 3).clamp(0, 100);
    });
    _savePetStatus(); // Salva automaticamente após cada ação
  }

  void sleep() {
    setState(() {
      energy = (energy + 15).clamp(0, 100);
      hunger = (hunger - 5).clamp(0, 100);
      happiness = (happiness - 10).clamp(0, 100);
      vitality = (vitality + 5).clamp(0, 100);
    });
    _savePetStatus(); // Salva automaticamente após cada ação
  }

  void increaseVitality() {
    setState(() {
      vitality = (vitality + 10).clamp(0, 100);
    });
    _savePetStatus(); // Salva automaticamente após cada ação
  }

  Widget needIndicator({
    required String iconPath,
    required int value,
    Color color = const Color(0xFFb29c48),
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final iconSize = screenWidth < 600 ? 24.0 : 28.0;
        final barWidth = screenWidth < 600 ? 28.0 : 32.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(iconPath, width: iconSize, height: iconSize),
            const SizedBox(height: 2),
            SizedBox(
              width: barWidth,
              height: 6,
              child: LinearProgressIndicator(
                value: value / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
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

        // Tamanhos adaptativos
        final characterWidth = isPortrait
            ? screenWidth * 0.4
            : screenHeight * 0.3;
        final characterHeight = characterWidth * 1.8; // Mantém proporção

        final buttonFontSize = screenWidth < 600 ? 12.0 : 16.0;
        final iconSize = screenWidth < 600 ? 48.0 : 64.0;

        return Container(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              // Background image responsivo
              Positioned.fill(
                child: Image.asset(
                  backgroundAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              // Personagem centralizado
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botões de trocar de tela (setas)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_left,
                            size: screenWidth < 600 ? 28 : 32,
                          ),
                          color: Colors.deepPurple,
                          onPressed: () {
                            setState(() {
                              _selectedIndex =
                                  (_selectedIndex - 1 + _pages.length) %
                                  _pages.length;
                              _pageController.jumpToPage(_selectedIndex);
                            });
                          },
                        ),
                        SizedBox(width: 16),
                        Text(
                          _getPageTitle(_selectedIndex),
                          style: TextStyle(
                            fontSize: screenWidth < 600 ? 16 : 20,
                            color: Colors.white,
                            fontFamily: 'Pixel',
                          ),
                        ),
                        SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_right,
                            size: screenWidth < 600 ? 28 : 32,
                          ),
                          color: Colors.deepPurple,
                          onPressed: () {
                            setState(() {
                              _selectedIndex =
                                  (_selectedIndex + 1) % _pages.length;
                              _pageController.jumpToPage(_selectedIndex);
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.25),
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
                    SizedBox(
                      height: screenHeight * 0.05,
                    ), // <-- Espaço entre personagem e botão
                    // Botão de ação ("alimentar", etc)
                    ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 600 ? 16 : 24,
                          vertical: screenWidth < 600 ? 8 : 12,
                        ),
                      ),
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          color: const Color(0xFFb29c48),
                          fontSize: buttonFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Ícones nos cantos - posicionamento responsivo
              Positioned(
                left: screenWidth * 0.05,
                bottom: screenHeight * 0.05,
                child: IconButton(
                  icon: Image.asset(
                    'assets/Icon_espada.png',
                    width: iconSize,
                    height: iconSize,
                  ),
                  onPressed: () {
                    // ação da espada
                  },
                ),
              ),

              Positioned(
                right: screenWidth * 0.05,
                bottom: screenHeight * 0.05,
                child: IconButton(
                  icon: Image.asset(
                    'assets/Icon_loja.png',
                    width: iconSize,
                    height: iconSize,
                  ),
                  onPressed: () {
                    // ação da loja
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> get _pages => [
    // Igreja
    _buildResponsivePage(
      backgroundAsset: 'assets/background_igr.png',
      buttonText: 'Igreja',
      onPressed: feed,
    ),

    // Caverna
    _buildResponsivePage(
      backgroundAsset: 'assets/background_cav.png',
      buttonText: 'Caverna',
      onPressed: play,
    ),

    // Montanhas
    _buildResponsivePage(
      backgroundAsset: 'assets/background_mon.png',
      buttonText: 'Montanhas',
      onPressed: sleep,
    ),

    // Albero
    _buildResponsivePage(
      backgroundAsset: 'assets/background_alb.png',
      buttonText: 'Albero',
      onPressed: increaseVitality,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leadingWidth: 10,
        leading: null,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Indicadores de necessidades (sem setas de navegação)
                  needIndicator(iconPath: 'assets/Icon_fé.jpg', value: hunger),
                  SizedBox(width: isSmallScreen ? 4 : 8),
                  needIndicator(
                    iconPath: 'assets/Icon_entretenimento.jpg',
                    value: happiness,
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 8),
                  needIndicator(
                    iconPath: 'assets/Icon_fervor.jpg',
                    value: energy,
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 8),
                  needIndicator(
                    iconPath: 'assets/Icon_vitalidade.jpg',
                    value: vitality,
                  ),
                ],
              ),
            );
          },
        ),
        centerTitle: true,
      ),

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Igreja';
      case 1:
        return 'Brincar';
      case 2:
        return 'Dormir';
      case 3:
        return 'Vitalidade';
      default:
        return '';
    }
  }
}
