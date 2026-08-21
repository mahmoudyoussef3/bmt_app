import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/finance/data/mappers/finance_row_mapper.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart';

/// The row shapes here are the ones the production table actually holds — the
/// `payment_status` × `status` combinations, the two spellings of a card
/// payment, the part-paid package. Every case below was a wrong number on the
/// screen before it was a test.
void main() {
  final now = DateTime(2026, 8, 20, 12);

  Map<String, dynamic> bookingRow({
    String paymentStatus = 'approved',
    String status = 'confirmed',
    String method = 'instapay',
    num amount = 100,
    String route = 'Obour, QH, Egypt → New Cairo, QH, Egypt',
    String? pickup,
    String? dropoff,
    String? receipt,
  }) => {
    'id': 'BK-1',
    'booking_number': 'BK-000123',
    'passenger_name': 'خالد أحمد',
    'phone': '01000000000',
    'route': route,
    'pickup_point_name': pickup,
    'dropoff_point_name': dropoff,
    'trip_date': '2026-08-25',
    'payment_amount': amount,
    'payment_method': method,
    'payment_status': paymentStatus,
    'payment_receipt_url': receipt,
    'payment_rejection_reason': null,
    'status': status,
    'created_at': '2026-08-19T09:00:00Z',
  };

  group('payment status is read against the seat, not on its own', () {
    test('an approved payment is collected money', () {
      final record = FinanceRowMapper.payment(bookingRow());

      expect(record.status, PaymentStatus.success);
      expect(record.bookingState, FinanceBookingState.live);
      expect(_entryFor(record).isRealised, isTrue);
    });

    test('a `pending` payment is outstanding — it is not dropped', () {
      // The single largest category on the live table, and the one an earlier
      // `.inFilter` excluded from the query entirely, so the module reported a
      // fraction of what the office was owed.
      final record = FinanceRowMapper.payment(
        bookingRow(paymentStatus: 'pending', status: 'reserved'),
      );

      expect(record.status, PaymentStatus.pending);
      expect(_entryFor(record).isCollectable, isTrue);
    });

    test('an unpaid fare on a cancelled seat is not outstanding', () {
      // The seat is gone and `approve_payment` would refuse it. Reporting it as
      // "قيد التحصيل" invites an owner to chase money that cannot arrive.
      final record = FinanceRowMapper.payment(
        bookingRow(paymentStatus: 'submitted', status: 'cancelled'),
      );

      expect(record.status, PaymentStatus.cancelled);
      expect(_entryFor(record).isCollectable, isFalse);
      expect(record.awaitingReview, isFalse);
    });

    test('a `cancelled` payment state is money that will never arrive', () {
      final record = FinanceRowMapper.payment(
        bookingRow(paymentStatus: 'cancelled', status: 'cancelled'),
      );

      expect(record.status, PaymentStatus.cancelled);
    });

    test('`failed` joins rejected rather than falling through to pending', () {
      final record = FinanceRowMapper.payment(
        bookingRow(paymentStatus: 'failed', status: 'reserved'),
      );

      expect(record.status, PaymentStatus.cancelled);
    });

    test('money collected on a seat that was then cancelled is flagged', () {
      final record = FinanceRowMapper.payment(
        bookingRow(paymentStatus: 'approved', status: 'cancelled'),
      );

      // Still collected — the office has the cash — but it now owes a service
      // it will not deliver, which is a decision and not a silent line item.
      expect(record.status, PaymentStatus.success);
      expect(record.bookingState, FinanceBookingState.cancelled);
      expect(_entryFor(record).isUnreleasedLiability, isTrue);
    });

    test('a submitted receipt on a live seat is a review queue item', () {
      final record = FinanceRowMapper.payment(
        bookingRow(
          paymentStatus: 'submitted',
          status: 'reserved',
          receipt: 'https://example.test/receipt.png',
        ),
      );

      expect(record.awaitingReview, isTrue);
      expect(record.status, PaymentStatus.pending);
      expect(record.context.hasReceipt, isTrue);
    });

    test('a refunded payment stays refunded whatever the seat did', () {
      final record = FinanceRowMapper.payment(
        bookingRow(paymentStatus: 'refunded', status: 'confirmed'),
      );

      expect(record.status, PaymentStatus.refunded);
    });
  });

  group('payment method spellings', () {
    test('`credit_card` and `Credit Card` are the same rail', () {
      // Both spellings are in the live table. Comparing the raw string put the
      // spaced one into "نقدي", so card takings were reported as cash.
      expect(FinanceRowMapper.method('credit_card'), FinancePaymentMethod.card);
      expect(FinanceRowMapper.method('Credit Card'), FinancePaymentMethod.card);
      expect(FinanceRowMapper.method('CREDIT-CARD'), FinancePaymentMethod.card);
    });

    test('`InstaPay` matches whatever its casing', () {
      expect(
        FinanceRowMapper.method('InstaPay'),
        FinancePaymentMethod.instapay,
      );
      expect(
        FinanceRowMapper.method('instapay'),
        FinancePaymentMethod.instapay,
      );
    });

    test('an unrecognised spelling still falls back to cash', () {
      // Cash is the honest default for a rail nobody recognised: it is the one
      // that leaves no digital trace, so an unknown string is most likely one.
      expect(
        FinanceRowMapper.method('cash_on_boarding'),
        FinancePaymentMethod.cash,
      );
      expect(FinanceRowMapper.method(''), FinancePaymentMethod.cash);
    });
  });

  group('route splitting', () {
    test('the stored arrow form is taken apart', () {
      final (origin, destination) = FinanceRowMapper.splitRoute(
        'Obour, QH, Egypt → New Cairo, QH, Egypt',
      );

      expect(origin, 'Obour, QH, Egypt');
      expect(destination, 'New Cairo, QH, Egypt');
    });

    test('an explicit pickup/dropoff pair wins over the joined string', () {
      final (origin, destination) = FinanceRowMapper.splitRoute(
        'Obour → New Cairo',
        pickup: 'محطة العبور',
        dropoff: 'التجمع الخامس',
      );

      expect(origin, 'محطة العبور');
      expect(destination, 'التجمع الخامس');
    });

    test('a leftwards arrow means the pair was stored the other way', () {
      final (origin, destination) = FinanceRowMapper.splitRoute('New Cairo ← Obour');

      expect(origin, 'Obour');
      expect(destination, 'New Cairo');
    });

    test('a name with no separator is left whole for the caller to print', () {
      expect(FinanceRowMapper.splitRoute('bdhjewndhj'), (null, null));
    });
  });

  group('subscriptions are worth what arrived, not what was invoiced', () {
    Map<String, dynamic> subscriptionRow({
      String status = 'active',
      num total = 720,
      num? paid,
      num? remaining,
      String review = 'accepted',
    }) => {
      'id': 'SUB-1',
      'customer_name': 'منى سعيد',
      'package_name': 'الباقة الشهرية',
      'total_price': total,
      'paid_amount': paid,
      'remaining_amount': remaining,
      'status': status,
      'payment_review_status': review,
      'trips_count': 20,
      'trips_used': 4,
      'start_date': '2026-08-01',
      'end_date': '2026-08-31',
      'created_at': '2026-08-01T08:00:00Z',
      'client': null,
    };

    test('a part-paid package contributes only the deposit', () {
      // The live shape: an expired package invoiced at 720 with 400 collected
      // and its receipt still unreviewed. Filing 720 as revenue invented 320.
      final record = FinanceRowMapper.subscription(
        subscriptionRow(
          status: 'expired',
          total: 720,
          paid: 400,
          remaining: 320,
          review: 'pending',
        ),
        now: now,
      );

      expect(record.amount, 720);
      expect(record.paidAmount, 400);
      expect(record.remainingAmount, 320);
      expect(record.awaitingReview, isTrue);

      final entry = FinanceLedger.build(
        payments: const [],
        subscriptions: [record],
      ).single;

      expect(entry.amount, 400, reason: 'only the money that arrived');
      expect(entry.outstanding, 320, reason: 'the rest is receivable');
      expect(entry.status, PaymentStatus.success);
    });

    test('a fully paid package is unchanged', () {
      final record = FinanceRowMapper.subscription(
        subscriptionRow(total: 500, paid: 500, remaining: 0),
        now: now,
      );

      final entry = FinanceLedger.build(
        payments: const [],
        subscriptions: [record],
      ).single;

      expect(entry.amount, 500);
      expect(entry.outstanding, 0);
    });

    test('a row that predates `paid_amount` falls back to the price', () {
      final record = FinanceRowMapper.subscription(
        subscriptionRow(total: 300, paid: null, remaining: null),
        now: now,
      );

      expect(record.paidAmount, 300);
      expect(record.remainingAmount, 0);
    });

    test('a cancelled package is money that never arrived', () {
      final record = FinanceRowMapper.subscription(
        subscriptionRow(status: 'cancelled', total: 865, paid: 865),
        now: now,
      );

      final entry = FinanceLedger.build(
        payments: const [],
        subscriptions: [record],
      ).single;

      expect(entry.status, PaymentStatus.cancelled);
      expect(
        entry.outstanding,
        0,
        reason: 'a cancelled package is not a receivable',
      );
    });
  });

  test('booking context survives the mapping', () {
    final record = FinanceRowMapper.payment(bookingRow());

    expect(record.context.reference, 'BK-000123');
    expect(record.context.phone, '01000000000');
    expect(record.context.serviceDate, DateTime(2026, 8, 25));
    expect(record.context.origin, 'Obour, QH, Egypt');
  });

  test('an empty string column reads as absent, not as an empty label', () {
    final row = bookingRow()
      ..['booking_number'] = ''
      ..['phone'] = '   ';
    final record = FinanceRowMapper.payment(row);

    expect(record.context.reference, isNull);
    expect(record.context.phone, isNull);
  });
}

/// The ledger row a record becomes — where the money predicates live.
FinanceLedgerEntry _entryFor(PaymentRecord record) =>
    FinanceLedger.build(payments: [record], subscriptions: const []).single;
