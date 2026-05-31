class AuditService {
  /// Append an audit entry. In production this should persist to an audit store.
  Future<void> record(
    String actorId,
    String action,
    Map<String, dynamic> meta,
  ) async {
    // simple print for now — replace with persistent storage
    final now = DateTime.now().toIso8601String();
    print('[AUDIT] $now - $actorId - $action - $meta');
  }
}
