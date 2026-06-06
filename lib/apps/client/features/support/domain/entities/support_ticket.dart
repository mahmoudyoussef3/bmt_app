enum TicketStatus { open, underReview, inProgress, resolved, closed }

class SupportMessage {
  const SupportMessage({
    required this.sender,
    required this.text,
    required this.time,
  });

  final String sender;
  final String text;
  final String time;

  Map<String, String> toMap() {
    return {'sender': sender, 'text': text, 'time': time};
  }
}

class SupportTicket {
  const SupportTicket({
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

  String get statusLabel => switch (status) {
    TicketStatus.open => 'Open',
    TicketStatus.underReview => 'Under Review',
    TicketStatus.inProgress => 'In Progress',
    TicketStatus.resolved => 'Resolved',
    TicketStatus.closed => 'Closed',
  };

  SupportTicket copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    String? priority,
    TicketStatus? status,
    String? dateCreated,
    List<String>? attachedImages,
    List<Map<String, String>>? conversation,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dateCreated: dateCreated ?? this.dateCreated,
      attachedImages: attachedImages ?? this.attachedImages,
      conversation: conversation ?? this.conversation,
    );
  }
}
