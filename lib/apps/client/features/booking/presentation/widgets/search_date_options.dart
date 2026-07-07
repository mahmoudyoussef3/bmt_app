/// Generates the next [count] selectable dates as display strings
/// (e.g. "Today, Jul 7", "Tomorrow, Jul 8", "Wed, Jul 9") for the date picker
/// on [SearchTripScreen].
List<String> buildSearchDateOptions({int count = 7}) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final now = DateTime.now();
  return List.generate(count, (i) {
    final d = now.add(Duration(days: i));
    final month = months[d.month - 1];
    final day = d.day;
    if (i == 0) return 'Today, $month $day';
    if (i == 1) return 'Tomorrow, $month $day';
    return '${weekdays[d.weekday - 1]}, $month $day';
  });
}

String todaySearchDateLabel() => buildSearchDateOptions(count: 1).first;
