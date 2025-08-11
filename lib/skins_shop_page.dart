import 'package:flutter/material.dart';

class SkinsShopPage extends StatelessWidget {
  final Future<bool> Function(Map<String, dynamic>) onBuySkin;
  final int currentCoins;
  
  const SkinsShopPage({
    super.key,
    required this.onBuySkin,
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
    final skins = [
      {
        'img': 'assets/Skin_Aqua_1.png',
        'img2': 'assets/Skin_Aqua_2.png',
        'name': 'Skin Aqua',
        'desc': 'O visual aqua do Penitente.',
        'price': 3000,
      },
      {
        'img': 'assets/Skin_Silver_1.png',
        'img2': 'assets/Skin_Silver_2.png',
        'name': 'Skin Silver',
        'desc': 'O visual prateado do Penitente.',
        'price': 5000,
      },
      {
        'img': 'assets/Skin_Gold_1.png',
        'img2': 'assets/Skin_Gold_2.png',
        'name': 'Skin Gold',
        'desc': 'O visual dourado do Penitente.',
        'price': 8000,
      },
    ];


    final List<Map<String, dynamic>>? inventorySkins = ModalRoute.of(context)?.settings.arguments as List<Map<String, dynamic>>?;
    final boughtNames = inventorySkins?.map((s) => s['name'] as String).toSet() ?? {};
    
    final availableSkins = skins.where((skin) => !boughtNames.contains(skin['name'])).toList();

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
              'Loja de Skins',
              style: TextStyle(
                color: Color(0xFFb29c48),
                fontFamily: 'Pixel',
                fontWeight: FontWeight.bold,
                fontSize: 20,
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
                      fontSize: 16,
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
      body: availableSkins.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_clock,
                    color: Color(0xFFb29c48),
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Você já comprou todas as skins!',
                    style: TextStyle(
                      color: Color(0xFFb29c48),
                      fontFamily: 'Pixel',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mais skins em breve...',
                    style: TextStyle(
                      color: Color(0xFFb29c48).withOpacity(0.7),
                      fontFamily: 'Pixel',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              itemCount: availableSkins.length,
              itemBuilder: (context, index) {
                final skin = availableSkins[index];
                return Container(
                  width: double.infinity,
                  height: 120,
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final int itemPrice = skin['price'] as int;
                        if (currentCoins >= itemPrice) {
                          final ok = await onBuySkin(skin);
                          if (ok) {
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
                            
                            Navigator.of(context).pop();
                          }
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
                            
                            Container(
                              width: 60,
                              height: 60,
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
                                      fontSize: 18,
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
                                      fontSize: 14,
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
                            
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                    _formatPrice(skin['price'] as int),
                                    style: TextStyle(
                                      color: Color(0xFFb29c48),
                                      fontFamily: 'Pixel',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Image.asset('assets/Icon_cifrao.png', width: 24, height: 24),
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
            ),
    );
  }
}
