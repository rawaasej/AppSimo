import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddMachinePage extends StatefulWidget {
  @override
  _AdminAddMachinePageState createState() => _AdminAddMachinePageState();
}

class _AdminAddMachinePageState extends State<AdminAddMachinePage> {
  final _formKey = GlobalKey<FormState>();
  final _ref = FirebaseFirestore.instance.collection('machines');
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredMachineList = [];

  final Map<String, TextEditingController> _controllers = {
    'nom': TextEditingController(),
    'matricule': TextEditingController(),
    'modele': TextEditingController(),
    'annee_mise_en_service': TextEditingController(),
    'localisation': TextEditingController(),
    'commentaire': TextEditingController(),
  };

  String etatAjout = 'OK';
  bool isEditMode = false;
  bool isMachineFound = false;
  bool isListLoading = false;

  List<Map<String, dynamic>> machineList = [];

  @override
  void initState() {
    super.initState();
    _loadMachineList();
    _searchController.addListener(_filterMachines);
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMachineList() async {
    setState(() {
      isListLoading = true;
    });

    final querySnapshot = await _ref.get();
    setState(() {
      machineList =
          querySnapshot.docs.map((doc) {
            return {'matricule': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList();
      filteredMachineList = machineList; // copie initiale
      isListLoading = false;
    });
  }

  void _filterMachines() {
    final searchText = _searchController.text.toLowerCase();
    setState(() {
      filteredMachineList =
          machineList.where((machine) {
            final matricule = machine['matricule'].toString().toLowerCase();
            final nom = machine['nom'].toString().toLowerCase();
            return matricule.contains(searchText) || nom.contains(searchText);
          }).toList();
    });
  }

  Future<bool> _isNomOrMatriculeExists(String nom, String matricule) async {
    final snapshot = await _ref.get();

    for (var doc in snapshot.docs) {
      final machine = doc.data() as Map<String, dynamic>;
      final currentMatricule = doc.id;
      final currentNom = machine['nom'] ?? '';

      if (currentMatricule != matricule && currentNom == nom) {
        return true;
      }

      if (!isEditMode && currentMatricule == matricule) {
        return true;
      }
    }

    return false;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final nom = _controllers['nom']!.text.trim();
      final matricule = _controllers['matricule']!.text.trim();

      final exists = await _isNomOrMatriculeExists(nom, matricule);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Matricule ou nom déjà utilisé')),
        );
        return;
      }

      final data = {
        for (var entry in _controllers.entries) entry.key: entry.value.text,
        'etat_ajout': etatAjout,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (isEditMode) {
        await _ref.doc(matricule).update(data);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Machine modifiée avec succès')));
      } else {
        await _ref.doc(matricule).set(data);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Machine ajoutée avec succès')));
      }

      setState(() {
        isEditMode = false;
        isMachineFound = false;
      });
      _clearForm();
      _loadMachineList();
    }
  }

  void _clearForm() {
    for (var controller in _controllers.values) {
      controller.clear();
    }
    setState(() {
      etatAjout = 'OK';
    });
  }

  void _editMachine(Map<String, dynamic> machine) {
    for (var entry in _controllers.entries) {
      _controllers[entry.key]!.text = machine[entry.key]?.toString() ?? '';
    }
    setState(() {
      etatAjout = machine['etat_ajout'] ?? 'OK';
      isEditMode = true;
      isMachineFound = true;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier Machine'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  for (var entry in _controllers.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: TextFormField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: entry.key,
                          prefixIcon: Icon(_getIconForField(entry.key)),
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Champ requis'
                                    : null,
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    value: etatAjout,
                    items:
                        ['OK', 'À tester']
                            .map(
                              (etat) => DropdownMenuItem(
                                value: etat,
                                child: Text(etat),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => etatAjout = val);
                    },
                    decoration: InputDecoration(
                      labelText: 'État au moment de l’ajout',
                      prefixIcon: Icon(Icons.check_circle),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _submit();
                Navigator.of(context).pop();
              },
              child: Text('Soumettre'),
            ),
          ],
        );
      },
    );
  }

  IconData _getIconForField(String field) {
    switch (field) {
      case 'nom':
        return Icons.devices;
      case 'matricule':
        return Icons.card_membership;
      case 'modele':
        return Icons.build;
      case 'annee_mise_en_service':
        return Icons.calendar_today;
      case 'localisation':
        return Icons.location_on;
      case 'commentaire':
        return Icons.comment;
      default:
        return Icons.text_fields;
    }
  }

  void _deleteMachine(String matricule) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer cette machine ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                await _ref.doc(matricule).delete();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Machine supprimée')));
                _loadMachineList();
                Navigator.of(context).pop();
              },
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des machines'),
        backgroundColor: const Color.fromARGB(255, 255, 68, 68),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Barre de recherche
            Card(
              margin: EdgeInsets.only(bottom: 20),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Matricule ou nom de la machine',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),

            // Titre
            Text(
              'Liste des machines :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // Liste de machines filtrées
            isListLoading
                ? Center(child: CircularProgressIndicator())
                : filteredMachineList.isEmpty
                ? Center(child: Text('Aucune machine trouvée'))
                : Column(
                  children:
                      filteredMachineList.map((machine) {
                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            title: Text(
                              'Matricule: ${machine['matricule']}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Nom: ${machine['nom']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editMachine(machine),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed:
                                      () =>
                                          _deleteMachine(machine['matricule']),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Ajouter ou modifier une machine'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        for (var entry in _controllers.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: TextFormField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                labelText: entry.key,
                                prefixIcon: Icon(_getIconForField(entry.key)),
                                border: OutlineInputBorder(),
                              ),
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Champ requis'
                                          : null,
                            ),
                          ),
                        DropdownButtonFormField<String>(
                          value: etatAjout,
                          items:
                              ['OK', 'À tester']
                                  .map(
                                    (etat) => DropdownMenuItem(
                                      value: etat,
                                      child: Text(etat),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => etatAjout = val);
                          },
                          decoration: InputDecoration(
                            labelText: 'État au moment de l’ajout',
                            prefixIcon: Icon(Icons.check_circle),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () {
                      _submit();
                      Navigator.of(context).pop();
                    },
                    child: Text('Soumettre'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }
}
