import 'package:flutter/material.dart';

class SkinsShopPage extends StatelessWidget {
  const SkinsShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final skins = [
      {
        'img': 'assets/Skin_Aqua_1.png',
        'name': 'Skin Aqua',
        'desc': 'Uma pele aquática para o Penitente.',
        'price': 300,
      },
      {
        'img': 'assets/Skin_Silver_1.png',
        'name': 'Skin Silver',
        'desc': 'Uma pele prateada para o Penitente.',
        'price': 500,
      },
      {
        'img': 'assets/Skin_Gold_1.png',
        'name': 'Skin Gold',
        'desc': 'Uma pele dourada para o Penitente.',
        'price': 800,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFb29c48), width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Faixa decorativa atrás do texto
              Positioned(
                top: 32,
                left: 32,
                right: 32,
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A2C1A), Color(0xFF2C1810)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFb29c48), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              // Título estilizado
              Positioned(
                top: 28,
                child: Text(
                  'Loja de Skins',
                  style: TextStyle(
                    color: Color(0xFFb29c48),
                    fontFamily: 'Pixel',
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              // Botão de voltar
              Positioned(
                left: 8,
                top: 28,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFFb29c48),
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Voltar',
                ),
              ),
            ],
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/loja_interior.png', fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: skins.map((skin) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFFb29c48), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            skin['img'] as String,
                            width: 64,
                            height: 64,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  skin['name'] as String,
                                  style: const TextStyle(
                                    color: Color(0xFFb29c48),
                                    fontFamily: 'Pixel',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  skin['desc'] as String,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Pixel',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          Column(
                            children: [
                              Image.asset(
                                'assets/contador_moedas.png',
                                width: 24,
                                height: 24,
                              ),
                              Text(
                                '${skin['price']}',
                                style: const TextStyle(
                                  color: Color(0xFFb29c48),
                                  fontFamily: 'Pixel',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
