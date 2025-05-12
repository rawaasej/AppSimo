import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _ChartData {
  final String label;
  final int value;
  _ChartData(this.label, this.value);
}

class MachineCard extends StatelessWidget {
  final String machineName;
  final Map<String, dynamic> machineData;

  const MachineCard({
    Key? key,
    required this.machineName,
    required this.machineData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool etatFonctionnement =
        (machineData['etat_fonctionnement'] as num?)?.toInt() == 1;
    int piecesPerHour = 0;
    var piecePerHourValue = machineData['piece_par_heure'];

    if (piecePerHourValue is double) {
      piecesPerHour = piecePerHourValue.toInt();
    } else if (piecePerHourValue is int) {
      piecesPerHour = piecePerHourValue;
    } else {
      piecesPerHour = 0;
    }

    int etatPanne = (machineData['etat_panne'] as num?)?.toInt() ?? 0;

    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _formatMachineName(machineName),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 63, 166, 198),
              ),
            ),
            const SizedBox(height: 16),
            _buildGaugeWithStatus(
              piecesPerHour.toDouble(),
              etatFonctionnement,
              etatPanne,
            ),
            const SizedBox(height: 16),
            _sparklineGraph(machineName),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _buildInfoText(machineData),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMachineName(String name) {
    if (name == "Machine1") return "Machine AHAP";
    if (name == "Machine2") return "Machine SHWEISS";
    return name;
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  Widget _buildGaugeWithStatus(
    double value,
    bool etatFonctionnement,
    int etatPanne,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double gaugeSize = constraints.maxWidth > 600 ? 240 : 180;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTimeBlock(
                    'Temps de marche',
                    (machineData['temps_marche_h'] as num?)?.toInt() ?? 0,
                    (machineData['temps_marche_m'] as num?)?.toInt() ?? 0,
                    (machineData['temps_marche_s'] as num?)?.toInt() ?? 0,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildTimeBlock(
                    'Temps d\'arrêt',
                    (machineData['temps_arret_h'] as num?)?.toInt() ?? 0,
                    (machineData['temps_arret_m'] as num?)?.toInt() ?? 0,
                    (machineData['temps_arret_s'] as num?)?.toInt() ?? 0,
                    Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildTimeBlock(
                    'Temps de panne',
                    (machineData['temps_panne_h'] as num?)?.toInt() ?? 0,
                    (machineData['temps_panne_m'] as num?)?.toInt() ?? 0,
                    (machineData['temps_panne_s'] as num?)?.toInt() ?? 0,
                    Colors.orange,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      etatFonctionnement ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 8),
                Text(
                  etatFonctionnement ? "Fonctionne" : "En arrêt",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: etatFonctionnement ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(height: 16),
                if (etatPanne == 1) ...[
                  CircleAvatar(radius: 30, backgroundColor: Colors.yellow),
                  const SizedBox(height: 8),
                  Text(
                    "Panne active",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                  ),
                ] else ...[
                  CircleAvatar(radius: 30, backgroundColor: Colors.black),
                  const SizedBox(height: 8),
                  Text(
                    "Pas de panne",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
            Expanded(
              flex: 3,
              child: SizedBox(
                width: gaugeSize,
                height: gaugeSize,
                child: SfRadialGauge(
                  title: const GaugeTitle(
                    text: 'Pièces par heure',
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 1000,
                      interval: 100,
                      axisLineStyle: const AxisLineStyle(
                        thickness: 0.15,
                        thicknessUnit: GaugeSizeUnit.factor,
                      ),
                      majorTickStyle: const MajorTickStyle(
                        length: 0.1,
                        thickness: 2,
                        lengthUnit: GaugeSizeUnit.factor,
                      ),
                      ranges: <GaugeRange>[
                        GaugeRange(
                          startValue: 0,
                          endValue: 200,
                          color: Colors.green,
                          startWidth: 0.15,
                          endWidth: 0.15,
                          sizeUnit: GaugeSizeUnit.factor,
                        ),
                        GaugeRange(
                          startValue: 200,
                          endValue: 600,
                          color: Colors.orange,
                          startWidth: 0.15,
                          endWidth: 0.15,
                          sizeUnit: GaugeSizeUnit.factor,
                        ),
                        GaugeRange(
                          startValue: 600,
                          endValue: 1000,
                          color: Colors.red,
                          startWidth: 0.15,
                          endWidth: 0.15,
                          sizeUnit: GaugeSizeUnit.factor,
                        ),
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(
                          value: value,
                          needleColor: Colors.black,
                          knobStyle: const KnobStyle(
                            color: Colors.black,
                            knobRadius: 0.06,
                          ),
                          needleLength: 0.8,
                          lengthUnit: GaugeSizeUnit.factor,
                          needleStartWidth: 1,
                          needleEndWidth: 4,
                        ),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          angle: 90,
                          positionFactor: 0.8,
                          widget: Text(
                            '${value.toInt()} P/h',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeBlock(
    String label,
    int hours,
    int minutes,
    int seconds,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatTime(hours)}:${_formatTime(minutes)}:${_formatTime(seconds)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int value) => value.toString().padLeft(2, '0');

  List<Widget> _buildInfoText(Map<String, dynamic> data) {
    Map<String, String> labels = {
      'MTBF': 'MTBF',
      'MTTR': 'MTTR',
      'disponibilite': 'Disponibilité',
      'performance': 'Performance',
      'nombre_panne': 'Pannes',
      'taux_cadence': 'Taux cadence',
      'taux_production': 'Taux production',
    };

    return labels.entries.map((entry) {
      final value = data[entry.key];
      if (value == null) return const SizedBox.shrink();

      if (entry.key == 'MTBF' || entry.key == 'MTTR') {
        int totalSeconds =
            value is num ? value.toInt() : int.tryParse(value.toString()) ?? 0;
        int hours = totalSeconds ~/ 3600;
        int minutes = (totalSeconds % 3600) ~/ 60;
        int seconds = totalSeconds % 60;
        String formatted = "${_pad(hours)}:${_pad(minutes)}:${_pad(seconds)}";
        return Chip(
          backgroundColor: Colors.blue.shade50,
          label: Text(
            '${entry.value}: $formatted',
            style: const TextStyle(fontSize: 14),
          ),
        );
      }

      return Chip(
        backgroundColor: Colors.blue.shade50,
        label: Text(
          '${entry.value}: ${value.toString()}',
          style: const TextStyle(fontSize: 14),
        ),
      );
    }).toList();
  }

  Widget _sparklineGraph(String machineCollection) {
    return SizedBox(
      height: 160,
      child: _buildLineChartFromFirestore(machineCollection),
    );
  }

  Widget _buildLineChartFromFirestore(String machineCollection) {
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection(getFirestoreCollection(machineCollection))
              .orderBy('timestamp')
              .limit(10)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("Aucune donnée disponible."));
        }

        final List<_ChartData> chartData = [];
        String titleDate = '';

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'] as Timestamp?;
          final nombrePiece = data['nombre_piece'] ?? 0;

          if (timestamp != null) {
            final date = timestamp.toDate();
            if (titleDate.isEmpty) {
              titleDate = "${date.day} ${_monthName(date.month)} ${date.year}";
            }

            final label =
                '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
            chartData.add(
              _ChartData(label, nombrePiece is int ? nombrePiece : 0),
            );
          }
        }

        return SfCartesianChart(
          title: ChartTitle(
            text: 'Statistique de nombre de pièces à partir de $titleDate',
          ),
          primaryXAxis: CategoryAxis(title: AxisTitle(text: 'Temps')),
          primaryYAxis: NumericAxis(title: AxisTitle(text: 'Nombre de pièces')),
          series: <CartesianSeries<_ChartData, String>>[
            LineSeries<_ChartData, String>(
              dataSource: chartData,
              xValueMapper: (_ChartData data, _) => data.label,
              yValueMapper: (_ChartData data, _) => data.value,
              markerSettings: const MarkerSettings(isVisible: true),
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
          ],
        );
      },
    );
  }

  String getFirestoreCollection(String machineName) {
    switch (machineName) {
      case 'Machine1':
        return 'machine_1';
      case 'Machine2':
        return 'machine_2';
      default:
        return machineName; // ou une valeur par défaut
    }
  }

  // Helper function to convert month number to name in French
  String _monthName(int month) {
    const months = [
      '', // index 0 unused
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return months[month];
  }
}
