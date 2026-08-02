import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/packages/data/datasources/packages_datasource.dart';
import 'package:bmt_app/apps/client/features/packages/data/mappers/package_plan_mapper.dart';
import 'package:bmt_app/apps/client/features/packages/data/models/package_plan_model.dart';
import 'package:bmt_app/apps/client/features/packages/data/repositories/packages_repository_impl.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';

PackagePlan _plan({
  required String id,
  String officeId = 'o1',
  String officeName = 'Nile Express',
  double officeRating = 4.5,
  int officeRatingsCount = 20,
  int durationDays = 30,
  int rideCount = 30,
  double price = 3000,
}) => PackagePlan(
  id: id,
  nameAr: 'باقة',
  nameEn: 'Package',
  packageType: 'work_month',
  durationDays: durationDays,
  rideCount: rideCount,
  price: price,
  officeId: officeId,
  officeName: officeName,
  officeRating: officeRating,
  officeRatingsCount: officeRatingsCount,
);

class _FakeDatasource implements PackagesDatasource {
  _FakeDatasource(this.rows, {this.officeRows});

  final List<PackagePlanModel> rows;
  final List<PackagePlanModel>? officeRows;
  String? requestedOfficeId;

  @override
  Future<List<PackagePlanModel>> getPackages({String? officeId}) async {
    requestedOfficeId = officeId;
    if (officeId != null && officeRows != null) return officeRows!;
    return rows;
  }

  @override
  Future<Map<String, dynamic>?> getMySubscription() async => null;
}

void main() {
  group('PackagePlanModel.fromJson office identity', () {
    test('reads the embedded public_offices identity', () {
      final model = PackagePlanModel.fromJson({
        'id': 'p1',
        'name_ar': 'شهرية',
        'name_en': 'Monthly',
        'package_type': 'work_month',
        'duration_days': 30,
        'ride_count': 30,
        'price': 3000,
        'office': {
          'id': 'o1',
          'name': 'Nile Express',
          'logo_url': 'https://cdn/logo.png',
          'rating': 4.7,
          'ratings_count': 42,
        },
      });

      expect(model.officeId, 'o1');
      expect(model.officeName, 'Nile Express');
      expect(model.officeLogoUrl, 'https://cdn/logo.png');
      expect(model.officeRating, 4.7);
      expect(model.officeRatingsCount, 42);
    });

    test(
      'a missing office embed leaves the package office-less, not crashed',
      () {
        // Happens when the seller is unlisted/paused: public_offices drops it, so
        // the embed comes back null.
        final model = PackagePlanModel.fromJson({
          'id': 'p2',
          'name_ar': 'شهرية',
          'name_en': 'Monthly',
          'package_type': 'work_month',
          'price': 3000,
        });

        expect(model.officeId, isEmpty);
        expect(model.officeName, isEmpty);
        expect(model.officeLogoUrl, isNull);
        expect(model.toEntity().hasOffice, isFalse);
      },
    );
  });

  group('PackagePlan office getters', () {
    test('hasOffice needs both an id and a name', () {
      expect(_plan(id: 'p').hasOffice, isTrue);
      expect(_plan(id: 'p', officeId: '').hasOffice, isFalse);
      expect(_plan(id: 'p', officeName: '').hasOffice, isFalse);
    });

    test('hasOfficeRating guards a brand-new office showing a fake 0.0', () {
      expect(_plan(id: 'p').hasOfficeRating, isTrue);
      expect(_plan(id: 'p', officeRatingsCount: 0).hasOfficeRating, isFalse);
      expect(_plan(id: 'p', officeRating: 0).hasOfficeRating, isFalse);
    });
  });

  group('PackagesRepositoryImpl marketplace guard', () {
    test(
      'drops packages whose seller did not resolve through public_offices',
      () async {
        final datasource = _FakeDatasource([
          const PackagePlanModel(
            id: 'listed',
            nameAr: 'باقة',
            nameEn: 'Package',
            packageType: 'work_month',
            durationDays: 30,
            rideCount: 30,
            price: 3000,
            officeId: 'o1',
            officeName: 'Nile Express',
          ),
          const PackagePlanModel(
            id: 'orphan',
            nameAr: 'باقة',
            nameEn: 'Package',
            packageType: 'work_month',
            durationDays: 30,
            rideCount: 30,
            price: 3000,
          ),
        ]);
        final repo = PackagesRepositoryImpl(datasource);

        final packages = await repo.getPackages();

        expect(packages.map((p) => p.id), ['listed']);
      },
    );

    test(
      'getOfficePackages passes the office id through to the datasource',
      () async {
        final datasource = _FakeDatasource(
          const [],
          officeRows: const [
            PackagePlanModel(
              id: 'p1',
              nameAr: 'باقة',
              nameEn: 'Package',
              packageType: 'work_month',
              durationDays: 30,
              rideCount: 30,
              price: 3000,
              officeId: 'o9',
              officeName: 'Delta Lines',
            ),
          ],
        );
        final repo = PackagesRepositoryImpl(datasource);

        final packages = await repo.getOfficePackages('o9');

        expect(datasource.requestedOfficeId, 'o9');
        expect(packages.single.officeId, 'o9');
      },
    );
  });
}
