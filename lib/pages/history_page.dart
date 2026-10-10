import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String selectedSensor = 'CO';

  List<Map<String, dynamic>> sensorReadings = [];

  bool isLoading = true;
  String? errorMessage;

  // Menyimpan tanggal data yang sedang ditampilkan
  DateTime? dataDate;

  // INIT

  @override
  void initState() {
    super.initState();
    _loadSensorReadings();
  }

  // AMBIL DATA SENSOR

  Future<void> _loadSensorReadings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Ambil data sensor terbaru.
      //
      // Kita tidak langsung memfilter "hari ini",
      // supaya kalau database terakhir berisi data tanggal
      // sebelumnya, data tersebut tetap bisa ditampilkan.

      final response = await _supabase
          .from('sensor_readings')
          .select('co_ppm, co2_ppm, status, created_at')
          .order('created_at', ascending: false)
          .limit(500);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        response,
      );

      if (data.isEmpty) {
        setState(() {
          sensorReadings = [];
          dataDate = null;
          isLoading = false;
        });

        return;
      }

      // Tentukan tanggal data terbaru

      DateTime? latestDate;

      for (final item in data) {
        final createdAt = DateTime.tryParse(
          item['created_at']?.toString() ?? '',
        );

        if (createdAt == null) {
          continue;
        }

        final localDate = createdAt.toLocal();

        latestDate = DateTime(localDate.year, localDate.month, localDate.day);

        break;
      }

      // Hanya tampilkan data pada tanggal terbaru

      List<Map<String, dynamic>> filteredData = [];

      if (latestDate != null) {
        filteredData = data.where((item) {
          final createdAt = DateTime.tryParse(
            item['created_at']?.toString() ?? '',
          );

          if (createdAt == null) {
            return false;
          }

          final localDate = createdAt.toLocal();

          return localDate.year == latestDate!.year &&
              localDate.month == latestDate.month &&
              localDate.day == latestDate.day;
        }).toList();

        // Urutkan dari waktu paling lama → terbaru
        filteredData.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '');

          final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '');

          if (dateA == null || dateB == null) {
            return 0;
          }

          return dateA.compareTo(dateB);
        });
      }

      setState(() {
        sensorReadings = filteredData;
        dataDate = latestDate;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal mengambil sensor_reading: $e');

      setState(() {
        isLoading = false;
        errorMessage = 'Gagal mengambil data sensor.\n$e';
      });
    }
  }

  // DATA GRAFIK

  List<FlSpot> get chartData {
    final List<FlSpot> spots = [];

    for (int i = 0; i < sensorReadings.length; i++) {
      final reading = sensorReadings[i];

      final dynamic rawValue = selectedSensor == 'CO'
          ? reading['co_ppm']
          : reading['co2_ppm'];

      if (rawValue == null) {
        continue;
      }

      final value = double.tryParse(rawValue.toString()) ?? 0;

      // X menggunakan INDEX data.
      //
      // Ini sengaja supaya semua data pasti masuk ke grafik,
      // walaupun interval pembacaan sensor tidak selalu sama.

      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  // NILAI MAKSIMUM Y

  double get maxY {
    if (sensorReadings.isEmpty) {
      return selectedSensor == 'CO' ? 60 : 3000;
    }

    double highest = 0;

    for (final reading in sensorReadings) {
      final dynamic rawValue = selectedSensor == 'CO'
          ? reading['co_ppm']
          : reading['co2_ppm'];

      if (rawValue == null) {
        continue;
      }

      final value = double.tryParse(rawValue.toString()) ?? 0;

      if (value > highest) {
        highest = value;
      }
    }

    if (selectedSensor == 'CO') {
      // Minimal 60 agar tampilan tetap seperti desain
      if (highest < 60) {
        return 60;
      }

      // Dibulatkan ke kelipatan 20
      return ((highest / 20).ceil() * 20).toDouble();
    }

    // CO2
    if (highest < 3000) {
      return 3000;
    }

    return ((highest / 1000).ceil() * 1000).toDouble();
  }

  // INTERVAL Y

  double get intervalY {
    if (selectedSensor == 'CO') {
      return 20;
    }

    return 1000;
  }

  // FORMAT WAKTU

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();

    return '${localTime.hour.toString().padLeft(2, '0')}.'
        '${localTime.minute.toString().padLeft(2, '0')}';
  }

  // FORMAT TANGGAL

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Harian';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // LABEL X

  String _getBottomLabel(double value) {
    if (sensorReadings.isEmpty) {
      return '';
    }

    final index = value.round();

    if (index < 0 || index >= sensorReadings.length) {
      return '';
    }

    final createdAt = DateTime.tryParse(
      sensorReadings[index]['created_at']?.toString() ?? '',
    );

    if (createdAt == null) {
      return '';
    }

    return _formatTime(createdAt);
  }

  // BUILD

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

              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),

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
                  // JUDUL + DROPDOWN

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
                            dataDate == null
                                ? 'Harian'
                                : 'Harian • ${_formatDate(dataDate)}',

                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          // REFRESH
                          IconButton(
                            onPressed: isLoading ? null : _loadSensorReadings,

                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),

                            tooltip: 'Refresh',
                          ),

                          // DROPDOWN
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
                                  if (value == null) {
                                    return;
                                  }

                                  setState(() {
                                    selectedSensor = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // GRAFIK
                  Container(
                    height: 260,
                    width: double.infinity,

                    padding: const EdgeInsets.fromLTRB(12, 18, 18, 12),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: _buildChart(),
                  ),
                ],
              ),
            ),

            // LOG KEJADIAN
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

                    // Untuk sekarang bagian ini
                    // belum mengambil alert_logs.
                    // Kita fokus memastikan
                    // grafik sensor sudah benar.
                    _buildLogPlaceholder(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CHART

  Widget _buildChart() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Icon(Icons.error_outline, size: 32, color: Colors.grey),

              const SizedBox(height: 8),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,

                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: _loadSensorReadings,

                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              selectedSensor == 'CO' ? Icons.air : Icons.cloud,

              size: 36,

              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 8),

            const Text(
              'Belum ada data sensor.',

              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    // Tentukan interval X

    double xInterval = 1;

    if (chartData.length > 10) {
      xInterval = (chartData.length / 5).ceil().toDouble();
    }

    return LineChart(
      LineChartData(
        minX: 0,

        maxX: chartData.length <= 1 ? 1 : (chartData.length - 1).toDouble(),

        minY: 0,

        maxY: maxY,

        // GRID
        gridData: FlGridData(
          show: true,

          horizontalInterval: intervalY,

          drawVerticalLine: false,

          getDrawingHorizontalLine: (value) {
            return FlLine(
              strokeWidth: 1,

              color: Colors.grey.withValues(alpha: 0.25),
            );
          },
        ),

        // BORDER
        borderData: FlBorderData(show: false),

        // TITLES
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          // Y AXIS
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,

              reservedSize: 38,

              interval: intervalY,

              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),

                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                );
              },
            ),
          ),

          // X AXIS
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,

              reservedSize: 25,

              interval: xInterval,

              getTitlesWidget: (value, meta) {
                return Text(
                  _getBottomLabel(value),

                  style: const TextStyle(fontSize: 9, color: Colors.black54),
                );
              },
            ),
          ),
        ),

        // TOUCH / TOOLTIP
        lineTouchData: LineTouchData(
          enabled: true,

          handleBuiltInTouches: true,

          touchTooltipData: LineTouchTooltipData(
            // Background tooltip dibuat gelap
            // supaya teks terlihat.

            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map((spot) {
                    final index = spot.x.round();

                    if (index < 0 || index >= sensorReadings.length) {
                      return null;
                    }

                    final reading = sensorReadings[index];

                    final createdAt = DateTime.tryParse(
                      reading['created_at']?.toString() ?? '',
                    );

                    final time = createdAt != null
                        ? _formatTime(createdAt)
                        : '--.--';

                    final value = spot.y.toStringAsFixed(2);

                    return LineTooltipItem(
                      '$selectedSensor\n'
                      '$value ppm\n'
                      '$time',

                      const TextStyle(
                        color: Colors.white,

                        fontSize: 11,

                        fontWeight: FontWeight.w600,
                      ),
                    );
                  })
                  .whereType<LineTooltipItem>()
                  .toList();
            },
          ),
        ),

        // DATA LINE
        lineBarsData: [
          LineChartBarData(
            spots: chartData,

            isCurved: true,

            curveSmoothness: 0.25,

            barWidth: 2,

            color: const Color(0xFF8FCB8F),

            dotData: const FlDotData(show: false),

            belowBarData: BarAreaData(
              show: true,

              gradient: LinearGradient(
                begin: Alignment.topCenter,

                end: Alignment.bottomCenter,

                colors: [
                  const Color(0xFF8FCB8F).withValues(alpha: 0.45),

                  const Color(0xFF8FCB8F).withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LOG PLACEHOLDER

  Widget _buildLogPlaceholder() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),

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
              color: Colors.green.withValues(alpha: 0.10),

              shape: BoxShape.circle,
            ),

            child: Icon(
              selectedSensor == 'CO' ? Icons.air : Icons.cloud,

              color: Colors.green,

              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  selectedSensor == 'CO' ? 'Data CO' : 'Data CO₂',

                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Log kejadian akan '
                  'ditampilkan dari alert_logs.',

                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
