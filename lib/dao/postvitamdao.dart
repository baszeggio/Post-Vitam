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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pet_status.db');

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pet_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hunger INTEGER NOT NULL,
        happiness INTEGER NOT NULL,
        energy INTEGER NOT NULL,
        vitality INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.insert('pet_status', {
      'id': 1,
      'hunger': 50,
      'happiness': 50,
      'energy': 50,
      'vitality': 50,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> insertPetStatus(PetStatus status) async {
    final db = await database;
    await db.insert('pet_status', {
      ...status.toMap(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<PetStatus?> getPetStatus() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pet_status',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (maps.isNotEmpty) {
      return PetStatus.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updatePetStatus(PetStatus status) async {
    final db = await database;

    final existing = await getPetStatus();
    final createdAt = existing?.createdAt ?? DateTime.now();

    await db.update(
      'pet_status',
      {
        'hunger': status.hunger,
        'happiness': status.happiness,
        'energy': status.energy,
        'vitality': status.vitality,
        'created_at': createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> savePetStatus({
    required int hunger,
    required int happiness,
    required int energy,
    required int vitality,
  }) async {
    final db = await database;

    // Verificar se já existe um registro
    final existing = await getPetStatus();

    if (existing != null) {
      await db.update(
        'pet_status',
        {
          'hunger': hunger,
          'happiness': happiness,
          'energy': energy,
          'vitality': vitality,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [1],
      );
    } else {
      await db.insert('pet_status', {
        'id': 1,
        'hunger': hunger,
        'happiness': happiness,
        'energy': energy,
        'vitality': vitality,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> closeDB() async {
    final db = await database;
    await db.close();
  }
}
