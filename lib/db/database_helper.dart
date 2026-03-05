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
    // v3: sin UNIQUE en type → múltiples métodos por tipo
    final path = join(dbPath, 'payment_app_v3.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE payment_methods (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        type    TEXT    NOT NULL,
        nickname TEXT,
        cardNumber    TEXT,
        expiryMonth   TEXT,
        expiryYear    TEXT,
        cvv           TEXT,
        cardHolder    TEXT,
        paypalEmail   TEXT,
        paypalPassword TEXT,
        walletPhone   TEXT,
        walletPin     TEXT,
        savedAt TEXT NOT NULL
      )
    ''');
  }

  // ─── INSERT ──────────────────────────────────────────────────────

  /// Inserta un nuevo método (siempre crea un registro nuevo)
  Future<int> insertMethod(PaymentMethodModel method) async {
    final db = await database;
    final map = method.toMap()
      ..remove('id')
      ..['savedAt'] = DateTime.now().toIso8601String();
    return await db.insert('payment_methods', map);
  }

  /// Actualiza un método existente por id
  Future<void> updateMethod(PaymentMethodModel method) async {
    assert(method.id != null, 'updateMethod requiere id');
    final db = await database;
    final map = method.toMap()
      ..['savedAt'] = DateTime.now().toIso8601String();
    await db.update('payment_methods', map,
        where: 'id = ?', whereArgs: [method.id]);
  }

  // ─── READ ─────────────────────────────────────────────────────────

  /// Todos los métodos guardados de un tipo (más reciente primero)
  Future<List<PaymentMethodModel>> getMethodsByType(PaymentType type) async {
    final db = await database;
    final rows = await db.query('payment_methods',
        where: 'type = ?', whereArgs: [type.key], orderBy: 'savedAt DESC');
    return rows.map(PaymentMethodModel.fromMap).toList();
  }

  /// Todos los métodos guardados sin filtro
  Future<List<PaymentMethodModel>> getAllMethods() async {
    final db = await database;
    final rows =
    await db.query('payment_methods', orderBy: 'savedAt DESC');
    return rows.map(PaymentMethodModel.fromMap).toList();
  }

  /// Total de métodos guardados
  Future<int> countAll() async {
    final db = await database;
    final v = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM payment_methods'));
    return v ?? 0;
  }

  // ─── DELETE ──────────────────────────────────────────────────────

  /// Elimina un método por su id
  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
  }

  /// Elimina todos
  Future<void> deleteAllMethods() async {
    final db = await database;
    await db.delete('payment_methods');
  }

  // ─── DEBUG ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRawRows() async {
    final db = await database;
    return await db.rawQuery(
        'SELECT id, type, nickname, savedAt FROM payment_methods ORDER BY savedAt DESC');
  }
}