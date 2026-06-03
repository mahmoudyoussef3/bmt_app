import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/features/component/presentation/screens/admin_dashboard_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/daily_booking_flow_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/driver_dashboard_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/seat_selection_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/payment_checkout_screen.dart';
import 'package:bmt_app/features/component/presentation/models/payment_models.dart';
import 'package:bmt_app/features/component/presentation/screens/subscription_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/subscription_confirmation_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/tracking_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/support_center_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/communication_screen.dart';
import 'package:bmt_app/features/component/presentation/auth/auth_routes.dart';
import 'package:bmt_app/features/component/presentation/screens/auth/auth_success_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/auth/otp_verification_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/auth/phone_number_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/auth/registration_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/auth/welcome_screen.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_routes.dart';
import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';
import 'package:bmt_app/features/component/presentation/screens/booking/available_trips_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/booking/map_route_selection_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/booking/popular_routes_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/booking/route_selection_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/booking/search_trip_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/booking/vehicle_details_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/booking/vehicle_listing_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/demo_shell_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/trips/my_trips_screen.dart';
import 'package:bmt_app/features/component/presentation/screens/trips/trip_details_screen.dart';
import 'package:bmt_app/features/component/presentation/trips/trips_routes.dart';

class ComponentDemoApp extends StatelessWidget {
  const ComponentDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mega Transportation',
      // Force dark theme across the client demo app
      theme: AppTheme.darkTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      home: const WelcomeScreen(),
      routes: {
        '/home': (_) => const DemoShellScreen(),
        AuthRoutes.welcome: (_) => const WelcomeScreen(),
        AuthRoutes.phone: (_) => const PhoneNumberScreen(),
        AuthRoutes.otp: (context) {
          final phone = ModalRoute.of(context)?.settings.arguments as String?;
          return OtpVerificationScreen(phoneNumber: phone);
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
          return RegistrationScreen(prefilledPhone: phone, viaSocial: via);
        },
        AuthRoutes.success: (_) => const AuthSuccessScreen(),
        BookingRoutes.search: (context) => SearchTripScreen(
          initialQuery: BookingSearchQuery.fromArguments(
            ModalRoute.of(context)?.settings.arguments,
          ),
        ),
        BookingRoutes.routeSelection: (_) => const RouteSelectionScreen(),
        BookingRoutes.popularRoutes: (_) => const PopularRoutesScreen(),
        BookingRoutes.mapSelection: (_) => const MapRouteSelectionScreen(),
        BookingRoutes.availableTrips: (_) => const AvailableTripsScreen(),
        BookingRoutes.vehicleListing: (_) => const VehicleListingScreen(),
        BookingRoutes.vehicleDetails: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? vehicleId;
          if (args is Map) {
            vehicleId = args['vehicleId']?.toString();
          }
          return VehicleDetailsScreen(vehicleId: vehicleId);
        },
        '/daily-booking': (_) => const DailyBookingFlowScreen(),
        '/seat-selection': (_) => const SeatSelectionScreen(),
        '/payment-demo': (_) => PaymentCheckoutScreen(
          checkoutData: PaymentCheckoutData(
            pickupPoint: 'Banha Station',
            destination: 'Smart Village',
            vehicleNumber: 'MB-15-2847',
            departureTime: '8:40 AM',
            arrivalTime: '9:20 AM',
            selectedSeat: '6',
            driverName: 'Ahmed Mohamed',
          ),
        ),
        '/subscription': (_) => const SubscriptionScreen(),
        '/subscription-confirmation': (_) =>
            const SubscriptionConfirmationScreen(
              pickup: '',
              destination: '',
              time: '',
              planName: 'Monthly',
              price: 'EGP 1,200/month',
            ),
        TripsRoutes.myTrips: (context) => MyTripsScreen(
          onOpenRoute: (route, [arguments]) => Navigator.of(
            context,
          ).pushNamed(route, arguments: arguments),
        ),
        TripsRoutes.tripDetails: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? tripId;
          if (args is Map) {
            tripId = args['tripId']?.toString();
          }
          return TripDetailsScreen(tripId: tripId);
        },
        '/tracking': (_) => const TrackingScreen(),
        '/support': (_) => const SupportCenterScreen(),
        '/communication': (_) => const CommunicationScreen(),
        '/driver': (_) => const CaptainDashboardScreen(),
        '/admin': (_) => const DashboardWebScreen(),
      },
    );
  }
}
