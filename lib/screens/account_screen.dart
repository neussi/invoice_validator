// lib/screens/account_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models.dart';
import '../database.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

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
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    // Initialiser les contrôleurs avec les données utilisateur
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      
      if (currentUser != null) {
        // Mettre à jour dans la base de données
        final updatedUser = currentUser.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );
        
        await DatabaseHelper.instance.updateUser(updatedUser);
        
        // Mettre à jour le provider
        userProvider.updateCurrentUser(updatedUser);
        
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text('Déconnexion'),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Déconnecter',
              style: TextStyle(color: Colors.white),
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
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  // App Bar personnalisé
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Color(0xFF667eea),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF667eea),
                              Color(0xFF764ba2),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 40),
                              // Avatar
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Color(0xFF667eea),
                                ),
                              ),
                              SizedBox(height: 15),
                              // Nom utilisateur
                              Consumer<UserProvider>(
                                builder: (context, userProvider, child) {
                                  final user = userProvider.currentUser;
                                  return Text(
                                    user?.name ?? 'Utilisateur',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      if (!_isEditing)
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                        ),
                    ],
                  ),
                  
                  // Contenu principal
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Formulaire de profil
                          Container(
                            padding: EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informations personnelles',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 25),
                                  
                                  // Nom
                                  TextFormField(
                                    controller: _nameController,
                                    enabled: _isEditing,
                                    decoration: InputDecoration(
                                      labelText: 'Nom complet',
                                      prefixIcon: Icon(Icons.person_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: _isEditing ? Colors.white : Colors.grey[100],
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre nom';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  
                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    enabled: _isEditing,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: _isEditing ? Colors.white : Colors.grey[100],
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Email invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  if (_isEditing) ...[
                                    SizedBox(height: 25),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = false;
                                                // Restaurer les valeurs originales
                                                final user = Provider.of<UserProvider>(context, listen: false).currentUser;
                                                if (user != null) {
                                                  _nameController.text = user.name;
                                                  _emailController.text = user.email;
                                                }
                                              });
                                            },
                                            child: Text('Annuler'),
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(vertical: 15),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 15),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _updateProfile,
                                            child: _isLoading
                                                ? SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text('Sauvegarder'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF667eea),
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: 15),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Statistiques utilisateur
                          Container(
                            padding: EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
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
                                  'Statistiques',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.receipt_long,
                                        title: 'Factures\nscannées',
                                        value: '0',
                                        color: Color(0xFF667eea),
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.check_circle,
                                        title: 'Validées',
                                        value: '0',
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 30),
                          
                          // Bouton de déconnexion
                          Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showLogoutDialog,
                              icon: Icon(Icons.logout),
                              label: Text('Se déconnecter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
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
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}