import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../models/pet_status.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    if (dart.library.html) 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _databaseVersion = 3; // Incrementar versão para forçar recriação

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'pet_status_v3.db'); // Novo nome do banco
      
      print('Inicializando banco de dados em: $path');
      
      return await openDatabase(
        path, 
        version: _databaseVersion, 
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onOpen: (db) {
          print('Banco de dados aberto com sucesso');
        },
      );
    } catch (e) {
      print('Erro ao inicializar banco de dados: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    print('Criando tabelas...');
    
    try {
      // Tabela pet_status
      await db.execute('''
        CREATE TABLE pet_status (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          hunger INTEGER NOT NULL,
          happiness INTEGER NOT NULL,
          energy INTEGER NOT NULL,
          vitality INTEGER NOT NULL,
          coins INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Tabela inventory
      await db.execute('''
        CREATE TABLE inventory (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_type TEXT NOT NULL,
          item_name TEXT NOT NULL,
          item_img TEXT NOT NULL,
          item_desc TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          equipped BOOLEAN NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      print('Tabelas criadas com sucesso. Inserindo dados iniciais...');
      
      // Dados iniciais do pet
      await db.insert('pet_status', {
        'id': 1,
        'hunger': 50,
        'happiness': 50,
        'energy': 50,
        'vitality': 50,
        'coins': 20000,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Dados iniciais do inventário (apenas skin padrão)
      await db.insert('inventory', {
        'item_type': 'skin',
        'item_name': 'Skin Padrão',
        'item_img': 'assets/Penitente_1.png',
        'item_desc': 'O visual padrão do Penitente.',
        'quantity': 1,
        'equipped': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('Dados iniciais inseridos com sucesso');
    } catch (e) {
      print('Erro ao criar banco de dados: $e');
      rethrow;
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('Atualizando banco de dados de v$oldVersion para v$newVersion');
    
    if (oldVersion < 3) {
      // Recriar tabelas para nova versão
      await db.execute('DROP TABLE IF EXISTS pet_status');
      await db.execute('DROP TABLE IF EXISTS inventory');
      await _createDB(db, newVersion);
    }
  }

  Future<void> insertPetStatus(PetStatus status) async {
    try {
      final db = await database;
      print('Inserindo status: ${status.toString()}');
      
      await db.insert('pet_status', {
        ...status.toMap(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      
      print('Status inserido com sucesso');
    } catch (e) {
      print('Erro ao inserir status: $e');
      rethrow;
    }
  }

  Future<PetStatus?> getPetStatus() async {
    try {
      final db = await database;
      print('Buscando status do pet...');
      
      final List<Map<String, dynamic>> maps = await db.query(
        'pet_status',
        where: 'id = ?',
        whereArgs: [1],
      );

      print('Resultado da busca: ${maps.length} registros encontrados');
      
      if (maps.isNotEmpty) {
        final status = PetStatus.fromMap(maps.first);
        print('Status carregado: ${status.toString()}');
        return status;
      }
      
      print('Nenhum status encontrado');
      return null;
    } catch (e) {
      print('Erro ao buscar status: $e');
      rethrow;
    }
  }

  Future<void> updatePetStatus(PetStatus status) async {
    try {
      final db = await database;
      print('Atualizando status: ${status.toString()}');

      final existing = await getPetStatus();
      final createdAt = existing?.createdAt ?? DateTime.now();

      final result = await db.update(
        'pet_status',
        {
          'hunger': status.hunger,
          'happiness': status.happiness,
          'energy': status.energy,
          'vitality': status.vitality,
          'coins': status.coins,
          'created_at': createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [1],
      );
      
      print('Status atualizado. Linhas afetadas: $result');
    } catch (e) {
      print('Erro ao atualizar status: $e');
      rethrow;
    }
  }

  Future<void> savePetStatus({
    required int hunger,
    required int happiness,
    required int energy,
    required int vitality,
    required int coins,
  }) async {
    try {
      final db = await database;
      print('Salvando status - Hunger: $hunger, Happiness: $happiness, Energy: $energy, Vitality: $vitality, Coins: $coins');

      // Verificar se já existe um registro
      final existing = await getPetStatus();

      if (existing != null) {
        print('Atualizando registro existente...');
        final result = await db.update(
          'pet_status',
          {
            'hunger': hunger,
            'happiness': happiness,
            'energy': energy,
            'vitality': vitality,
            'coins': coins,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [1],
        );
        print('Registro atualizado. Linhas afetadas: $result');
      } else {
        print('Criando novo registro...');
        final result = await db.insert('pet_status', {
          'id': 1,
          'hunger': hunger,
          'happiness': happiness,
          'energy': energy,
          'vitality': vitality,
          'coins': coins,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        print('Novo registro criado. ID: $result');
      }
      
      // Verificar se foi salvo corretamente
      final savedStatus = await getPetStatus();
      if (savedStatus != null) {
        print('Verificação: Status salvo corretamente - Coins: ${savedStatus.coins}');
      } else {
        print('ERRO: Status não foi salvo corretamente!');
      }
    } catch (e) {
      print('Erro ao salvar status: $e');
      rethrow;
    }
  }

  Future<void> closeDB() async {
    try {
      final db = await database;
      await db.close();
      _database = null;
      print('Banco de dados fechado');
    } catch (e) {
      print('Erro ao fechar banco de dados: $e');
    }
  }

  // Método para calcular degradação automática dos status
  Future<PetStatus> calculateDegradation() async {
    try {
      final currentStatus = await getPetStatus();
      if (currentStatus == null) {
        print('Nenhum status encontrado, criando novo...');
        // Se não há dados, criar um novo registro com valores padrão
        final newStatus = PetStatus(
          hunger: 50,
          happiness: 50,
          energy: 50,
          vitality: 50,
          coins: 20000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await insertPetStatus(newStatus);
        return newStatus;
      }

      final now = DateTime.now();
      final lastUpdate = currentStatus.updatedAt ?? now;
      final timeDifference = now.difference(lastUpdate);

      print('--- DEBUG DEGRADAÇÃO ---');
      print('Status ANTES: ${currentStatus.toString()}');
      print('updated_at: $lastUpdate');
      print('now: $now');
      print('Diferença em minutos: ${timeDifference.inMinutes}');

      // Nova lógica: sempre diminui 10 pontos de cada status
      int newHunger = (currentStatus.hunger - 10).clamp(0, 100);
      int newHappiness = (currentStatus.happiness - 10).clamp(0, 100);
      int newEnergy = (currentStatus.energy - 10).clamp(0, 100);
      int newVitality = (currentStatus.vitality - 10).clamp(0, 100);

      print('Valores calculados:');
      print('newHunger: $newHunger');
      print('newHappiness: $newHappiness');
      print('newEnergy: $newEnergy');
      print('newVitality: $newVitality');

      final degradedStatus = PetStatus(
        id: currentStatus.id,
        hunger: newHunger,
        happiness: newHappiness,
        energy: newEnergy,
        vitality: newVitality,
        coins: currentStatus.coins, // Preservar moedas
        createdAt: currentStatus.createdAt,
        updatedAt: now,
      );

      print('Status DEPOIS: ${degradedStatus.toString()}');
      print('--- FIM DEBUG DEGRADAÇÃO ---');

      // Salvar o status degradado no banco
      await updatePetStatus(degradedStatus);

      return degradedStatus;
    } catch (e) {
      print('Erro ao calcular degradação: $e');
      rethrow;
    }
  }

  // Novo método: degradação proporcional ao tempo offline
  Future<PetStatus> calculateDegradationOffline() async {
    try {
      final currentStatus = await getPetStatus();
      if (currentStatus == null) {
        print('Nenhum status encontrado, criando novo...');
        final newStatus = PetStatus(
          hunger: 50,
          happiness: 50,
          energy: 50,
          vitality: 50,
          coins: 20000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await insertPetStatus(newStatus);
        return newStatus;
      }
      final now = DateTime.now();
      final lastUpdate = currentStatus.updatedAt ?? now;
      final timeDifference = now.difference(lastUpdate);
      final minutesPassed = timeDifference.inMinutes;
      print('--- DEBUG DEGRADAÇÃO OFFLINE ---');
      print('Status ANTES: ${currentStatus.toString()}');
      print('updated_at: $lastUpdate');
      print('now: $now');
      print('Diferença em minutos: $minutesPassed');
      // Degrada -10 pontos por minuto offline
      int newHunger = (currentStatus.hunger - (minutesPassed * 10)).clamp(0, 100);
      int newHappiness = (currentStatus.happiness - (minutesPassed * 10)).clamp(0, 100);
      int newEnergy = (currentStatus.energy - (minutesPassed * 10)).clamp(0, 100);
      int newVitality = (currentStatus.vitality - (minutesPassed * 10)).clamp(0, 100);
      print('Valores calculados OFFLINE:');
      print('newHunger: $newHunger');
      print('newHappiness: $newHappiness');
      print('newEnergy: $newEnergy');
      print('newVitality: $newVitality');
      final degradedStatus = PetStatus(
        id: currentStatus.id,
        hunger: newHunger,
        happiness: newHappiness,
        energy: newEnergy,
        vitality: newVitality,
        coins: currentStatus.coins,
        createdAt: currentStatus.createdAt,
        updatedAt: now,
      );
      print('Status DEPOIS OFFLINE: ${degradedStatus.toString()}');
      print('--- FIM DEBUG DEGRADAÇÃO OFFLINE ---');
      await updatePetStatus(degradedStatus);
      return degradedStatus;
    } catch (e) {
      print('Erro ao calcular degradação offline: $e');
      rethrow;
    }
  }

  // Degradação fixa para uso online (timer)
  Future<PetStatus> calculateDegradationOnline() async {
    try {
      final currentStatus = await getPetStatus();
      if (currentStatus == null) {
        print('Nenhum status encontrado, criando novo...');
        final newStatus = PetStatus(
          hunger: 50,
          happiness: 50,
          energy: 50,
          vitality: 50,
          coins: 20000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await insertPetStatus(newStatus);
        return newStatus;
      }
      final now = DateTime.now();
      print('--- DEBUG DEGRADAÇÃO ONLINE ---');
      print('Status ANTES: ${currentStatus.toString()}');
      // Agora diminui apenas 1 ponto de cada status
      int newHunger = (currentStatus.hunger - 1).clamp(0, 100);
      int newHappiness = (currentStatus.happiness - 1).clamp(0, 100);
      int newEnergy = (currentStatus.energy - 1).clamp(0, 100);
      int newVitality = (currentStatus.vitality - 1).clamp(0, 100);
      print('Valores calculados ONLINE:');
      print('newHunger: $newHunger');
      print('newHappiness: $newHappiness');
      print('newEnergy: $newEnergy');
      print('newVitality: $newVitality');
      final degradedStatus = PetStatus(
        id: currentStatus.id,
        hunger: newHunger,
        happiness: newHappiness,
        energy: newEnergy,
        vitality: newVitality,
        coins: currentStatus.coins,
        createdAt: currentStatus.createdAt,
        updatedAt: now,
      );
      print('Status DEPOIS ONLINE: ${degradedStatus.toString()}');
      print('--- FIM DEBUG DEGRADAÇÃO ONLINE ---');
      await updatePetStatus(degradedStatus);
      return degradedStatus;
    } catch (e) {
      print('Erro ao calcular degradação online: $e');
      rethrow;
    }
  }

  // Método para aplicar degradação e retornar status atualizado
  Future<PetStatus> applyDegradationAndGetStatus() async {
    return await calculateDegradation();
  }

  // Método para carregar status sem aplicar degradação
  Future<PetStatus> loadPetStatusWithoutDegradation() async {
    try {
      final currentStatus = await getPetStatus();
      if (currentStatus == null) {
        print('Nenhum status encontrado, retornando valores padrão');
        return PetStatus(
          hunger: 50,
          happiness: 50,
          energy: 50,
          vitality: 50,
          coins: 20000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      print('Status carregado sem degradação: ${currentStatus.toString()}');
      return currentStatus;
    } catch (e) {
      print('Erro ao carregar status sem degradação: $e');
      rethrow;
    }
  }

  // Método para verificar integridade do banco
  Future<void> checkDatabaseIntegrity() async {
    try {
      final db = await database;
      final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      print('Tabelas no banco: ${tables.map((t) => t['name']).toList()}');
      
      final petStatusCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pet_status'));
      print('Registros na tabela pet_status: $petStatusCount');
      
      final inventoryCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM inventory'));
      print('Registros na tabela inventory: $inventoryCount');
      
      if (petStatusCount! > 0) {
        final allRecords = await db.query('pet_status');
        print('Todos os registros pet_status: $allRecords');
      }
      
      if (inventoryCount! > 0) {
        final allInventory = await db.query('inventory');
        print('Todos os registros inventory: $allInventory');
      }
    } catch (e) {
      print('Erro ao verificar integridade: $e');
    }
  }

  // Métodos para gerenciar inventário
  Future<List<Map<String, dynamic>>> getInventory() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('inventory');
      
      return maps.map((map) => {
        'img': map['item_img'],
        'name': map['item_name'],
        'desc': map['item_desc'],
        'quantity': map['quantity'],
        'type': map['item_type'],
        'equipped': map['equipped'] == 1,
      }).toList();
    } catch (e) {
      print('Erro ao buscar inventário: $e');
      return [];
    }
  }

  Future<void> saveInventory(List<Map<String, dynamic>> potions, List<Map<String, dynamic>> skins) async {
    try {
      final db = await database;
      
      // Limpar inventário atual
      await db.delete('inventory');
      
      // Salvar poções
      for (var potion in potions) {
        await db.insert('inventory', {
          'item_type': 'potion',
          'item_name': potion['name'],
          'item_img': potion['img'],
          'item_desc': potion['desc'],
          'quantity': potion['quantity'],
          'equipped': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      // Salvar skins
      for (var skin in skins) {
        await db.insert('inventory', {
          'item_type': 'skin',
          'item_name': skin['name'],
          'item_img': skin['img'],
          'item_desc': skin['desc'],
          'quantity': skin['quantity'],
          'equipped': skin['equipped'] ? 1 : 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      print('Inventário salvo com sucesso');
    } catch (e) {
      print('Erro ao salvar inventário: $e');
    }
  }

  // Método para resetar o banco de dados para o estado inicial
  Future<void> resetDatabase() async {
    final db = await database;
    // Limpa inventário
    await db.delete('inventory');
    // Reseta status do pet
    await db.update(
      'pet_status',
      {
        'hunger': 50,
        'happiness': 50,
        'energy': 50,
        'vitality': 50,
        'coins': 20000,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
    // Garante skin padrão no inventário
    await db.insert('inventory', {
      'item_type': 'skin',
      'item_name': 'Skin Padrão',
      'item_img': 'assets/Penitente_1.png',
      'item_desc': 'O visual padrão do Penitente.',
      'quantity': 1,
      'equipped': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    print('Banco de dados resetado para o estado inicial.');
  }
}
