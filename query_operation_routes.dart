import 'package:supabase/supabase.dart';
void main() async {
  final supabaseUrl = 'https://nbwzourpbnmewwklewyr.supabase.co';
  final supabaseKey = 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z';
  final supabase = SupabaseClient(supabaseUrl, supabaseKey);
  try {
    final res = await supabase.from('operation_routes').select().limit(1);
    print(res);
  } catch (e) {
    print(e);
  }
}
