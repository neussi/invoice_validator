// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF8B5CF6),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header avec profil utilisateur amélioré
                Container(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Avatar utilisateur avec effet glassmorphism
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 18),
                      
                      // Salutation améliorée
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour,',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              user?.name ?? 'Utilisateur',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Bouton notifications
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenu principal avec effet moderne
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre principal amélioré
                          Text(
                            'Actions rapides',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey[800],
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Choisissez une action à effectuer',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 30),
                          
                          // Grille d'actions améliorée
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 0.9, // Ajusté pour éviter le débordement
                              children: [
                                // Scanner une facture
                                _buildActionCard(
                                  icon: Icons.camera_alt_rounded,
                                  title: 'Scanner',
                                  subtitle: 'Nouvelle facture',
                                  gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
                                  onTap: () => Navigator.pushNamed(context, '/camera'),
                                ),
                                
                                // Historique
                                _buildActionCard(
                                  icon: Icons.history_rounded,
                                  title: 'Historique',
                                  subtitle: 'Factures scannées',
                                  gradient: [Color(0xFF764ba2), Color(0xFF8B5CF6)],
                                  onTap: () => Navigator.pushNamed(context, '/history'),
                                ),
                                
                                // Informations du compte
                                _buildActionCard(
                                  icon: Icons.account_circle_rounded,
                                  title: 'Mon profil',
                                  subtitle: 'Informations',
                                  gradient: [Color(0xFF4CAF50), Color(0xFF45A049)],
                                  onTap: () => Navigator.pushNamed(context, '/account'),
                                ),
                                
                                // Paramètres
                                _buildActionCard(
                                  icon: Icons.settings_rounded,
                                  title: 'Paramètres',
                                  subtitle: 'Configuration',
                                  gradient: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                  onTap: () => Navigator.pushNamed(context, '/settings'),
                                ),
                              ],
                            ),
                          ),
                          
                          // Statistiques rapides améliorées
                          Container(
                            margin: EdgeInsets.only(top: 20),
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.grey[50]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('0', 'Factures\nscannées', Color(0xFF667eea)),
                                _buildDivider(),
                                _buildStatItem('0', 'Validées', Color(0xFF4CAF50)),
                                _buildDivider(),
                                _buildStatItem('0', 'En attente', Color(0xFFFF9800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      
      // Bottom Navigation Bar améliorée
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            
            switch (index) {
              case 0:
                // Déjà sur Home
                break;
              case 1:
                Navigator.pushNamed(context, '/camera');
                break;
              case 2:
                Navigator.pushNamed(context, '/history');
                break;
              case 3:
                Navigator.pushNamed(context, '/account');
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Color(0xFF667eea),
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_rounded),
              label: 'Scanner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Historique',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded),
              label: 'Compte',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              offset: Offset(-5, -5),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            // Solution pour éviter le débordement des subtitles
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey[300]!,
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}