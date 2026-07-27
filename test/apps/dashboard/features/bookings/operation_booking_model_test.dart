import 'package:flutter_test/flutter_test.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/data/models/operation_booking_model.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';

void main() {
  group('OperationBookingModel.fromJson', () {
    Map<String, dynamic> baseJson() => {
      'id': 'b-1',
      'booking_number': 'BK-ABCD1234',
      'client_id': 'client-123',
      'passenger_name': 'أحمد',
      'phone': '01000000000',
      'route': 'القاهرة - الإسكندرية',
      'trip_time': '08:00',
      'trip_date': '2026-07-10',
      'seat': 'A3',
      'payment_method': 'instapay',
      'status': 'reserved',
      'payment_status': 'submitted',
      'payment_amount': 160,
      'payment_receipt_url': 'https://example.com/r.png',
      'created_at': '2026-07-06T09:00:00Z',
      'notes': ['ملاحظة'],
      'package': {'name_ar': 'ذهاب وعودة'},
      'trip': {
        'id': 't-9',
        'trip_date': '2026-07-10',
        'departure_time': '08:00',
        'route': {'name': 'خط الإسكندرية'},
        'driver': {'full_name': 'سامي'},
        'vehicle': {'plate_number': '١٢٣٤'},
      },
    };

    test('maps snake_case db columns onto the entity', () {
      final b = OperationBookingModel.fromJson(baseJson());

      expect(b.bookingNumber, 'BK-ABCD1234');
      expect(b.clientId, 'client-123');
      expect(b.status, BookingStatus.reserved);
      expect(b.paymentStatus, PaymentStatus.submitted);
      expect(b.packageName, 'ذهاب وعودة');
      expect(b.notes, ['ملاحظة']);
      expect(b.awaitingReview, isTrue);
      expect(b.hasReceipt, isTrue);
    });

    test('parses the real payment_amount instead of defaulting to zero', () {
      final b = OperationBookingModel.fromJson(baseJson());
      expect(b.paymentAmount, 160);
      expect(b.amountLabel, '160 ج.م');
    });

    test('maps snake_case payment methods to the enum (regression)', () {
      String methodFor(String raw) {
        final json = baseJson()..['payment_method'] = raw;
        return OperationBookingModel.fromJson(json).paymentMethod.name;
      }

      expect(methodFor('instapay'), BookingPaymentMethod.instaPay.name);
      expect(
        methodFor('vodafone_cash'),
        BookingPaymentMethod.vodafoneCash.name,
      );
      expect(
        methodFor('bank_transfer'),
        BookingPaymentMethod.bankTransfer.name,
      );
      expect(methodFor('credit_card'), BookingPaymentMethod.card.name);
    });

    test('reads trip details from the joined operation_trips row', () {
      final b = OperationBookingModel.fromJson(baseJson());
      expect(b.tripDetails.route, 'خط الإسكندرية');
      expect(b.tripDetails.driver, 'سامي');
      expect(b.tripDetails.vehicle, '١٢٣٤');
    });

    test('surfaces payment_rejection_reason and a review timeline event', () {
      final json = baseJson()
        ..['status'] = 'cancelled'
        ..['payment_status'] = 'rejected'
        ..['payment_rejection_reason'] = 'الإيصال غير واضح'
        ..['reviewed_at'] = '2026-07-06T10:00:00Z';

      final b = OperationBookingModel.fromJson(json);
      expect(b.rejectionReason, 'الإيصال غير واضح');
      expect(b.timeline.length, 2);
      expect(b.timeline.last.action, 'تم رفض الدفع');
      expect(b.timeline.last.note, 'الإيصال غير واضح');
    });

    test('falls back safely when optional columns are missing', () {
      final b = OperationBookingModel.fromJson({'id': 'x'});
      expect(b.status, BookingStatus.draft);
      expect(b.paymentStatus, PaymentStatus.pending);
      expect(b.paymentAmount, 0);
      expect(b.rejectionReason, isNull);
      expect(b.timeline.length, 1);
      expect(b.tripDetails.route, '');
    });
  });
}
