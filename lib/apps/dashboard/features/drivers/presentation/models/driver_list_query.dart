import '../../domain/entities/driver.dart';

enum DriverSortBy {
  name('الاسم'),
  trips('عدد الرحلات'),
  rating('التقييم'),
  status('الحالة');

  final String label;

  const DriverSortBy(this.label);
}

class DriverListQuery {
  final String search;
  final DriverStatus? status;
  final DriverSortBy sortBy;
  final bool ascending;
  final int page;
  final int pageSize;

  const DriverListQuery({
    this.search = '',
    this.status,
    this.sortBy = DriverSortBy.name,
    this.ascending = true,
    this.page = 0,
    this.pageSize = 6,
  });

  DriverListQuery copyWith({
    String? search,
    DriverStatus? status,
    bool clearStatus = false,
    DriverSortBy? sortBy,
    bool? ascending,
    int? page,
    int? pageSize,
  }) {
    return DriverListQuery(
      search: search ?? this.search,
      status: clearStatus ? null : status ?? this.status,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
