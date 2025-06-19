// lib/services/ocr_service.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' as mlkit_text_recognition;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final mlkit_text_recognition.TextRecognizer _textRecognizer = mlkit_text_recognition.TextRecognizer();

  Future<InvoiceData> processInvoice(String imagePath) async {
    try {
      final inputImage = mlkit_text_recognition.InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Extraire le texte complet
      String fullText = recognizedText.text;
      print('Texte OCR complet: $fullText');
      
      // Traiter le texte pour extraire les informations
      return _extractInvoiceData(fullText, recognizedText);
      
    } catch (e) {
      print('Erreur OCR: $e');
      throw Exception('Erreur lors de la reconnaissance de texte: $e');
    }
  }

  InvoiceData _extractInvoiceData(String fullText, RecognizedText recognizedText) {
    Map<String, dynamic> rawData = {
      'full_text': fullText,
      'confidence': _calculateConfidence(recognizedText),
    };

    // Nettoyer le texte
    String cleanText = fullText.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    
    return InvoiceData(
      invoiceNumber: _extractInvoiceNumber(cleanText),
      customerName: _extractCustomerName(cleanText),
      amount: _extractAmount(cleanText),
      date: _extractDate(cleanText),
      meterNumber: _extractMeterNumber(cleanText),
      currentReading: _extractCurrentReading(cleanText),
      previousReading: _extractPreviousReading(cleanText),
      consumption: _extractConsumption(cleanText),
      rawData: rawData,
    );
  }

  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int blockCount = 0;
    
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          // Note: La confiance n'est pas directement disponible dans ML Kit
          // On utilise la longueur du texte comme approximation
          totalConfidence += element.text.length > 2 ? 1.0 : 0.5;
          blockCount++;
        }
      }
    }
    
    return blockCount > 0 ? (totalConfidence / blockCount) : 0.0;
  }

  String? _extractInvoiceNumber(String text) {
    // Patterns pour numéro de facture
    List<RegExp> patterns = [
      RegExp(r'FAC[T]?[-\s]*(\d{4}[-\s]*\d{6})', caseSensitive: false),
      RegExp(r'FACTURE\s*N[°O]?\s*:?\s*([A-Z0-9-]{8,})', caseSensitive: false),
      RegExp(r'N[°O]\s*FACTURE\s*:?\s*([A-Z0-9-]{8,})', caseSensitive: false),
      RegExp(r'INVOICE\s*N[°O]?\s*:?\s*([A-Z0-9-]{8,})', caseSensitive: false),
      RegExp(r'([A-Z]{2,4}[-\s]*\d{4}[-\s]*\d{6})', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String number = match.group(1) ?? match.group(0)!;
        return number.replaceAll(RegExp(r'\s+'), '').toUpperCase();
      }
    }
    
    return null;
  }

  String? _extractCustomerName(String text) {
    // Patterns pour nom client
    List<RegExp> patterns = [
      RegExp(r'CLIENT\s*:?\s*([A-Z\s]{10,40})', caseSensitive: false),
      RegExp(r'NOM\s*:?\s*([A-Z\s]{10,40})', caseSensitive: false),
      RegExp(r'BENEFICIAIRE\s*:?\s*([A-Z\s]{10,40})', caseSensitive: false),
      RegExp(r'M[RS]?[\.:]?\s*([A-Z\s]{10,40})', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String name = match.group(1)!.trim();
        // Nettoyer le nom (enlever mots parasites)
        name = name.replaceAll(RegExp(r'\b(FACTURE|CLIENT|NOM|ENEO|CAMEROUN)\b', caseSensitive: false), '').trim();
        if (name.length >= 3) {
          return _capitalizeWords(name);
        }
      }
    }
    
    return null;
  }

  double? _extractAmount(String text) {
    // Patterns pour montant
    List<RegExp> patterns = [
      RegExp(r'MONTANT\s*:?\s*([0-9,.\s]+)\s*FCFA', caseSensitive: false),
      RegExp(r'TOTAL\s*:?\s*([0-9,.\s]+)\s*FCFA', caseSensitive: false),
      RegExp(r'([0-9,.\s]+)\s*FCFA', caseSensitive: false),
      RegExp(r'(\d{1,3}(?:[,.\s]\d{3})*(?:[,.]\d{2})?)\s*F?CFA', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String amountStr = match.group(1)!;
        // Nettoyer et convertir
        amountStr = amountStr.replaceAll(RegExp(r'[,\s]'), '').replaceAll('.', '');
        try {
          return double.parse(amountStr);
        } catch (e) {
          continue;
        }
      }
    }
    
    return null;
  }

  DateTime? _extractDate(String text) {
    // Patterns pour date
    List<RegExp> patterns = [
      RegExp(r'DATE\s*:?\s*(\d{1,2}[/.-]\d{1,2}[/.-]\d{4})', caseSensitive: false),
      RegExp(r'(\d{1,2}[/.-]\d{1,2}[/.-]\d{4})'),
      RegExp(r'(\d{4}[/.-]\d{1,2}[/.-]\d{1,2})'),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String dateStr = match.group(1)!;
        try {
          // Essayer différents formats
          List<String> formats = ['dd/MM/yyyy', 'dd-MM-yyyy', 'dd.MM.yyyy'];
          for (String format in formats) {
            try {
              return _parseDate(dateStr, format);
            } catch (e) {
              continue;
            }
          }
        } catch (e) {
          continue;
        }
      }
    }
    
    return null;
  }

  DateTime? _parseDate(String dateStr, String format) {
    List<String> parts = dateStr.split(RegExp(r'[/.-]'));
    if (parts.length != 3) return null;
    
    try {
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);
      
      // Vérifier la validité
      if (year < 2020 || year > 2030) return null;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  String? _extractMeterNumber(String text) {
    // Patterns pour numéro de compteur
    List<RegExp> patterns = [
      RegExp(r'COMPTEUR\s*N[°O]?\s*:?\s*(COMP[-\s]*\d{6})', caseSensitive: false),
      RegExp(r'METER\s*N[°O]?\s*:?\s*([A-Z0-9-]{8,})', caseSensitive: false),
      RegExp(r'N[°O]\s*COMPTEUR\s*:?\s*([A-Z0-9-]{8,})', caseSensitive: false),
      RegExp(r'(COMP[-\s]*\d{6})', caseSensitive: false),
      RegExp(r'COMPTEUR\s*:?\s*([A-Z0-9-]{6,})', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String number = match.group(1)!;
        return number.replaceAll(RegExp(r'\s+'), '').toUpperCase();
      }
    }
    
    return null;
  }

  int? _extractCurrentReading(String text) {
    // Patterns pour index actuel
    List<RegExp> patterns = [
      RegExp(r'INDEX\s*ACTUEL\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'NOUVEL?\s*INDEX\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'CURRENT\s*READING\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'ACTUEL\s*:?\s*(\d+)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        try {
          return int.parse(match.group(1)!);
        } catch (e) {
          continue;
        }
      }
    }
    
    return null;
  }

  int? _extractPreviousReading(String text) {
    // Patterns pour index précédent
    List<RegExp> patterns = [
      RegExp(r'INDEX\s*PRECEDENT\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'ANCIEN\s*INDEX\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'PREVIOUS\s*READING\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'PRECEDENT\s*:?\s*(\d+)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        try {
          return int.parse(match.group(1)!);
        } catch (e) {
          continue;
        }
      }
    }
    
    return null;
  }

  double? _extractConsumption(String text) {
    // Patterns pour consommation
    List<RegExp> patterns = [
      RegExp(r'CONSOMMATION\s*:?\s*(\d+(?:[,.]\d+)?)\s*KWH', caseSensitive: false),
      RegExp(r'CONSUMPTION\s*:?\s*(\d+(?:[,.]\d+)?)\s*KWH', caseSensitive: false),
      RegExp(r'(\d+(?:[,.]\d+)?)\s*KWH', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String consumptionStr = match.group(1)!.replaceAll(',', '.');
        try {
          return double.parse(consumptionStr);
        } catch (e) {
          continue;
        }
      }
    }
    
    return null;
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void dispose() {
    _textRecognizer.close();
  }
}