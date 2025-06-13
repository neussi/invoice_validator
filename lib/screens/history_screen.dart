// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models.dart';
import '../database.dart';
import 'dart:io';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String _selectedFilter = 'Tous';
  
  final List<String> _filters = ['Tous', 'Validées', 'En attente', 'Rejetées'];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadInvoices();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user?.id != null) {
      final invoices = await DatabaseHelper.instance.getInvoicesByUser(user!.id!);
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Invoice> get _filteredInvoices {
    if (_selectedFilter == 'Tous') return _invoices;
    
    String statusFilter;
    switch (_selectedFilter) {
      case 'Validées':
        statusFilter = 'validee';
        break;
      case 'En attente':
        statusFilter = 'pending';
        break;
      case 'Rejetées':
        statusFilter = 'rejected';
        break;
      default:
        return _invoices;
    }
    
    return _invoices.where((invoice) => invoice.status == statusFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'validee':
        return Color(0xFF4CAF50);
      case 'rejected':
        return Color(0xFFf44336);
      default:
        return Color(0xFFFF9800);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'validee':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'validee':
        return 'Validée';
      case 'rejected':
        return 'Rejetée';
      default:
        return 'En attente';
    }
  }

  void _showInvoiceDetails(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Header avec statut
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(invoice.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(invoice.status).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(invoice.status),
                              size: 16,
                              color: _getStatusColor(invoice.status),
                            ),
                            SizedBox(width: 5),
                            Text(
                              _getStatusText(invoice.status),
                              style: TextStyle(
                                color: _getStatusColor(invoice.status),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Image de la facture si disponible
                  if (invoice.imagePath != null && File(invoice.imagePath!).existsSync())
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          File(invoice.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  
                  SizedBox(height: 25),
                  
                  // Détails de la facture
                  Text(
                    'Détails de la facture',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  _buildDetailRow('Numéro', invoice.invoiceNumber),
                  _buildDetailRow('Client', invoice.customerName),
                  _buildDetailRow('Montant', '${invoice.amount.toStringAsFixed(0)} FCFA'),
                  _buildDetailRow('Date', invoice.date.toString().substring(0, 10)),
                  _buildDetailRow('Analysé le', invoice.createdAt.toString().substring(0, 16)),
                  
                  SizedBox(height: 30),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Partager la facture
                          },
                          icon: Icon(Icons.share),
                          label: Text('Partager'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Réanalyser la facture
                            Navigator.pop(context);
                            if (invoice.imagePath != null) {
                              Navigator.pushNamed(
                                context,
                                '/analyse',
                                arguments: {'imagePath': invoice.imagePath},
                              );
                            }
                          },
                          icon: Icon(Icons.refresh),
                          label: Text('Réanalyser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Historique',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF667eea),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Filtres
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;
                  
                  return Container(
                    margin: EdgeInsets.only(right: 10),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Color(0xFF667eea).withOpacity(0.2),
                      checkmarkColor: Color(0xFF667eea),
                      labelStyle: TextStyle(
                        color: isSelected ? Color(0xFF667eea) : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Color(0xFF667eea) : Colors.grey[300]!,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Liste des factures
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF667eea),
                      ),
                    )
                  : _filteredInvoices.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadInvoices,
                          color: Color(0xFF667eea),
                          child: ListView.builder(
                            padding: EdgeInsets.all(20),
                            itemCount: _filteredInvoices.length,
                            itemBuilder: (context, index) {
                              final invoice = _filteredInvoices[index];
                              return _buildInvoiceCard(invoice, index);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/camera'),
        backgroundColor: Color(0xFF667eea),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            _selectedFilter == 'Tous' 
                ? 'Aucune facture analysée'
                : 'Aucune facture ${_selectedFilter.toLowerCase()}',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Commencez par scanner votre première facture',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/camera'),
            icon: Icon(Icons.camera_alt),
            label: Text('Scanner une facture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          onTap: () => _showInvoiceDetails(invoice),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec numéro et statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.invoiceNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(invoice.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(invoice.status),
                            size: 14,
                            color: _getStatusColor(invoice.status),
                          ),
                          SizedBox(width: 4),
                          Text(
                            _getStatusText(invoice.status),
                            style: TextStyle(
                              color: _getStatusColor(invoice.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Informations principales
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.customerName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${invoice.amount.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667eea),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          invoice.date.toString().substring(0, 10),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Analysé ${invoice.createdAt.toString().substring(8, 16)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}