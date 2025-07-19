import 'package:flutter/material.dart';

class ShopPage extends StatelessWidget {
  final Function(Map<String, dynamic>) onBuyPotion;
  final int currentCoins;
  
  const ShopPage({
    super.key,
    required this.onBuyPotion,
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
    // Recebe o inventário de skins já compradas do parâmetro
    final List<Map<String, dynamic>>? inventorySkins = ModalRoute.of(context)?.settings.arguments as List<Map<String, dynamic>>?;
    final boughtNames = inventorySkins?.map((s) => s['name'] as String).toSet() ?? {};
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
    // Filtra as skins que já foram compradas
    final availableSkins = skins.where((skin) => !boughtNames.contains(skin['name'])).toList();

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
      body: availableSkins.isEmpty
        ? Center(
            child: Text(
              '(mais skins em breve...)',
              style: TextStyle(
                color: Color(0xFFb29c48),
                fontFamily: 'Pixel',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isTablet = screenWidth > 600;
              final itemWidth = isTablet ? 300.0 : screenWidth * 0.85;
              final itemHeight = isTablet ? 140.0 : 120.0;
              final imageSize = isTablet ? 80.0 : 60.0;
              final fontSize = isTablet ? 20.0 : 16.0;
              final descFontSize = isTablet ? 14.0 : 12.0;
              return ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40.0 : 20.0,
                  vertical: 20.0,
                ),
                itemCount: availableSkins.length,
                itemBuilder: (context, index) {
                  final skin = availableSkins[index];
                  return Container(
                    width: itemWidth,
                    height: itemHeight,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFb29c48).withOpacity(0.3),
                          Color(0xFFb29c48).withOpacity(0.2),
                          Color(0xFFb29c48).withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFb29c48),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Color(0xFFb29c48).withOpacity(0.5),
                          blurRadius: 12,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Imagem da skin
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
                          // Botão de compra e 1/1
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  onBuyPotion(skin);
                                  // Remove da lista imediatamente
                                  Navigator.of(context).pop();
                                },
                                child: Text('Comprar'),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '1/1',
                                style: TextStyle(
                                  color: Color(0xFFb29c48),
                                  fontFamily: 'Pixel',
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 14 : 12,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 2,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _formatPrice(skin['price'] as int),
                                style: TextStyle(
                                  color: Color(0xFFb29c48),
                                  fontFamily: 'Pixel',
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 14 : 12,
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
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}
