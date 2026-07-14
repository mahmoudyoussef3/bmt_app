import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/seat_release_data.dart';

abstract class SeatReleaseDatasource {
  Future<SeatReleaseData> getSeatReleaseData();
}

class SupabaseSeatReleaseDatasource implements SeatReleaseDatasource {
  const SupabaseSeatReleaseDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<SeatReleaseData> getSeatReleaseData() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _empty();

    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);
    final monthStart = DateTime(
      today.year,
      today.month,
      1,
    ).toIso8601String().substring(0, 10);

    final results = await Future.wait([
      // Active subscription
      _client
          .from('subscriptions')
          .select('package_name, route_name, start_date, end_date, status')
          .eq('client_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),

      // Upcoming confirmed bookings
      _client
          .from('operation_bookings')
          .select(
            'id, trip_date, trip_time, route, seat, status, assigned_trip',
          )
          .eq('client_id', userId)
          .inFilter('status', const ['reserved', 'confirmed', 'boarded'])
          .gte('trip_date', todayStr)
          .order('trip_date')
          .limit(10),

      // Cancelled bookings this month (proxy for released seats)
      _client
          .from('operation_bookings')
          .select('id')
          .eq('client_id', userId)
          .eq('status', 'cancelled')
          .gte('trip_date', monthStart),
    ]);

    final sub = results[0] as Map<String, dynamic>?;
    final bookingRows = (results[1] as List?) ?? [];
    final cancelledRows = (results[2] as List?) ?? [];

    final upcomingTrips = bookingRows.map((r) {
      final m = r as Map<String, dynamic>;
      final tripDate = m['trip_date'] as String? ?? '';
      return UpcomingTrip(
        id: m['id'] as String,
        date: _formatDate(tripDate),
        pickup: _pickupFromRoute(m['route'] as String? ?? ''),
        destination: _destinationFromRoute(m['route'] as String? ?? ''),
        departureTime: m['trip_time'] as String? ?? '',
        vehicle: m['assigned_trip'] as String? ?? '',
        seatNumber: m['seat'] as String? ?? '',
      );
    }).toList();

    return SeatReleaseData(
      packageName: sub?['package_name'] as String? ?? '',
      packageType: 'Subscription package',
      packageRoute: sub?['route_name'] as String? ?? '',
      startDate: _formatDateStr(sub?['start_date'] as String? ?? ''),
      endDate: _formatDateStr(sub?['end_date'] as String? ?? ''),
      packageStatus: sub != null ? 'Active' : 'No subscription',
      remainingDays: _remainingDays(sub?['end_date'] as String?),
      releasedSeatsThisMonth: cancelledRows.length,
      successfullyRebookedSeats: 0,
      totalCompensationEarned: 0,
      reasons: const [
        'Personal plans',
        'Working from home',
        'Vacation',
        'Alternative transport',
        'Medical reason',
        'Other',
      ],
      upcomingTrips: upcomingTrips,
      pastReleases: const [],
    );
  }

  int _remainingDays(String? endDateStr) {
    if (endDateStr == null || endDateStr.isEmpty) return 0;
    try {
      final end = DateTime.parse(endDateStr);
      final diff = end.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return 0;
    }
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final d = DateTime.parse(isoDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(d.year, d.month, d.day);
      final diff = target.difference(today).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Tomorrow';
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return '${days[d.weekday % 7]} ${d.day}/${d.month}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatDateStr(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final d = DateTime.parse(isoDate);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _pickupFromRoute(String route) {
    final parts = route.split('→');
    return parts.isNotEmpty ? parts.first.trim() : route;
  }

  String _destinationFromRoute(String route) {
    final parts = route.split('→');
    return parts.length > 1 ? parts.last.trim() : route;
  }

  SeatReleaseData _empty() => const SeatReleaseData(
    packageName: '',
    packageType: '',
    packageRoute: '',
    startDate: '',
    endDate: '',
    packageStatus: 'No subscription',
    remainingDays: 0,
    releasedSeatsThisMonth: 0,
    successfullyRebookedSeats: 0,
    totalCompensationEarned: 0,
    reasons: [
      'Personal plans',
      'Working from home',
      'Vacation',
      'Alternative transport',
      'Medical reason',
      'Other',
    ],
    upcomingTrips: [],
    pastReleases: [],
  );
}
