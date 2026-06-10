import '../../domain/entities/complaint.dart';

class ComplaintMessageModel extends ComplaintMessage {
  const ComplaintMessageModel({
    required super.id,
    required super.senderName,
    required super.senderType,
    required super.content,
    required super.timestamp,
    required super.attachments,
  });

  factory ComplaintMessageModel.fromJson(Map<String, dynamic> json) {
    return ComplaintMessageModel(
      id: json['id'].toString(),
      senderName: json['senderName'].toString(),
      senderType: json['senderType'].toString(),
      content: json['content'].toString(),
      timestamp: DateTime.parse(json['timestamp'].toString()),
      attachments: List<String>.from(json['attachments'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderName': senderName,
        'senderType': senderType,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'attachments': attachments,
      };

  factory ComplaintMessageModel.fromEntity(ComplaintMessage entity) {
    return ComplaintMessageModel(
      id: entity.id,
      senderName: entity.senderName,
      senderType: entity.senderType,
      content: entity.content,
      timestamp: entity.timestamp,
      attachments: entity.attachments,
    );
  }
}

class ComplaintLogModel extends ComplaintLog {
  const ComplaintLogModel({
    required super.id,
    required super.action,
    required super.timestamp,
    required super.actor,
  });

  factory ComplaintLogModel.fromJson(Map<String, dynamic> json) {
    return ComplaintLogModel(
      id: json['id'].toString(),
      action: json['action'].toString(),
      timestamp: DateTime.parse(json['timestamp'].toString()),
      actor: json['actor'].toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'timestamp': timestamp.toIso8601String(),
        'actor': actor,
      };

  factory ComplaintLogModel.fromEntity(ComplaintLog entity) {
    return ComplaintLogModel(
      id: entity.id,
      action: entity.action,
      timestamp: entity.timestamp,
      actor: entity.actor,
    );
  }
}

class ComplaintModel extends Complaint {
  const ComplaintModel({
    required super.id,
    required super.clientName,
    required super.clientPhone,
    required super.category,
    required super.tripCode,
    required super.createdAt,
    super.assignedTo,
    required super.status,
    required super.priority,
    required super.description,
    required super.conversation,
    required super.attachments,
    required super.history,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'].toString(),
      clientName: json['clientName'].toString(),
      clientPhone: json['clientPhone'].toString(),
      category: ComplaintCategory.values.byName(json['category'].toString()),
      tripCode: json['tripCode'].toString(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      assignedTo: json['assignedTo']?.toString(),
      status: ComplaintStatus.values.byName(json['status'].toString()),
      priority: ComplaintPriority.values.byName(json['priority'].toString()),
      description: json['description'].toString(),
      conversation: (json['conversation'] as List? ?? [])
          .map((e) => ComplaintMessageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachments: List<String>.from(json['attachments'] as List? ?? []),
      history: (json['history'] as List? ?? [])
          .map((e) => ComplaintLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'category': category.name,
        'tripCode': tripCode,
        'createdAt': createdAt.toIso8601String(),
        'assignedTo': assignedTo,
        'status': status.name,
        'priority': priority.name,
        'description': description,
        'conversation': conversation
            .map((e) => ComplaintMessageModel.fromEntity(e).toJson())
            .toList(),
        'attachments': attachments,
        'history': history
            .map((e) => ComplaintLogModel.fromEntity(e).toJson())
            .toList(),
      };

  factory ComplaintModel.fromEntity(Complaint entity) {
    return ComplaintModel(
      id: entity.id,
      clientName: entity.clientName,
      clientPhone: entity.clientPhone,
      category: entity.category,
      tripCode: entity.tripCode,
      createdAt: entity.createdAt,
      assignedTo: entity.assignedTo,
      status: entity.status,
      priority: entity.priority,
      description: entity.description,
      conversation: List<ComplaintMessage>.from(entity.conversation),
      attachments: List<String>.from(entity.attachments),
      history: List<ComplaintLog>.from(entity.history),
    );
  }
}
