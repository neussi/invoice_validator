// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _notificationsEnabled = true;
  bool _autoSaveEnabled = true;
  bool _darkModeEnabled = false;
  bool _highQualityOCR = true;
  String _selectedLanguage = 'Français';
  String _ocrEngine = 'Google ML Kit';

  final List<String> _languages = ['Français', 'English', 'Español'];
  final List<String> _ocrEngines = ['Google ML Kit', 'Tesseract OCR'];

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
    
    _loadSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _autoSaveEnabled = prefs.getBool('auto_save_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _highQualityOCR = prefs.getBool('high_quality_ocr') ?? true;
      _selectedLanguage = prefs.getString('selected_language') ?? 'Français';
      _ocrEngine = prefs.getString('ocr_engine') ?? 'Google ML Kit';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('auto_save_enabled', _autoSaveEnabled);
    await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
    await prefs.setBool('high_quality_ocr', _highQualityOCR);
    await prefs.setString('selected_language', _selectedLanguage);
    await prefs.setString('ocr_engine', _ocrEngine);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paramètres sauvegardés'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
                _saveSettings();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showOCREngineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text('Moteur OCR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _ocrEngines.map((engine) {
            return RadioListTile<String>(
              title: Text(engine),
              subtitle: Text(
                engine == 'Google ML Kit' 
                    ? 'Recommandé - Plus précis'
                    : 'Alternative - Fonctionne hors ligne',
                style: TextStyle(fontSize: 12),
              ),
              value: engine,
              groupValue: _ocrEngine,
              onChanged: (value) {
                setState(() {
                  _ocrEngine = value!;
                });
                Navigator.pop(context);
                _saveSettings();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF667eea)),
            SizedBox(width: 10),
            Text('À propos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Validator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Version 1.0.0'),
            SizedBox(height: 15),
            Text(
              'Application de validation intelligente de factures d\'électricité utilisant l\'IA et l\'OCR.',
              style: TextStyle(height: 1.4),
            ),
            SizedBox(height: 15),
            Text(
              'Développé avec ❤️ en Flutter',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text('Vider le cache'),
        content: Text('Êtes-vous sûr de vouloir vider le cache de l\'application ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cache vidé avec succès'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF667eea),
            ),
            child: Text('Vider', style: TextStyle(color: Colors.white)),
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
          'Paramètres',
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Section Général
              _buildSection(
                title: 'Général',
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Recevoir des notifications push',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.save_alt,
                    title: 'Sauvegarde automatique',
                    subtitle: 'Sauvegarder automatiquement les analyses',
                    value: _autoSaveEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoSaveEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                  _buildTile(
                    icon: Icons.language,
                    title: 'Langue',
                    subtitle: _selectedLanguage,
                    onTap: _showLanguageDialog,
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Section OCR
              _buildSection(
                title: 'Reconnaissance optique (OCR)',
                children: [
                  _buildTile(
                    icon: Icons.auto_awesome,
                    title: 'Moteur OCR',
                    subtitle: _ocrEngine,
                    onTap: _showOCREngineDialog,
                  ),
                  _buildSwitchTile(
                    icon: Icons.high_quality,
                    title: 'Haute qualité',
                    subtitle: 'Meilleure précision mais plus lent',
                    value: _highQualityOCR,
                    onChanged: (value) {
                      setState(() {
                        _highQualityOCR = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Section Apparence
              _buildSection(
                title: 'Apparence',
                children: [
                  _buildSwitchTile(
                    icon: Icons.dark_mode,
                    title: 'Mode sombre',
                    subtitle: 'Thème sombre pour l\'interface',
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Section Stockage
              _buildSection(
                title: 'Stockage',
                children: [
                  _buildTile(
                    icon: Icons.cleaning_services,
                    title: 'Vider le cache',
                    subtitle: 'Libérer de l\'espace de stockage',
                    onTap: _clearCache,
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Section Support
              _buildSection(
                title: 'Support',
                children: [
                  _buildTile(
                    icon: Icons.help_outline,
                    title: 'Aide',
                    subtitle: 'Guide d\'utilisation',
                    onTap: () {
                      // TODO: Ouvrir la page d'aide
                    },
                  ),
                  _buildTile(
                    icon: Icons.bug_report,
                    title: 'Signaler un problème',
                    subtitle: 'Nous aider à améliorer l\'app',
                    onTap: () {
                      // TODO: Ouvrir le formulaire de rapport
                    },
                  ),
                  _buildTile(
                    icon: Icons.info_outline,
                    title: 'À propos',
                    subtitle: 'Version et informations',
                    onTap: _showAboutDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(0xFF667eea).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Color(0xFF667eea),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(0xFF667eea).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Color(0xFF667eea),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFF667eea),
      ),
    );
  }
}