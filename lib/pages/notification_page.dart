import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

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

            const Padding(
              padding: EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF303038),
                ),
              ),
            ),

            // ==================================================
            // LIST NOTIFIKASI
            // ==================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: const [
                  // ==========================================
                  // NOTIFIKASI 1 - KEMBALI NORMAL
                  // ==========================================

                  NotificationCard(
                    type: NotificationType.normal,
                    title: 'Kembali normal',
                    subtitle: 'Semua parameter aman',
                    time: '15:20',
                  ),

                  SizedBox(height: 10),

                  // ==========================================
                  // NOTIFIKASI 2 - CO TINGGI
                  // ==========================================
                  NotificationCard(
                    type: NotificationType.warning,
                    title: 'Kadar CO mencapai 42 ppm',
                    subtitle: 'Jendela terbuka otomatis',
                    time: '14:17',
                  ),

                  SizedBox(height: 10),

                  // ==========================================
                  // NOTIFIKASI 3 - BATAS WASPADA
                  // ==========================================
                  NotificationCard(
                    type: NotificationType.alert,
                    title: 'Kadar CO mencapai batas waspada',
                    subtitle: '35 ppm',
                    time: '12:00',
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
