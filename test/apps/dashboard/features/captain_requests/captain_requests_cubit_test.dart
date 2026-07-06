import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/entities/captain_request.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/repositories/captain_requests_repository.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/usecases/captain_requests_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/presentation/cubit/captain_requests_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/presentation/cubit/captain_requests_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeRepo repo;
  late CaptainRequestsCubit cubit;

  CaptainRequest pending(String id) => CaptainRequest(
    id: id,
    fullName: 'كابتن $id',
    phone: '0100000000$id',
    status: CaptainRequestStatus.pending,
    createdAt: DateTime(2026, 7, 5),
  );

  setUp(() {
    repo = _FakeRepo()..requests = [pending('1'), pending('2')];
    cubit = CaptainRequestsCubit(
      getRequests: GetCaptainRequestsUseCase(repo),
      watchRequests: WatchCaptainRequestsUseCase(repo),
      approve: ApproveCaptainRequestUseCase(repo),
      reject: RejectCaptainRequestUseCase(repo),
    );
  });

  tearDown(() => cubit.close());

  test('load exposes the pending count', () async {
    await cubit.load();
    final state = cubit.state;
    expect(state, isA<CaptainRequestsLoaded>());
    expect((state as CaptainRequestsLoaded).pendingCount, 2);
  });

  test('approve links the driver and clears it from pending', () async {
    await cubit.load();

    final error = await cubit.approve(requestId: '1', driverId: 'driver-9');

    expect(error, isNull);
    expect(repo.approvedWith, ('1', 'driver-9'));
    expect((cubit.state as CaptainRequestsLoaded).pendingCount, 1);
  });

  test('approve surfaces a failure message without throwing', () async {
    await cubit.load();
    repo.failApprove = true;

    final error = await cubit.approve(requestId: '1', driverId: 'driver-9');

    expect(error, isNotNull);
  });

  test('reject records the reason', () async {
    await cubit.load();

    await cubit.reject(requestId: '2', reason: 'مستندات ناقصة');

    expect(repo.rejectedWith, ('2', 'مستندات ناقصة'));
    expect((cubit.state as CaptainRequestsLoaded).pendingCount, 1);
  });
}

class _FakeRepo implements CaptainRequestsRepository {
  List<CaptainRequest> requests = [];
  (String, String)? approvedWith;
  (String, String)? rejectedWith;
  bool failApprove = false;

  @override
  Future<List<CaptainRequest>> getRequests() async => requests;

  @override
  Stream<List<CaptainRequest>> watchRequests() => const Stream.empty();

  @override
  Future<void> approve({
    required String requestId,
    required String driverId,
  }) async {
    if (failApprove) throw Exception('تعذر ربط الطلب');
    approvedWith = (requestId, driverId);
    requests = requests.where((r) => r.id != requestId).toList();
  }

  @override
  Future<void> reject({
    required String requestId,
    required String reason,
  }) async {
    rejectedWith = (requestId, reason);
    requests = requests
        .map(
          (r) => r.id == requestId
              ? CaptainRequest(
                  id: r.id,
                  fullName: r.fullName,
                  phone: r.phone,
                  status: CaptainRequestStatus.rejected,
                  createdAt: r.createdAt,
                  rejectionReason: reason,
                )
              : r,
        )
        .toList();
  }
}
