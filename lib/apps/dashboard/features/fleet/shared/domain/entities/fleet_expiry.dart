/// Single source of truth for "is this date expiring soon".
///
/// Before this file, the same 30-day rule was implemented four times
/// independently — `FleetVehicle`, `FleetDriver`, `DriverOperations`, and
/// `FleetDocumentsCubit` — and could silently drift apart if only one copy
/// was ever edited. Every one of those now calls through here instead.
library;

enum FleetExpiryLevel { valid, expiringSoon, expired, missing }

abstract final class FleetExpiry {
  static const int expiringSoonWindowDays = 30;

  static FleetExpiryLevel levelOf(String dateText, {DateTime? now}) {
    final date = DateTime.tryParse(dateText);
    if (date == null) return FleetExpiryLevel.missing;

    final today = now ?? DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final days = dateOnly.difference(todayOnly).inDays;

    if (days < 0) return FleetExpiryLevel.expired;
    if (days <= expiringSoonWindowDays) return FleetExpiryLevel.expiringSoon;
    return FleetExpiryLevel.valid;
  }

  static bool isExpired(String dateText, {DateTime? now}) =>
      levelOf(dateText, now: now) == FleetExpiryLevel.expired;

  static bool isExpiringSoon(String dateText, {DateTime? now}) =>
      levelOf(dateText, now: now) == FleetExpiryLevel.expiringSoon;

  /// Days remaining until [dateText]; negative once past. Null if unparsable.
  static int? daysRemaining(String dateText, {DateTime? now}) {
    final date = DateTime.tryParse(dateText);
    if (date == null) return null;
    final today = now ?? DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    return dateOnly.difference(todayOnly).inDays;
  }
}
