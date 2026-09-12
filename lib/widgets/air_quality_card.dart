import 'package:flutter/material.dart';

class AirQualityCard extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final double maxValue;
  final double warningValue;
  final IconData icon;

  const AirQualityCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.maxValue,
    required this.warningValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    double progress = value / maxValue;

    if (progress > 1) {
      progress = 1;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
          // Judul + icon
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                icon,
                size: 24,
                color: Colors.black87,
              ),
            ],
          ),

          const SizedBox(height: 5),

          // Nilai sensor
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toStringAsFixed(
                  value % 1 == 0 ? 0 : 1,
                ),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                value >= warningValue
                    ? Colors.orange.shade400
                    : Colors.blue.shade500,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Skala
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                warningValue.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                maxValue.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}