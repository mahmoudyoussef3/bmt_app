import 'package:bmt_app/apps/captain/main.dart' as captain;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/apps/captain/core/di/captain_di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nbwzourpbnmewwklewyr.supabase.co',
    anonKey: 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z',
  );

  registerCaptainDependencies();

  runApp(const captain.CaptainApp());
}
