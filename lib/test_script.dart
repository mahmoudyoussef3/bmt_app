import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/apps/dashboard/features/routes/data/datasources/supabase_routes_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We can't easily initialize Supabase without keys.
  // Wait, the project might have a .env or hardcoded keys in main.dart?
}
