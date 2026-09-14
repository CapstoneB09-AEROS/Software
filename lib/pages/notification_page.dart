import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<NotificationItem> notifications = [];

  bool isLoading = true;
  String? errorMessage;

  Timer? _refreshTimer;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadNotifications();

    // Refresh otomatis setiap 5 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadNotifications(showLoading: false);
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // AMBIL DATA DARI ALERT_LOGS
  // ============================================================

  Future<void> _loadNotifications({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await _supabase
          .from('alert_logs')
          .select(
            'id, alert_type, co_value, co2_value, '
            'resolved_at, created_at, acknowledged_at',
          )
          .order('created_at', ascending: false)
          .limit(50);

      final data = List<Map<String, dynamic>>.from(response);

      final List<NotificationItem> result = [];

      for (final item in data) {
        // ======================================================
        // DATA DASAR
        // ======================================================

        final alertType = item['alert_type']?.toString().toUpperCase();

        final coValue = _toDouble(item['co_value']);

        final co2Value = _toDouble(item['co2_value']);

        final createdAt = DateTime.tryParse(
          item['created_at']?.toString() ?? '',
        );

        final resolvedAt = DateTime.tryParse(
          item['resolved_at']?.toString() ?? '',
        );

        // ======================================================
        // NOTIFIKASI WARNING
        // ======================================================

        final warningNotification = _createWarningNotification(
          alertType: alertType,
          coValue: coValue,
          co2Value: co2Value,
          createdAt: createdAt,
        );

        if (warningNotification != null) {
          result.add(warningNotification);
        }

        // ======================================================
        // NOTIFIKASI KEMBALI NORMAL
        // ======================================================

        if (resolvedAt != null) {
          result.add(
            NotificationItem(
              type: NotificationType.normal,
              title: 'Kembali normal',
              subtitle: 'Semua parameter aman',
              time: _formatTime(resolvedAt),
              dateTime: resolvedAt,
            ),
          );
        }
      }

      // ========================================================
      // URUTKAN BERDASARKAN WAKTU TERBARU
      // ========================================================

      result.sort((a, b) {
        return b.dateTime.compareTo(a.dateTime);
      });

      if (!mounted) {
        return;
      }

      setState(() {
        notifications = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint('Gagal mengambil alert_logs: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = 'Gagal mengambil data notifikasi.\n$e';
      });
    }
  }

  // ============================================================
  // BUAT NOTIFIKASI WARNING
  // ============================================================

  NotificationItem? _createWarningNotification({
    required String? alertType,
    required double? coValue,
    required double? co2Value,
    required DateTime? createdAt,
  }) {
    if (createdAt == null) {
      return null;
    }

    // ----------------------------------------------------------
    // CO
    // ----------------------------------------------------------

    final bool isCO =
        alertType != null &&
        (alertType.contains('CO_WARNING') ||
            alertType.contains('CO_HIGH') ||
            alertType == 'CO');

    // ----------------------------------------------------------
    // CO2
    // ----------------------------------------------------------

    final bool isCO2 =
        alertType != null &&
        (alertType.contains('CO2_WARNING') ||
            alertType.contains('CO2_HIGH') ||
            alertType.contains('CO₂_WARNING') ||
            alertType.contains('CO₂_HIGH') ||
            alertType == 'CO2' ||
            alertType == 'CO₂');

    // ==========================================================
    // Kalau alert_type jelas CO
    // ==========================================================

    if (isCO) {
      final value = coValue ?? 0;

      return NotificationItem(
        type: NotificationType.warning,
        title: 'Kadar CO mencapai ${_formatValue(value)} ppm',
        subtitle: 'Jendela terbuka otomatis',
        time: _formatTime(createdAt),
        dateTime: createdAt,
      );
    }

    // ==========================================================
    // Kalau alert_type jelas CO2
    // ==========================================================

    if (isCO2) {
      final value = co2Value ?? 0;

      return NotificationItem(
        type: NotificationType.warning,
        title: 'Kadar CO₂ mencapai ${_formatValue(value)} ppm',
        subtitle: 'Jendela terbuka otomatis',
        time: _formatTime(createdAt),
        dateTime: createdAt,
      );
    }

    // ==========================================================
    // Kalau alert_type tidak spesifik
    //
    // Kita lihat nilai CO / CO2 untuk menentukan.
    // ==========================================================

    if (coValue != null && coValue > 35) {
      return NotificationItem(
        type: NotificationType.warning,
        title: 'Kadar CO mencapai ${_formatValue(coValue)} ppm',
        subtitle: 'Jendela terbuka otomatis',
        time: _formatTime(createdAt),
        dateTime: createdAt,
      );
    }

    if (co2Value != null && co2Value > 2500) {
      return NotificationItem(
        type: NotificationType.warning,
        title: 'Kadar CO₂ mencapai ${_formatValue(co2Value)} ppm',
        subtitle: 'Buzzer aktif',
        time: _formatTime(createdAt),
        dateTime: createdAt,
      );
    }

    // Kalau tidak memenuhi kondisi warning,
    // tidak ditampilkan sebagai warning.
    return null;
  }

  // ============================================================
  // KONVERSI DOUBLE
  // ============================================================

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    return double.tryParse(value.toString());
  }

  // ============================================================
  // FORMAT NILAI
  // ============================================================

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  // ============================================================
  // FORMAT WAKTU
  // ============================================================

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();

    return '${localTime.hour.toString().padLeft(2, '0')}:'
        '${localTime.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),

      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 20, 18),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    'Notifikasi',

                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF303038),
                    ),
                  ),

                  IconButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            _loadNotifications();
                          },

                    tooltip: 'Refresh',

                    icon: const Icon(Icons.refresh, size: 26),
                  ),
                ],
              ),
            ),

            // ==================================================
            // LIST
            // ==================================================
            Expanded(child: _buildNotificationList()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LIST NOTIFIKASI
  // ============================================================

  Widget _buildNotificationList() {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(Icons.error_outline, size: 42, color: Colors.grey.shade500),

              const SizedBox(height: 12),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,

                style: const TextStyle(fontSize: 12, color: Color(0xFF777780)),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _loadNotifications,

                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // DATA KOSONG
    // ----------------------------------------------------------

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 50,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 12),

            const Text(
              'Belum ada notifikasi',

              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF777780),
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Notifikasi akan muncul saat terjadi kejadian.',

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------------
    // DATA ADA
    // ----------------------------------------------------------

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

      itemCount: notifications.length,

      separatorBuilder: (context, index) {
        return const SizedBox(height: 10);
      },

      itemBuilder: (context, index) {
        final notification = notifications[index];

        return NotificationCard(
          type: notification.type,

          title: notification.title,

          subtitle: notification.subtitle,

          time: notification.time,
        );
      },
    );
  }
}

// ============================================================
// MODEL NOTIFIKASI
// ============================================================

class NotificationItem {
  final NotificationType type;

  final String title;

  final String subtitle;

  final String time;

  final DateTime dateTime;

  NotificationItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.dateTime,
  });
}

// ============================================================
// TIPE NOTIFIKASI
// ============================================================

enum NotificationType { normal, warning, alert }

// ============================================================
// CARD NOTIFIKASI
// ============================================================

class NotificationCard extends StatelessWidget {
  final NotificationType type;

  final String title;

  final String subtitle;

  final String time;

  const NotificationCard({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  // ==========================================================
  // WARNA SISI
  // ==========================================================

  Color get accentColor {
    switch (type) {
      case NotificationType.normal:
        return const Color(0xFF4CAF78);

      case NotificationType.warning:
        return const Color(0xFFFFA726);

      case NotificationType.alert:
        return const Color(0xFFE57373);
    }
  }

  // ==========================================================
  // BACKGROUND ICON
  // ==========================================================

  Color get iconBackground {
    switch (type) {
      case NotificationType.normal:
        return const Color(0xFFE7F6EC);

      case NotificationType.warning:
        return const Color(0xFFFFF1DD);

      case NotificationType.alert:
        return const Color(0xFFFDE8E8);
    }
  }

  // ==========================================================
  // ICON
  // ==========================================================

  IconData get icon {
    switch (type) {
      case NotificationType.normal:
        return Icons.check_circle_rounded;

      case NotificationType.warning:
        return Icons.info_rounded;

      case NotificationType.alert:
        return Icons.warning_rounded;
    }
  }

  // ==========================================================
  // BUILD CARD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        // Garis warna di sebelah kiri
        border: Border(left: BorderSide(color: accentColor, width: 4)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),

            blurRadius: 6,

            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        child: Row(
          children: [
            // ==================================================
            // ICON
            // ==================================================

            Container(
              width: 34,
              height: 34,

              decoration: BoxDecoration(
                color: iconBackground,

                shape: BoxShape.circle,
              ),

              child: Icon(icon, color: accentColor, size: 19),
            ),

            const SizedBox(width: 10),

            // ==================================================
            // TEKS
            // ==================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF303038),
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,

                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF777780),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ==================================================
            // WAKTU
            // ==================================================
            Text(
              time,

              style: const TextStyle(fontSize: 9, color: Color(0xFF777780)),
            ),
          ],
        ),
      ),
    );
  }
}
