import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getDeviceState() async {
    final response = await _supabase
        .from('device_state')
        .select()
        .limit(1)
        .maybeSingle();

    return response;
  }
}
