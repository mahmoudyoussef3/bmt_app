import 'package:bmt_app/apps/client/client_app.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/core/network/dio_factory.dart';
import 'package:bmt_app/core/network/supabase_dio_adapter.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nbwzourpbnmewwklewyr.supabase.co',
    anonKey: 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z',
    httpClient: DioHttpClientAdapter(DioFactory.getDio()),
  );

  registerClientDependencies();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppModeCubit()..load()),
        BlocProvider(create: (_) => LocaleCubit()..load()),
      ],
      child: const ClientApp(),
    ),
  );
}
