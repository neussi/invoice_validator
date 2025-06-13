// lib/screens/present_screen.dart
import 'package:flutter/material.dart';

class PresentScreen extends StatefulWidget {
  @override
  _PresentScreenState createState() => _PresentScreenState();
}

class _PresentScreenState extends State<PresentScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.camera_alt,
      'title': 'Scannez vos factures',
      'description': 'Utilisez votre caméra pour capturer vos factures d\'électricité en quelques secondes',
      'color': Color(0xFF667eea),
    },
    {
      'icon': Icons.auto_awesome,
      'title': 'IA intelligente',
      'description': 'Notre intelligence artificielle extrait automatiquement toutes les informations importantes',
      'color': Color(0xFF764ba2),
    },
    {
      'icon': Icons.verified,
      'title': 'Validation automatique',
      'description': 'Vérification instantanée de la correspondance avec vos index de compteur',
      'color': Color(0xFF667eea),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec skip
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invoice Validator',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: Text(
                        'Passer',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // PageView avec les fonctionnalités
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icône avec animation
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              _pages[index]['icon'],
                              size: 80,
                              color: _pages[index]['color'],
                            ),
                          ),
                          SizedBox(height: 60),
                          
                          // Titre
                          Text(
                            _pages[index]['title'],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 25),
                          
                          // Description
                          Text(
                            _pages[index]['description'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Indicateurs de page et bouton
              Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  children: [
                    // Points indicateurs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          width: _currentPage == index ? 30 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _currentPage == index 
                                ? Colors.white 
                                : Colors.white30,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    
                    // Bouton de navigation
                    Container(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF667eea),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1 ? 'Suivant' : 'Commencer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}