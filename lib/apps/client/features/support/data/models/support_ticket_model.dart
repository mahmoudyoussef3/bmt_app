import '../../domain/entities/support_ticket.dart';

class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dateCreated,
    this.attachedImages = const [],
    this.conversation = const [],
  });

  final String id;
  final String category;
  final String title;
  final String description;
  final String priority;
  final TicketStatus status;
  final String dateCreated;
  final List<String> attachedImages;
  final List<Map<String, String>> conversation;

  SupportTicket toEntity() {
    return SupportTicket(
      id: id,
      category: category,
      title: title,
      description: description,
      priority: priority,
      status: status,
      dateCreated: dateCreated,
      attachedImages: attachedImages,
      conversation: conversation,
    );
  }
}
