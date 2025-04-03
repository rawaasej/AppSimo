import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Import Firestore
import 'observer_page.dart'; // Import de la nouvelle page
import 'machine_down_page.dart'; // Import de la page "Machine en panne"
import 'login_screen.dart'; // Import de la page LoginScreen
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart'; // Import du package pour jouer le son

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  HomeScreen({required this.isAdmin});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isMachineDown = false; // 🔴 État de la machine (en panne ou pas)
  late FlutterLocalNotificationsPlugin
  flutterLocalNotificationsPlugin; // Déclare la variable
  late AudioPlayer _audioPlayer; // Déclare un lecteur audio

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _audioPlayer = AudioPlayer(); // Initialisation du lecteur audio
    _listenToMachineStatus();
  }

  // Initialisation du plugin de notifications
  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Afficher la notification avec son personnalisé
  void _showNotification() async {
    // Lire le son depuis les assets avant de montrer la notification
    await _audioPlayer.play(AssetSource('sounds/alert.mp3'));

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'maintenance_channel',
          'Maintenance Notifications',
          channelDescription: 'Notifications when the machine is down',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Alerte de maintenance',
      'La machine est en panne!',
      notificationDetails,
    );
  }

  // Écouter l'état de la machine dans Firestore
  void _listenToMachineStatus() {
    FirebaseFirestore.instance
        .collection('maintenance')
        .doc('RTLNtlToGpMEM5YogZli')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            setState(() {
              isMachineDown = snapshot.data()?['panne'] ?? false;
            });

            // Si la machine est en panne, afficher la notification
            if (isMachineDown) {
              _showNotification();
            }
          }
        });
  }

  void _navigateToObserverPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ObserverPage()),
    );
  }

  void _navigateToMachineDownPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MachineDownPage()),
    );
  }

  // Fonction pour se déconnecter et revenir à la page de login
  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ), // Rediriger vers la page de connexion
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.redAccent,
        title: Text(
          'Maintenance App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications,
                  color:
                      isMachineDown
                          ? const Color.fromARGB(255, 8, 1, 1)
                          : Colors.black, // 🔥 Changement de couleur
                  size: 28,
                ),
                if (isMachineDown)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed:
                _navigateToMachineDownPage, // Navigate when clicking on the notification icon
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black, size: 28),
            onPressed: _logout, // Appel de la fonction de déconnexion
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.white),
              child: Center(
                child: ClipOval(
                  child: Image.asset(
                    'images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Accueil'),
              onTap: () {},
            ),
            if (widget.isAdmin)
              ListTile(
                leading: Icon(Icons.supervisor_account),
                title: Text('Gérer observateur'),
                onTap: _navigateToObserverPage,
              ),
            ListTile(
              leading: Icon(Icons.thermostat),
              title: Text('Température du moteur'),
              onTap: () {},
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.warning),
              title: Text('Machine en panne'),
              onTap:
                  _navigateToMachineDownPage, // Navigate to "Machine en panne" page
            ),
          ],
        ),
      ),
    );
  }
}
