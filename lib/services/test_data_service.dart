// lib/services/test_data_service.dart
import '../database.dart';
import '../models.dart';

class TestDataService {
  
  /// Insérer des données de test supplémentaires
  static Future<void> insertAdditionalTestData(int userId) async {
    try {
      // Relevés de compteur additionnels pour différents scénarios
      final additionalMeterReadings = [
        MeterReading(
          meterNumber: 'COMP-111222',
          currentReading: 9876,
          previousReading: 9654,
          readingDate: DateTime(2024, 12, 20),
          userId: userId,
          location: 'Villa Rosette',
          notes: 'Relevé automatique - smart meter',
        ),
        MeterReading(
          meterNumber: 'COMP-333444',
          currentReading: 15432,
          previousReading: 15089,
          readingDate: DateTime(2024, 12, 18),
          userId: userId,
          location: 'Magasin central',
          notes: 'Relevé mensuel - forte consommation',
        ),
        MeterReading(
          meterNumber: 'COMP-555666',
          currentReading: 4567,
          previousReading: 4321,
          readingDate: DateTime(2024, 12, 12),
          userId: userId,
          location: 'Résidence secondaire',
          notes: 'Relevé trimestriel',
        ),
      ];

      // Insérer les relevés
      for (var reading in additionalMeterReadings) {
        await DatabaseHelper.instance.insertMeterReading(reading);
      }

      // Factures de test avec différents statuts
      final testInvoices = [
        Invoice(
          invoiceNumber: 'FAC-2024-001100',
          customerName: 'MARIE DUPONT',
          amount: 28750.0,
          date: DateTime(2024, 12, 18),
          status: 'validated',
          userId: userId,
          createdAt: DateTime.now(),
          meterNumber: 'COMP-333444',
          currentReading: 15432,
          previousReading: 15089,
          consumption: 343.0,
        ),
        Invoice(
          invoiceNumber: 'FAC-2024-001101',
          customerName: 'PAUL MARTIN',
          amount: 15420.0,
          date: DateTime(2024, 12, 15),
          status: 'rejected',
          userId: userId,
          createdAt: DateTime.now(),
          meterNumber: 'COMP-999888', // Compteur inexistant pour test
          currentReading: 5000,
          previousReading: 4800,
          consumption: 200.0,
        ),
        Invoice(
          invoiceNumber: 'FAC-2024-001102',
          customerName: 'JEAN KAMDEM',
          amount: 35680.0,
          date: DateTime(2024, 12, 10),
          status: 'pending',
          userId: userId,
          createdAt: DateTime.now(),
          meterNumber: 'COMP-111222',
          currentReading: 9876,
          previousReading: 9654,
          consumption: 222.0,
        ),
      ];

      // Insérer les factures
      for (var invoice in testInvoices) {
        await DatabaseHelper.instance.insertInvoice(invoice);
      }

      print('✅ Données de test supplémentaires insérées avec succès');
      print('📊 ${additionalMeterReadings.length} relevés de compteur ajoutés');
      print('📄 ${testInvoices.length} factures de test ajoutées');

    } catch (e) {
      print('❌ Erreur lors de l\'insertion des données de test: $e');
    }
  }

  /// Obtenir les statistiques de test
  static Future<Map<String, dynamic>> getTestStatistics(int userId) async {
    try {
      final meterReadings = await DatabaseHelper.instance.getMeterReadingsByUser(userId);
      final invoices = await DatabaseHelper.instance.getInvoicesByUser(userId);
      
      // Compter par statut
      int validatedCount = invoices.where((inv) => inv.status == 'validated').length;
      int rejectedCount = invoices.where((inv) => inv.status == 'rejected').length;
      int pendingCount = invoices.where((inv) => inv.status == 'pending').length;
      
      // Calculer la consommation totale
      double totalConsumption = meterReadings.fold(0.0, (sum, reading) => sum + reading.consumption);
      
      return {
        'total_meter_readings': meterReadings.length,
        'total_invoices': invoices.length,
        'validated_invoices': validatedCount,
        'rejected_invoices': rejectedCount,
        'pending_invoices': pendingCount,
        'total_consumption': totalConsumption,
        'available_meters': meterReadings.map((r) => r.meterNumber).toSet().toList(),
      };
    } catch (e) {
      print('❌ Erreur lors du calcul des statistiques: $e');
      return {};
    }
  }

  /// Nettoyer toutes les données de test
  static Future<void> clearAllTestData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Supprimer toutes les factures de test
      await db.delete('invoices');
      
      // Supprimer tous les relevés de compteur de test
      await db.delete('meter_readings');
      
      print('🧹 Toutes les données de test supprimées');
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
    }
  }

  /// Générer un rapport de validation
  static String generateValidationReport(ValidationResult result, InvoiceData invoiceData) {
    StringBuffer report = StringBuffer();
    
    report.writeln('=== RAPPORT DE VALIDATION ===');
    report.writeln('Date: ${DateTime.now().toLocal()}');
    report.writeln('');
    
    report.writeln('📋 DONNÉES FACTURE:');
    report.writeln('• Numéro: ${invoiceData.invoiceNumber ?? "Non détecté"}');
    report.writeln('• Client: ${invoiceData.customerName ?? "Non détecté"}');
    report.writeln('• Montant: ${invoiceData.amount?.toStringAsFixed(0) ?? "Non détecté"} FCFA');
    report.writeln('• Date: ${invoiceData.date ?? "Non détectée"}');
    report.writeln('• Compteur: ${invoiceData.meterNumber ?? "Non détecté"}');
    report.writeln('• Index actuel: ${invoiceData.currentReading ?? "Non détecté"}');
    report.writeln('• Index précédent: ${invoiceData.previousReading ?? "Non détecté"}');
    report.writeln('• Consommation: ${invoiceData.calculatedConsumption?.toStringAsFixed(1) ?? "Non calculée"} kWh');
    report.writeln('');
    
    report.writeln('✅ RÉSULTAT VALIDATION:');
    report.writeln('• Statut: ${result.status.toUpperCase()}');
    report.writeln('• Valide: ${result.isValid ? "OUI" : "NON"}');
    if (result.confidenceScore != null) {
      report.writeln('• Score confiance: ${(result.confidenceScore! * 100).toInt()}%');
    }
    report.writeln('');
    
    if (result.matchedMeterReading != null) {
      report.writeln('🔍 RÉFÉRENCE TROUVÉE:');
      report.writeln('• Compteur: ${result.matchedMeterReading!.meterNumber}');
      report.writeln('• Index actuel: ${result.matchedMeterReading!.currentReading}');
      report.writeln('• Index précédent: ${result.matchedMeterReading!.previousReading}');
      report.writeln('• Consommation: ${result.matchedMeterReading!.consumption.toStringAsFixed(1)} kWh');
      report.writeln('• Date relevé: ${result.matchedMeterReading!.readingDate}');
      report.writeln('');
    }
    
    if (result.errors.isNotEmpty) {
      report.writeln('❌ ERREURS:');
      for (var error in result.errors) {
        report.writeln('• $error');
      }
      report.writeln('');
    }
    
    if (result.warnings.isNotEmpty) {
      report.writeln('⚠️ AVERTISSEMENTS:');
      for (var warning in result.warnings) {
        report.writeln('• $warning');
      }
      report.writeln('');
    }
    
    report.writeln('=== FIN RAPPORT ===');
    
    return report.toString();
  }

  /// Simuler différents scénarios de validation
  static List<Map<String, dynamic>> getTestScenarios() {
    return [
      {
        'title': 'Scénario 1: Validation parfaite',
        'description': 'Tous les champs correspondent parfaitement',
        'meter_number': 'COMP-789456',
        'current_reading': 12680,
        'previous_reading': 12450,
        'expected_result': 'validated',
      },
      {
        'title': 'Scénario 2: Compteur inexistant',
        'description': 'Le numéro de compteur n\'existe pas en base',
        'meter_number': 'COMP-999999',
        'current_reading': 5000,
        'previous_reading': 4800,
        'expected_result': 'rejected',
      },
      {
        'title': 'Scénario 3: Index incohérent',
        'description': 'Les index ne correspondent pas aux données de référence',
        'meter_number': 'COMP-789456',
        'current_reading': 15000, // Différent de la base (12680)
        'previous_reading': 14800,
        'expected_result': 'rejected',
      },
      {
        'title': 'Scénario 4: Validation en attente',
        'description': 'Données partiellement correctes nécessitant validation manuelle',
        'meter_number': 'COMP-123789',
        'current_reading': 8945,
        'previous_reading': 8700, // Légèrement différent de la base (8720)
        'expected_result': 'pending',
      },
    ];
  }
}

// Extension pour faciliter l'utilisation
extension TestDataExtension on DatabaseHelper {
  Future<void> setupTestEnvironment(int userId) async {
    await TestDataService.insertAdditionalTestData(userId);
  }
  
  Future<Map<String, dynamic>> getTestStats(int userId) async {
    return await TestDataService.getTestStatistics(userId);
  }
}