abstract class SeenTripsRepository {
  Future<Set<String>> getSeenTripIds();
  Future<void> markSeen(Set<String> tripIds);
}
