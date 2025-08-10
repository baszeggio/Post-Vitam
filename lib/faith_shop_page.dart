import 'package:flutter/material.dart';

class FaithShopPage extends StatelessWidget {
  final bool Function(Map<String, dynamic>) onBuyPotion;
  final int currentCoins;

  const FaithShopPage({
    super.key,
    required this.onBuyPotion,
    required this.currentCoins,
  });

  
  String _formatPrice(int amount) {
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

  

  @override
  Widget build(BuildContext context) {
    final potions = [
      {
        'img': 'assets/Santa_Chaga_1.png',
        'name': 'Santa Chaga do Atrito',
        'desc': 'Restaura 15 pontos de fé.',
        'price': 1000,
      },
      {
        'img': 'assets/Santa_Chaga_2.png',
        'name': 'Santa Chaga da Contrição',
        'desc': 'Restaura 25 pontos de fé.',
        'price': 2000,
      },
      {
        'img': 'assets/Santa_Chaga_3.png',
        'name': 'Santa Chaga da Compunção',
        'desc': 'Restaura 40 pontos de fé.',
        'price': 3000,
      },
      {
        'img': 'assets/Santa_Chaga_4.png',
        'name': 'Santa Chagada da Abnegação',
        'desc': 'Restaura 100 pontos de fé.',
        'price': 5000,
      },
    ];

    return Scaffold(
      backgroundColor: Color(0xFF2C1810),
      appBar: AppBar(
        backgroundColor: Color(0xFF2C1810),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFFb29c48),
          size: 28,
        ),
        title: Row(
          children: [
            Text(
              'Ordem das Chagas',
              style: TextStyle(
                color: Color(0xFFb29c48),
                fontFamily: 'Pixel',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFb29c48), width: 1),
              ),
              child: Row(
                children: [
                  Text(
                    _formatPrice(currentCoins),
                    style: TextStyle(
                      color: Color(0xFFb29c48),
                      fontFamily: 'Pixel',
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 8),
                  Image.asset(
                    'assets/Icon_cifrao.png',
                    width: 20,
                    height: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isTablet = screenWidth > 600;

          final itemWidth = isTablet ? 300.0 : screenWidth * 0.85;
          final itemHeight = isTablet ? 120.0 : 100.0;
          final imageSize = isTablet ? 70.0 : 50.0;
          final fontSize = isTablet ? 18.0 : 14.0;
          final descFontSize = isTablet ? 12.0 : 10.0;

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40.0 : 20.0,
              vertical: 20.0,
            ),
            itemCount: potions.length,
            itemBuilder: (context, index) {
              final potion = potions[index];
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
                  border: Border.all(color: Color(0xFFb29c48), width: 3),
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final success = onBuyPotion(potion);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Você comprou ${potion['name']}!',
                              style: TextStyle(
                                fontFamily: 'Pixel',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Color(0xFFb29c48),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.of(context).pop();
                      } else {
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
                          // Imagem do frasco
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
                                potion['img'] as String,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          // Informações do frasco
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  potion['name'] as String,
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
                                  potion['desc'] as String,
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
                          // Preço
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Color(0xFFb29c48),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatPrice(potion['price'] as int),
                                  style: TextStyle(
                                    color: Color(0xFFb29c48),
                                    fontFamily: 'Pixel',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Image.asset('assets/Icon_cifrao.png', width: 16, height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
