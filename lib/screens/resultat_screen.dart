// lib/screens/resultat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models.dart';
import '../database.dart';
import '../main.dart';

class ResultatScreen extends StatefulWidget {
  @override
  _ResultatScreenState createState() => _ResultatScreenState();
}

class _ResultatScreenState extends State<ResultatScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  InvoiceData? _invoiceData;
  ValidationResult? _validationResult;
  String? _imagePath;
  bool _isLoading = false;

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

    // Récupérer les données passées en argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _invoiceData = args['invoiceData'] as InvoiceData?;
          _validationResult = args['validationResult'] as ValidationResult?;
          _imagePath = args['imagePath'] as String?;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (_validationResult == null) return Color(0xFFFF9800);
    
    switch (_validationResult!.status) {
      case 'validated':
        return Color(0xFF4CAF50);
      case 'rejected':
        return Color(0xFFf44336);
      default:
        return Color(0xFFFF9800);
    }
  }

  IconData _getStatusIcon() {
    if (_validationResult == null) return Icons.hourglass_empty;
    
    switch (_validationResult!.status) {
      case 'validated':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  String _getStatusText() {
    if (_validationResult == null) return 'Validation en cours';
    
    switch (_validationResult!.status) {
      case 'validated':
        return 'Facture validée';
      case 'rejected':
        return 'Facture rejetée';
      default:
        return 'Validation en attente';
    }
  }

  String _getStatusDescription() {
    if (_validationResult == null) return 'Analyse en cours...';
    
    switch (_validationResult!.status) {
      case 'validated':
        return 'Les données de la facture correspondent parfaitement aux relevés de votre compteur';
      case 'rejected':
        return 'Des incohérences ont été détectées entre la facture et les données de votre compteur';
      default:
        return 'La validation nécessite une vérification manuelle supplémentaire';
    }
  }

  Future<void> _validateInvoice() async {
    if (_invoiceData == null || _validationResult == null) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser == null) return;

      // Créer une nouvelle facture en base avec le statut validé
      final invoice = Invoice(
        invoiceNumber: _invoiceData!.invoiceNumber ?? 'N/A',
        customerName: _invoiceData!.customerName ?? 'N/A',
        amount: _invoiceData!.amount ?? 0.0,
        date: _invoiceData!.date ?? DateTime.now(),
        status: 'validated',
        imagePath: _imagePath,
        userId: userProvider.currentUser!.id!,
        createdAt: DateTime.now(),
        meterNumber: _invoiceData!.meterNumber,
        currentReading: _invoiceData!.currentReading,
        previousReading: _invoiceData!.previousReading,
        consumption: _invoiceData!.calculatedConsumption,
      );

      await DatabaseHelper.instance.insertInvoice(invoice);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Facture validée et sauvegardée avec succès'),
            ],
          ),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Erreur lors de la sauvegarde: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectInvoice() async {
    if (_invoiceData == null) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser == null) return;

      // Créer une nouvelle facture en base avec le statut rejeté
      final invoice = Invoice(
        invoiceNumber: _invoiceData!.invoiceNumber ?? 'N/A',
        customerName: _invoiceData!.customerName ?? 'N/A',
        amount: _invoiceData!.amount ?? 0.0,
        date: _invoiceData!.date ?? DateTime.now(),
        status: 'rejected',
        imagePath: _imagePath,
        userId: userProvider.currentUser!.id!,
        createdAt: DateTime.now(),
        meterNumber: _invoiceData!.meterNumber,
        currentReading: _invoiceData!.currentReading,
        previousReading: _invoiceData!.previousReading,
        consumption: _invoiceData!.calculatedConsumption,
      );

      await DatabaseHelper.instance.insertInvoice(invoice);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Facture rejetée et enregistrée'),
            ],
          ),
          backgroundColor: Color(0xFFFF9800),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
          'Résultats de validation',
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
                            _getStatusDescription(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          // Score de confiance
                          if (_validationResult?.confidenceScore != null) ...[
                            SizedBox(height: 15),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Confiance: ${(_validationResult!.confidenceScore! * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Erreurs et avertissements
                    if (_validationResult?.errors.isNotEmpty == true) ...[
                      SizedBox(height: 20),
                      _buildMessageSection(
                        title: 'Erreurs détectées',
                        messages: _validationResult!.errors,
                        color: Colors.red,
                        icon: Icons.error_outline,
                      ),
                    ],
                    
                    if (_validationResult?.warnings.isNotEmpty == true) ...[
                      SizedBox(height: 20),
                      _buildMessageSection(
                        title: 'Avertissements',
                        messages: _validationResult!.warnings,
                        color: Colors.orange,
                        icon: Icons.warning_amber_outlined,
                      ),
                    ],
                    
                    SizedBox(height: 30),
                    
                    // Informations extraites de la facture
                    _buildInfoSection(
                      title: 'Données extraites de la facture',
                      items: [
                        _buildInfoItem('Numéro de facture', _invoiceData?.invoiceNumber ?? 'Non détecté'),
                        _buildInfoItem('Nom du client', _invoiceData?.customerName ?? 'Non détecté'),
                        _buildInfoItem('Montant total', _invoiceData?.amount != null 
                            ? '${_invoiceData!.amount!.toStringAsFixed(0)} FCFA' 
                            : 'Non détecté'),
                        _buildInfoItem('Date d\'émission', _invoiceData?.date != null 
                            ? '${_invoiceData!.date!.day}/${_invoiceData!.date!.month}/${_invoiceData!.date!.year}' 
                            : 'Non détectée'),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Données du compteur de la facture
                    _buildInfoSection(
                      title: 'Données du compteur (facture)',
                      items: [
                        _buildInfoItem('Numéro de compteur', _invoiceData?.meterNumber ?? 'Non détecté'),
                        _buildInfoItem('Index précédent', _invoiceData?.previousReading?.toString() ?? 'Non détecté'),
                        _buildInfoItem('Index actuel', _invoiceData?.currentReading?.toString() ?? 'Non détecté'),
                        _buildInfoItem('Consommation', _invoiceData?.calculatedConsumption != null 
                            ? '${_invoiceData!.calculatedConsumption!.toStringAsFixed(1)} kWh' 
                            : 'Non calculée'),
                      ],
                    ),
                    
                    // Données du compteur de la base de données
                    if (_validationResult?.matchedMeterReading != null) ...[
                      SizedBox(height: 20),
                      _buildInfoSection(
                        title: 'Données de référence (base de données)',
                        items: [
                          _buildInfoItem('Numéro de compteur', _validationResult!.matchedMeterReading!.meterNumber),
                          _buildInfoItem('Index précédent', _validationResult!.matchedMeterReading!.previousReading.toString()),
                          _buildInfoItem('Index actuel', _validationResult!.matchedMeterReading!.currentReading.toString()),
                          _buildInfoItem('Consommation', '${_validationResult!.matchedMeterReading!.consumption.toStringAsFixed(1)} kWh'),
                          _buildInfoItem('Date de relevé', '${_validationResult!.matchedMeterReading!.readingDate.day}/${_validationResult!.matchedMeterReading!.readingDate.month}/${_validationResult!.matchedMeterReading!.readingDate.year}'),
                        ],
                      ),
                    ],
                    
                    SizedBox(height: 30),
                    
                    // Boutons d'action selon le statut
                    if (_validationResult?.status == 'validated') ...[
                      // Facture validée - bouton pour confirmer
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _validateInvoice,
                          icon: _isLoading 
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(Icons.check_circle),
                          label: Text(_isLoading ? 'Sauvegarde...' : 'Confirmer et sauvegarder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ] else if (_validationResult?.status == 'rejected') ...[
                      // Facture rejetée - bouton pour enregistrer le rejet
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _rejectInvoice,
                          icon: _isLoading 
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(Icons.cancel),
                          label: Text(_isLoading ? 'Enregistrement...' : 'Confirmer le rejet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFf44336),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Validation en attente - boutons pour valider ou rejeter manuellement
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _validateInvoice,
                              icon: _isLoading 
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Icon(Icons.check),
                              label: Text('Valider'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4CAF50),
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
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _rejectInvoice,
                              icon: Icon(Icons.close),
                              label: Text('Rejeter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFf44336),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    SizedBox(height: 15),
                    
                    // Bouton de nouvelle analyse
                    Container(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/camera');
                        },
                        icon: Icon(Icons.camera_alt),
                        label: Text('Nouvelle analyse'),
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
                    
                    SizedBox(height: 10),
                    
                    // Bouton historique
                    Container(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/history');
                        },
                        icon: Icon(Icons.history),
                        label: Text('Voir l\'historique'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildMessageSection({
    required String title,
    required List<String> messages,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...messages.map((message) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: EdgeInsets.only(top: 6, right: 8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
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