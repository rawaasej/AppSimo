import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'observer_page.dart';
import 'package:appsimo/admin_add_machine_page.dart';
import 'login_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:appsimo/gestion_panne_page.dart';
import 'widgets/machine_card.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;
  final bool isTechnicien;

  HomeScreen({required this.isAdmin, this.isTechnicien = false});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late AudioPlayer _audioPlayer;
  List<String> machinesDown = [];
  bool _reverseOrder = false;
  final database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _audioPlayer = AudioPlayer();
    _listenToMachineStatus();
  }

  void _navigateToGestionPanne() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GestionPannePage()),
    );
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final settings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(settings);

    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  Future<void> _showNotificationEtAlerte(
    String title,
    String body,
    int id,
  ) async {
    if (!(widget.isAdmin || widget.isTechnicien)) return;

    final androidDetails = AndroidNotificationDetails(
      'channel_$id',
      'Channel $id',
      channelDescription: 'Notifications pour les machines',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
    );
    final details = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(id, title, body, details);

    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/alert.mp3'));

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text(title, style: TextStyle(color: Colors.red)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(body),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  color: Colors.red[100],
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Problème critique ! Veuillez vérifier immédiatement.',
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  _audioPlayer.stop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _listenToMachineStatus() {
    final machineNames = ['Machine1', 'Machine2'];

    for (var machine in machineNames) {
      final ref = database.ref('/machines/$machine/etat_panne');
      final id = machine.hashCode;

      ref.onValue.listen((event) {
        final value = event.snapshot.value;
        final isDown = (value == 1 || value == true); // Correction ici
        final wasDown = machinesDown.contains(machine);

        if (isDown && !wasDown) {
          setState(() => machinesDown.add(machine));
          _showNotificationEtAlerte(
            'Machine $machine en panne',
            'Vérifier $machine',
            id,
          );
        } else if (!isDown && wasDown) {
          setState(() => machinesDown.remove(machine));
          flutterLocalNotificationsPlugin.cancel(id);
        }
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _machineStatusStream() async* {
    final machines = ['Machine1', 'Machine2'];

    while (true) {
      await Future.delayed(Duration(seconds: 2));
      final states = <Map<String, dynamic>>[];

      for (var m in machines) {
        final snap = await database.ref('/machines/$m').get();
        final snapValue = snap.value;
        if (snapValue is Map) {
          final data = Map<String, dynamic>.from(snapValue);
          states.add({'name': m, ...data});
        } else {
          states.add({'name': m}); // Fallback au cas où les données sont nulles
        }
      }

      yield states;
    }
  }

  void _navigateToObserver() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ObserverPage()));
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.redAccent,
        title: Text('App Simo', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (widget.isAdmin || widget.isTechnicien)
            IconButton(
              icon: Stack(
                children: [
                  Icon(
                    Icons.notifications,
                    color:
                        machinesDown.isNotEmpty ? Colors.black : Colors.black54,
                    size: 28,
                  ),
                  if (machinesDown.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${machinesDown.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _navigateToGestionPanne,
            ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: _logout,
          ),
        ],
      ),
      drawer:
          (widget.isAdmin || widget.isTechnicien)
              ? Drawer(
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
                      onTap: () => Navigator.pop(context),
                    ),
                    if (widget.isAdmin || widget.isTechnicien)
                      ListTile(
                        leading: Icon(Icons.warning_amber_outlined),
                        title: Text('Gestion des Pannes'),
                        onTap: _navigateToGestionPanne,
                      ),
                    if (widget.isAdmin) ...[
                      ListTile(
                        leading: Icon(Icons.supervisor_account),
                        title: Text('Gérer observateur'),
                        onTap: _navigateToObserver,
                      ),
                      ListTile(
                        leading: Icon(Icons.precision_manufacturing),
                        title: Text('Gérer machine'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminAddMachinePage(),
                            ),
                          );
                        },
                      ),
                    ],
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Déconnexion'),
                      onTap: _logout,
                    ),
                  ],
                ),
              )
              : null,

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _machineStatusStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var list = snapshot.data!;
          if (_reverseOrder) list = list.reversed.toList();

          if (isWideScreen) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final machine = list[index];
                  return MachineCard(
                    machineName: machine['name'],
                    machineData: machine,
                  );
                },
              ),
            );
          } else {
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final machine = list[index];
                return SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: MachineCard(
                    machineName: machine['name'],
                    machineData: machine,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
