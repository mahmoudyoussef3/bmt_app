import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Test datasources
import 'package:bmt_app/apps/client/features/routes/data/datasources/supabase_routes_hub_datasource.dart';
import 'package:bmt_app/apps/client/features/seat_selection/data/datasources/supabase_seat_selection_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/data/datasources/supabase_tickets_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/finance/data/datasources/supabase_finance_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/data/datasources/supabase_subscriptions_datasource.dart';

class EmptyLocalStorage extends LocalStorage {
  const EmptyLocalStorage();
  @override Future<void> initialize() async {}
  @override Future<bool> hasAccessToken() async => false;
  @override Future<String?> accessToken() async => null;
  @override Future<void> removePersistedSession() async {}
  @override Future<void> persistSession(String persistSessionString) async {}
}

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://nbwzourpbnmewwklewyr.supabase.co',
      anonKey: 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  group('Runtime Verification', () {
    test('1. Client Routes Hub - fetches from operation_routes', () async {
      final client = Supabase.instance.client;
      final datasource = SupabaseRoutesHubDatasource(client);
      
      try {
        final data = await datasource.getRoutesHubData();
        print('✅ Routes Hub Data fetched successfully.');
        print('Returned Action: ${data.searchAction.route}');
        expect(data.searchAction.route, isNotEmpty);
      } catch (e) {
        print('❌ Routes Hub failed: $e');
        rethrow;
      }
    });

    test('3. Client Booking - RPC call structural validation', () async {
      // We cannot complete the RPC because we are not authenticated. 
      // It will return an RLS error or missing user error. 
      // But we can check if it throws the *correct* error.
      final client = Supabase.instance.client;
      final datasource = SupabaseSeatSelectionDatasource(client);

      try {
        await datasource.bookTripSeat({
          'p_trip_id': '00000000-0000-0000-0000-000000000000',
          'p_seat_id': '00000000-0000-0000-0000-000000000000',
          'p_passenger_name': 'Test',
          'p_phone': '000',
          'p_route': 'Test',
          'p_trip_time': '10:00',
          'p_trip_date': '2026-01-01',
          'p_seat': 'A1',
          'p_payment_method': 'Cash',
          'p_payment_amount': 50,
        });
        fail('Should throw unauthorized or missing params');
      } catch (e) {
        print('✅ Booking RPC handled locally. Error: $e');
        expect(e.toString().contains('User not logged in'), true);
      }
    });

    test('4 & 5. Support Tickets - fetches correctly with join', () async {
      final client = Supabase.instance.client;
      final datasource = SupabaseTicketsDatasource(client);

      try {
        // Will test if the select query format `client:clients(...)` is accepted by Supabase schema
        final tickets = await datasource.getComplaints();
        print('✅ Support Tickets fetched successfully. Count: ${tickets.length}');
      } catch (e) {
        print('❌ Support Tickets failed: $e');
        rethrow;
      }
    });

    test('6. Refunds - fetches correctly from refund_requests', () async {
      final client = Supabase.instance.client;
      final datasource = SupabaseFinanceDatasource(client);

      try {
        final refunds = await datasource.getRefundRequests();
        print('✅ Refunds fetched successfully. Count: ${refunds.length}');
      } catch (e) {
        print('❌ Refunds failed: $e');
        rethrow;
      }
    });

    test('7. Subscriptions - fetches correctly from subscriptions', () async {
      final client = Supabase.instance.client;
      final datasource = SupabaseSubscriptionsDatasource(client);

      try {
        final subs = await datasource.fetchSubscriptions();
        print('✅ Subscriptions fetched successfully. Count: ${subs.length}');
      } catch (e) {
        print('❌ Subscriptions failed: $e');
        rethrow;
      }
    });
  });
}
