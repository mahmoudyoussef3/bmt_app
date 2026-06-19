import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';

class SupabaseCommunicationDatasource {
  final SupabaseClient _supabase;

  const SupabaseCommunicationDatasource(this._supabase);

  Future<List<ConversationModel>> getConversations() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const [];

    await _supabase
        .from('support_conversations')
        .select('id')
        .eq('client_id', userId)
        .limit(1);

    return [];
  }
}
