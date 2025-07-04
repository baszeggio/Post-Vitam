import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stickman Pet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Penitente Pet'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  int hunger = 50;
  int happiness = 50;
  int energy = 50;
  int vitality = 50;
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  late AnimationController _penitenteController;
  late Animation<int> _penitenteAnimation;

  @override
  void initState() {
    super.initState();
    _penitenteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _penitenteAnimation = IntTween(begin: 1, end: 2).animate(_penitenteController);
  }

  @override
  void dispose() {
    _penitenteController.dispose();
    super.dispose();
  }

  void feed() {
    setState(() {
      hunger = (hunger + 10).clamp(0, 100);
      vitality = (vitality + 2).clamp(
        0,
        100,
      ); // Exemplo: alimentar aumenta vitalidade
    });
  }

  void play() {
    setState(() {
      happiness = (happiness + 10).clamp(0, 100);
      energy = (energy - 5).clamp(0, 100);
      vitality = (vitality + 3).clamp(
        0,
        100,
      ); // Exemplo: brincar aumenta vitalidade
    });
  }

  void sleep() {
    setState(() {
      energy = (energy + 15).clamp(0, 100);
      hunger = (hunger - 5).clamp(0, 100);
      vitality = (vitality + 5).clamp(
        0,
        100,
      ); // Exemplo: dormir aumenta vitalidade
    });
  }

  Widget _stickmanAndStatus(VoidCallback action, String actionLabel) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Estatísticas em duas linhas, duas por linha
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/Icon_fé.jpg', width: 24, height: 24),
            const SizedBox(width: 8),
            Text('Fé: $hunger', style: const TextStyle(color: Color(0xFFb29c48))),
            const SizedBox(width: 24),
            Image.asset('assets/Icon_entretenimento.jpg', width: 24, height: 24),
            const SizedBox(width: 8),
            Text('Entretenimento: $happiness', style: const TextStyle(color: Color(0xFFb29c48))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/Icon_fervor.jpg', width: 24, height: 24),
            const SizedBox(width: 8),
            Text('Fervor: $energy', style: const TextStyle(color: Color(0xFFb29c48))),
            const SizedBox(width: 24),
            Image.asset('assets/Icon_vitalidade.jpg', width: 24, height: 24),
            const SizedBox(width: 8),
            Text('Vitalidade: $vitality', style: const TextStyle(color: Color(0xFFb29c48))),
          ],
        ),
        const SizedBox(height: 30),
        // Botão de ação acima do boneco
        ElevatedButton(
          onPressed: action,
          child: Text(actionLabel, style: const TextStyle(color: Color(0xFFb29c48))),
        ),
        const SizedBox(height: 20),
        // Boneco maior
        AnimatedBuilder(
          animation: _penitenteAnimation,
          builder: (context, child) {
            return Image.asset(
              'assets/Penitente_${_penitenteAnimation.value}.png',
              width: 220,
              height: 400,
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  List<Widget> get _pages => [
    // Tela de Fé com background_igr
    Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Image.asset(
              'assets/background_igr.png',
              width: 1920,
              height: 1080,
              alignment: Alignment.center,
            ),
          ),
        ),
        _stickmanAndStatus(feed, 'Confessar'),
        // Botão loja no canto inferior esquerdo
        Positioned(
          left: 16,
          bottom: 16,
          child: IconButton(
            icon: Image.asset('assets/Icon_loja.png', width: 40, height: 40),
            onPressed: () {
              // ação da loja aqui
            },
          ),
        ),
      ],
    ),
    // Tela de Entretenimento com background_cav
    Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Image.asset(
              'assets/background_cav.png',
              width: 1920,
              height: 1080,
              alignment: Alignment.center,
            ),
          ),
        ),
        _stickmanAndStatus(play, 'Entreter'),
        Positioned(
          left: 16,
          bottom: 16,
          child: IconButton(
            icon: Image.asset('assets/Icon_loja.png', width: 40, height: 40),
            onPressed: () {
              // ação da loja aqui
            },
          ),
        ),
      ],
    ),
    // Tela de Dormir com background_mon
    Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Image.asset(
              'assets/background_mon.png',
              width: 1920,
              height: 1080,
              alignment: Alignment.center,
            ),
          ),
        ),
        _stickmanAndStatus(sleep, 'Descansar'),
        Positioned(
          left: 16,
          bottom: 16,
          child: IconButton(
            icon: Image.asset('assets/Icon_loja.png', width: 40, height: 40),
            onPressed: () {
              // ação da loja aqui
            },
          ),
        ),
      ],
    ),
    // Tela de Vitalidade com background_alb
    Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Image.asset(
              'assets/background_alb.png',
              width: 1920,
              height: 1080,
              alignment: Alignment.center,
            ),
          ),
        ),
        _stickmanAndStatus(() {
          setState(() {
            vitality = (vitality + 10).clamp(0, 100);
          });
        }, 'Aumentar Vitalidade'),
        Positioned(
          left: 16,
          bottom: 16,
          child: IconButton(
            icon: Image.asset('assets/Icon_loja.png', width: 40, height: 40),
            onPressed: () {
              // ação da loja aqui
            },
          ),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leadingWidth: 10, // Reduz a largura do leading para centralizar mais
        leading: null, // Remove o leading para liberar espaço
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícones centralizados
            Image.asset('assets/faith.jpeg', width: 28, height: 28),
            const SizedBox(width: 4),
            Image.asset('assets/entertainment.jpeg', width: 28, height: 28),
            const SizedBox(width: 4),
            Image.asset('assets/fervor.jpeg', width: 28, height: 28),
            const SizedBox(width: 4),
            Image.asset('assets/vitality.jpeg', width: 28, height: 28),
            const SizedBox(width: 16),
            // Título e navegação
            IconButton(
              icon: const Icon(Icons.arrow_left),
              color: Colors.white,
              onPressed: () {
                setState(() {
                  _selectedIndex =
                      (_selectedIndex - 1 + _pages.length) % _pages.length;
                  _pageController.jumpToPage(_selectedIndex);
                });
              },
            ),
            const SizedBox(width: 8),
            Text(
              _getPageTitle(_selectedIndex),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_right),
              color: Colors.white,
              onPressed: () {
                setState(() {
                  _selectedIndex = (_selectedIndex + 1) % _pages.length;
                  _pageController.jumpToPage(_selectedIndex);
                });
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // impede deslizar
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left, size: 32),
              color: Colors.deepPurple,
              onPressed: () {
                setState(() {
                  _selectedIndex =
                      (_selectedIndex - 1 + _pages.length) % _pages.length;
                  _pageController.jumpToPage(_selectedIndex);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right, size: 32),
              color: Colors.deepPurple,
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
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Fé';
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

class StickmanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors
          .blue // Alterado para azul para melhor visibilidade
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Cabeça
    canvas.drawCircle(Offset(size.width / 2, 30), 20, paint);
    // Corpo
    canvas.drawLine(
      Offset(size.width / 2, 50),
      Offset(size.width / 2, 120),
      paint,
    );
    // Braço esquerdo
    canvas.drawLine(
      Offset(size.width / 2, 70),
      Offset(size.width / 2 - 30, 100),
      paint,
    );
    // Braço direito
    canvas.drawLine(
      Offset(size.width / 2, 70),
      Offset(size.width / 2 + 30, 100),
      paint,
    );
    // Perna esquerda
    canvas.drawLine(
      Offset(size.width / 2, 120),
      Offset(size.width / 2 - 20, 170),
      paint,
    );
    // Perna direita
    canvas.drawLine(
      Offset(size.width / 2, 120),
      Offset(size.width / 2 + 20, 170),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
