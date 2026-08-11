import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/auth/data/datasources/client_session_datasource.dart';
import 'package:bmt_app/apps/client/features/auth/data/repositories/client_session_repository_impl.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/ensure_client_session_usecase.dart';

/// A device runs the client, captain and dashboard apps against one Supabase
/// session store, so the session the client app restores at launch is not
/// necessarily a passenger's. A captain's is not: that account has no `clients`
/// row, and every screen looked normal until the booking insert failed on
/// `operation_bookings_client_id_fkey` — at the last step of the wizard, after
/// the rider had entered payment details.
void main() {
  group('Client session guard', () {
    test('admits a session that belongs to a registered client', () async {
      final datasource = _FakeSessionDatasource(registered: true);
      final ensure = EnsureClientSessionUseCase(
        ClientSessionRepositoryImpl(datasource),
      );

      expect(await ensure(), isTrue);
      expect(datasource.calls, 1);
    });

    test('rejects a session with no client account behind it', () async {
      final ensure = EnsureClientSessionUseCase(
        ClientSessionRepositoryImpl(_FakeSessionDatasource(registered: false)),
      );

      expect(await ensure(), isFalse);
    });
  });
}

class _FakeSessionDatasource implements ClientSessionDatasource {
  _FakeSessionDatasource({required this.registered});

  final bool registered;
  int calls = 0;

  @override
  Future<bool> ensureClientSession() async {
    calls++;
    return registered;
  }
}
