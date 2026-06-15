import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';

class SupabaseCommunicationDatasource {
  final SupabaseClient _supabase;

  const SupabaseCommunicationDatasource(this._supabase);

  @override
  Future<List<ConversationModel>> getConversations() async {
    // For now, return an empty list or query a real table when it exists
    return [];
  }
}
