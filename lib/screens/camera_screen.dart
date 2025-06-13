// lib/screens/camera_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Demander les permissions
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus != PermissionStatus.granted) {
      _showPermissionDialog();
      return;
    }

    try {
      // Obtenir les caméras disponibles
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showNoCameraDialog();
        return;
      }

      // Initialiser la caméra
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Erreur caméra: $e');
      _showCameraError();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      
      setState(() {
        _capturedImagePath = image.path;
        _isProcessing = false;
      });

      // Naviguer vers l'analyse avec le chemin de l'image
      Navigator.pushNamed(
        context, 
        '/analyse',
        arguments: {'imagePath': image.path},
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la capture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      
      if (image != null) {
        Navigator.pushNamed(
          context, 
          '/analyse',
          arguments: {'imagePath': image.path},
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur galerie: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission requise'),
        content: Text('L\'accès à la caméra est nécessaire pour scanner les factures.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  void _showNoCameraDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Caméra non disponible'),
        content: Text('Aucune caméra détectée sur cet appareil.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCameraError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur caméra'),
        content: Text('Impossible d\'initialiser la caméra.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Aperçu de la caméra ou chargement
            if (_isInitialized && _cameraController != null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Initialisation de la caméra...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Scanner une facture',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Pour équilibrer avec le bouton retour
                  ],
                ),
              ),
            ),
            
            // Overlay avec cadre de capture
            if (_isInitialized)
              CustomPaint(
                painter: CameraOverlayPainter(),
                child: Container(),
              ),
            
            // Instructions
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Placez la facture dans le cadre\nAssurez-vous qu\'elle soit bien éclairée et lisible',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Contrôles en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Galerie
                      _buildControlButton(
                        icon: Icons.photo_library,
                        label: 'Galerie',
                        onTap: _pickFromGallery,
                      ),
                      
                      // Bouton de capture principal
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: GestureDetector(
                              onTap: _isProcessing || !_isInitialized ? null : _takePicture,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _isProcessing || !_isInitialized 
                                      ? Colors.grey 
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _isProcessing
                                    ? CircularProgressIndicator(
                                        color: Colors.grey[600],
                                        strokeWidth: 3,
                                      )
                                    : Icon(
                                        Icons.camera_alt,
                                        size: 35,
                                        color: _isInitialized 
                                            ? Colors.grey[700] 
                                            : Colors.grey[500],
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Flash toggle (placeholder)
                      _buildControlButton(
                        icon: Icons.flash_off,
                        label: 'Flash',
                        onTap: () {
                          // TODO: Implémenter le toggle flash
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Indicateur de traitement global
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircularProgressIndicator(
                          color: Color(0xFF667eea),
                          strokeWidth: 4,
                        ),
                      ),
                      SizedBox(height: 30),
                      Text(
                        'Capture en cours...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 25,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Painter pour dessiner le cadre de capture
class CameraOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final frameWidth = size.width * 0.8;
    final frameHeight = size.height * 0.5;
    final cornerLength = 25.0;

    final left = centerX - frameWidth / 2;
    final right = centerX + frameWidth / 2;
    final top = centerY - frameHeight / 2;
    final bottom = centerY + frameHeight / 2;

    // Coins du cadre
    // Coin supérieur gauche
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), paint);
    
    // Coin supérieur droit
    canvas.drawLine(Offset(right, top), Offset(right - cornerLength, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), paint);

    // Coin inférieur gauche
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left, bottom - cornerLength), paint);
    
    // Coin inférieur droit
    canvas.drawLine(Offset(right, bottom), Offset(right - cornerLength, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), paint);

    // Ligne centrale horizontale (guide)
    final centerLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(left + 20, centerY), 
      Offset(right - 20, centerY), 
      centerLinePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}