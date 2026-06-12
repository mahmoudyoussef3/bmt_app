import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Test Supabase Connection', () async {
    await Supabase.initialize(
      url: 'https://nbwzourpbnmewwklewyr.supabase.co',
      anonKey: 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z',
    );
    final client = Supabase.instance.client;
    
    try {
      final routes = await client.from('operation_routes').select().eq('status', 'active');
      print('Routes: $routes');
      
      final drivers = await client.from('drivers').select().eq('status', 'active');
      print('Drivers: $drivers');

      final vehicles = await client.from('vehicles').select().eq('status', 'active');
      print('Vehicles: $vehicles');
      
    } catch (e) {
      print('Supabase Error: $e');
      fail(e.toString());
    }
  });
}
