/// Geometry shared between the loaded profile header and its loading skeleton.
///
/// The two must agree or the load→loaded transition visibly jumps, which is
/// exactly what happened while each file carried its own copy of the height.
class DriverProfileMetrics {
  DriverProfileMetrics._();

  /// Expanded height of the identity header.
  ///
  /// Sized for the tallest content it hosts (avatar + name + rating pill +
  /// stats row) with headroom for moderate text scaling.
  static const double headerHeight = 320;
}
