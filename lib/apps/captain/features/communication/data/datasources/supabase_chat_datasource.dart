import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/conversation.dart';
import '../models/conversation_model.dart';
import 'chat_datasource.dart';

class SupabaseChatDatasource implements ChatDatasource {
  const SupabaseChatDatasource(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<CaptainConversationModel> getConversation({
    required String tripId,
    String? passengerId,
  }) async {
    final List<Map<String, dynamic>> rows;
    if (passengerId != null) {
      rows = await _supabase
          .from('captain_messages')
          .select()
          .eq('trip_id', tripId)
          .eq('passenger_id', passengerId)
          .order('sent_at', ascending: true);
    } else {
      rows = await _supabase
          .from('captain_messages')
          .select()
          .eq('trip_id', tripId)
          .isFilter('passenger_id', null)
          .order('sent_at', ascending: true);
    }

    final messages = rows.map<CaptainMessageModel>(_rowToMessage).toList();
    final broadcast = passengerId == null;

    return CaptainConversationModel(
      id: broadcast ? 'broadcast-$tripId' : 'chat-$tripId-$passengerId',
      title: broadcast ? 'All Passengers' : 'Passenger Chat',
      passengerId: passengerId,
      broadcast: broadcast,
      messages: messages,
    );
  }

  @override
  Future<CaptainConversationModel> sendMessage({
    required String tripId,
    String? passengerId,
    required String text,
    required CaptainMessageType type,
  }) async {
    await _supabase.from('captain_messages').insert({
      'trip_id': tripId,
      'sender_type': 'driver',
      'sender_id': _supabase.auth.currentUser?.id,
      'passenger_id': passengerId,
      'body': text,
      'message_type': type.name,
    });
    return getConversation(tripId: tripId, passengerId: passengerId);
  }

  CaptainMessageModel _rowToMessage(Map<String, dynamic> row) {
    final senderType = row['sender_type'] as String? ?? 'driver';
    final mine = senderType == 'driver';
    return CaptainMessageModel(
      id: row['id'] as String,
      senderName: mine ? 'أنت' : 'العمليات',
      text: row['body'] as String? ?? '',
      type: _typeFromDb(row['message_type'] as String? ?? 'text'),
      isMine: mine,
    );
  }

  /// The newest operations message on any trip RLS lets this captain see —
  /// which, by `captain_messages_captain_read`, means their own trips only.
  ///
  /// The row's id travels with the body so the banner can tell a *new* message
  /// from a *repeated* one. Suppressing by text meant an operator who sent the
  /// same instruction twice reached the captain once.
  @override
  Stream<OpsBroadcast> watchIncomingOpsMessages() {
    return _supabase
        .from('captain_messages')
        .stream(primaryKey: ['id'])
        .eq('sender_type', 'operations')
        .order('sent_at', ascending: false)
        .limit(1)
        .map((rows) {
          if (rows.isEmpty) return null;
          final row = rows.first;
          final body = row['body'] as String? ?? '';
          final id = row['id']?.toString() ?? '';
          if (body.isEmpty || id.isEmpty) return null;
          return OpsBroadcast(id: id, body: body);
        })
        .where((broadcast) => broadcast != null)
        .cast<OpsBroadcast>();
  }

  CaptainMessageType _typeFromDb(String t) => switch (t) {
    'image' => CaptainMessageType.image,
    'voice' => CaptainMessageType.voice,
    _ => CaptainMessageType.text,
  };
}
