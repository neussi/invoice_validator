// lib/screens/analyse_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import '../services/enhanced_eneo_ocr_service.dart'; // ✅ Nouveau service ENEO
import '../database.dart';
import '../models.dart';
import '../main.dart';

class AnalyseScreen extends StatefulWidget {
  @override
  _AnalyseScreenState createState() => _AnalyseScreenState();
}

class _AnalyseScreenState extends State<AnalyseScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  int _currentStep = 0;
  String _currentStepText = 'Préparation de l\'image...';
  String? _imagePath;
  InvoiceData? _extractedData;
  ValidationResult? _validationResult;
  bool _hasError = false;
  String _errorMessage = '';
  String _detectedFormat = 'UNKNOWN';
  double _ocrConfidence = 0.0;
  
  final List<String> _steps = [
    'Préparation de l\'image...',
    'Reconnaissance optique (OCR)...',
    'Extraction des informations...',
    'Validation des données...',
    'Analyse terminée !',
  ];

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: Duration(seconds: 12), // Augmenté pour la nouvelle validation
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();

    // Récupérer l'image passée en argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['imagePath'] != null) {
        _imagePath = args['imagePath'];
        _startEnhancedAnalysis();
      } else {
        _showError('Aucune image fournie');
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startEnhancedAnalysis() async {
    if (_imagePath == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser == null) {
      _showError('Utilisateur non connecté');
      return;
    }

    _pulseController.repeat(reverse: true);
    _progressController.forward();
    
    try {
      print('🚀 Début de l\'analyse ENEO avancée');
      print('📁 Chemin image: $_imagePath');
      
      // Étape 1: Préparation et validation de l'image
      await Future.delayed(Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          _currentStep = 1;
          _currentStepText = _steps[1];
        });
      }

      // Vérifier que le fichier existe
      File imageFile = File(_imagePath!);
      if (!await imageFile.exists()) {
        throw Exception('Fichier image introuvable');
      }

      // Étape 2: OCR avec détection automatique ENEO
      await Future.delayed(Duration(milliseconds: 1200));
      if (mounted) {
        setState(() {
          _currentStep = 2;
          _currentStepText = 'Analyse intelligente ENEO...';
        });
      }

      print('🔍 Initialisation du service OCR Enhanced ENEO');
      
      // ✅ Utilisation du nouveau service OCR ENEO
      final enhancedOcrService = OCRService();
      _extractedData = await enhancedOcrService.processInvoice(_imagePath!);

      // Récupérer les informations du format détecté
      _detectedFormat = _extractedData?.rawData['detected_format'] ?? 'UNKNOWN';
      _ocrConfidence = _extractedData?.rawData['confidence'] ?? 0.0;

      print('📊 Format détecté: $_detectedFormat');
      print('🎯 Confiance OCR: ${(_ocrConfidence * 100).toInt()}%');
      print('📄 Données extraites: ${_extractedData?.toMap()}');

      // Étape 3: Validation des données extraites
      await Future.delayed(Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          _currentStep = 3;
          _currentStepText = _steps[3];
        });
      }

      // Vérifier que des données ont été extraites
      if (_extractedData == null) {
        throw Exception('Aucune donnée extraite de la facture');
      }

      // Étape 4: Validation avec la base de données ENEO
      await Future.delayed(Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _currentStepText = _detectedFormat == 'ENEO_CAMEROUN' 
              ? 'Validation ENEO Cameroun...' 
              : 'Validation générique...';
        });
      }

      print('🏢 Début validation avec base de données');
      
      // ✅ Validation avancée avec les vraies données ENEO
      _validationResult = await DatabaseHelper.instance.validateInvoice(_extractedData!);
      
      print('✅ Résultat validation: ${_validationResult?.status}');
      print('🎯 Score validation: ${(_validationResult?.confidenceScore ?? 0 * 100).toInt()}%');
      print('❌ Erreurs: ${_validationResult?.errors}');
      print('⚠️  Avertissements: ${_validationResult?.warnings}');

      // Étape 5: Finalisation
      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _currentStep = 4;
          _currentStepText = _steps[4];
        });
      }

      _pulseController.stop();
      
      print('🎉 Analyse terminée avec succès');
      
      // Naviguer vers les résultats avec toutes les données
      await Future.delayed(Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.pushReplacementNamed(
          context, 
          '/resultat',
          arguments: {
            'invoiceData': _extractedData,
            'validationResult': _validationResult,
            'imagePath': _imagePath,
            'detectedFormat': _detectedFormat,
            'ocrConfidence': _ocrConfidence,
          },
        );
      }

    } catch (e) {
      print('💥 Erreur analyse Enhanced: $e');
      _showError('Erreur lors de l\'analyse: ${e.toString()}');
    }
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
    _pulseController.stop();
    _progressController.stop();
    
    print('❌ Erreur affichée: $message');
  }

  void _retryAnalysis() {
    print('🔄 Redémarrage de l\'analyse');
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _currentStep = 0;
      _currentStepText = _steps[0];
      _detectedFormat = 'UNKNOWN';
      _ocrConfidence = 0.0;
    });
    
    _progressController.reset();
    _startEnhancedAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1117),
              Color(0xFF161B22),
              Color(0xFF21262D),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header moderne avec détection de format
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _detectedFormat == 'ENEO_CAMEROUN' ? 'Analyse ENEO' : 'Analyse Intelligente',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_detectedFormat != 'UNKNOWN')
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _detectedFormat == 'ENEO_CAMEROUN' 
                                      ? Color(0xFF2196F3).withOpacity(0.2)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _detectedFormat == 'ENEO_CAMEROUN' 
                                        ? Color(0xFF2196F3)
                                        : Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  _detectedFormat == 'ENEO_CAMEROUN' ? 'ENEO Cameroun' : 'Générique',
                                  style: TextStyle(
                                    color: _detectedFormat == 'ENEO_CAMEROUN' 
                                        ? Color(0xFF2196F3)
                                        : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 44),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    physics: BouncingScrollPhysics(),
                    child: _hasError ? _buildErrorView() : _buildAnalysisView(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisView() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height - 240, // Ajusté pour le header plus grand
      ),
      child: Column(
        children: [
          SizedBox(height: 16),
          
          // Image de la facture avec effet moderne et indicateur de format
          if (_imagePath != null)
            Container(
              width: 260,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: Offset(0, 15),
                  ),
                  BoxShadow(
                    color: (_detectedFormat == 'ENEO_CAMEROUN' ? Color(0xFF2196F3) : Color(0xFF667eea)).withOpacity(0.2),
                    blurRadius: 30,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Image réelle avec bordure colorée selon le format
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (_detectedFormat == 'ENEO_CAMEROUN' ? Color(0xFF2196F3) : Colors.white).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        File(_imagePath!),
                        width: 260,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  // Overlay de scan animé adapté au format
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: (_progressAnimation.value * 270) + 15,
                        left: 15,
                        right: 15,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                _detectedFormat == 'ENEO_CAMEROUN' ? Color(0xFF2196F3) : Color(0xFF667eea),
                                _detectedFormat == 'ENEO_CAMEROUN' ? Color(0xFF1976D2) : Color(0xFF764ba2),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: (_detectedFormat == 'ENEO_CAMEROUN' ? Color(0xFF2196F3) : Color(0xFF667eea)).withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Indicateur de progression avec confiance OCR
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.5)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        _ocrConfidence > 0 
                            ? '${((_currentStep + 1) / _steps.length * 100).toInt()}% • ${(_ocrConfidence * 100).toInt()}%'
                            : '${((_currentStep + 1) / _steps.length * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Badge ENEO si détecté
                  if (_detectedFormat == 'ENEO_CAMEROUN')
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF2196F3).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.business, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'ENEO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          SizedBox(height: 32),
          
          // Indicateur de progression circulaire adaptatif
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (_detectedFormat == 'ENEO_CAMEROUN' ? Color(0xFF2196F3) : Color(0xFF667eea)).withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: _progressAnimation.value,
                              strokeWidth: 5,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _detectedFormat == 'ENEO_CAMEROUN' ? Color(0xFF2196F3) : Color(0xFF667eea),
                              ),
                              strokeCap: StrokeCap.round,
                            );
                          },
                        ),
                      ),
                      
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _detectedFormat == 'ENEO_CAMEROUN' 
                                ? [Color(0xFF2196F3), Color(0xFF1976D2)]
                                : [Color(0xFF667eea), Color(0xFF764ba2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_detectedFormat == 'ENEO_CAMEROUN' ? Color(0xFF2196F3) : Color(0xFF667eea)).withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          _currentStep >= 3 
                              ? Icons.verified_rounded 
                              : (_detectedFormat == 'ENEO_CAMEROUN' ? Icons.business : Icons.auto_awesome_rounded),
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: 24),
          
          // Texte de l'étape actuelle
          Container(
            height: 50,
            child: Center(
              child: Text(
                _currentStepText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Indicateurs d'étapes colorés selon le format
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (index) {
                bool isActive = index <= _currentStep;
                bool isCurrent = index == _currentStep;
                
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  width: isCurrent ? 40 : (isActive ? 24 : 12),
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: _detectedFormat == 'ENEO_CAMEROUN' 
                                ? [Color(0xFF2196F3), Color(0xFF1976D2)]
                                : [Color(0xFF667eea), Color(0xFF764ba2)],
                          )
                        : null,
                    color: isActive ? null : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: (_detectedFormat == 'ENEO_CAMEROUN' ? Color(0xFF2196F3) : Color(0xFF667eea)).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ] : null,
                  ),
                );
              }),
            ),
          ),
          
          SizedBox(height: 32),
          
          // Informations techniques enrichies
          Container(
            margin: EdgeInsets.only(bottom: 24),
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Technologie:',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _detectedFormat == 'ENEO_CAMEROUN' ? 'ENEO OCR Specialist' : 'Google ML Kit OCR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Format:',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _detectedFormat == 'ENEO_CAMEROUN' 
                                  ? Color(0xFF2196F3)
                                  : (_detectedFormat == 'GENERIC' ? Color(0xFFFF9800) : Colors.grey),
                            ),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _detectedFormat == 'ENEO_CAMEROUN' 
                                  ? 'ENEO Cameroun'
                                  : (_detectedFormat == 'GENERIC' ? 'Générique' : 'Détection...'),
                              style: TextStyle(
                                color: _detectedFormat == 'ENEO_CAMEROUN' 
                                    ? Color(0xFF2196F3)
                                    : (_detectedFormat == 'GENERIC' ? Color(0xFFFF9800) : Colors.grey),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Validation:',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentStep < 3 
                                  ? Color(0xFFFF9800)
                                  : (_currentStep == 3 
                                      ? Color(0xFF2196F3) 
                                      : Color(0xFF4CAF50)),
                            ),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _currentStep < 3 
                                  ? 'En attente...' 
                                  : (_currentStep == 3 
                                      ? (_detectedFormat == 'ENEO_CAMEROUN' ? 'ENEO DB...' : 'Validation...') 
                                      : 'Terminée'),
                              style: TextStyle(
                                color: _currentStep < 3 
                                    ? Color(0xFFFF9800)
                                    : (_currentStep == 3 
                                        ? Color(0xFF2196F3) 
                                        : Color(0xFF4CAF50)),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height - 240,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.red.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.red[400],
            ),
          ),
          SizedBox(height: 24),
          
          Text(
            'Erreur d\'analyse',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: 32),
          
          // Bouton de nouvelle tentative
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: _retryAnalysis,
              icon: Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Réessayer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF667eea),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: Color(0xFF667eea).withOpacity(0.3),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Bouton retour à l'accueil
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, 
                '/home', 
                (route) => false,
              ),
              icon: Icon(
                Icons.home_rounded, 
                color: Colors.white.withOpacity(0.8),
              ),
              label: Text(
                'Retour à l\'accueil',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }
}