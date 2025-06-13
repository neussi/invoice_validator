// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'database.dart';

// Import des screens
import 'screens/splash_screen.dart';
import 'screens/present_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/analyse_screen.dart';
import 'screens/resultat_screen.dart';
import 'screens/account_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';

// Import des services
import 'services/ocr_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser la base de données
  await DatabaseHelper.instance.init();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp(
        title: 'Invoice Validator',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(),
        routes: {
          '/present': (context) => PresentScreen(),
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
          '/home': (context) => HomeScreen(),
          '/camera': (context) => CameraScreen(),
          '/analyse': (context) => AnalyseScreen(),
          '/resultat': (context) => ResultatScreen(),
          '/history': (context) => HistoryScreen(),
          '/account': (context) => AccountScreen(),
          '/settings': (context) => SettingsScreen(),
        },
      ),
    );
  }
}

// Provider pour gérer l'état utilisateur
class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Vérifier dans la base de données
      final user = await DatabaseHelper.instance.loginUser(email, password);
      if (user != null) {
        _currentUser = user;
        
        // Sauvegarder la session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user.id!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Erreur login: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Vérifier si l'email existe déjà
      final emailExists = await DatabaseHelper.instance.emailExists(email);
      if (emailExists) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = User(
        name: name,
        email: email,
        password: password,
        createdAt: DateTime.now(),
      );

      final id = await DatabaseHelper.instance.insertUser(user);
      if (id > 0) {
        _currentUser = user.copyWith(id: id);
        
        // Sauvegarder la session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', id);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Erreur register: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    notifyListeners();
  }

  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId != null) {
      final user = await DatabaseHelper.instance.getUserById(userId);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    }
  }

  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}

