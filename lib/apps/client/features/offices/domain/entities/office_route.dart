/// One route an office operates, as shown on its marketplace profile.
///
/// Just enough to recognise the corridor and jump into the existing booking
/// search — which owns everything richer (stations, departures, pricing).
class OfficeRoute {
  const OfficeRoute({
    required this.id,
    required this.name,
    required this.startCity,
    required this.endCity,
  });

  final String id;
  final String name;
  final String startCity;
  final String endCity;
}
