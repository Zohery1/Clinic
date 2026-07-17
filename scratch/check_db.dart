import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/src/core/constants/supabase_config.dart';

void main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );
  
  final client = Supabase.instance.client;
  print('Fetching columns of patients table...');
  try {
    final response = await client.from('patients').select().limit(1);
    if (response.isNotEmpty) {
      final keys = (response.first as Map).keys.toList();
      print('Columns: $keys');
      if (keys.contains('medical_history')) {
        print('SUCCESS: medical_history column exists!');
      } else {
        print('WARNING: medical_history column does NOT exist!');
      }
    } else {
      print('Patients table is empty, but we got response: $response');
    }
  } catch (e) {
    print('Error: $e');
  }
}
