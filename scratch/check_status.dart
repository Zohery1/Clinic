import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/src/core/constants/supabase_config.dart';

void main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );
  
  final client = Supabase.instance.client;
  print('Fetching first appointment...');
  try {
    final response = await client.from('appointments').select().limit(1);
    if (response.isNotEmpty) {
      final appointment = response.first as Map<String, dynamic>;
      print('Appointment: $appointment');
      final id = appointment['id'];
      final originalStatus = appointment['status'];
      print('Original Status: $originalStatus');
      
      print('Trying to update status to "active"...');
      try {
        await client.from('appointments').update({'status': 'active'}).eq('id', id);
        print('SUCCESS: Updated status to "active"!');
        // Restore
        await client.from('appointments').update({'status': originalStatus}).eq('id', id);
        print('Restored status to "$originalStatus"');
      } catch (updateError) {
        print('UPDATE ERROR: $updateError');
      }
    } else {
      print('Appointments table is empty!');
    }
  } catch (e) {
    print('Error: $e');
  }
}
