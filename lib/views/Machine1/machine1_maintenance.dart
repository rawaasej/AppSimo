import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Machine1MaintenancePage extends StatelessWidget {
  const Machine1MaintenancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final machineCollection = FirebaseFirestore.instance.collection('Machine1');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance - Machine 1'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            machineCollection
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Erreur de chargement des données."),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return const Center(child: Text("Aucune donnée disponible."));
          }

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final data = documents[index].data() as Map<String, dynamic>;

              final maintenanceTime = data['maintenance_time'] ?? 'N/A';
              final issue = data['issue'] ?? 'Aucun problème signalé';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.build, color: Colors.redAccent),
                  title: Text("Durée de maintenance : $maintenanceTime min"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Problème : $issue"),
                      if (timestamp != null)
                        Text(
                          "Date : ${timestamp.toLocal()}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
