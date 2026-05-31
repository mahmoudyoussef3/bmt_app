class ShiftRecord {
  final String id;
  final DateTime start;
  DateTime? end;
  final String? notes;

  ShiftRecord({required this.id, required this.start, this.end, this.notes});

  Duration? get duration => end?.difference(start);
}
