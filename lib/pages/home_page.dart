import 'package:flutter/material.dart';

import '../widgets/air_quality_card.dart';
import '../widgets/device_status_card.dart';
import 'history_page.dart';
import 'notification_page.dart';
import '../services/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final SupabaseService _supabaseService = SupabaseService();

  // DATA DARI SUPABASE
  double currentCO = 0;
  double currentCO2 = 0;

  String systemStatus = 'NORMAL';
  String buzzerStatus = 'OFF';
  String windowStatus = 'CLOSED';

  int windowPosition = 0;

  bool driverAcknowledged = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceState();
  }

  // ============================================================
  // MENGAMBIL DATA DARI SUPABASE
  // ============================================================

  Future<void> _loadDeviceState() async {
    try {
      final data = await _supabaseService.getDeviceState();

      if (data == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      setState(() {
        currentCO = (data['last_co_ppm'] ?? 0).toDouble();
        currentCO2 = (data['last_co2_ppm'] ?? 0).toDouble();

        systemStatus = data['status'] ?? 'NORMAL';
        buzzerStatus = data['buzzer_state'] ?? 'OFF';
        windowStatus = data['window_status'] ?? 'CLOSED';

        windowPosition = (data['window_position'] ?? 0) as int;

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal mengambil data device_state: $e');

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget? _getAppBar() {
    // BERANDA
    if (_selectedIndex == 0) {
      return AppBar(
        backgroundColor: const Color(0xFF5B82D6),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AEROS',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'Sistem Monitoring Kualitas Udara Kendaraan',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),

        // TOMBOL REFRESH DATA SUPABASE
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              _loadDeviceState();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      );
    }

    return null;
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _getBody() {
    if (_selectedIndex == 0) {
      return _buildHomePage();
    }

    if (_selectedIndex == 1) {
      return const HistoryPage();
    }

    return const NotificationPage();
  }

  // ============================================================
  // HOME PAGE
  // ============================================================

  Widget _buildHomePage() {
    final bool isWarning = systemStatus.toUpperCase() == 'WARNING';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // STATUS SISTEM
            // ==================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: isWarning
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Text(
                    systemStatus == 'WARNING' ? 'Waspada' : 'Normal',

                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isWarning
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================================
            // CO
            // ==================================================
            AirQualityCard(
              title: 'Karbon Monoksida (CO)',
              value: currentCO,
              unit: 'ppm',
              maxValue: 200,
              warningValue: 35,
              icon: Icons.air,
            ),

            const SizedBox(height: 12),

            // ==================================================
            // CO2
            // ==================================================
            AirQualityCard(
              title: 'Karbon Dioksida (CO₂)',
              value: currentCO2,
              unit: 'ppm',
              maxValue: 5000,
              warningValue: 2500,
              icon: Icons.cloud,
            ),

            const SizedBox(height: 22),

            // ==================================================
            // STATUS SISTEM
            // ==================================================
            const Text(
              'Status Sistem',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // BUZZER
                // ==================================================

                Expanded(
                  child: DeviceStatusCard(
                    title: 'Buzzer',

                    status: buzzerStatus == 'ON' ? 'Aktif' : 'Tidak Aktif',

                    isActive: buzzerStatus == 'ON',

                    icon: buzzerStatus == 'ON'
                        ? Icons.notifications_active
                        : Icons.notifications_off,

                    showButton:
                        isWarning &&
                        buzzerStatus == 'ON' &&
                        !driverAcknowledged,

                    onAcknowledge: () {
                      setState(() {
                        driverAcknowledged = true;
                        buzzerStatus = 'OFF';
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Peringatan telah diketahui.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // ==================================================
                // JENDELA
                // ==================================================
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 120),

                    padding: const EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(12),

                      border: Border.all(color: Colors.grey.shade300),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // HEADER JENDELA

                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,

                              decoration: BoxDecoration(
                                color: isWarning
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100,

                                borderRadius: BorderRadius.circular(8),
                              ),

                              child: Icon(
                                Icons.window,
                                size: 18,
                                color: isWarning
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                              ),
                            ),

                            const SizedBox(width: 7),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                const Text(
                                  'Jendela',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                Text(
                                  windowStatus == 'OPEN'
                                      ? 'Terbuka'
                                      : 'Tertutup',

                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // POSISI JENDELA
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,

                          children: [
                            Text(
                              '$windowPosition%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(width: 5),

                            const Padding(
                              padding: EdgeInsets.only(bottom: 2),

                              child: Text(
                                'Terbuka',
                                style: TextStyle(fontSize: 9),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // PROGRESS JENDELA
                        LinearProgressIndicator(
                          value: windowPosition / 100,

                          minHeight: 5,

                          borderRadius: BorderRadius.circular(10),

                          backgroundColor: Colors.grey.shade200,

                          valueColor: AlwaysStoppedAnimation<Color>(
                            isWarning
                                ? Colors.orange.shade400
                                : Colors.green.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ==================================================
            // REKOMENDASI SAAT WARNING
            // ==================================================
            if (isWarning)
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: Colors.orange.shade50,

                  borderRadius: BorderRadius.circular(10),

                  border: Border.all(color: Colors.orange.shade200),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Kualitas udara perlu diperhatikan. '
                        'Ikuti rekomendasi sistem dan pastikan '
                        'kondisi kendaraan tetap aman.',

                        style: const TextStyle(fontSize: 11, height: 1.4),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _getAppBar(),

      body: isLoading && _selectedIndex == 0
          ? const Center(child: CircularProgressIndicator())
          : _getBody(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,

        onDestinationSelected: _onItemTapped,

        height: 65,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),

          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),

          NavigationDestination(
            icon: Icon(Icons.notifications_none_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
        ],
      ),
    );
  }
}
