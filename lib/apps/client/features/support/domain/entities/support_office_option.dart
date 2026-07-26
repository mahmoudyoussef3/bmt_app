/// An office the client can direct a complaint to.
///
/// A ticket only reaches an office's dashboard when it carries that office's
/// id. When the ticket isn't tied to a specific booking/trip (which the server
/// would resolve the office from), the client picks the office here, and the
/// backend honours the choice — but only for a real, pickable office, and
/// filing never grants any read access to that office's data.
class SupportOfficeOption {
  const SupportOfficeOption({required this.id, required this.name});

  final String id;
  final String name;
}
