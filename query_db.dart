import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = 'https://nbwzourpbnmewwklewyr.supabase.co';
  final supabaseKey = 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z';
  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    print('--- Routes ---');
    final routes = await supabase.from('operation_routes').select().limit(5);
    for (var r in routes) print(r);

    print('\n--- Stations ---');
    final stations = await supabase.from('route_stations').select().limit(5);
    for (var s in stations) print(s);

    print('\n--- Trips ---');
    final trips = await supabase.from('operation_trips').select().limit(5);
    for (var t in trips) print(t);

    print('\n--- Fleet Vehicles ---');
    final vehicles = await supabase.from('vehicles').select().limit(5);
    for (var v in vehicles) print(v);

    print('\n--- Trip Pricing ---');
    final pricing = await supabase.from('trip_pricing').select().limit(5);
    for (var p in pricing) print(p);

  } catch (e) {
    print(e);
  }
}
