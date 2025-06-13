// lib/screens/resultat_screen.dart
import 'package:flutter/material.dart';

class ResultatScreen extends StatefulWidget {
  @override
  _ResultatScreenState createState() => _ResultatScreenState();
}

class _ResultatScreenState extends State<ResultatScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Données simulées extraites de la facture
  final Map<String, dynamic> _extractedData = {
    'facture_numero': 'FAC-2024-001234',
    'nom_client': 'PATRICE KAMDEM',
    'montant': '45,650 FCFA',
    'date': '15/12/2024',
    'compteur_numero': 'COMP-789456',
    'index_precedent': '12450',
    'index_actuel': '12680',
    'consommation': '230 kWh',
    'statut_validation': 'validee', // 'validee', 'rejected', 'pending'
  };

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (_extractedData['statut_validation']) {
      case 'validee':
        return Color(0xFF4CAF50);
      case 'rejected':
        return Color(0xFFf44336);
      default:
        return Color(0xFFFF9800);
    }
  }

  IconData _getStatusIcon() {
    switch (_extractedData['statut_validation']) {
      case 'validee':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getStatusText() {
    switch (_extractedData['statut_validation']) {
      case 'validee':
        return 'Facture validée';
      case 'rejected':
        return 'Facture rejetée';
      default:
        return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[800]),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context, 
            '/home', 
            (route) => false,
          ),
        ),
        title: Text(
          'Résultats de l\'analyse',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * _slideAnimation.value),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Statut de validation
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor().withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getStatusIcon(),
                            size: 60,
                            color: _getStatusColor(),
                          ),
                          SizedBox(height: 15),
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            _extractedData['statut_validation'] == 'validee'
                                ? 'La facture correspond aux données de votre compteur'
                                : _extractedData['statut_validation'] == 'rejected'
                                ? 'Incohérence détectée avec les données du compteur'
                                : 'Validation en cours...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Informations extraites
                    _buildInfoSection(
                      title: 'Informations de la facture',
                      items: [
                        _buildInfoItem('Numéro de facture', _extractedData['facture_numero']),
                        _buildInfoItem('Nom du client', _extractedData['nom_client']),
                        _buildInfoItem('Montant total', _extractedData['montant']),
                        _buildInfoItem('Date d\'émission', _extractedData['date']),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Informations du compteur
                    _buildInfoSection(
                      title: 'Données du compteur',
                      items: [
                        _buildInfoItem('Numéro de compteur', _extractedData['compteur_numero']),
                        _buildInfoItem('Index précédent', _extractedData['index_precedent']),
                        _buildInfoItem('Index actuel', _extractedData['index_actuel']),
                        _buildInfoItem('Consommation', _extractedData['consommation']),
                      ],
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Sauvegarder dans l'historique
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Facture sauvegardée'),
                                  backgroundColor: Color(0xFF4CAF50),
                                ),
                              );
                            },
                            icon: Icon(Icons.save),
                            label: Text('Sauvegarder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF667eea),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Partager les résultats
                            },
                            icon: Icon(Icons.share),
                            label: Text('Partager'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF667eea),
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Color(0xFF667eea)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 15),
                    
                    // Bouton de nouvelle analyse
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/camera');
                        },
                        icon: Icon(Icons.camera_alt),
                        label: Text('Nouvelle analyse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF667eea),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Color(0xFF667eea)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 20),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}