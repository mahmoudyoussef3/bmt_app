/// One route as it appears in the client's routes catalog: just enough to
/// recognise the corridor and who runs it before opening its full details.
class RouteSummary {
  const RouteSummary({
    required this.id,
    required this.name,
    required this.startCity,
    required this.endCity,
    this.distance = '',
    this.duration = '',
    this.officeId = '',
    this.officeName = '',
    this.officeLogoUrl,
  });

  final String id;
  final String name;
  final String startCity;
  final String endCity;
  final String distance;
  final String duration;
  final String officeId;
  final String officeName;
  final String? officeLogoUrl;
}
