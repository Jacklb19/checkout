import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/card_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'payment_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cardNumber TEXT NOT NULL,
        expiryMonth TEXT NOT NULL,
        expiryYear TEXT NOT NULL,
        cvv TEXT NOT NULL,
        cardHolder TEXT NOT NULL,
        paymentMethod TEXT NOT NULL
      )
    ''');
  }

  // Insert card
  Future<int> insertCard(CardModel card) async {
    final db = await database;
    return await db.insert('cards', card.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get the saved card (only one card saved)
  Future<CardModel?> getSavedCard() async {
    final db = await database;
    final maps = await db.query('cards', limit: 1, orderBy: 'id DESC');
    if (maps.isEmpty) return null;
    return CardModel.fromMap(maps.first);
  }

  // Check if a card exists
  Future<bool> hasCard() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM cards'));
    return (count ?? 0) > 0;
  }

  // Delete all cards
  Future<void> deleteCards() async {
    final db = await database;
    await db.delete('cards');
  }

  // Update card
  Future<int> updateCard(CardModel card) async {
    final db = await database;
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }
}