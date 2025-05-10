import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Machine1DowntimePage extends StatelessWidget {
  const Machine1DowntimePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final machineCollection = FirebaseFirestore.instance.collection('Machine1');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taux d’arrêt - Machine 1'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.redAccent,
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

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Aucune donnée trouvée."));
          }

          double totalDowntime = 0;
          int count = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final downtime = data['downtime'] ?? 0;
            totalDowntime += downtime;
            count++;
          }

          final averageDowntime = count > 0 ? totalDowntime / count : 0;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  "Taux moyen d'arrêt pour Machine 1",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                Text(
                  "${averageDowntime.toStringAsFixed(2)} min",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.orangeAccent : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 40),
                Divider(color: Theme.of(context).dividerColor),
                Text(
                  "Historique des arrêts récents",
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final downtime = data['downtime'] ?? 0;
                      final timestamp =
                          (data['timestamp'] as Timestamp?)?.toDate();

                      return ListTile(
                        leading: Icon(
                          Icons.timer_off,
                          color:
                              isDark ? Colors.orangeAccent : Colors.redAccent,
                        ),
                        title: Text(
                          "Durée de l'arrêt : $downtime min",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        subtitle:
                            timestamp != null
                                ? Text(
                                  "Date : ${timestamp.toLocal()}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                                : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
