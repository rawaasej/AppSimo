import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class Machine1ProductionPage extends StatelessWidget {
  const Machine1ProductionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final machineCollection = FirebaseFirestore.instance.collection('Machine1');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production - Machine 1'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Titre général centré
            const Center(
              child: Text(
                'Temps de Cycle de Production',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Layout avec titre Y à gauche
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Titre de l'axe Y
                  const RotatedBox(
                    quarterTurns: -1,
                    child: Center(
                      child: Text(
                        'Valeur',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Graphique
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          machineCollection
                              .orderBy(
                                'temps_cycle.timestamp',
                                descending: false,
                              )
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text("Erreur de chargement des données."),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text("Aucune donnée disponible."),
                          );
                        }

                        List<FlSpot> spots = [];
                        List<String> labels = [];

                        int index = 0;
                        for (var doc in docs) {
                          final data = doc['temps_cycle'];
                          final double value =
                              (data['value'] as num).toDouble();
                          final timestamp = data['timestamp'] as Timestamp;
                          String formattedTime = DateFormat(
                            'HH:mm',
                          ).format(timestamp.toDate());

                          spots.add(FlSpot(index.toDouble(), value));
                          labels.add(formattedTime);
                          index++;
                        }

                        return Column(
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: LineChart(
                                    LineChartData(
                                      lineTouchData: LineTouchData(
                                        touchTooltipData: LineTouchTooltipData(
                                          getTooltipItems: (touchedSpots) {
                                            return touchedSpots.map((spot) {
                                              return LineTooltipItem(
                                                'Heure ${labels[spot.x.toInt()]}\nCycle: ${spot.y.toInt()}',
                                                const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              );
                                            }).toList();
                                          },
                                          tooltipPadding: const EdgeInsets.all(
                                            10,
                                          ),
                                          tooltipMargin: 5,
                                        ),
                                        handleBuiltInTouches: true,
                                      ),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 32,
                                            getTitlesWidget: (value, meta) {
                                              int idx = value.toInt();
                                              if (idx >= 0 &&
                                                  idx < labels.length) {
                                                return Text(
                                                  labels[idx],
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                '${value.toInt()}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        rightTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        topTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      gridData: FlGridData(show: true),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: spots,
                                          isCurved: true,
                                          color: Colors.blue,
                                          barWidth: 3,
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.blue.withOpacity(0.4),
                                                Colors.blue.withOpacity(0.1),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                          dotData: FlDotData(show: true),
                                        ),
                                      ],
                                    ),
                                    duration: const Duration(milliseconds: 500),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Titre de l'axe X
                            const Text(
                              'Temps (heure)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
