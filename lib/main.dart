import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDQorUdSXFFnfccur9JbMcONsce8TTzQm4",
      appId: "1:461654124379:android:f4cee8235ae0341a7a1c7e",
      messagingSenderId: "461654124379",
      projectId: "appsimo-38a84",
      authDomain: "appsimo-38a84.firebaseapp.com",
      storageBucket: "appsimo-38a84.firebasestorage.app",
      databaseURL: "https://appsimo-38a84-default-rtdb.firebaseio.com/", // Spécifie l'URL ici

    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Application de connexion',
      theme: ThemeData(primarySwatch: Colors.green),
      home: LoginScreen(),
    );
  }
}
