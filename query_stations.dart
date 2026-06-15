import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? 'http://127.0.0.1:54321';
  final supabaseKey = Platform.environment['SUPABASE_ANON_KEY'] ?? 'ey...'; // This won't work without actual keys
}
