import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dao/postvitamdao.dart';
import 'models/pet_status.dart';
import 'shop_page.dart';

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
  int coins = 1250; // Exemplo de moedas
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

  // Botão personalizado estilo Blasphemous
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

  // Setas de navegação estilo Blasphemous
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
        final iconSize = screenWidth < 600 ? 48.0 : 56.0; // Aumentado
        final barWidth = screenWidth < 600 ? 50.0 : 60.0; // Aumentado
        final barHeight = screenWidth < 600 ? 8.0 : 10.0; // Aumentado

        return Container(
          padding: EdgeInsets.all(8),
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
              const SizedBox(height: 6),
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
                    value: value / 100,
                    backgroundColor: Color(0xFF2C1810),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
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

              // Indicadores de status (fora da AppBar, abaixo dela)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      needIndicator(
                        iconPath: 'assets/Icon_fé.jpg',
                        value: hunger,
                      ),
                      needIndicator(
                        iconPath: 'assets/Icon_entretenimento.jpg',
                        value: happiness,
                      ),
                      needIndicator(
                        iconPath: 'assets/Icon_fervor.jpg',
                        value: energy,
                      ),
                      needIndicator(
                        iconPath: 'assets/Icon_vitalidade.jpg',
                        value: vitality,
                      ),
                    ],
                  ),
                ),
              ),

              // Navegação e título
              Positioned(
                top: screenHeight * 0.25,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNavigationArrow(
                      icon: Icons.arrow_left,
                      size: arrowSize,
                      onPressed: () {
                        setState(() {
                          _selectedIndex =
                              (_selectedIndex - 1 + _pages.length) %
                              _pages.length;
                          _pageController.jumpToPage(_selectedIndex);
                        });
                      },
                    ),
                    SizedBox(width: 24),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xFFb29c48), width: 2),
                      ),
                      child: Text(
                        _getPageTitle(_selectedIndex),
                        style: TextStyle(
                          fontSize: screenWidth < 600 ? 18 : 24,
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
                    SizedBox(width: 24),
                    _buildNavigationArrow(
                      icon: Icons.arrow_right,
                      size: arrowSize,
                      onPressed: () {
                        setState(() {
                          _selectedIndex = (_selectedIndex + 1) % _pages.length;
                          _pageController.jumpToPage(_selectedIndex);
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Personagem centralizado
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
                    SizedBox(height: screenHeight * 0.005),
                    // Botão de ação estilo Blasphemous
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
                      'assets/Icon_espada.png',
                      width: screenWidth < 600 ? 48 : 64,
                      height: screenWidth < 600 ? 48 : 64,
                    ),
                    onPressed: () {
                      // ação da espada
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
                          builder: (context) => const ShopPage(),
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
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Título
              Text(
                'Post Vitam',
                style: TextStyle(
                  color: Color(0xFFb29c48),
                  fontSize: 20,
                  fontFamily: 'Pixel',
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Contador de moedas
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFFb29c48), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/contador_moedas.png', // Adicione sua imagem de moeda aqui
                      width: 20,
                      height: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '$coins',
                      style: TextStyle(
                        color: Color(0xFFb29c48),
                        fontSize: 16,
                        fontFamily: 'Pixel',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
