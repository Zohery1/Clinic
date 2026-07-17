import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/src/core/constants/supabase_config.dart';

void main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );
  
  final client = Supabase.instance.client;
  print('Querying appointments summary...');
  try {
    final response = await client.from('appointments').select('status, price_charged');
    if (response.isNotEmpty) {
      final counts = <String, int>{};
      final revenues = <String, double>{};
      for (var row in response) {
        final status = row['status'] as String? ?? 'unknown';
        final price = (row['price_charged'] as num? ?? 0.0).toDouble();
        counts[status] = (counts[status] ?? 0) + 1;
        revenues[status] = (revenues[status] ?? 0.0) + price;
      }
      print('Total appointments: ${response.length}');
      print('Appointments by Status: $counts');
      print('Revenue by Status: $revenues');
      
      // Let's also print the dates of these appointments
      final dateResponse = await client.from('appointments').select('appointment_date, status').order('appointment_date', ascending: false);
      print('Recent appointments:');
      for (var row in dateResponse.take(10)) {
        print('  Date: ${row['appointment_date']}, Status: ${row['status']}');
      }
    } else {
      print('Appointments table is empty!');
    }
  } catch (e) {
    print('Error: $e');
  }
}
