/// The duration buckets riders can filter the package catalogue by.
///
/// Modelled as an enum rather than a display string on purpose: the tab strip
/// shows localized labels, so matching on the label text left the list empty in
/// every locale whose word for "All" is not the literal `'All'`.
enum PackageFilter {
  all,
  weekly,
  monthly,
  quarterly;

  /// Whether a package of [durationDays] belongs in this bucket.
  bool matches(int durationDays) => switch (this) {
    PackageFilter.all => true,
    PackageFilter.weekly => durationDays <= 14,
    PackageFilter.monthly => durationDays == 30,
    PackageFilter.quarterly => durationDays == 90,
  };
}
