import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

/// Maps the `subscriptions` row the rider owns into the package Home shows.
abstract final class HomeActivePackageMapper {
  /// `null` when the rider holds no active subscription — Home then shows no
  /// package section at all rather than advertising plans they have not bought.
  static HomeActivePackageData? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    return HomeActivePackageData(
      title: row['package_name']?.toString() ?? '',
      routeLabel: row['route_name']?.toString() ?? '',
      startDate: DateTime.tryParse(row['start_date']?.toString() ?? ''),
      endDate: DateTime.tryParse(row['end_date']?.toString() ?? ''),
    );
  }
}
