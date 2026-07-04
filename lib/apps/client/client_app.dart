import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/core/notifications/fcm_service.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/screens/client_shell_screen.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/screens/my_trips_screen.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/screens/support_center_screen.dart';
import 'package:bmt_app/apps/client/features/support/presentation/screens/create_support_ticket_screen.dart';
import 'package:bmt_app/apps/client/features/support/presentation/screens/support_ticket_details_screen.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/screens/profile_screen.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/screens/routes_hub_screen.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/cubit/communication_cubit.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/screens/communication_screen.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/cubit/referral_rewards_cubit.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/screens/referral_rewards_screen.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/cubit/loyalty_cubit.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/screens/loyalty_screen.dart';
import 'package:bmt_app/apps/client/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:bmt_app/apps/client/features/settings/presentation/screens/settings_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/welcome_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/auth_success_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/screens/booking_approval_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/booking_wizard_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/map_route_selection_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/popular_routes_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/route_overview_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/route_selection_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/search_trip_screen.dart';
import 'package:bmt_app/apps/client/features/seat_release/presentation/cubit/seat_release_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_release/presentation/screens/seat_release_screen.dart';
import 'package:bmt_app/apps/client/core/theme/client_app_theme.dart';
import 'package:bmt_app/apps/client/core/theme/client_theme.dart';
import 'package:bmt_app/apps/client/features/home/presentation/screens/client_splash_screen.dart';
import 'package:bmt_app/apps/client/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:bmt_app/apps/client/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:bmt_app/apps/client/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:bmt_app/core/flavors/app_flavor.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/screens/subscription_screen.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';

class ClientApp extends StatefulWidget {
  const ClientApp({super.key});

  @override
  State<ClientApp> createState() => _ClientAppState();
}

class _ClientAppState extends State<ClientApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSub;

  void _setThemeMode(ThemeMode mode) => setState(() => _themeMode = mode);

  @override
  void initState() {
    super.initState();
    registerClientDependencies();
    _listenAuth();
  }

  void _listenAuth() {
    final supabase = Supabase.instance.client;

    // Initialise FCM for a session that already exists at startup.
    final current = supabase.auth.currentSession;
    if (current != null) {
      FcmService.instance.initialize(
        userId: current.user.id,
        appType: 'client',
        supabase: supabase,
        navigatorKey: _navigatorKey,
      );
    }

    // Track future sign-in / sign-out events.
    _authSub = supabase.auth.onAuthStateChange.listen((state) {
      final session = state.session;
      if (session != null) {
        FcmService.instance.initialize(
          userId: session.user.id,
          appType: 'client',
          supabase: supabase,
          navigatorKey: _navigatorKey,
        );
      } else {
        FcmService.instance.deactivateToken(supabase);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClientAppTheme(
      themeMode: _themeMode,
      setThemeMode: _setThemeMode,
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return BlocProvider<OnboardingCubit>(
            create: (_) => clientGetIt<OnboardingCubit>()..checkStatus(),
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              debugShowCheckedModeBanner: false,
              title: AppFlavorConfig.current.appName,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: locale,
              localeResolutionCallback: (deviceLocale, supportedLocales) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    return supportedLocale;
                  }
                }
                return supportedLocales.first;
              },
              theme: ClientTheme.light(),
              darkTheme: ClientTheme.dark(),
              themeMode: _themeMode,

              home: BlocBuilder<OnboardingCubit, OnboardingState>(
                builder: (context, onboardingState) {
                  if (onboardingState is OnboardingLoading ||
                      onboardingState is OnboardingInitial) {
                    return const ClientSplashScreen();
                  }

                  if (onboardingState is OnboardingLoaded &&
                      !onboardingState.hasSeenOnboarding) {
                    return const OnboardingScreen();
                  }

                  return StreamBuilder<AuthState>(
                    stream: Supabase.instance.client.auth.onAuthStateChange,
                    builder: (context, snapshot) {
                      // Also check currentSession as initial state might not emit immediately
                      final session =
                          snapshot.data?.session ??
                          Supabase.instance.client.auth.currentSession;
                      if (session != null) {
                        return _buildClientShell();
                      }
                      return _buildAuthScope(const WelcomeScreen());
                    },
                  );
                },
              ),

              routes: {
                '/home': (_) => _buildClientShell(),

                // Authentication Screens
                AuthRoutes.welcome: (_) =>
                    _buildAuthScope(const WelcomeScreen()),
                AuthRoutes.signIn: (_) => _buildAuthScope(const SignInScreen()),
                AuthRoutes.signUp: (_) => _buildAuthScope(const SignUpScreen()),
                AuthRoutes.forgotPassword: (_) =>
                    _buildForgotPasswordScope(const ForgotPasswordScreen()),

                AuthRoutes.success: (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  final email = args is Map ? args['email']?.toString() : null;
                  return AuthSuccessScreen(email: email);
                },

                // Booking
                BookingRoutes.search: (context) => _buildBookingScope(
                  SearchTripScreen(
                    initialQuery: BookingSearchQuery.fromArguments(
                      ModalRoute.of(context)?.settings.arguments,
                    ),
                  ),
                ),

                BookingRoutes.routeSelection: (_) =>
                    _buildBookingScope(const RouteSelectionScreen()),
                BookingRoutes.popularRoutes: (_) =>
                    _buildBookingScope(const PopularRoutesScreen()),
                BookingRoutes.mapSelection: (_) =>
                    _buildBookingScope(const MapRouteSelectionScreen()),
                BookingRoutes.availableTrips: (_) =>
                    _buildBookingScope(const SearchTripScreen()),
                BookingRoutes.vehicleListing: (_) =>
                    _buildBookingScope(const SearchTripScreen()),
                BookingRoutes.vehicleDetails: (_) =>
                    _buildBookingScope(const SearchTripScreen()),

                // New booking wizard flow
                BookingRoutes.wizard: (context) {
                  final route = ModalRoute.of(context)?.settings.arguments;
                  if (route is! RouteOptionData) return const SizedBox.shrink();
                  return BlocProvider(
                    create: (_) => BookingWizardCubit(route),
                    child: const BookingWizardScreen(),
                  );
                },

                BookingRoutes.routeOverview: (context) {
                  final route = ModalRoute.of(context)?.settings.arguments;
                  if (route is! RouteOptionData) return const SizedBox.shrink();
                  return RouteOverviewScreen(route: route);
                },

                BookingRoutes.approval: (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  final m = args is Map ? args : <String, dynamic>{};
                  return BookingApprovalScreen(
                    routeName: m['routeName']?.toString() ?? '',
                    pickup: m['pickup']?.toString() ?? '',
                    dropoff: m['dropoff']?.toString() ?? '',
                    departure: m['departure']?.toString() ?? '',
                    seat: m['seat']?.toString() ?? '',
                    package: m['package']?.toString() ?? '',
                    total: m['total']?.toString() ?? '0',
                  );
                },

                '/daily-booking': (_) =>
                    _buildBookingScope(const SearchTripScreen()),
                '/seat-selection': (_) =>
                    _buildBookingScope(const SearchTripScreen()),
                '/seat-release': (_) =>
                    _buildSeatReleaseScope(const SeatReleaseScreen()),
                '/payment-checkout': (_) =>
                    _buildBookingScope(const SearchTripScreen()),
                '/subscription': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
                  return _buildPackagesScope(SubscriptionScreen(
                    bookingData: args,
                  ));
                },

                // Trips
                TripsRoutes.myTrips: (context) => _buildTripsScope(
                  MyTripsScreen(
                    onOpenRoute: (route, [arguments]) {
                      Navigator.of(
                        context,
                      ).pushNamed(route, arguments: arguments);
                    },
                  ),
                ),

                TripsRoutes.tripDetails: (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  String? tripId;

                  if (args is Map) {
                    tripId = args['tripId']?.toString();
                  }

                  return _buildTripsScope(TripDetailsScreen(tripId: tripId));
                },

                // Other Features
                '/tracking': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  String? bookingId;
                  String? tripId;
                  if (args is Map) {
                    bookingId = args['bookingId']?.toString();
                    tripId = args['tripId']?.toString();
                  }
                  return _buildTrackingScope(
                    TrackingScreen(bookingId: bookingId, tripId: tripId),
                  );
                },
                '/support': (_) =>
                    _buildSupportScope(const SupportCenterScreen()),
                '/create_ticket': (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments as String?;
                  return _buildSupportScope(
                    CreateSupportTicketScreen(initialCategory: args),
                  );
                },
                '/ticket_details': (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments as String;
                  return _buildSupportScope(
                    SupportTicketDetailsScreen(ticketId: args),
                  );
                },

                '/communication': (_) =>
                    _buildCommunicationScope(const CommunicationScreen()),
                '/rewards': (_) =>
                    _buildReferralRewardsScope(const ReferralRewardsScreen()),
                '/loyalty': (_) => _buildLoyaltyScope(const LoyaltyScreen()),
                '/settings': (_) => _buildSettingsScope(const SettingsScreen()),

                '/profile': (context) => _buildProfileScope(
                  ProfileScreen(
                    onOpenRoute: (route, [arguments]) {
                      Navigator.of(
                        context,
                      ).pushNamed(route, arguments: arguments);
                    },
                  ),
                ),

                // Other Versions
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildClientShell() {
    return ClientShellScreen(
      routesBuilder: (context) => _buildRoutesHubScope(
        RoutesHubScreen(
          onOpenRoute: (route, [arguments]) {
            Navigator.of(context).pushNamed(route, arguments: arguments);
          },
        ),
      ),
      tripsBuilder: (context) => _buildTripsScope(
        MyTripsScreen(
          onOpenRoute: (route, [arguments]) {
            Navigator.of(context).pushNamed(route, arguments: arguments);
          },
        ),
      ),
      profileBuilder: (context) => _buildProfileScope(
        ProfileScreen(
          onOpenRoute: (route, [arguments]) {
            Navigator.of(context).pushNamed(route, arguments: arguments);
          },
        ),
      ),
      notificationsBuilder: (context) =>
          _buildNotificationsScope(const NotificationsScreen()),
    );
  }

  Widget _buildAuthScope(Widget child) {
    return BlocProvider<ClientAuthCubit>(
      create: (_) => clientGetIt<ClientAuthCubit>(),
      child: child,
    );
  }

  Widget _buildForgotPasswordScope(Widget child) {
    return BlocProvider<ForgotPasswordCubit>(
      create: (_) => clientGetIt<ForgotPasswordCubit>(),
      child: child,
    );
  }

  Widget _buildTripsScope(Widget child) {
    return BlocProvider<TripsCubit>(
      create: (_) => clientGetIt<TripsCubit>(),
      child: child,
    );
  }

  Widget _buildBookingScope(Widget child) {
    return BlocProvider<BookingCubit>(
      create: (_) => clientGetIt<BookingCubit>(),
      child: child,
    );
  }



  Widget _buildSeatReleaseScope(Widget child) {
    return BlocProvider<SeatReleaseCubit>(
      create: (_) => clientGetIt<SeatReleaseCubit>(),
      child: child,
    );
  }



  Widget _buildPackagesScope(Widget child) {
    return BlocProvider<PackagesCubit>(
      create: (_) => clientGetIt<PackagesCubit>(),
      child: child,
    );
  }

  Widget _buildTrackingScope(Widget child) {
    return BlocProvider<TrackingCubit>(
      create: (_) => clientGetIt<TrackingCubit>(),
      child: child,
    );
  }

  Widget _buildSupportScope(Widget child) {
    return BlocProvider<SupportCubit>(
      create: (_) => clientGetIt<SupportCubit>(),
      child: child,
    );
  }

  Widget _buildNotificationsScope(Widget child) {
    return BlocProvider<NotificationsCubit>(
      create: (_) => clientGetIt<NotificationsCubit>(),
      child: child,
    );
  }

  Widget _buildProfileScope(Widget child) {
    return BlocProvider<ProfileCubit>(
      create: (_) => clientGetIt<ProfileCubit>(),
      child: child,
    );
  }

  Widget _buildRoutesHubScope(Widget child) {
    return BlocProvider<RoutesHubCubit>(
      create: (_) => clientGetIt<RoutesHubCubit>(),
      child: child,
    );
  }

  Widget _buildCommunicationScope(Widget child) {
    return BlocProvider<CommunicationCubit>(
      create: (_) => clientGetIt<CommunicationCubit>(),
      child: child,
    );
  }

  Widget _buildReferralRewardsScope(Widget child) {
    return BlocProvider<ReferralRewardsCubit>(
      create: (_) => clientGetIt<ReferralRewardsCubit>(),
      child: child,
    );
  }

  Widget _buildLoyaltyScope(Widget child) {
    return BlocProvider<LoyaltyCubit>(
      create: (_) => clientGetIt<LoyaltyCubit>(),
      child: child,
    );
  }

  Widget _buildSettingsScope(Widget child) {
    return BlocProvider<SettingsCubit>(
      create: (_) => clientGetIt<SettingsCubit>(),
      child: child,
    );
  }
}
