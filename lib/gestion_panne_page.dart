import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class GestionPannePage extends StatefulWidget {
  @override
  _GestionPannePageState createState() => _GestionPannePageState();
}

class _GestionPannePageState extends State<GestionPannePage> {
  final _commentaireController = TextEditingController();
  final _raisonController = TextEditingController();

  String? selectedMachineId;
  String? selectedMachineNom;
  String? selectedMachineMatricule;

  DatabaseReference? tempsReparationRef;
  Stream<DatabaseEvent>? tempsReparationStream;
  String? tempsReparationFormatte;

  void updateRealtimeListener() {
    if (selectedMachineMatricule == null) return;

    String? machineKey;
    if (selectedMachineMatricule == '2002297') {
      machineKey = 'Machine1';
    } else if (selectedMachineMatricule == '2002298') {
      machineKey = 'Machine2';
    }

    if (machineKey != null) {
      tempsReparationRef = FirebaseDatabase.instance
          .ref()
          .child('machines')
          .child(machineKey)
          .child('temps_reparation');

      tempsReparationStream = tempsReparationRef!.onValue;
      setState(() {}); // Redessiner avec le nouveau stream
    } else {
      tempsReparationStream = null;
      tempsReparationFormatte = null;
    }
  }

  Future<void> _ajouterPanne() async {
    if (selectedMachineId == null ||
        _commentaireController.text.isEmpty ||
        _raisonController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Remplissez tous les champs")));
      return;
    }

    final panneData = {
      'commentaire': _commentaireController.text,
      'raison': _raisonController.text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('machines')
        .doc(selectedMachineId)
        .collection('pannes')
        .add(panneData);

    _commentaireController.clear();
    _raisonController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Panne ajoutée avec succès")));
  }

  String formatTemps(num secondesTotales) {
    final int heures = secondesTotales ~/ 3600;
    final int minutes = (secondesTotales % 3600) ~/ 60;
    final int secondes = (secondesTotales % 60).toInt();
    return '$heures h : $minutes m : $secondes s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestion des pannes')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('machines').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final machines = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: machines.length,
                  itemBuilder: (context, index) {
                    final machine = machines[index];
                    final nom = machine['nom'] ?? 'Inconnu';
                    final matricule = machine['matricule'] ?? 'Inconnu';

                    return ListTile(
                      title: Text('Nom: $nom'),
                      subtitle: Text('Matricule: $matricule'),
                      onTap: () {
                        setState(() {
                          selectedMachineId = machine.id;
                          selectedMachineNom = nom;
                          selectedMachineMatricule = matricule;
                          updateRealtimeListener();
                        });
                      },
                      selected: machine.id == selectedMachineId,
                      selectedTileColor: const Color.fromARGB(
                        255,
                        212,
                        208,
                        208,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (selectedMachineId != null)
            Padding(
              padding: EdgeInsets.all(10),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.grey[50],
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajouter panne pour $selectedMachineNom',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '(Matricule: $selectedMachineMatricule)',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 12),
                      if (tempsReparationStream != null)
                        StreamBuilder<DatabaseEvent>(
                          stream: tempsReparationStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                snapshot.data!.snapshot.value != null) {
                              final secondes =
                                  snapshot.data!.snapshot.value
                                      as num; // double ou int
                              tempsReparationFormatte = formatTemps(
                                secondes.floorToDouble(),
                              );
                            } else {
                              tempsReparationFormatte = 'Non disponible';
                            }

                            return Text(
                              'Temps de réparation : $tempsReparationFormatte',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      SizedBox(height: 14),
                      TextField(
                        controller: _commentaireController,
                        decoration: InputDecoration(
                          labelText: 'Commentaire',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _raisonController,
                        decoration: InputDecoration(
                          labelText: 'Raison de la panne',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _ajouterPanne,
                          icon: Icon(Icons.add),
                          label: Text('Ajouter Panne'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: const Color.fromARGB(
                              255,
                              222,
                              39,
                              26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
