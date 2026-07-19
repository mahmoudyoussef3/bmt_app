import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation_model.dart';
import 'communication_datasource.dart';

/// Reads and writes the client's support threads in `operation_complaints`.
class SupabaseCommunicationDatasource implements CommunicationDatasource {
  const SupabaseCommunicationDatasource(this._supabase);

  final SupabaseClient _supabase;

  static const _table = 'operation_complaints';
  static const _columns =
      'id, category, status, priority, description, assigned_to, '
      'conversation, created_at, updated_at';

  /// How many compare-and-set rounds to attempt before giving up and asking
  /// the client to send again.
  static const _maxAppendAttempts = 3;

  @override
  Future<List<ConversationModel>> getConversations() async {
    final userId = _requireUserId();

    try {
      final rows = await _supabase
          .from(_table)
          .select(_columns)
          .eq('client_id', userId)
          .order('updated_at', ascending: false);

      return rows
          .map(
            (row) => ConversationModel.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
    } on PostgrestException catch (error) {
      _fail(error, 'Unable to load support conversations.');
    }
  }

  @override
  Future<ConversationModel> getConversation(String conversationId) async {
    final userId = _requireUserId();

    try {
      final row = await _supabase
          .from(_table)
          .select(_columns)
          .eq('id', conversationId)
          .eq('client_id', userId)
          .single();

      return ConversationModel.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      _fail(error, 'Unable to load this conversation.');
    }
  }

  /// Appends a client message to a thread's `conversation` JSONB array.
  ///
  /// PostgREST cannot express `conversation || $1`, so the array is read,
  /// extended, and written back. The write is guarded by the `updated_at` we
  /// read, making it a compare-and-set: if anyone wrote in between — an agent
  /// replying, or this client on another device — the update matches no row and
  /// we retry against the fresh thread rather than silently overwriting them.
  @override
  Future<void> appendClientMessage({
    required String conversationId,
    required String text,
  }) async {
    final userId = _requireUserId();
    final message = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'sender': 'client',
      'message': text,
      'type': 'text',
      'is_read': true,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      for (var attempt = 0; attempt < _maxAppendAttempts; attempt++) {
        if (await _tryAppend(conversationId, userId, message)) return;
      }
    } on PostgrestException catch (error) {
      _fail(error, 'Unable to send your message.');
    }

    // A zero-row update means either a competing write or a policy that
    // refused ours — PostgREST reports both the same way, so the message
    // stays neutral about which it was.
    throw Exception('Your message could not be sent. Please try again.');
  }

  /// One compare-and-set round. Returns whether the write landed.
  Future<bool> _tryAppend(
    String conversationId,
    String userId,
    Map<String, Object?> message,
  ) async {
    final row = await _supabase
        .from(_table)
        .select('conversation, updated_at')
        .eq('id', conversationId)
        .eq('client_id', userId)
        .single();

    final previousUpdatedAt = row['updated_at'];
    if (previousUpdatedAt == null) {
      throw Exception('Support conversation is missing its update timestamp.');
    }

    final conversation = row['conversation'];
    final messages = conversation is List
        ? List<dynamic>.from(conversation)
        : <dynamic>[];

    final written = await _supabase
        .from(_table)
        .update({
          'conversation': [...messages, message],
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', conversationId)
        .eq('client_id', userId)
        .eq('updated_at', previousUpdatedAt)
        .select('id');

    return written.isNotEmpty;
  }

  /// Surfaces a Postgrest failure as a plain message, since the raw exception
  /// string reads as internals to the client.
  Never _fail(PostgrestException error, String fallback) {
    throw Exception(error.message.isEmpty ? fallback : error.message);
  }

  String _requireUserId() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be signed in to use support chat.');
    }
    return userId;
  }
}
