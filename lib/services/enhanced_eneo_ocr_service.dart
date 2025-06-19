// lib/services/enhanced_eneo_ocr_service.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models.dart';

class EnhancedEneoOCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<InvoiceData> processEneoInvoice(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Extraire le texte complet
      String fullText = recognizedText.text;
      print('📄 Texte OCR ENEO complet: $fullText');
      
      // Traiter spécifiquement pour ENEO
      return _extractEneoInvoiceData(fullText, recognizedText);
      
    } catch (e) {
      print('❌ Erreur OCR ENEO: $e');
      throw Exception('Erreur lors de la reconnaissance ENEO: $e');
    }
  }

  InvoiceData _extractEneoInvoiceData(String fullText, RecognizedText recognizedText) {
    Map<String, dynamic> rawData = {
      'full_text': fullText,
      'confidence': _calculateConfidence(recognizedText),
      'detected_format': 'ENEO_CAMEROUN',
    };

    // Nettoyer le texte pour ENEO
    String cleanText = fullText.toUpperCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('°', 'O') // Remplacer le symbole degré par O
        .replaceAll('№', 'N'); // Remplacer № par N

    print('🧹 Texte nettoyé ENEO: $cleanText');
    
    return InvoiceData(
      invoiceNumber: _extractEneoInvoiceNumber(cleanText),
      customerName: _extractEneoCustomerName(cleanText),
      amount: _extractEneoAmount(cleanText),
      date: _extractEneoDate(cleanText),
      meterNumber: _extractEneoMeterNumber(cleanText),
      currentReading: _extractEneoCurrentReading(cleanText),
      previousReading: _extractEneoPreviousReading(cleanText),
      consumption: _extractEneoConsumption(cleanText),
      rawData: rawData,
    );
  }

  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int elementCount = 0;
    
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          // Score basé sur la longueur et les mots clés ENEO
          double score = 0.5;
          if (element.text.length > 3) score += 0.3;
          if (element.text.toUpperCase().contains('ENEO')) score += 0.4;
          if (element.text.toUpperCase().contains('COMPTEUR')) score += 0.3;
          if (RegExp(r'\d{8,}').hasMatch(element.text)) score += 0.4;
          
          totalConfidence += score.clamp(0.0, 1.0);
          elementCount++;
        }
      }
    }
    
    return elementCount > 0 ? (totalConfidence / elementCount) : 0.0;
  }

  String? _extractEneoInvoiceNumber(String text) {
    // Patterns spécifiques ENEO pour numéro de facture
    List<RegExp> patterns = [
      // Format: N°425514358 ou N: 425514358
      RegExp(r'N[°O]?\s*:?\s*(\d{8,10})', caseSensitive: false),
      // Format: Facture N°396586037
      RegExp(r'FACTURE.*?N[°O]?\s*:?\s*(\d{8,10})', caseSensitive: false),
      // Format direct: 737537690 (après Electricity Bill)
      RegExp(r'ELECTRICITY\s*BILL.*?(\d{8,10})', caseSensitive: false),
      // Format: Bill N°
      RegExp(r'BILL.*?N[°O]?\s*:?\s*(\d{8,10})', caseSensitive: false),
      // Numéro isolé de 8-10 chiffres (après avoir éliminé les autres)
      RegExp(r'(?<![\d])\d{8,10}(?![\d])', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String number = match.group(1) ?? match.group(0)!;
        // Vérifier que ce n'est pas un numéro de compteur ou date
        if (!_isDateOrMeterNumber(number)) {
          print('🔢 Numéro facture ENEO trouvé: $number');
          return number;
        }
      }
    }
    
    print('❌ Numéro de facture ENEO non trouvé');
    return null;
  }

  String? _extractEneoCustomerName(String text) {
    // Patterns pour noms clients ENEO
    List<RegExp> patterns = [
      // Nom avant l'adresse ou après Central N°
      RegExp(r'CENTRAL\s*N[°O]?\s*:?\s*\d+\s+([A-Z\s]{15,50})', caseSensitive: false),
      // Nom sur plusieurs lignes typique ENEO
      RegExp(r'([A-Z]{3,}\s+[A-Z]{3,}(?:\s+[A-Z]{3,})*)\s*CENTRAL', caseSensitive: false),
      // Pattern générique pour nom propre en majuscules
      RegExp(r'([A-Z]{3,}\s+[A-Z]{3,}(?:\s+[A-Z]{3,})*)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String name = match.group(1)!.trim();
        // Nettoyer le nom
        name = name
            .replaceAll(RegExp(r'\b(ENEO|CAMEROUN|FACTURE|BILL|CENTRAL|CONTRACT)\b'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        
        if (name.length >= 6 && name.split(' ').length >= 2) {
          print('👤 Nom client ENEO trouvé: $name');
          return _formatCustomerName(name);
        }
      }
    }
    
    print('❌ Nom client ENEO non trouvé');
    return null;
  }

  double? _extractEneoAmount(String text) {
    // Patterns pour montants ENEO en FCFA
    List<RegExp> patterns = [
      // Format avec séparateurs: 1.570.723,752 ou 57.953
      RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,3})?)\s*FCFA', caseSensitive: false),
      // Format dans les totaux TTC
      RegExp(r'TOTAL.*?TTC.*?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,3})?)', caseSensitive: false),
      // Format montant de la facture
      RegExp(r'FACTURE.*?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,3})?)', caseSensitive: false),
      // Format avec WITH TAX
      RegExp(r'WITH\s*TAX.*?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,3})?)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String amountStr = match.group(1)!;
        try {
          // Convertir le format français/camerounais vers format standard
          amountStr = amountStr
              .replaceAll('.', '') // Enlever séparateurs de milliers
              .replaceAll(',', '.'); // Virgule devient point décimal
          
          double amount = double.parse(amountStr);
          // Vérifier que c'est un montant raisonnable (entre 100 et 10M FCFA)
          if (amount >= 100 && amount <= 10000000) {
            print('💰 Montant ENEO trouvé: ${amount.toStringAsFixed(0)} FCFA');
            return amount;
          }
        } catch (e) {
          continue;
        }
      }
    }
    
    print('❌ Montant ENEO non trouvé');
    return null;
  }

  DateTime? _extractEneoDate(String text) {
    // Patterns pour dates ENEO
    List<RegExp> patterns = [
      // Format DD/MM/YYYY typique ENEO
      RegExp(r'(\d{1,2}[/.-]\d{1,2}[/.-]\d{4})'),
      // Date après "Date"
      RegExp(r'DATE.*?(\d{1,2}[/.-]\d{1,2}[/.-]\d{4})', caseSensitive: false),
      // Date limite de paiement
      RegExp(r'DUE\s*DATE.*?(\d{1,2}[/.-]\d{1,2}[/.-]\d{4})', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String dateStr = match.group(1)!;
        try {
          DateTime? date = _parseEneoDate(dateStr);
          if (date != null) {
            print('📅 Date ENEO trouvée: ${date.day}/${date.month}/${date.year}');
            return date;
          }
        } catch (e) {
          continue;
        }
      }
    }
    
    print('❌ Date ENEO non trouvée');
    return null;
  }

  String? _extractEneoMeterNumber(String text) {
    // Patterns spécifiques ENEO pour numéro de compteur
    List<RegExp> patterns = [
      // Format: No. Compteur / Meter No: 021850139466
      RegExp(r'METER\s*NO[°O]?\s*:?\s*(\d{8,12})', caseSensitive: false),
      // Format: No. Compteur: 009210202161
      RegExp(r'COMPTEUR.*?(\d{8,12})', caseSensitive: false),
      // Format: Meter Number après des mots-clés
      RegExp(r'(?:METER|COMPTEUR).*?(\d{8,12})', caseSensitive: false),
      // Numéros longs potentiels de compteur (8-12 chiffres, pas de facture)
      RegExp(r'(?<!N[°O]\s*)(\d{8,12})(?!\s*FCFA)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String number = match.group(1)!;
        // Vérifier que ce n'est pas un numéro de facture déjà trouvé
        if (number.length >= 8 && !_isInvoiceNumber(number, text)) {
          print('🔌 Numéro compteur ENEO trouvé: $number');
          return number;
        }
      }
    }
    
    print('❌ Numéro compteur ENEO non trouvé');
    return null;
  }

  int? _extractEneoCurrentReading(String text) {
    // Patterns pour index actuel ENEO
    List<RegExp> patterns = [
      // Format: Current Reading ou Current Meter Consump.
      RegExp(r'CURRENT.*?READING.*?(\d{3,8})', caseSensitive: false),
      RegExp(r'CURRENT.*?METER.*?(\d{3,8})', caseSensitive: false),
      // Format: dans les tableaux avec Previous/Current
      RegExp(r'CURRENT.*?(\d{3,8})', caseSensitive: false),
      // Format français: Compteur actuel
      RegExp(r'ACTUEL.*?(\d{3,8})', caseSensitive: false),
    ];

    return _extractReadingValue(patterns, text, 'actuel');
  }

  int? _extractEneoPreviousReading(String text) {
    // Patterns pour index précédent ENEO
    List<RegExp> patterns = [
      // Format: Previous Reading
      RegExp(r'PREVIOUS.*?READING.*?(\d{3,8})', caseSensitive: false),
      RegExp(r'PREVIOUS.*?(\d{3,8})', caseSensitive: false),
      // Format français: Précédent
      RegExp(r'PRECEDENT.*?(\d{3,8})', caseSensitive: false),
    ];

    return _extractReadingValue(patterns, text, 'précédent');
  }

  double? _extractEneoConsumption(String text) {
    // Patterns pour consommation ENEO
    List<RegExp> patterns = [
      // Format: Energy Consumed ou kWh
      RegExp(r'ENERGY\s*CONSUMED.*?(\d{1,6})', caseSensitive: false),
      RegExp(r'(\d{1,6})\s*KWH', caseSensitive: false),
      // Format: Consommation
      RegExp(r'CONSOMMATION.*?(\d{1,6})', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        try {
          double consumption = double.parse(match.group(1)!);
          if (consumption > 0 && consumption < 100000) { // Limite raisonnable
            print('⚡ Consommation ENEO trouvée: ${consumption.toStringAsFixed(0)} kWh');
            return consumption;
          }
        } catch (e) {
          continue;
        }
      }
    }
    
    print('❌ Consommation ENEO non trouvée');
    return null;
  }

  // Méthodes utilitaires
  
  int? _extractReadingValue(List<RegExp> patterns, String text, String type) {
    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        try {
          int reading = int.parse(match.group(1)!);
          if (reading >= 0 && reading <= 99999999) { // Limite raisonnable
            print('📊 Index $type ENEO trouvé: $reading');
            return reading;
          }
        } catch (e) {
          continue;
        }
      }
    }
    
    print('❌ Index $type ENEO non trouvé');
    return null;
  }

  bool _isDateOrMeterNumber(String number) {
    // Vérifier si c'est une date (format DDMMYYYY ou YYYYMMDD)
    if (number.length == 8) {
      int year = int.tryParse(number.substring(0, 4)) ?? 0;
      if (year >= 1900 && year <= 2030) return true;
      
      int year2 = int.tryParse(number.substring(4, 8)) ?? 0;
      if (year2 >= 1900 && year2 <= 2030) return true;
    }
    
    // Vérifier si c'est potentiellement un numéro de compteur
    if (number.length >= 10) return true;
    
    return false;
  }

  bool _isInvoiceNumber(String number, String fullText) {
    // Vérifier si ce numéro apparaît près des mots-clés de facture
    String context = fullText.toUpperCase();
    List<String> invoiceKeywords = ['FACTURE', 'BILL', 'INVOICE', 'N°', 'NO'];
    
    for (String keyword in invoiceKeywords) {
      if (context.contains(keyword) && context.contains(number)) {
        int keywordIndex = context.indexOf(keyword);
        int numberIndex = context.indexOf(number);
        if ((numberIndex - keywordIndex).abs() < 50) {
          return true;
        }
      }
    }
    
    return false;
  }

  DateTime? _parseEneoDate(String dateStr) {
    List<String> parts = dateStr.split(RegExp(r'[/.-]'));
    if (parts.length != 3) return null;
    
    try {
      int day, month, year;
      
      // Détecter le format (DD/MM/YYYY vs MM/DD/YYYY vs YYYY/MM/DD)
      if (parts[0].length == 4) {
        // Format YYYY/MM/DD
        year = int.parse(parts[0]);
        month = int.parse(parts[1]);
        day = int.parse(parts[2]);
      } else {
        // Format DD/MM/YYYY (standard Cameroun)
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
        
        // Si l'année est à 2 chiffres, l'ajuster
        if (year < 100) {
          year += (year < 50) ? 2000 : 1900;
        }
      }
      
      // Vérifier la validité
      if (year < 2000 || year > 2030) return null;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  String _formatCustomerName(String name) {
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void dispose() {
    _textRecognizer.close();
  }
}

// Service principal OCR qui détecte automatiquement le type de facture
class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final EnhancedEneoOCRService _eneoService = EnhancedEneoOCRService();

  Future<InvoiceData> processInvoice(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String fullText = recognizedText.text.toUpperCase();
      
      // Détecter si c'est une facture ENEO
      if (_isEneoInvoice(fullText)) {
        print('🏢 Facture ENEO détectée - Utilisation du parser spécialisé');
        return await _eneoService.processEneoInvoice(imagePath);
      } else {
        print('📄 Facture générique détectée - Utilisation du parser standard');
        return await _processGenericInvoice(imagePath, recognizedText);
      }
      
    } catch (e) {
      print('❌ Erreur OCR générale: $e');
      throw Exception('Erreur lors de la reconnaissance: $e');
    }
  }

  bool _isEneoInvoice(String text) {
    // Indicateurs que c'est une facture ENEO
    List<String> eneoIndicators = [
      'ENEO',
      'ENERGY OF CAMEROON',
      'CAMEROUN',
      'ELECTRICITY BILL',
      'FACTURE D\'ELECTRICITE',
      'METER NO',
      'NO. COMPTEUR',
    ];
    
    int indicators = 0;
    for (String indicator in eneoIndicators) {
      if (text.contains(indicator)) {
        indicators++;
      }
    }
    
    // Si au moins 2 indicateurs ENEO sont présents
    bool isEneo = indicators >= 2;
    print('🔍 Indicateurs ENEO trouvés: $indicators - ${isEneo ? "ENEO" : "Générique"}');
    
    return isEneo;
  }

  Future<InvoiceData> _processGenericInvoice(String imagePath, RecognizedText recognizedText) async {
    // Fallback vers l'ancien système pour les factures non-ENEO
    String fullText = recognizedText.text;
    String cleanText = fullText.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    
    return InvoiceData(
      invoiceNumber: _extractGenericInvoiceNumber(cleanText),
      customerName: _extractGenericCustomerName(cleanText),
      amount: _extractGenericAmount(cleanText),
      date: _extractGenericDate(cleanText),
      meterNumber: _extractGenericMeterNumber(cleanText),
      currentReading: _extractGenericCurrentReading(cleanText),
      previousReading: _extractGenericPreviousReading(cleanText),
      consumption: _extractGenericConsumption(cleanText),
      rawData: {
        'full_text': fullText,
        'detected_format': 'GENERIC',
        'confidence': 0.7,
      },
    );
  }

  // Méthodes génériques (versions simplifiées pour les factures non-ENEO)
  
  String? _extractGenericInvoiceNumber(String text) {
    List<RegExp> patterns = [
      RegExp(r'FAC[T]?[-\s]*(\d{4}[-\s]*\d{6})'),
      RegExp(r'INVOICE\s*N[°O]?\s*:?\s*([A-Z0-9-]{6,})'),
      RegExp(r'([A-Z]{2,4}[-\s]*\d{4}[-\s]*\d{6})'),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1) ?? match.group(0)!;
      }
    }
    return null;
  }

  String? _extractGenericCustomerName(String text) {
    List<RegExp> patterns = [
      RegExp(r'CLIENT\s*:?\s*([A-Z\s]{10,40})'),
      RegExp(r'NAME\s*:?\s*([A-Z\s]{10,40})'),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String name = match.group(1)!.trim();
        if (name.length >= 3) {
          return name;
        }
      }
    }
    return null;
  }

  double? _extractGenericAmount(String text) {
    List<RegExp> patterns = [
      RegExp(r'TOTAL\s*:?\s*([0-9,.\s]+)\s*FCFA'),
      RegExp(r'AMOUNT\s*:?\s*([0-9,.\s]+)'),
      RegExp(r'(\d{1,3}(?:[,.\s]\d{3})*(?:[,.]\d{2})?)\s*FCFA'),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String amountStr = match.group(1)!.replaceAll(RegExp(r'[,\s]'), '');
        try {
          return double.parse(amountStr);
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  DateTime? _extractGenericDate(String text) {
    RegExp pattern = RegExp(r'(\d{1,2}[/.-]\d{1,2}[/.-]\d{4})');
    Match? match = pattern.firstMatch(text);
    if (match != null) {
      try {
        List<String> parts = match.group(1)!.split(RegExp(r'[/.-]'));
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String? _extractGenericMeterNumber(String text) {
    List<RegExp> patterns = [
      RegExp(r'METER\s*N[°O]?\s*:?\s*([A-Z0-9-]{6,})'),
      RegExp(r'COMPTEUR\s*:?\s*([A-Z0-9-]{6,})'),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!;
      }
    }
    return null;
  }

  int? _extractGenericCurrentReading(String text) {
    RegExp pattern = RegExp(r'CURRENT.*?(\d+)');
    Match? match = pattern.firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  int? _extractGenericPreviousReading(String text) {
    RegExp pattern = RegExp(r'PREVIOUS.*?(\d+)');
    Match? match = pattern.firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  double? _extractGenericConsumption(String text) {
    RegExp pattern = RegExp(r'(\d+)\s*KWH');
    Match? match = pattern.firstMatch(text);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }

  void dispose() {
    _textRecognizer.close();
    _eneoService.dispose();
  }
}