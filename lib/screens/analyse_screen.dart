// lib/screens/analyse_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../services/ocr_service.dart';

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
  bool _hasError = false;
  String _errorMessage = '';
  
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
      duration: Duration(seconds: 8),
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
        _startAnalysis();
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

  void _startAnalysis() async {
    if (_imagePath == null) return;

    _pulseController.repeat(reverse: true);
    _progressController.forward();
    
    try {
      // Étape 1: Préparation
      await Future.delayed(Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _currentStep = 1;
          _currentStepText = _steps[1];
        });
      }

      // Étape 2: OCR réel
      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _currentStep = 2;
          _currentStepText = _steps[2];
        });
      }

      // Traitement OCR réel
      final ocrService = OCRService();
      _extractedData = await ocrService.processInvoice(_imagePath!);

      // Étape 3: Extraction
      await Future.delayed(Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          _currentStep = 3;
          _currentStepText = _steps[3];
        });
      }

      // Étape 4: Validation
      await Future.delayed(Duration(milliseconds: 1200));
      if (mounted) {
        setState(() {
          _currentStep = 4;
          _currentStepText = _steps[4];
        });
      }

      _pulseController.stop();
      
      // Naviguer vers les résultats
      await Future.delayed(Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushReplacementNamed(
          context, 
          '/resultat',
          arguments: {
            'invoiceData': _extractedData,
            'imagePath': _imagePath,
          },
        );
      }

    } catch (e) {
      print('Erreur analyse: $e');
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
  }

  void _retryAnalysis() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _currentStep = 0;
      _currentStepText = _steps[0];
    });
    
    _progressController.reset();
    _startAnalysis();
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
                // Header moderne
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
                        child: Text(
                          'Analyse intelligente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
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
        minHeight: MediaQuery.of(context).size.height - 200, // Assure la hauteur minimale
      ),
      child: Column(
        children: [
          SizedBox(height: 16), // Réduit de 20 à 16
          
          // Image de la facture avec effet moderne
          if (_imagePath != null)
            Container(
              width: 260, // Réduit de 280 à 260
              height: 300, // Réduit de 320 à 300
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Color(0xFF667eea).withOpacity(0.2),
                    blurRadius: 30,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Image réelle avec bordure
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
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
                  
                  // Overlay de scan animé amélioré
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
                                Color(0xFF667eea),
                                Color(0xFF764ba2),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF667eea).withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Indicateur de progression dans le coin
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
                        '${((_currentStep + 1) / _steps.length * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(height: 32), // Réduit de 40 à 32
          
          // Indicateur de progression circulaire amélioré
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100, // Réduit de 120 à 100
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Cercle de fond
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFF667eea).withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      
                      // Cercle de progression principal
                      SizedBox(
                        width: 80, // Réduit de 100 à 80
                        height: 80,
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: _progressAnimation.value,
                              strokeWidth: 5, // Réduit de 6 à 5
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF667eea),
                              ),
                              strokeCap: StrokeCap.round,
                            );
                          },
                        ),
                      ),
                      
                      // Icône centrale animée
                      Container(
                        width: 50, // Réduit de 60 à 50
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF667eea).withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 24, // Réduit de 28 à 24
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: 24), // Réduit de 32 à 24
          
          // Texte de l'étape actuelle avec animation
          Container(
            height: 50, // Réduit de 60 à 50
            child: Center(
              child: Text(
                _currentStepText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16, // Réduit de 18 à 16
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          SizedBox(height: 20), // Réduit de 24 à 20
          
          // Indicateurs d'étapes améliorés
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
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          )
                        : null,
                    color: isActive ? null : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: Color(0xFF667eea).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ] : null,
                  ),
                );
              }),
            ),
          ),
          
          SizedBox(height: 32), // Espace flexible
          
          // Informations techniques améliorées
          Container(
            margin: EdgeInsets.only(bottom: 24), // Espace de fin
            padding: EdgeInsets.all(18), // Réduit de 20 à 18
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
                        'IA utilisée:',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13, // Réduit de 14 à 13
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Google ML Kit OCR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13, // Réduit de 14 à 13
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10), // Réduit de 12 à 10
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Statut:',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13, // Réduit de 14 à 13
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
                              color: _currentStep < _steps.length - 1 
                                  ? Color(0xFFFF9800)
                                  : Color(0xFF4CAF50),
                            ),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _currentStep < _steps.length - 1 ? 'En cours...' : 'Terminé',
                              style: TextStyle(
                                color: _currentStep < _steps.length - 1 
                                    ? Color(0xFFFF9800)
                                    : Color(0xFF4CAF50),
                                fontSize: 13, // Réduit de 14 à 13
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
        minHeight: MediaQuery.of(context).size.height - 200,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône d'erreur avec animation
          Container(
            width: 80, // Réduit de 100 à 80
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
              size: 50, // Réduit de 60 à 50
              color: Colors.red[400],
            ),
          ),
          SizedBox(height: 24), // Réduit de 32 à 24
          
          Text(
            'Erreur d\'analyse',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22, // Réduit de 24 à 22
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12), // Réduit de 16 à 12
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 15, // Réduit de 16 à 15
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 3, // Réduit de 4 à 3
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 32), // Réduit de 48 à 32
          
          // Boutons d'action améliorés
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48, // Réduit de 50 à 48
                    child: ElevatedButton.icon(
                      onPressed: _retryAnalysis,
                      icon: Icon(Icons.refresh_rounded, size: 18), // Réduit de 20 à 18
                      label: Text(
                        'Réessayer',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15, // Réduit de 16 à 15
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(
                        'Retour',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24), // Espace de fin
        ],
      ),
    );
  }
}