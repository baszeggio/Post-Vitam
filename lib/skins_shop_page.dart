import 'package:flutter/material.dart';

class SkinsShopPage extends StatelessWidget {
  final Function(Map<String, dynamic>) onBuySkin;
  final int currentCoins;
  
  const SkinsShopPage({
    super.key,
    required this.onBuySkin,
    required this.currentCoins,
  });

  // Formatar números de dinheiro (1000+ vira X.XK)
  String _formatPrice(int amount) {
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

  @override
  Widget build(BuildContext context) {
    final skins = [
      {
        'img': 'assets/Skin_Aqua_1.png',
        'name': 'Skin Aqua',
        'desc': 'O visual aqua do Penitente.',
        'price': 3000,
      },
      {
        'img': 'assets/Skin_Silver_1.png',
        'name': 'Skin Silver',
        'desc': 'O visual prateado do Penitente.',
        'price': 5000,
      },
      {
        'img': 'assets/Skin_Gold_1.png',
        'name': 'Skin Gold',
        'desc': 'O visual dourado do Penitente.',
        'price': 8000,
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
          // Background com overlay escuro
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/loja_interior.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          // Conteúdo principal
          SafeArea(
            child: Column(
              children: [
                // Espaçamento superior
                SizedBox(height: 20),
                // Grid responsivo de skins
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final screenHeight = constraints.maxHeight;
                      final isTablet = screenWidth > 600;
                      
                      // Calcular tamanhos responsivos
                      final itemWidth = isTablet ? 300.0 : screenWidth * 0.85;
                      final itemHeight = isTablet ? 140.0 : 120.0;
                      final imageSize = isTablet ? 80.0 : 60.0;
                      final fontSize = isTablet ? 20.0 : 16.0;
                      final descFontSize = isTablet ? 14.0 : 12.0;
                      
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 40.0 : 20.0,
                          vertical: 20.0,
                        ),
                        child: Column(
                          children: skins.map((skin) {
                            return Container(
                              width: itemWidth,
                              height: itemHeight,
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF2C1810).withOpacity(0.95),
                                    Color(0xFF4A2C1A).withOpacity(0.95),
                                    Color(0xFF2C1810).withOpacity(0.95),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFFb29c48),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: Color(0xFFb29c48).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    // Verificar se tem dinheiro suficiente
                                    if (currentCoins >= (skin['price'] as int)) {
                                      // Comprar a skin
                                      onBuySkin(skin);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Você comprou ${skin['name']}!',
                                            style: TextStyle(
                                              fontFamily: 'Pixel',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor: Color(0xFFb29c48),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } else {
                                      // Dinheiro insuficiente
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Moedas insuficientes!',
                                            style: TextStyle(
                                              fontFamily: 'Pixel',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Imagem da skin com efeito
                                        Container(
                                          width: imageSize,
                                          height: imageSize,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.4),
                                                blurRadius: 6,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.asset(
                                              skin['img'] as String,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        // Informações da skin
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                skin['name'] as String,
                                                style: TextStyle(
                                                  color: Color(0xFFb29c48),
                                                  fontFamily: 'Pixel',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: fontSize,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 3,
                                                      offset: Offset(1, 1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                skin['desc'] as String,
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontFamily: 'Pixel',
                                                  fontSize: descFontSize,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 2,
                                                      offset: Offset(1, 1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Preço com design melhorado
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFFb29c48).withOpacity(0.2),
                                                Color(0xFFb29c48).withOpacity(0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Color(0xFFb29c48).withOpacity(0.5),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                'assets/contador_moedas.png',
                                                width: isTablet ? 28 : 24,
                                                height: isTablet ? 28 : 24,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                _formatPrice(skin['price'] as int),
                                                style: TextStyle(
                                                  color: Color(0xFFb29c48),
                                                  fontFamily: 'Pixel',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isTablet ? 18 : 14,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 2,
                                                      offset: Offset(1, 1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
