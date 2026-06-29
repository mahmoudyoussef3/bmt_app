import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';

// Import Cubits
import 'package:bmt_app/apps/dashboard/modules/analytics/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/bookings/presentation/cubit/bookings_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/trips/live_trips/presentation/cubit/live_trips_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/routes/presentation/cubit/routes_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/trips/dashboard_operations/presentation/cubit/dashboard_workspace_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/payments/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/users/referrals/presentation/cubit/referral_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/analytics/owner_overview/presentation/cubit/owner_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/finance/presentation/cubit/finance_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/payments/payment_verification/presentation/cubit/payment_verification_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/tickets/presentation/cubit/tickets_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/analytics/reports/presentation/cubit/reports_cubit.dart';

// Import Screens
import 'package:bmt_app/apps/dashboard/modules/analytics/dashboard_home/presentation/screens/dashboard_home_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/bookings/presentation/screens/bookings_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/trips/presentation/screens/trips_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/trips/live_trips/presentation/screens/live_trips_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/overview/presentation/screens/fleet_overview_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/routes/presentation/screens/routes_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/users/presentation/screens/users_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/payments/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/users/referrals/presentation/screens/referral_management_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/analytics/owner_overview/presentation/screens/owner_overview_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/finance/presentation/screens/finance_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/payments/payment_verification/presentation/screens/payment_verification_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/tickets/presentation/screens/tickets_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/analytics/reports/presentation/screens/reports_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/settings/presentation/screens/settings_screen.dart';
import 'package:bmt_app/apps/dashboard/modules/settings/permissions/presentation/screens/permissions_screen.dart';

import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_common.dart';

class AppRouter {
  static Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case DashboardRoutes.home:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<DashboardHomeCubit>()..load(),
            child: const DashboardHomeScreen(),
          ),
        );
      case DashboardRoutes.bookings:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<BookingsCubit>()..load(),
            child: const BookingsScreen(),
          ),
        );
      case DashboardRoutes.trips:
        return MaterialPageRoute(
          builder: (_) => const TripsScreen(),
        );
      case DashboardRoutes.liveTrips:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<LiveTripsCubit>()..loadLiveTrips(),
            child: const LiveTripsScreen(),
          ),
        );
      case DashboardRoutes.fleet:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<FleetOverviewCubit>()..loadWorkspace(),
            child: const FleetOverviewScreen(),
          ),
        );
      case DashboardRoutes.drivers:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<FleetOverviewCubit>()..loadWorkspace(),
            child: const FleetOverviewScreen(initialTab: FleetTab.drivers),
          ),
        );
      case DashboardRoutes.assignments:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<FleetOverviewCubit>()..loadWorkspace(),
            child: const FleetOverviewScreen(initialTab: FleetTab.drivers),
          ),
        );
      case DashboardRoutes.vehicles:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<FleetOverviewCubit>()..loadWorkspace(),
            child: const FleetOverviewScreen(initialTab: FleetTab.vehicles),
          ),
        );
      case DashboardRoutes.routes:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<RoutesCubit>()..load(),
            child: const RoutesScreen(),
          ),
        );
      case DashboardRoutes.users:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<DashboardWorkspaceCubit>()..load('users'),
            child: const UsersScreen(),
          ),
        );
      case DashboardRoutes.subscriptions:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<SubscriptionsCubit>()..load(),
            child: const SubscriptionsScreen(),
          ),
        );
      case DashboardRoutes.referrals:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<ReferralCubit>()..load(),
            child: const ReferralManagementScreen(),
          ),
        );
      case DashboardRoutes.ownerOverview:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<OwnerOverviewCubit>()..load(),
            child: const OwnerOverviewScreen(),
          ),
        );
      case DashboardRoutes.payments:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<FinanceCubit>()..load(),
            child: const FinanceScreen(),
          ),
        );
      case DashboardRoutes.paymentVerification:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<PaymentVerificationCubit>()..load(),
            child: const PaymentVerificationScreen(),
          ),
        );
      case DashboardRoutes.tickets:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<TicketsCubit>()..load(),
            child: const TicketsScreen(),
          ),
        );
      case DashboardRoutes.reports:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<ReportsCubit>()..load(),
            child: const ReportsScreen(),
          ),
        );
      case DashboardRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<DashboardWorkspaceCubit>()..load('settings'),
            child: const SettingsScreen(),
          ),
        );
      case DashboardRoutes.permissions:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => dashboardDi<DashboardWorkspaceCubit>()..load('permissions'),
            child: const PermissionsScreen(),
          ),
        );
      default:
        return null;
    }
  }
}
