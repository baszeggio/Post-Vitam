import 'package:flutter/material.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final potions = [
      {
        'img': 'assets/Frasco_1.png',
        'name': 'Frasco Pequeno',
        'desc': 'Aumenta 1/4 da vitalidade do Penitente.',
        'price': 100,
      },
      {
        'img': 'assets/Frasco_2.png',
        'name': 'Frasco Médio',
        'desc': 'Restaura 40% da vitalidade total do Peninente.',
        'price': 120,
      },
      {
        'img': 'assets/Frasco_3.png',
        'name': 'Frasco Grande',
        'desc': 'Aumenta 3/4 da vitalidade do Penitente .',
        'price': 150,
      },
      {
        'img': 'assets/Frasco_4.png',
        'name': 'Frasco do Milagre',
        'desc': 'Restaura completamente a vitalidade do Penitente.',
        'price': 200,
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
                  'Loja',
                  style: TextStyle(
                    color: Color(0xFFb29c48),
                    fontFamily: 'Pixel',
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
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
                  children: potions.map((potion) {
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
                            potion['img'] as String,
                            width: 64,
                            height: 64,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  potion['name'] as String,
                                  style: const TextStyle(
                                    color: Color(0xFFb29c48),
                                    fontFamily: 'Pixel',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  potion['desc'] as String,
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
                                '${potion['price']}',
                                style: const TextStyle(
                                  color: Color(0xFFb29c48),
                                  fontFamily: 'Pixel',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFb29c48),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Pixel',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  // Lógica de compra aqui
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Você comprou ${potion['name']}!',
                                      ),
                                      backgroundColor: Colors.black87,
                                    ),
                                  );
                                },
                                child: const Text('Comprar'),
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
