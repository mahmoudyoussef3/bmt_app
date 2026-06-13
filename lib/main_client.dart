import 'package:bmt_app/apps/client/client_app.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nbwzourpbnmewwklewyr.supabase.co',
    anonKey: 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z',
  );

  registerClientDependencies();

  runApp(const ClientApp());
}
