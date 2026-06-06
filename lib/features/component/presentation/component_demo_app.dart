import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_app_shell.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/screens/client_shell_screen.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/screens/my_trips_screen.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/features/component/presentation/screens/admin_dashboard_screen.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/payment_checkout_screen.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/screens/subscription_screen.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/screens/subscription_confirmation_screen.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/screens/support_center_screen.dart';
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
import 'package:bmt_app/apps/client/features/auth/presentation/screens/auth_success_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/phone_number_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/registration_screen.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/screens/welcome_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/available_trips_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/daily_booking_flow_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/map_route_selection_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/popular_routes_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/route_selection_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/search_trip_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/vehicle_details_screen.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/screens/vehicle_listing_screen.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/screens/seat_selection_screen.dart';
import 'package:bmt_app/apps/client/features/seat_release/presentation/cubit/seat_release_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_release/presentation/screens/seat_release_screen.dart';
import 'package:bmt_app/apps/client/core/theme/client_app_theme.dart';

class ComponentDemoApp extends StatefulWidget {
  const ComponentDemoApp({super.key});

  @override
  State<ComponentDemoApp> createState() => _ComponentDemoAppState();
}

class _ComponentDemoAppState extends State<ComponentDemoApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode mode) => setState(() => _themeMode = mode);

  @override
  void initState() {
    super.initState();
    registerClientDependencies();
    registerCaptainDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return ClientAppTheme(
      themeMode: _themeMode,
      setThemeMode: _setThemeMode,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mega Transportation',

        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: _themeMode,

        // Skip Authentication during UI development
        home: _buildClientShell(),

        routes: {
          '/home': (_) => _buildClientShell(),

          // Authentication Screens
          AuthRoutes.welcome: (_) => _buildAuthScope(const WelcomeScreen()),
          AuthRoutes.phone: (_) => _buildAuthScope(const PhoneNumberScreen()),

          AuthRoutes.otp: (context) {
            final phone = ModalRoute.of(context)?.settings.arguments as String?;
            return _buildAuthScope(OtpVerificationScreen(phoneNumber: phone));
          },

          AuthRoutes.registration: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            String? phone;
            String? via;

            if (args is Map<String, dynamic>) {
              phone = args['phone'] as String?;
              via = args['via'] as String?;
            } else if (args is Map) {
              phone = args['phone']?.toString();
              via = args['via']?.toString();
            }

            return _buildAuthScope(
              RegistrationScreen(prefilledPhone: phone, viaSocial: via),
            );
          },

          AuthRoutes.success: (_) => _buildAuthScope(const AuthSuccessScreen()),

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
              _buildBookingScope(const AvailableTripsScreen()),
          BookingRoutes.vehicleListing: (_) =>
              _buildBookingScope(const VehicleListingScreen()),

          BookingRoutes.vehicleDetails: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            String? vehicleId;

            if (args is Map) {
              vehicleId = args['vehicleId']?.toString();
            }

            return _buildBookingScope(
              VehicleDetailsScreen(vehicleId: vehicleId),
            );
          },

          '/daily-booking': (_) =>
              _buildBookingScope(const DailyBookingFlowScreen()),
          '/seat-selection': (_) =>
              _buildSeatSelectionScope(const SeatSelectionScreen()),
          '/seat-release': (_) =>
              _buildSeatReleaseScope(const SeatReleaseScreen()),

          '/payment-demo': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final checkoutData = args is Map
                ? PaymentCheckoutData(
                    pickupPoint:
                        args['pickupPoint']?.toString() ?? 'Banha Station',
                    destination:
                        args['destination']?.toString() ?? 'Smart Village',
                    vehicleNumber:
                        args['vehicleNumber']?.toString() ?? 'MB-15-2847',
                    departureTime:
                        args['departureTime']?.toString() ?? '8:40 AM',
                    arrivalTime: args['arrivalTime']?.toString() ?? '9:20 AM',
                    selectedSeat: args['selectedSeat']?.toString() ?? '6',
                    driverName:
                        args['driverName']?.toString() ?? 'Ahmed Mohamed',
                  )
                : PaymentCheckoutData(
                    pickupPoint: 'Banha Station',
                    destination: 'Smart Village',
                    vehicleNumber: 'MB-15-2847',
                    departureTime: '8:40 AM',
                    arrivalTime: '9:20 AM',
                    selectedSeat: '6',
                    driverName: 'Ahmed Mohamed',
                  );

            return _buildPaymentScope(
              PaymentCheckoutScreen(checkoutData: checkoutData),
            );
          },

          '/subscription': (_) =>
              _buildPackagesScope(const SubscriptionScreen()),

          '/subscription-confirmation': (_) => _buildPackagesScope(
            const SubscriptionConfirmationScreen(
              pickup: '',
              destination: '',
              time: '',
              planName: 'Monthly',
              price: 'EGP 1,200/month',
            ),
          ),

          // Trips
          TripsRoutes.myTrips: (context) => _buildTripsScope(
            MyTripsScreen(
              onOpenRoute: (route, [arguments]) {
                Navigator.of(context).pushNamed(route, arguments: arguments);
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
          '/tracking': (_) => _buildTrackingScope(const TrackingScreen()),
          '/support': (_) => _buildSupportScope(const SupportCenterScreen()),
          '/communication': (_) =>
              _buildCommunicationScope(const CommunicationScreen()),
          '/rewards': (_) =>
              _buildReferralRewardsScope(const ReferralRewardsScreen()),
          '/loyalty': (_) => _buildLoyaltyScope(const LoyaltyScreen()),
          '/settings': (_) => _buildSettingsScope(const SettingsScreen()),

          '/profile': (context) => _buildProfileScope(
            ProfileScreen(
              onOpenRoute: (route, [arguments]) {
                Navigator.of(context).pushNamed(route, arguments: arguments);
              },
            ),
          ),

          // Other Versions
          '/driver': (_) => const CaptainAppShell(),
          '/admin': (_) => const DashboardWebScreen(),
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
      trackingBuilder: (context) =>
          _buildTrackingScope(const TrackingScreen(shellMode: true)),
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

  Widget _buildSeatSelectionScope(Widget child) {
    return BlocProvider<SeatSelectionCubit>(
      create: (_) => clientGetIt<SeatSelectionCubit>(),
      child: child,
    );
  }

  Widget _buildSeatReleaseScope(Widget child) {
    return BlocProvider<SeatReleaseCubit>(
      create: (_) => clientGetIt<SeatReleaseCubit>(),
      child: child,
    );
  }

  Widget _buildPaymentScope(Widget child) {
    return BlocProvider<PaymentCubit>(
      create: (_) => clientGetIt<PaymentCubit>(),
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
