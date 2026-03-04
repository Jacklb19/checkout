import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment_method_model.dart';

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
    final path = join(dbPath, 'payment_app_v2.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL UNIQUE,
        cardNumber TEXT,
        expiryMonth TEXT,
        expiryYear TEXT,
        cvv TEXT,
        cardHolder TEXT,
        paypalEmail TEXT,
        paypalPassword TEXT,
        walletPhone TEXT,
        walletPin TEXT,
        savedAt TEXT NOT NULL
      )
    ''');
  }

  // ─── SAVE / UPDATE ───────────────────────────────────────────────

  /// Guarda o actualiza el método para ese tipo (upsert por type)
  Future<void> upsertMethod(PaymentMethodModel method) async {
    final db = await database;
    final map = method.toMap()..['savedAt'] = DateTime.now().toIso8601String();
    map.remove('id');

    final existing = await db.query('payment_methods',
        where: 'type = ?', whereArgs: [method.type.key]);

    if (existing.isEmpty) {
      await db.insert('payment_methods', map);
    } else {
      await db.update('payment_methods', map,
          where: 'type = ?', whereArgs: [method.type.key]);
    }
  }

  // ─── READ ─────────────────────────────────────────────────────────

  /// Trae el método guardado para un tipo específico (null si no existe)
  Future<PaymentMethodModel?> getMethodByType(PaymentType type) async {
    final db = await database;
    final rows = await db.query('payment_methods',
        where: 'type = ?', whereArgs: [type.key]);
    if (rows.isEmpty) return null;
    return PaymentMethodModel.fromMap(rows.first);
  }

  /// Trae todos los métodos guardados
  Future<List<PaymentMethodModel>> getAllMethods() async {
    final db = await database;
    final rows =
    await db.query('payment_methods', orderBy: 'savedAt DESC');
    return rows.map((r) => PaymentMethodModel.fromMap(r)).toList();
  }

  /// ¿Existe un método guardado para este tipo?
  Future<bool> hasMethod(PaymentType type) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM payment_methods WHERE type = ?',
        [type.key]));
    return (count ?? 0) > 0;
  }

  // ─── DELETE ──────────────────────────────────────────────────────

  /// Elimina el método de un tipo
  Future<void> deleteMethod(PaymentType type) async {
    final db = await database;
    await db.delete('payment_methods',
        where: 'type = ?', whereArgs: [type.key]);
  }

  /// Elimina todos los métodos guardados
  Future<void> deleteAllMethods() async {
    final db = await database;
    await db.delete('payment_methods');
  }

  // ─── DEBUG ───────────────────────────────────────────────────────

  /// Devuelve un mapa raw de todos los registros (para debug)
  Future<List<Map<String, dynamic>>> getRawRows() async {
    final db = await database;
    return await db.rawQuery(
        'SELECT id, type, savedAt FROM payment_methods ORDER BY savedAt DESC');
  }
}