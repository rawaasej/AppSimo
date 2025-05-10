import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isRememberMeChecked = false;
  bool isPasswordVisible =
      false; // Variable pour gérer la visibilité du mot de passe

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  void _loadCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        isRememberMeChecked = true;
      });
    }
  }

  void _saveCredentials(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (isRememberMeChecked) {
      await prefs.setString('email', email);
      await prefs.setString('password', password);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  Future<void> _checkCredentials() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Veuillez remplir tous les champs.");
      return;
    }

    try {
      // 🔍 Rechercher l'utilisateur par email
      QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

      if (userSnapshot.docs.isNotEmpty) {
        var userDoc = userSnapshot.docs.first;
        String storedPassword = userDoc['password'].toString().trim();

        if (storedPassword == password) {
          // ✅ Authentification réussie

          String role = userDoc['role'];
          String nom = userDoc['name'];
          String matricule = userDoc['matricule'];

          // Sauvegarder email et mot de passe si "remember me"
          _saveCredentials(email, password);

          // Sauvegarder toutes les infos dans SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('role', role);
          await prefs.setString('nom_technicien', nom);
          await prefs.setString('matricule_technicien', matricule);

          // Redirection selon le rôle
          bool isAdmin = role == 'admin';
          bool isTechnicien = role == 'technicien';

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      HomeScreen(isAdmin: isAdmin, isTechnicien: isTechnicien),
            ),
          );
        } else {
          _showErrorDialog("Mot de passe incorrect.");
        }
      } else {
        _showErrorDialog("Email non trouvé.");
      }
    } catch (e) {
      print('Erreur Firestore: $e');
      _showErrorDialog("Une erreur est survenue. Veuillez réessayer.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erreur'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'images/simo.jpg',
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Bienvenue à notre application',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Adresse email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.email),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              SizedBox(height: 12),
              // Champ de texte pour le mot de passe avec visibilité
              TextField(
                controller: passwordController,
                obscureText:
                    !isPasswordVisible, // Utilise la variable pour contrôler la visibilité
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: isPasswordVisible ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible =
                            !isPasswordVisible; // Bascule la visibilité
                      });
                    },
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: _checkCredentials,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 68, 81),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  'Se connecter',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: isRememberMeChecked,
                    onChanged: (value) {
                      setState(() {
                        isRememberMeChecked = value!;
                      });
                    },
                  ),
                  Text('Remember me', style: TextStyle(color: Colors.black87)),
                ],
              ),
              SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
