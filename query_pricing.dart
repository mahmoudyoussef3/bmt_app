import 'package:supabase/supabase.dart';
void main() async {
  final supabaseUrl = 'https://nbwzourpbnmewwklewyr.supabase.co';
  final supabaseKey = 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z';
  final supabase = SupabaseClient(supabaseUrl, supabaseKey);
  try {
    final pricing = await supabase.from('trip_pricing').select().limit(5);
    for (var p in pricing) print(p);
  } catch (e) {
    print(e);
  }
}
