import 'package:flutter/material.dart';

class DeviceStatusCard extends StatelessWidget {
  final String title;
  final String status;
  final IconData icon;
  final bool isActive;
  final bool showButton;
  final VoidCallback? onAcknowledge;

  const DeviceStatusCard({
    super.key,
    required this.title,
    required this.status,
    required this.icon,
    required this.isActive,
    this.showButton = false,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
            // Icon + title
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isActive
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                  ),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        status,
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

            const SizedBox(height: 10),


            if (showButton)
              SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: isActive ? onAcknowledge : null,
                  icon: const Icon(Icons.notifications_off, size: 14),
                  label: const Text(
                    'Matikan Buzzer',
                    style: TextStyle(fontSize: 10),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: Colors.blue.shade500,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
