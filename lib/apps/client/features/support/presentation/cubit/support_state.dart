import 'package:equatable/equatable.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/support_attachment.dart';

abstract class SupportState extends Equatable {
  const SupportState();

  @override
  List<Object?> get props => [];
}

class SupportInitial extends SupportState {}

class SupportLoading extends SupportState {}

class SupportLoaded extends SupportState {
  final List<String> categories;
  final List<SupportTicket> tickets;

  const SupportLoaded({
    required this.categories,
    required this.tickets,
  });

  @override
  List<Object?> get props => [categories, tickets];

  SupportLoaded copyWith({
    List<String>? categories,
    List<SupportTicket>? tickets,
  }) {
    return SupportLoaded(
      categories: categories ?? this.categories,
      tickets: tickets ?? this.tickets,
    );
  }
}

class SupportError extends SupportState {
  final String message;

  const SupportError(this.message);

  @override
  List<Object?> get props => [message];
}

class SupportActionLoading extends SupportState {
  final String message;
  
  const SupportActionLoading(this.message);

  @override
  List<Object?> get props => [message];
}

class SupportTicketDetailsLoaded extends SupportState {
  final SupportTicket ticket;
  final List<SupportAttachment> attachments;

  const SupportTicketDetailsLoaded({
    required this.ticket,
    required this.attachments,
  });

  @override
  List<Object?> get props => [ticket, attachments];

  SupportTicketDetailsLoaded copyWith({
    SupportTicket? ticket,
    List<SupportAttachment>? attachments,
  }) {
    return SupportTicketDetailsLoaded(
      ticket: ticket ?? this.ticket,
      attachments: attachments ?? this.attachments,
    );
  }
}

class SupportSuccess extends SupportState {
  final String message;
  final SupportTicket? ticket; 
  
  const SupportSuccess({required this.message, this.ticket});

  @override
  List<Object?> get props => [message, ticket];
}
