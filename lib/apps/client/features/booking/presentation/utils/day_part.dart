/// A coarse time-of-day bucket for a trip's departure time, parsed
/// defensively — an unparseable time never excludes a trip from a filter.
enum DayPart { morning, afternoon, evening }

String timeOfDayLabel(DayPart bucket) {
  return switch (bucket) {
    DayPart.morning => 'Morning',
    DayPart.afternoon => 'Afternoon',
    DayPart.evening => 'Evening',
  };
}
