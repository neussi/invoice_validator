// lib/database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invoice_validator.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Table users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Table invoices
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        image_path TEXT,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Table meter_readings
    await db.execute('''
      CREATE TABLE meter_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meter_number TEXT NOT NULL,
        current_reading INTEGER NOT NULL,
        previous_reading INTEGER NOT NULL,
        reading_date TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    print('Base de données créée avec succès');
  }

  Future<void> init() async {
    await database;
  }

  // ==================== USERS ====================
  
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ==================== INVOICES ====================
  
  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    return await db.insert('invoices', invoice.toMap());
  }

  Future<List<Invoice>> getInvoicesByUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'invoices',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<void> updateInvoiceStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'invoices',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== METER READINGS ====================
  
  Future<int> insertMeterReading(MeterReading reading) async {
    final db = await database;
    return await db.insert('meter_readings', reading.toMap());
  }

  Future<List<MeterReading>> getMeterReadingsByUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'meter_readings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'reading_date DESC',
    );

    return result.map((map) => MeterReading.fromMap(map)).toList();
  }

  Future<MeterReading?> getMeterReadingByNumber(String meterNumber) async {
    final db = await database;
    final result = await db.query(
      'meter_readings',
      where: 'meter_number = ?',
      whereArgs: [meterNumber],
      orderBy: 'reading_date DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return MeterReading.fromMap(result.first);
    }
    return null;
  }

  // ==================== CLEANUP ====================
  
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}