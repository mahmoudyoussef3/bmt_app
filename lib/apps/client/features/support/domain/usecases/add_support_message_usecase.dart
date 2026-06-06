import '../entities/support_ticket.dart';

class AddSupportMessageUseCase {
  const AddSupportMessageUseCase();

  SupportTicket call({
    required SupportTicket ticket,
    required String sender,
    required String text,
    required String time,
  }) {
    final conversation = List<Map<String, String>>.from(ticket.conversation)
      ..add({'sender': sender, 'text': text, 'time': time});
    return ticket.copyWith(conversation: conversation);
  }
}
