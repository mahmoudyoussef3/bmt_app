import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation_model.dart';

class SupabaseCommunicationDatasource {
  final SupabaseClient _supabase;

  const SupabaseCommunicationDatasource(this._supabase);

  Future<List<ConversationModel>> getConversations() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const [];

    try {
      final response = await _supabase
          .from('operation_complaints')
          .select(
            'id, category, status, priority, description, assigned_to, conversation, created_at, updated_at',
          )
          .eq('client_id', userId)
          .order('updated_at', ascending: false);

      return response
          .map((row) => _mapComplaint(Map<String, dynamic>.from(row)))
          .toList();
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST205' || error.code == '42P01') {
        return const <ConversationModel>[];
      }
      throw Exception(
        error.message.isEmpty
            ? 'Unable to load support conversations.'
            : error.message,
      );
    }
  }

  /// Appends a client message to a support conversation's `conversation`
  /// JSONB array and bumps `updated_at`. Scoped to the authenticated client.
  Future<void> appendClientMessage({
    required String conversationId,
    required String text,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be signed in to send a message.');
    }

    final row = await _supabase
        .from('operation_complaints')
        .select('conversation')
        .eq('id', conversationId)
        .eq('client_id', userId)
        .single();

    final messages = row['conversation'] is List
        ? List<dynamic>.from(row['conversation'] as List)
        : <dynamic>[];

    messages.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'sender': 'client',
      'sender_name': 'You',
      'message': text,
      'type': 'text',
      'is_read': true,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    await _supabase
        .from('operation_complaints')
        .update({
          'conversation': messages,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', conversationId)
        .eq('client_id', userId);
  }

  ConversationModel _mapComplaint(Map<String, dynamic> row) {
    final category = row['category']?.toString() ?? 'Support';
    final assignedTo = row['assigned_to']?.toString();
    final title = assignedTo == null || assignedTo.trim().isEmpty
        ? 'Support Team'
        : assignedTo;
    final conversation = row['conversation'] is List
        ? row['conversation'] as List
        : const [];
    final messages = conversation
        .whereType<Map>()
        .map((item) => _mapMessage(Map<String, dynamic>.from(item)))
        .toList();
    final fallbackMessage = row['description']?.toString() ?? '';
    final lastMessage = messages.isEmpty ? fallbackMessage : messages.last.text;

    return ConversationModel(
      id: row['id']?.toString() ?? '',
      name: title,
      category: category,
      lastMessage: lastMessage,
      time: _relativeTime(row['updated_at'] ?? row['created_at']),
      initials: _initials(title),
      isOnline: false,
      unreadCount: 0,
      messages: messages,
      meta: {
        'Status': row['status']?.toString() ?? 'newlyCreated',
        'Priority': row['priority']?.toString() ?? 'low',
      },
    );
  }

  ChatMessageModel _mapMessage(Map<String, dynamic> json) {
    final sender =
        json['sender']?.toString() ??
        json['author_role']?.toString() ??
        json['role']?.toString() ??
        'support';
    return ChatMessageModel(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      sender: sender,
      senderName:
          json['sender_name']?.toString() ??
          json['author_name']?.toString() ??
          (sender == 'client' ? 'You' : 'Support Team'),
      text:
          json['message']?.toString() ??
          json['text']?.toString() ??
          json['body']?.toString() ??
          '',
      time: _relativeTime(json['created_at'] ?? json['timestamp']),
      type: json['type']?.toString() ?? 'text',
      attachmentName: json['attachment_name']?.toString(),
      attachmentSize: json['attachment_size']?.toString(),
      duration: json['duration']?.toString(),
      isRead: json['is_read'] != false,
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'ST';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  /// Returns the raw ISO timestamp. Relative-time phrasing ("5 min ago",
  /// "Yesterday"...) is computed in the presentation layer, which has the
  /// `BuildContext` this data layer must stay free of — see `_displayTime`
  /// in `communication_screen.dart`.
  String _relativeTime(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    return parsed.toIso8601String();
  }
}
