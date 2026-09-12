import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../pages/home_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedSensor = 'CO';

  final List<FlSpot> coData = const [
    FlSpot(0, 12),
    FlSpot(1, 15),
    FlSpot(2, 18),
    FlSpot(3, 17),
    FlSpot(4, 20),
    FlSpot(5, 24),
    FlSpot(6, 38),
    FlSpot(7, 42),
    FlSpot(8, 35),
    FlSpot(9, 28),
  ];

 final List<FlSpot> co2Data = const [
    FlSpot(0, 600),
    FlSpot(1, 750),
    FlSpot(2, 900),
    FlSpot(3, 850),
    FlSpot(4, 1100),
    FlSpot(5, 1400),
    FlSpot(6, 1800),
    FlSpot(7, 2200),
    FlSpot(8, 1900),
    FlSpot(9, 1600),
  ];

  List<FlSpot> get chartData {
    if (selectedSensor == 'CO') {
      return coData;
    }

    return co2Data;
  }

  double get maxY {
    if (selectedSensor == 'CO') {
      return 60;
    }

    return 3000;
  }

  double get intervalY {
    if (selectedSensor == 'CO') {
      return 20;
    }

    return 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
           Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5B82D8), Color(0xFF8BB2E8)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Riwayat',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Harian',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),

                      // DROPDOWN CO / CO2
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSensor,
                            dropdownColor: Colors.white,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'CO',
                                child: Text(
                                  'CO',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'CO₂',
                                child: Text(
                                  'CO₂',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                selectedSensor = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // CHART
                  // =========================
                  Container(
                    height: 220,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 18, 18, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 9,
                        minY: 0,
                        maxY: maxY,

                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: intervalY,
                          verticalInterval: 3,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              strokeWidth: 1,
                              color: Colors.grey.withValues(alpha: 0.25),
                            );
                          },
                        ),

                        borderData: FlBorderData(show: false),

                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              interval: intervalY,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 25,
                              interval: 3,
                              getTitlesWidget: (value, meta) {
                                const times = [
                                  '06.00',
                                  '09.00',
                                  '12.00',
                                  '15.00',
                                ];

                                final index = value ~/ 3;

                                if (index < 0 || index >= times.length) {
                                  return const SizedBox();
                                }

                                return Text(
                                  times[index],
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        lineBarsData: [
                          LineChartBarData(
                            spots: chartData,
                            isCurved: true,
                            barWidth: 0,
                            color: Colors.transparent,

                            dotData: const FlDotData(show: false),

                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF8FCB8F)
                                      .withValues(alpha: 0.45),
                                  const Color(0xFF8FCB8F)
                                      .withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =========================
            // LOG KEJADIAN
            // =========================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Log Kejadian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (selectedSensor == 'CO')
                      ..._buildCoLogs()
                    else
                      ..._buildCo2Logs(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // LOG CO
  // =========================

  List<Widget> _buildCoLogs() {
    return [
      _eventCard(
        icon: Icons.air,
        iconColor: Colors.green,
        title: 'Kembali normal',
        description: 'Semua parameter aman',
        time: '15:20',
      ),

      _eventCard(
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
        title: 'Kadar CO mencapai 42 ppm',
        description: 'Jendela terbuka otomatis',
        time: '14:17',
      ),

      _eventCard(
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
        title: 'Kadar CO mencapai batas waspada 35 ppm',
        description: 'Semua parameter aman',
        time: '12:00',
      ),
    ];
  }

  // =========================
  // LOG CO2
  // =========================

  List<Widget> _buildCo2Logs() {
    return [
      _eventCard(
        icon: Icons.air,
        iconColor: Colors.green,
        title: 'Kembali normal',
        description: 'Semua parameter aman',
        time: '15:20',
      ),

      _eventCard(
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
        title: 'Kadar CO₂ mencapai 2800 ppm',
        description: 'Jendela terbuka otomatis',
        time: '14:17',
      ),

      _eventCard(
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
        title: 'Kadar CO₂ mencapai batas waspada 2500 ppm',
        description: 'Buzzer aktif',
        time: '12:00',
      ),
    ];
  }

  // =========================
  // EVENT CARD
  // =========================

  Widget _eventCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),

          Text(
            time,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
