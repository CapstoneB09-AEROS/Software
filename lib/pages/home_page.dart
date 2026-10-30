import 'dart:async';

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

  String systemStatus = 'normal';
  String buzzerStatus = 'OFF';
  dynamic windowStatus;

  String connectionStatus = 'offline';
  DateTime? lastUpdatedAt;

  bool isLoading = true;
  bool driverAcknowledged = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _loadDeviceState();

    // Refresh data setiap 5 detik.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _loadDeviceState(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // MENGAMBIL DATA DARI SUPABASE

  Future<void> _loadDeviceState() async {
    try {
      final data = await _supabaseService.getDeviceState();

      if (!mounted) return;

      if (data == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      setState(() {
        // CO sementara selalu bernilai 0.
        // Tidak mengambil data dari Supabase.
        currentCO = 0;

        // CO2 mengambil data aktual dari Supabase.
        currentCO2 =
            double.tryParse(
              data['last_co2_ppm']?.toString() ?? '',
            ) ??
                0;

        systemStatus =
            data['status']?.toString().toLowerCase() ?? 'unknown';

        final rawBuzzer = data['buzzer_state'];
        final buzzerValue =
        rawBuzzer?.toString().trim().toUpperCase();

        buzzerStatus =
        rawBuzzer == true ||
            rawBuzzer == 1 ||
            ['ON', 'TRUE', '1', 'ACTIVE', 'AKTIF']
                .contains(buzzerValue)
            ? 'ON'
            : 'OFF';

        // Nilai dapat berupa 0, 50, atau null.
        // Jangan menganggap angka sebagai String secara langsung.
        windowStatus = data['window_status'];

        connectionStatus =
            data['connection_status']?.toString().toLowerCase() ??
                'offline';

        lastUpdatedAt = DateTime.tryParse(
          data['updated_at']?.toString() ?? '',
        );

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal mengambil data device_state: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // NAVIGATION

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // APP BAR

  PreferredSizeWidget? _getAppBar() {
    if (_selectedIndex == 0) {
      return AppBar(
        backgroundColor: const Color(0xFF5B82D6),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
              'assets/AEROS.png',
              height: 40,
              width: 45,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AEROS',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sistem Monitoring Kualitas Udara Kendaraan',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadDeviceState,
            icon: const Icon(Icons.refresh),
          ),
        ],
      );
    }

    return null;
  }

  // BODY

  Widget _getBody() {
    if (_selectedIndex == 0) {
      return _buildHomePage();
    }

    if (_selectedIndex == 1) {
      return const HistoryPage();
    }

    return const NotificationPage();
  }

  // HOME PAGE

  Widget _buildHomePage() {
    final status = systemStatus.toLowerCase();

    final bool isNormal = status == 'normal';
    final bool isWarning = status == 'waspada';
    final bool isDanger = status == 'bahaya';

    final bool isOffline = connectionStatus != 'online';

    final bool isDataStale = lastUpdatedAt == null ||
        DateTime.now().difference(lastUpdatedAt!).inSeconds > 30;

    final bool isDataUnavailable = isOffline || isDataStale;

    final statusColor = isDanger
        ? Colors.red
        : isWarning
        ? Colors.orange
        : isNormal
        ? Colors.green
        : Colors.grey;

    final statusLabel = isDanger
        ? 'Bahaya'
        : isWarning
        ? 'Waspada'
        : isNormal
        ? 'Normal'
        : 'Status tidak diketahui';

    // Jika koneksi putus atau data kedaluwarsa,
    // jangan menampilkan status lama sebagai kondisi terkini.
    final displayStatusColor =
    isDataUnavailable ? Colors.grey : statusColor;

    final displayStatusLabel =
    isDataUnavailable ? 'Data tidak terbaru' : statusLabel;

    // window_status berupa angka 0, 50, atau null.
    final String windowPosition = windowStatus?.toString() ?? '';

    final String windowLabel = windowPosition == '0'
        ? 'TERTUTUP'
        : windowPosition == '50'
        ? 'TERBUKA'
        : 'Bergerak / tidak diketahui';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KONEKSI DAN KESEGARAN DATA

            if (isOffline)
              const Text(
                'Perangkat offline. Data terbaru belum dapat dipastikan.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              )
            else if (isDataStale)
              const Text(
                'Data sudah lebih dari 30 detik atau belum tersedia. '
                    'Status keselamatan belum dapat dipastikan.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              )
            else
              Text(
                'Perangkat online • Data diperbarui: '
                    '${lastUpdatedAt!.toLocal()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

            const SizedBox(height: 8),

            // BADGE STATUS SISTEM

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: displayStatusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayStatusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: displayStatusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // CO

            AirQualityCard(
              title: 'Karbon Monoksida (CO)',
              value: currentCO,
              unit: 'ppm',
              maxValue: 200,
              warningValue: 35,
              icon: Icons.air,
            ),

            const SizedBox(height: 12),

            // CO2

            AirQualityCard(
              title: 'Karbon Dioksida (CO₂)',
              value: currentCO2,
              unit: 'ppm',
              maxValue: 5000,
              warningValue: 2500,
              icon: Icons.cloud,
            ),

            const SizedBox(height: 22),

            // STATUS PERANGKAT

            const Text(
              'Status Sistem',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BUZZER

                Expanded(
                  child: DeviceStatusCard(
                    title: 'Buzzer',
                    status: buzzerStatus == 'ON'
                        ? 'Aktif'
                        : 'Tidak Aktif',
                    isActive: buzzerStatus == 'ON',
                    icon: buzzerStatus == 'ON'
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    showButton: true,

                    // MASIH SIMULASI.
                    // Belum mengirim perintah ke hardware.
                    onAcknowledge: () {
                      setState(() {
                        driverAcknowledged = true;
                        buzzerStatus = 'OFF';
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Buzzer dimatikan (simulasi).',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // JENDELA

                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 120,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
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
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.window,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Jendela',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    windowLabel,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // REKOMENDASI WASPADA ATAU BAHAYA
            // Hanya ditampilkan jika data masih terbaru
            // dan perangkat sedang online.

            if (!isDataUnavailable && (isWarning || isDanger))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDanger
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDanger
                        ? Colors.red.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: isDanger
                          ? Colors.red.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isDanger
                            ? 'Kualitas udara berada pada status bahaya. '
                            'Segera ikuti prosedur keselamatan dan '
                            'keluar dari area berisiko sesuai arahan '
                            'petugas.'
                            : 'Kualitas udara berstatus waspada. '
                            'Perhatikan kondisi lingkungan dan ikuti '
                            'rekomendasi sistem.',
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.4,
                        ),
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

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _getAppBar(),
      body: isLoading && _selectedIndex == 0
          ? const Center(
        child: CircularProgressIndicator(),
      )
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
