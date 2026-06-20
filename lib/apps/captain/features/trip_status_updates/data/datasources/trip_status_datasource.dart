import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/captain_trip_status.dart';
import '../models/trip_status_model.dart';

class TripStatusDataSource {
  const TripStatusDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<TripStatusModel> updateStatus(
    String tripId,
    CaptainTripStatus status,
  ) async {
    await _supabase.from('trip_events').insert({
      'trip_id': tripId,
      'title': _title(status),
      'description': _description(status),
      'done': status == CaptainTripStatus.completed,
      'event_time': DateTime.now().toUtc().toIso8601String(),
    });

    return TripStatusModel(tripId: tripId, status: status);
  }

  String _title(CaptainTripStatus status) {
    return switch (status) {
      CaptainTripStatus.headingToPickup => 'السائق في الطريق',
      CaptainTripStatus.arrivedPickup => 'وصل السائق لنقطة الانطلاق',
      CaptainTripStatus.boarding => 'صعود الركاب',
      CaptainTripStatus.departed => 'غادرت الرحلة',
      CaptainTripStatus.arrivedDestination => 'وصلت الرحلة للوجهة',
      CaptainTripStatus.completed => 'اكتملت الرحلة',
    };
  }

  String _description(CaptainTripStatus status) {
    return switch (status) {
      CaptainTripStatus.headingToPickup =>
        'أبلغ السائق أنه في الطريق إلى نقطة الانطلاق.',
      CaptainTripStatus.arrivedPickup =>
        'أبلغ السائق بالوصول إلى نقطة الانطلاق.',
      CaptainTripStatus.boarding => 'بدأ السائق استقبال وصعود الركاب.',
      CaptainTripStatus.departed => 'أبلغ السائق بانطلاق الرحلة.',
      CaptainTripStatus.arrivedDestination => 'أبلغ السائق بالوصول إلى الوجهة.',
      CaptainTripStatus.completed => 'أبلغ السائق باكتمال الرحلة.',
    };
  }
}
