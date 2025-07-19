import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> potions;
  final List<Map<String, dynamic>> skins;
  final Function(int) onUsePotion;
  final Function(int) onEquipSkin;
  final VoidCallback onUpdate;
  
  const InventoryPage({
    super.key,
    required this.potions,
    required this.skins,
    required this.onUsePotion,
    required this.onEquipSkin,
    required this.onUpdate,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> get _skinsWithDefault {
    List<Map<String, dynamic>> skins = List<Map<String, dynamic>>.from(widget.skins);
    final int defaultIndex = skins.indexWhere((skin) => skin['name'] == 'Skin Padrão');
    if (defaultIndex == -1) {
      skins.insert(0, {
        'img': 'assets/Penitente_1.png',
        'name': 'Skin Padrão',
        'desc': 'O visual padrão do Penitente.',
        'quantity': 1,
        'type': 'skin',
        'equipped': true,
      });
    } else {
      for (var skin in skins) {
        skin['equipped'] = false;
      }
      skins[defaultIndex]['equipped'] = true;
    }
    return skins;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Formatar números de quantidade
  String _formatQuantity(int quantity) {
    if (quantity >= 1000) {
      double kValue = quantity / 1000.0;
      if (kValue == kValue.toInt()) {
        return '${kValue.toInt()}K';
      } else {
        return '${kValue.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}K';
      }
    }
    return quantity.toString();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Inventário',
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
                // Tabs
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFb29c48), width: 2),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFb29c48), Color(0xFFb29c48).withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Color(0xFFb29c48),
                    labelStyle: TextStyle(
                      fontFamily: 'Pixel',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontFamily: 'Pixel',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    tabs: [
                      Tab(text: 'Frascos'),
                      Tab(text: 'Skins'),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Conteúdo das tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPotionsTab(),
                      _buildSkinsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPotionsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600;
        
        final itemWidth = isTablet ? 300.0 : screenWidth * 0.85;
        final itemHeight = isTablet ? 120.0 : 100.0;
        final imageSize = isTablet ? 70.0 : 50.0;
        final fontSize = isTablet ? 18.0 : 14.0;
        final descFontSize = isTablet ? 12.0 : 10.0;
        
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 40.0 : 20.0,
            vertical: 20.0,
          ),
          child: Column(
            children: widget.potions.map((potion) {
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
                      // Usar frasco
                      final index = widget.potions.indexOf(potion);
                      if (index != -1) {
                        widget.onUsePotion(index);
                        // Forçar atualização da tela
                        widget.onUpdate();
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Você usou ${potion['name']}!',
                              style: TextStyle(
                                fontFamily: 'Pixel',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Color(0xFFb29c48),
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
                          // Quantidade
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
                                Icon(
                                  Icons.inventory,
                                  color: Color(0xFFb29c48),
                                  size: isTablet ? 24 : 20,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'x${_formatQuantity(potion['quantity'])}',
                                  style: TextStyle(
                                    color: Color(0xFFb29c48),
                                    fontFamily: 'Pixel',
                                    fontWeight: FontWeight.bold,
                                    fontSize: isTablet ? 16 : 12,
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
    );
  }

  Widget _buildSkinsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600;
        
        final itemWidth = isTablet ? 300.0 : screenWidth * 0.85;
        final itemHeight = isTablet ? 120.0 : 100.0;
        final imageSize = isTablet ? 70.0 : 50.0;
        final fontSize = isTablet ? 18.0 : 14.0;
        final descFontSize = isTablet ? 12.0 : 10.0;
        
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 40.0 : 20.0,
            vertical: 20.0,
          ),
          child: Column(
            children: _skinsWithDefault.map((skin) {
              final isEquipped = skin['equipped'] as bool;
              
              return Container(
                width: itemWidth,
                height: itemHeight,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEquipped 
                      ? [
                          Color(0xFFb29c48).withOpacity(0.3),
                          Color(0xFFb29c48).withOpacity(0.2),
                          Color(0xFFb29c48).withOpacity(0.3),
                        ]
                      : [
                          Color(0xFF2C1810).withOpacity(0.95),
                          Color(0xFF4A2C1A).withOpacity(0.95),
                          Color(0xFF2C1810).withOpacity(0.95),
                        ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEquipped ? Color(0xFFb29c48) : Color(0xFFb29c48).withOpacity(0.7),
                    width: isEquipped ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                    if (isEquipped)
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
                      final index = _skinsWithDefault.indexOf(skin);
                      if (skin['equipped'] == true) return;
                      widget.onEquipSkin(index);
                    },
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
                                Row(
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
                                    if (isEquipped) ...[
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xFFb29c48),
                                        size: 16,
                                      ),
                                    ],
                                  ],
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
                          // Status equipado
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
                                Icon(
                                  isEquipped ? Icons.check_circle : Icons.circle_outlined,
                                  color: Color(0xFFb29c48),
                                  size: isTablet ? 24 : 20,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  isEquipped ? 'Equipado' : 'Equipar',
                                  style: TextStyle(
                                    color: Color(0xFFb29c48),
                                    fontFamily: 'Pixel',
                                    fontWeight: FontWeight.bold,
                                    fontSize: isTablet ? 12 : 10,
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
    );
  }
} 