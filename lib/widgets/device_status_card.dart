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
              color: Colors.black.withValues(alpha:  0.06),
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
                height: 30,
                child: ElevatedButton.icon(
                  onPressed: onAcknowledge,
                  icon: const Icon(
                    Icons.touch_app,
                    size: 13,
                  ),
                  label: const Text(
                    'Saya Tahu',
                    style: TextStyle(
                      fontSize: 9,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.blue.shade500,
                    foregroundColor: Colors.white,
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