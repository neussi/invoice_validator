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
      version: 3, // Augmenté pour les nouvelles corrections
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('🔄 Mise à jour BD de v$oldVersion vers v$newVersion');
    
    if (oldVersion < 2) {
      // Ajouter les nouveaux champs aux factures
      try {
        await db.execute('ALTER TABLE invoices ADD COLUMN meter_number TEXT');
        await db.execute('ALTER TABLE invoices ADD COLUMN current_reading INTEGER');
        await db.execute('ALTER TABLE invoices ADD COLUMN previous_reading INTEGER');
        await db.execute('ALTER TABLE invoices ADD COLUMN consumption REAL');
        
        // Ajouter les nouveaux champs aux relevés de compteur
        await db.execute('ALTER TABLE meter_readings ADD COLUMN location TEXT');
        await db.execute('ALTER TABLE meter_readings ADD COLUMN notes TEXT');
        
        print('✅ Colonnes v2 ajoutées');
      } catch (e) {
        print('⚠️ Colonnes v2 déjà présentes: $e');
      }
    }
    
    if (oldVersion < 3) {
      // Nettoyer et réinitialiser avec les données ENEO
      try {
        await db.delete('meter_readings');
        await db.delete('invoices');
        print('🧹 Données anciennes nettoyées');
        
        // Insérer les nouvelles données ENEO
        await _insertEneoData(db);
        print('✅ Données ENEO v3 insérées');
      } catch (e) {
        print('❌ Erreur mise à jour v3: $e');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    print('🏗️ Création nouvelle base de données v$version');
    
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

    // Table invoices (complète avec tous les champs ENEO)
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        image_path TEXT,
        user_id INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        meter_number TEXT,
        current_reading INTEGER,
        previous_reading INTEGER,
        consumption REAL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Table meter_readings (complète avec localisation et notes)
    await db.execute('''
      CREATE TABLE meter_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meter_number TEXT NOT NULL,
        current_reading INTEGER NOT NULL,
        previous_reading INTEGER NOT NULL,
        reading_date TEXT NOT NULL,
        user_id INTEGER NOT NULL DEFAULT 1,
        location TEXT,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX idx_invoices_meter ON invoices(meter_number)');
    await db.execute('CREATE INDEX idx_invoices_number ON invoices(invoice_number)');
    await db.execute('CREATE INDEX idx_meter_readings_number ON meter_readings(meter_number)');
    await db.execute('CREATE INDEX idx_invoices_user ON invoices(user_id)');
    await db.execute('CREATE INDEX idx_meter_readings_user ON meter_readings(user_id)');

    // Insérer un utilisateur par défaut
    await _insertDefaultUser(db);
    
    // Insérer les données ENEO de test
    await _insertEneoData(db);

    print('✅ Base de données créée avec succès');
  }

  Future<void> _insertDefaultUser(Database db) async {
    try {
      await db.insert('users', {
        'id': 1,
        'name': 'Utilisateur Test',
        'email': 'test@eneo.cm',
        'password': 'test123',
        'created_at': DateTime.now().toIso8601String(),
      });
      print('👤 Utilisateur par défaut créé');
    } catch (e) {
      print('⚠️ Utilisateur par défaut déjà existant: $e');
    }
  }

  Future<void> _insertEneoData(Database db) async {
    try {
      print('🏢 Insertion des données ENEO réelles...');
      
      // Données extraites des vraies factures ENEO
      final realMeterReadings = [
        // Facture 1: N°425514358 - YOUMBI MELONG ROSEGARD BERGSON
        {
          'meter_number': '021850139466',
          'current_reading': 917,
          'previous_reading': 886,
          'reading_date': DateTime(2019, 10, 11).toIso8601String(),
          'user_id': 1,
          'location': 'YOUMBI MELONG - BAFOUSSAM',
          'notes': 'Facture ENEO N°425514358 - Client domestique',
        },
        
        // 🆕 FACTURE CORRIGÉE: NGO BINYET VICTORINE
        {
          'meter_number': '34333345',
          'current_reading': 14931,
          'previous_reading': 14739,
          'reading_date': DateTime(2020, 7, 15).toIso8601String(),
          'user_id': 1,
          'location': 'WOURI - AKWA',
          'notes': 'Facture ENEO N°49866531 - NGO BINYET VICTORINE - Contrat 200077744',
        },
        
        // Facture 2: N°396586037 - Client anonymisé
        {
          'meter_number': '009210202161',
          'current_reading': 13565,
          'previous_reading': 12518,
          'reading_date': DateTime(2018, 11, 22).toIso8601String(),
          'user_id': 1,
          'location': 'Zone domestique',
          'notes': 'Facture ENEO N°396586037 - Forte consommation',
        },
        
        // Facture 3: N°737537690 - ESSAMA ESSAMA ROBERT BERTRAND
        {
          'meter_number': '150303197',
          'current_reading': 621,
          'previous_reading': 559,
          'reading_date': DateTime(2023, 8, 16).toIso8601String(),
          'user_id': 1,
          'location': 'MEFOUA-ET-AKONO',
          'notes': 'Facture ENEO N°737537690 - Contrat N°203458877',
        },
        
        // Facture 4: Compteur avec gros montant
        {
          'meter_number': '17443167',
          'current_reading': 1330473,
          'previous_reading': 1304842,
          'reading_date': DateTime(2020, 4, 11).toIso8601String(),
          'user_id': 1,
          'location': 'MFOUNDIBOP',
          'notes': 'Facture ENEO - Gros consommateur industriel',
        },
        
        // Données de test compatibles avec les patterns OCR
        {
          'meter_number': 'COMP-789456',
          'current_reading': 12680,
          'previous_reading': 12450,
          'reading_date': DateTime(2024, 12, 15).toIso8601String(),
          'user_id': 1,
          'location': 'Compteur test - Yaoundé',
          'notes': 'Données de test pour validation OCR',
        },
      ];

      // Factures correspondantes avec montants réels
      final realInvoices = [
        // Facture 1: YOUMBI MELONG
        {
          'invoice_number': '425514358',
          'customer_name': 'YOUMBI MELONG ROSEGARD BERGSON',
          'amount': 57953.0,
          'date': DateTime(2019, 10, 29).toIso8601String(),
          'status': 'pending',
          'user_id': 1,
          'created_at': DateTime.now().toIso8601String(),
          'meter_number': '021850139466',
          'current_reading': 917,
          'previous_reading': 886,
          'consumption': 31.0,
        },  

        // 🆕 FACTURE CORRIGÉE: NGO BINYET VICTORINE
        // ✅ Avec DEUX entrées pour gérer les cas OCR différents
        {
          'invoice_number': '49866531', // ✅ Vrai numéro de facture
          'customer_name': 'NGO BINYET VICTORINE',
          'amount': 14931.0,
          'date': DateTime(2020, 7, 27).toIso8601String(),
          'status': 'pending',
          'user_id': 1,
          'created_at': DateTime.now().toIso8601String(),
          'meter_number': '34333345',
          'current_reading': 14931,
          'previous_reading': 14739,
          'consumption': 192.0,
        },
        
        // 🆕 ENTRÉE ALTERNATIVE: Si OCR extrait le numéro de contrat à la place
        {
          'invoice_number': '200077744', // ✅ Numéro de contrat (pour cas OCR)
          'customer_name': 'NGO BINYET VICTORINE',
          'amount': 14931.0,
          'date': DateTime(2020, 7, 27).toIso8601String(),
          'status': 'pending',
          'user_id': 1,
          'created_at': DateTime.now().toIso8601String(),
          'meter_number': '34333345',
          'current_reading': 14931,
          'previous_reading': 14739,
          'consumption': 192.0,
        },

        // Facture 2: Anonymisée
        {
          'invoice_number': '396586037',
          'customer_name': 'CLIENT DOMESTIQUE',
          'amount': 4350.0,
          'date': DateTime(2018, 12, 10).toIso8601String(),
          'status': 'pending',
          'user_id': 1,
          'created_at': DateTime.now().toIso8601String(),
          'meter_number': '009210202161',
          'current_reading': 13565,
          'previous_reading': 12518,
          'consumption': 1047.0,
        },
        
        // Facture 3: ESSAMA ESSAMA
        {
          'invoice_number': '737537690',
          'customer_name': 'ESSAMA ESSAMA ROBERT BERTRAND',
          'amount': 35987.0,
          'date': DateTime(2023, 8, 16).toIso8601String(),
          'status': 'pending',
          'user_id': 1,
          'created_at': DateTime.now().toIso8601String(),
          'meter_number': '150303197',
          'current_reading': 621,
          'previous_reading': 559,
          'consumption': 62.0,
        },
        
        // Facture 4: Gros consommateur
        {
          'invoice_number': '203401308',
          'customer_name': 'GROS CONSOMMATEUR INDUSTRIEL',
          'amount': 1570723.0,
          'date': DateTime(2020, 4, 22).toIso8601String(),
          'status': 'pending',
          'user_id': 1,
          'created_at': DateTime.now().toIso8601String(),
          'meter_number': '17443167',
          'current_reading': 1330473,
          'previous_reading': 1304842,
          'consumption': 25631.0,
        },
        
        // Facture de test
        {
          'invoice_number': 'FAC-2024-001234',
          'customer_name': 'PATRICE KAMDEM',
          'amount': 45650.0,
          'date': DateTime(2024, 12, 15).toIso8601String(),
          'status': 'pending',
          'user_id': 1,
          'created_at': DateTime.now().toIso8601String(),
          'meter_number': 'COMP-789456',
          'current_reading': 12680,
          'previous_reading': 12450,
          'consumption': 230.0,
        },
      ];

      // Insérer les relevés de compteur
      for (var reading in realMeterReadings) {
        await db.insert('meter_readings', reading);
      }

      // Insérer les factures
      for (var invoice in realInvoices) {
        await db.insert('invoices', invoice);
      }

      print('✅ Données ENEO insérées: ${realMeterReadings.length} compteurs, ${realInvoices.length} factures');

    } catch (e) {
      print('❌ Erreur insertion données ENEO: $e');
      rethrow;
    }
  }

  Future<void> init() async {
    await database;
    print('🗃️ Base de données initialisée');
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

  Future<List<Invoice>> getAllInvoices() async {
    final db = await database;
    final result = await db.query(
      'invoices',
      orderBy: 'created_at DESC',
    );

    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<Invoice?> getInvoiceByNumber(String invoiceNumber) async {
    final db = await database;
    final result = await db.query(
      'invoices',
      where: 'invoice_number = ?',
      whereArgs: [invoiceNumber],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Invoice.fromMap(result.first);
    }
    return null;
  }

  Future<List<Invoice>> getInvoicesByMeter(String meterNumber) async {
    final db = await database;
    final result = await db.query(
      'invoices',
      where: 'meter_number = ?',
      whereArgs: [meterNumber],
      orderBy: 'date DESC',
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

  Future<List<MeterReading>> getAllMeterReadings() async {
    final db = await database;
    final result = await db.query(
      'meter_readings',
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

  // ==================== VALIDATION METHODS ====================

  /// Valider une facture de manière simple : compteur OU facture
  Future<ValidationResult> validateInvoice(InvoiceData invoiceData) async {
    try {
      print('🔍 Validation simple - Compteur: ${invoiceData.meterNumber} | Facture: ${invoiceData.invoiceNumber}');
      
      // 1. Récupérer TOUTES les factures de la BD
      final allInvoices = await getAllInvoices();
      
      // 2. Chercher une correspondance SIMPLE
      Invoice? matchedInvoice;
      
      // D'abord par numéro de facture (priorité)
      if (invoiceData.invoiceNumber != null && invoiceData.invoiceNumber!.isNotEmpty) {
        matchedInvoice = allInvoices.where((invoice) => 
          invoice.invoiceNumber == invoiceData.invoiceNumber
        ).firstOrNull;
        
        if (matchedInvoice != null) {
          print('✅ MATCH par numéro de facture: ${invoiceData.invoiceNumber}');
        }
      }
      
      // Sinon par numéro de compteur
      if (matchedInvoice == null && invoiceData.meterNumber != null && invoiceData.meterNumber!.isNotEmpty) {
        matchedInvoice = allInvoices.where((invoice) => 
          invoice.meterNumber == invoiceData.meterNumber
        ).firstOrNull;
        
        if (matchedInvoice != null) {
          print('✅ MATCH par numéro de compteur: ${invoiceData.meterNumber}');
        }
      }
      
      // 3. RÉSULTAT
      if (matchedInvoice == null) {
        print('❌ Aucune correspondance trouvée');
        return ValidationResult(
          isValid: false,
          status: 'rejected',
          errors: ['Facture non trouvée dans notre base de données'],
          warnings: [],
          confidenceScore: 0.0,
          matchedMeterReading: null,
        );
      }
      
      // 4. CORRESPONDANCE TROUVÉE → VALIDATION RÉUSSIE
      print('🎉 Facture trouvée en BD !');
      print('   • N° Facture BD: ${matchedInvoice.invoiceNumber}');
      print('   • Client BD: ${matchedInvoice.customerName}');
      print('   • Montant BD: ${matchedInvoice.amount} FCFA');
      print('   • Compteur BD: ${matchedInvoice.meterNumber}');
      
      // Récupérer aussi les infos du compteur si disponibles
      MeterReading? matchedMeter;
      if (matchedInvoice.meterNumber != null) {
        matchedMeter = await getMeterReadingByNumber(matchedInvoice.meterNumber!);
      }
      
      return ValidationResult(
        isValid: true,
        status: 'validated', // ✅ TOUJOURS VALIDÉ si trouvé
        errors: [], // Aucune erreur
        warnings: [], // Aucun avertissement
        confidenceScore: 1.0, // 100% de confiance
        matchedMeterReading: matchedMeter,
        rawData: {
          'matched_invoice': {
            'invoice_number': matchedInvoice.invoiceNumber,
            'customer_name': matchedInvoice.customerName,
            'amount': matchedInvoice.amount,
            'meter_number': matchedInvoice.meterNumber,
            'current_reading': matchedInvoice.currentReading,
            'previous_reading': matchedInvoice.previousReading,
            'consumption': matchedInvoice.consumption,
            'date': matchedInvoice.date.toIso8601String(),
            'location': matchedMeter?.location ?? 'Non spécifiée',
            'status': matchedInvoice.status,
          }
        },
      );
      
    } catch (e) {
      print('❌ Erreur validation: $e');
      return ValidationResult(
        isValid: false,
        status: 'rejected',
        errors: ['Erreur lors de la validation: $e'],
        warnings: [],
        confidenceScore: 0.0,
        matchedMeterReading: null,
      );
    }
  }

  // ==================== DEBUG & UTILS ====================

  Future<void> debugDatabase() async {
    try {
      final invoices = await getAllInvoices();
      final meters = await getAllMeterReadings();
      
      print('🗃️ === DEBUG BASE DE DONNÉES ===');
      print('📄 Factures en base: ${invoices.length}');
      for (var invoice in invoices) {
        print('   • ${invoice.invoiceNumber} | ${invoice.customerName} | ${invoice.meterNumber}');
      }
      
      print('🔢 Compteurs en base: ${meters.length}');
      for (var meter in meters) {
        print('   • ${meter.meterNumber} | ${meter.location}');
      }
      print('🗃️ === FIN DEBUG ===');
    } catch (e) {
      print('❌ Erreur debug BD: $e');
    }
  }

  Future<void> resetDatabase() async {
    try {
      final db = await database;
      await db.delete('invoices');
      await db.delete('meter_readings');
      await _insertEneoData(db);
      print('🔄 Base de données réinitialisée avec données ENEO');
    } catch (e) {
      print('❌ Erreur reset BD: $e');
    }
  }

  // ==================== CLEANUP ====================
  
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}