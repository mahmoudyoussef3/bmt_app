import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/main.dart';
import 'package:bmt_app/apps/client/client_app.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/main.dart';
import 'package:bmt_app/core/app_mode/app_mode_cubit.dart';
import 'package:bmt_app/core/flavors/app_flavor.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/core/network/dio_factory.dart';
import 'package:bmt_app/core/network/supabase_dio_adapter.dart';
import 'package:bmt_app/core/notifications/fcm_background_handler.dart';
import 'package:bmt_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrapFlavorApp(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  AppFlavorConfig.activate(flavor);
  final config = AppFlavorConfig.forFlavor(flavor);
  await _initializeSupabase(config);

  Widget app;
  switch (flavor) {
    case AppFlavor.client:
      registerClientDependencies();
      app = const ClientApp();
    case AppFlavor.captain:
      registerCaptainDependencies();
      app = const CaptainApp();
    case AppFlavor.dashboard:
      registerDashboardDependencies();
      app = const DashboardWebApp();
  }

  runApp(_FlavorAppProviders(child: app));
}

Future<void> _initializeSupabase(AppFlavorConfig config) async {
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
    httpClient: DioHttpClientAdapter(DioFactory.getDio()),
  );
}

class _FlavorAppProviders extends StatelessWidget {
  const _FlavorAppProviders({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppModeCubit()..load()),
        BlocProvider(
          create: (_) => LocaleCubit(
            defaultLanguageCode: 'en',
          )..load(),
        ),
      ],
      child: child,
    );
  }
}
