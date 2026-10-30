
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
  final Set<String> _shownPopupIds = {};
  bool _hasCompletedInitialLoad = false;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();

    _loadNotifications();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _loadNotifications(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // AMBIL DATA NOTIFIKASI

  Future<void> _loadNotifications({
    bool showLoading = true,
  }) async {
    if (_isFetching) return;
    _isFetching = true;

    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await _supabase
          .from('alert_logs')
          .select('''
            id,
            alert_type,
            created_at,
            resolved_at,
            acknowledged_at,
            sensor_readings (
              co2_ppm,
              status,
              measured_at
            )
          ''')
          .order('created_at', ascending: false)
          .limit(50);

      final data = List<Map<String, dynamic>>.from(response);
      final List<NotificationItem> result = [];

      for (final item in data) {
        final alertId = item['id']?.toString() ?? '';
        final alertType =
            item['alert_type']?.toString().toUpperCase() ?? '';

        final sensorData = item['sensor_readings'];

        final List<Map<String, dynamic>> readings =
        sensorData is List
            ? sensorData
            .whereType<Map>()
            .map(
              (e) => Map<String, dynamic>.from(e),
        )
            .toList()
            : sensorData is Map
            ? [Map<String, dynamic>.from(sensorData)]
            : [];

        readings.sort((a, b) {
          final aTime = DateTime.tryParse(
            a['measured_at']?.toString() ?? '',
          );
          final bTime = DateTime.tryParse(
            b['measured_at']?.toString() ?? '',
          );

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return bTime.compareTo(aTime);
        });

        final latestReading =
        readings.isNotEmpty ? readings.first : null;

        final createdAt = DateTime.tryParse(
          item['created_at']?.toString() ?? '',
        );

        final resolvedAt = DateTime.tryParse(
          item['resolved_at']?.toString() ?? '',
        );

        final co2Value = _toDouble(
          latestReading?['co2_ppm'],
        );

        // STATUS DARI BACKEND

        String? episodeStatus =
        latestReading?['status']?.toString().toLowerCase();

        if (episodeStatus != 'normal' &&
            episodeStatus != 'waspada' &&
            episodeStatus != 'bahaya') {
          if (alertType.contains('BAHAYA') ||
              alertType.contains('DANGER') ||
              alertType.contains('HIGH')) {
            episodeStatus = 'bahaya';
          } else if (alertType.contains('WASPADA') ||
              alertType.contains('WARNING')) {
            episodeStatus = 'waspada';
          } else {
            episodeStatus = null;
          }
        }

        // NOTIFIKASI WASPADA / BAHAYA

        if (createdAt != null &&
            (episodeStatus == 'waspada' ||
                episodeStatus == 'bahaya')) {
          final notification = _createWarningNotification(
            status: episodeStatus!,
            co2Value: co2Value,
            createdAt: createdAt,
          );

          result.add(notification);

          // Popup hanya untuk episode/status yang belum ditampilkan.
          final popupKey = '$alertId:$episodeStatus';

          if (alertId.isNotEmpty &&
              _hasCompletedInitialLoad &&
              _shownPopupIds.add(popupKey)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showWarningPopup(notification);
              }
            });
          } else if (alertId.isNotEmpty) {
            _shownPopupIds.add(popupKey);
          }
        }

        // NOTIFIKASI KEMBALI NORMAL

        if (resolvedAt != null) {
          result.add(
            NotificationItem(
              id: '${alertId}_resolved',
              type: NotificationType.normal,
              title: 'Kembali normal',
              subtitle: 'Episode peringatan telah selesai',
              time: _formatTime(resolvedAt),
              dateTime: resolvedAt,
            ),
          );
        }
      }

      result.sort(
            (a, b) => b.dateTime.compareTo(a.dateTime),
      );

      if (!mounted) return;

      setState(() {
        notifications = result;
        isLoading = false;
        errorMessage = null;
        _hasCompletedInitialLoad = true;
      });
    } catch (e) {
      debugPrint('Gagal mengambil data notifikasi: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
        'Gagal mengambil data notifikasi.\n$e';
      });
    } finally {
      _isFetching = false;
    }
  }

  // MEMBUAT NOTIFIKASI

  NotificationItem _createWarningNotification({
    required String status,
    required double? co2Value,
    required DateTime createdAt,
  }) {
    final bool isDanger = status == 'bahaya';

    final String title = isDanger
        ? 'BAHAYA: Kualitas udara tidak aman'
        : 'Waspada: Kualitas udara meningkat';

    final String co2Description = co2Value == null
        ? 'Nilai CO₂ belum tersedia'
        : 'CO₂: ${_formatValue(co2Value)} ppm';

    return NotificationItem(
      id: '${createdAt.microsecondsSinceEpoch}_$status',
      type: isDanger
          ? NotificationType.alert
          : NotificationType.warning,
      title: title,
      subtitle: '$co2Description • Status dari sistem AEROS',
      time: _formatTime(createdAt),
      dateTime: createdAt,
    );
  }

  // POPUP PERINGATAN

  void _showWarningPopup(NotificationItem notification) {
    if (!mounted) return;

    final bool isDanger =
        notification.type == NotificationType.alert;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: Icon(
            isDanger
                ? Icons.warning_rounded
                : Icons.notifications_active_rounded,
            size: 48,
            color: isDanger
                ? const Color(0xFFE53935)
                : const Color(0xFFFFA726),
          ),
          title: Text(
            isDanger ? 'BAHAYA!' : 'PERINGATAN WASPADA',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notification.subtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  // KONVERSI NILAI

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  // FORMAT ANGKA

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  // FORMAT WAKTU

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();

    return '${localTime.hour.toString().padLeft(2, '0')}:'
        '${localTime.minute.toString().padLeft(2, '0')}';
  }

  // BUILD HALAMAN

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                22,
                20,
                18,
              ),
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
                        : () => _loadNotifications(),
                    tooltip: 'Refresh',
                    icon: const Icon(
                      Icons.refresh,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            // LIST NOTIFIKASI

            Expanded(
              child: _buildNotificationList(),
            ),
          ],
        ),
      ),
    );
  }

  // LIST NOTIFIKASI

  Widget _buildNotificationList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 42,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF777780),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _loadNotifications(),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

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
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      );
    }

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

// MODEL NOTIFIKASI

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String subtitle;
  final String time;
  final DateTime dateTime;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.dateTime,
  });
}

// TIPE NOTIFIKASI

enum NotificationType {
  normal,
  warning,
  alert,
}

// CARD NOTIFIKASI

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

  Color get accentColor {
    switch (type) {
      case NotificationType.normal:
        return const Color(0xFF4CAF78);
      case NotificationType.warning:
        return const Color(0xFFFFA726);
      case NotificationType.alert:
        return const Color(0xFFE53935);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: accentColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Row(
          children: [
            // ICON

            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 19,
              ),
            ),

            const SizedBox(width: 10),

            // TEKS

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

            // WAKTU

            Text(
              time,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF777780),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
