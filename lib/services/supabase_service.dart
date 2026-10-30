
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String deviceId = 'AEROS_01';

  Future<Map<String, dynamic>?> getDeviceState() async {
    // Ambil status terkini khusus perangkat AEROS_01.
    final state = await _supabase
        .from('device_state')
        .select(
      'device_id, last_co_ppm, last_co2_ppm, status, '
          'buzzer_state, window_status, connection_status, '
          'active_alert_id, updated_at, ack_driver, ack_at',
    )
        .eq('device_id', deviceId)
        .maybeSingle();

    if (state == null) {
      return null;
    }

    // Angka CO tidak digunakan pada MVP.
    // CO2 terkini berasal dari device_state.
    return {
      ...state,
      'last_co_ppm': state['last_co_ppm'] ?? 0,
      'last_co2_ppm': state['last_co2_ppm'],
    };
  }

  // Ambil riwayat pembacaan sensor untuk grafik.
  Future<List<Map<String, dynamic>>> getSensorReadings({
    int limit = 50,
  }) async {
    final response = await _supabase
        .from('sensor_readings')
        .select(
      'device_id, co2_ppm, co2_peak_ppm, '
          'co2_peak_second, status, measured_at',
    )
        .eq('device_id', deviceId)
        .order('measured_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }
}
