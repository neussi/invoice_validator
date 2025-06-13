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

  MeterReading({
    this.id,
    required this.meterNumber,
    required this.currentReading,
    required this.previousReading,
    required this.readingDate,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meter_number': meterNumber,
      'current_reading': currentReading,
      'previous_reading': previousReading,
      'reading_date': readingDate.toIso8601String(),
      'user_id': userId,
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
    );
  }
}