abstract class ClientSessionDatasource {
  /// Whether the session currently in storage belongs to a registered client,
  /// signing out one that does not.
  Future<bool> ensureClientSession();
}
