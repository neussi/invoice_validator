// lib/models.dart
class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Invoice {
  final int? id;
  final String invoiceNumber;
  final String customerName;
  final double amount;
  final DateTime date;
  final String status; // 'pending', 'validated', 'rejected'
  final String? imagePath;
  final int userId;
  final DateTime createdAt;
  final String? meterNumber; // Numéro de compteur associé
  final int? currentReading; // Index actuel sur la facture
  final int? previousReading; // Index précédent sur la facture
  final double? consumption; // Consommation calculée

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.status,
    this.imagePath,
    required this.userId,
    required this.createdAt,
    this.meterNumber,
    this.currentReading,
    this.previousReading,
    this.consumption,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status,
      'image_path': imagePath,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'meter_number': meterNumber,
      'current_reading': currentReading,
      'previous_reading': previousReading,
      'consumption': consumption,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      customerName: map['customer_name'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      status: map['status'],
      imagePath: map['image_path'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
      meterNumber: map['meter_number'],
      currentReading: map['current_reading'],
      previousReading: map['previous_reading'],
      consumption: map['consumption'],
    );
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    String? customerName,
    double? amount,
    DateTime? date,
    String? status,
    String? imagePath,
    int? userId,
    DateTime? createdAt,
    String? meterNumber,
    int? currentReading,
    int? previousReading,
    double? consumption,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      meterNumber: meterNumber ?? this.meterNumber,
      currentReading: currentReading ?? this.currentReading,
      previousReading: previousReading ?? this.previousReading,
      consumption: consumption ?? this.consumption,
    );
  }
}

class MeterReading {
  final int? id;
  final String meterNumber;
  final int currentReading;
  final int previousReading;
  final DateTime readingDate;
  final int userId;
  final String? location; // Localisation du compteur
  final String? notes; // Notes additionnelles

  MeterReading({
    this.id,
    required this.meterNumber,
    required this.currentReading,
    required this.previousReading,
    required this.readingDate,
    required this.userId,
    this.location,
    this.notes,
  });

  double get consumption => (currentReading - previousReading).toDouble();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meter_number': meterNumber,
      'current_reading': currentReading,
      'previous_reading': previousReading,
      'reading_date': readingDate.toIso8601String(),
      'user_id': userId,
      'location': location,
      'notes': notes,
    };
  }

  factory MeterReading.fromMap(Map<String, dynamic> map) {
    return MeterReading(
      id: map['id'],
      meterNumber: map['meter_number'],
      currentReading: map['current_reading'],
      previousReading: map['previous_reading'],
      readingDate: DateTime.parse(map['reading_date']),
      userId: map['user_id'],
      location: map['location'],
      notes: map['notes'],
    );
  }
}

// Classe pour les données extraites de l'OCR
class InvoiceData {
  final String? invoiceNumber;
  final String? customerName;
  final double? amount;
  final DateTime? date;
  final String? meterNumber;
  final int? currentReading;
  final int? previousReading;
  final double? consumption;
  final Map<String, dynamic> rawData; // Données brutes OCR

  InvoiceData({
    this.invoiceNumber,
    this.customerName,
    this.amount,
    this.date,
    this.meterNumber,
    this.currentReading,
    this.previousReading,
    this.consumption,
    this.rawData = const {},
  });

  // Calculer la consommation si les index sont disponibles
  double? get calculatedConsumption {
    if (currentReading != null && previousReading != null) {
      return (currentReading! - previousReading!).toDouble();
    }
    return consumption;
  }

  Map<String, dynamic> toMap() {
    return {
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'amount': amount,
      'date': date?.toIso8601String(),
      'meter_number': meterNumber,
      'current_reading': currentReading,
      'previous_reading': previousReading,
      'consumption': consumption,
      'raw_data': rawData,
    };
  }

  factory InvoiceData.fromMap(Map<String, dynamic> map) {
    return InvoiceData(
      invoiceNumber: map['invoice_number'],
      customerName: map['customer_name'],
      amount: map['amount'],
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
      meterNumber: map['meter_number'],
      currentReading: map['current_reading'],
      previousReading: map['previous_reading'],
      consumption: map['consumption'],
      rawData: map['raw_data'] ?? {},
    );
  }
}

// Classe pour le résultat de validation
class ValidationResult {
  final bool isValid;
  final String status; // 'validated', 'rejected', 'pending'
  final List<String> errors;
  final List<String> warnings;
  final MeterReading? matchedMeterReading;
  final double? confidenceScore; // Score de confiance 0-1
  final Map<String, dynamic>? rawData; // Added rawData parameter


  ValidationResult({
    required this.isValid,
    required this.status,
    this.errors = const [],
    this.warnings = const [],
    this.matchedMeterReading,
    this.confidenceScore,
    this.rawData, // Initialize rawData

  });

  ValidationResult copyWith({
    bool? isValid,
    String? status,
    List<String>? errors,
    List<String>? warnings,
    MeterReading? matchedMeterReading,
    double? confidenceScore,
  }) {
    return ValidationResult(
      isValid: isValid ?? this.isValid,
      status: status ?? this.status,
      errors: errors ?? this.errors,
      warnings: warnings ?? this.warnings,
      matchedMeterReading: matchedMeterReading ?? this.matchedMeterReading,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }
}
