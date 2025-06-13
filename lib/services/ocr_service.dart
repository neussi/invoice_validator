// lib/services/ocr_service.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();

  // Nettoyer et analyser le texte OCR
  Future<InvoiceData> processInvoice(String imagePath) async {
    try {
      // Préprocessing de l'image
      final processedImagePath = await _preprocessImage(imagePath);
      
      // OCR avec Google ML Kit
      final inputImage = InputImage.fromFilePath(processedImagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Parser le texte extrait
      final invoiceData = _parseInvoiceText(recognizedText.text);
      
      return invoiceData;
    } catch (e) {
      print('Erreur OCR: $e');
      throw Exception('Erreur lors de l\'analyse: $e');
    }
  }

  // Préprocessing de l'image pour améliorer l'OCR
  Future<String> _preprocessImage(String imagePath) async {
    try {
      // Charger l'image
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) return imagePath;

      // Améliorer le contraste
      image = img.adjustColor(image, contrast: 1.2, brightness: 1.1);
      
      // Convertir en niveaux de gris
      image = img.grayscale(image);
      
      // Appliquer un filtre de netteté
      image = img.convolution(image, filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ]);

      // Sauvegarder l'image traitée
      final processedPath = imagePath.replaceAll('.jpg', '_processed.jpg');
      await File(processedPath).writeAsBytes(img.encodeJpg(image));
      
      return processedPath;
    } catch (e) {
      print('Erreur preprocessing: $e');
      return imagePath; // Retourner l'image originale en cas d'erreur
    }
  }

  // Parser intelligent du texte pour extraire les informations
  InvoiceData _parseInvoiceText(String text) {
    final lines = text.split('\n').map((line) => line.trim()).toList();
    
    return InvoiceData(
      invoiceNumber: _extractInvoiceNumber(lines),
      customerName: _extractCustomerName(lines),
      amount: _extractAmount(lines),
      date: _extractDate(lines),
      meterNumber: _extractMeterNumber(lines),
      previousReading: _extractPreviousReading(lines),
      currentReading: _extractCurrentReading(lines),
      consumption: _extractConsumption(lines),
      rawText: text,
      confidence: _calculateConfidence(lines),
    );
  }

  String _extractInvoiceNumber(List<String> lines) {
    final patterns = [
      RegExp(r'(?:facture|invoice|n°|no\.?|#)\s*:?\s*([a-z0-9\-]+)', caseSensitive: false),
      RegExp(r'(\d{4,}-\d{3,})', caseSensitive: false),
      RegExp(r'(fac[a-z]*\s*\d+)', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return match.group(1)?.toUpperCase() ?? '';
        }
      }
    }
    return 'N/A';
  }

  String _extractCustomerName(List<String> lines) {
    final patterns = [
      RegExp(r'(?:nom|name|client)\s*:?\s*([a-zÀ-ÿ\s]+)', caseSensitive: false),
      RegExp(r'^([A-ZÀ-Ÿ][a-zà-ÿ]+(?:\s+[A-ZÀ-Ÿ][a-zà-ÿ]+)+)$'),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final name = match.group(1)?.trim() ?? '';
          if (name.length > 3 && name.split(' ').length >= 2) {
            return name.toUpperCase();
          }
        }
      }
    }
    return 'CLIENT INCONNU';
  }

  String _extractAmount(List<String> lines) {
    final patterns = [
      RegExp(r'(?:total|montant|amount)\s*:?\s*(\d{1,3}(?:[,\s]\d{3})*(?:[.,]\d{2})?)\s*(?:fcfa|f\s*cfa|xaf|€|\$)?', caseSensitive: false),
      RegExp(r'(\d{1,3}(?:[,\s]\d{3})*(?:[.,]\d{2})?)\s*(?:fcfa|f\s*cfa|xaf)', caseSensitive: false),
      RegExp(r'(\d{3,})\s*(?:fcfa|f\s*cfa)', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          String amount = match.group(1) ?? '';
          // Normaliser le format
          amount = amount.replaceAll(RegExp(r'[,\s]'), ',');
          return '$amount FCFA';
        }
      }
    }
    return '0 FCFA';
  }

  String _extractDate(List<String> lines) {
    final patterns = [
      RegExp(r'(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})'),
      RegExp(r'(\d{1,2}\s+(?:jan|fév|mar|avr|mai|jun|jul|aoû|sep|oct|nov|déc)[a-z]*\s+\d{2,4})', caseSensitive: false),
      RegExp(r'(?:date|du|le)\s*:?\s*(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return match.group(1) ?? '';
        }
      }
    }
    return DateTime.now().toString().substring(0, 10);
  }

  String _extractMeterNumber(List<String> lines) {
    final patterns = [
      RegExp(r'(?:compteur|meter|n°\s*compteur)\s*:?\s*([a-z0-9\-]+)', caseSensitive: false),
      RegExp(r'(comp[a-z]*\s*\d+)', caseSensitive: false),
      RegExp(r'(\d{6,})', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return match.group(1)?.toUpperCase() ?? '';
        }
      }
    }
    return 'COMP-000000';
  }

  String _extractPreviousReading(List<String> lines) {
    final patterns = [
      RegExp(r'(?:précédent|previous|ancien)\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'index\s*précédent\s*:?\s*(\d+)', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return match.group(1) ?? '';
        }
      }
    }
    return '0';
  }

  String _extractCurrentReading(List<String> lines) {
    final patterns = [
      RegExp(r'(?:actuel|current|nouveau)\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'index\s*actuel\s*:?\s*(\d+)', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return match.group(1) ?? '';
        }
      }
    }
    return '0';
  }

  String _extractConsumption(List<String> lines) {
    final patterns = [
      RegExp(r'(?:consommation|consumption)\s*:?\s*(\d+)\s*(?:kwh|kw|w)?', caseSensitive: false),
      RegExp(r'(\d+)\s*kwh', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return '${match.group(1)} kWh';
        }
      }
    }
    return '0 kWh';
  }

  double _calculateConfidence(List<String> lines) {
    int score = 0;
    int maxScore = 8;

    // Vérifier la présence d'éléments clés
    final text = lines.join(' ').toLowerCase();
    
    if (text.contains(RegExp(r'facture|invoice'))) score++;
    if (text.contains(RegExp(r'\d+.*fcfa'))) score++;
    if (text.contains(RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}'))) score++;
    if (text.contains(RegExp(r'compteur|meter'))) score++;
    if (text.contains(RegExp(r'kwh|kw'))) score++;
    if (text.contains(RegExp(r'total|montant'))) score++;
    if (text.contains(RegExp(r'eneo|aes|électricité'))) score++;
    if (lines.length > 10) score++; // Suffisamment de texte

    return (score / maxScore).clamp(0.0, 1.0);
  }

  void dispose() {
    _textRecognizer.close();
  }
}

// Modèle pour les données extraites
class InvoiceData {
  final String invoiceNumber;
  final String customerName;
  final String amount;
  final String date;
  final String meterNumber;
  final String previousReading;
  final String currentReading;
  final String consumption;
  final String rawText;
  final double confidence;

  InvoiceData({
    required this.invoiceNumber,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.meterNumber,
    required this.previousReading,
    required this.currentReading,
    required this.consumption,
    required this.rawText,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'amount': amount,
      'date': date,
      'meter_number': meterNumber,
      'previous_reading': previousReading,
      'current_reading': currentReading,
      'consumption': consumption,
      'raw_text': rawText,
      'confidence': confidence,
    };
  }

  // Valider les données extraites
  ValidationResult validate() {
    List<String> errors = [];
    
    if (invoiceNumber == 'N/A' || invoiceNumber.isEmpty) {
      errors.add('Numéro de facture non trouvé');
    }
    
    if (amount == '0 FCFA') {
      errors.add('Montant non détecté');
    }
    
    if (confidence < 0.5) {
      errors.add('Confiance faible dans l\'extraction');
    }

    final isValid = errors.isEmpty && confidence >= 0.7;
    
    return ValidationResult(
      isValid: isValid,
      errors: errors,
      confidence: confidence,
      status: isValid ? 'validee' : 'rejected',
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final double confidence;
  final String status;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.confidence,
    required this.status,
  });
}