class CaptainLocationFix {
  const CaptainLocationFix({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.heading,
    this.speed,
    this.accuracy,
  });

  final double latitude;
  final double longitude;

  final DateTime recordedAt;

  final double? heading;

  final double? speed;

  final double? accuracy;

  double? get speedKmh => speed == null || speed! < 0 ? null : speed! * 3.6;
}
