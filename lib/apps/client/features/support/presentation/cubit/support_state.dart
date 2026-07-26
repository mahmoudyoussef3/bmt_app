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
  final List<SupportTicket> tickets;

  const SupportLoaded({required this.tickets});

  @override
  List<Object?> get props => [tickets];

  SupportLoaded copyWith({List<SupportTicket>? tickets}) {
    return SupportLoaded(tickets: tickets ?? this.tickets);
  }
}

/// Signals that the related-booking picker options finished loading. Carries
/// no data — the options live on the cubit — it exists only so the create
/// screen rebuilds its form once the picker has something to show.
class SupportRelatedBookingsLoaded extends SupportState {
  const SupportRelatedBookingsLoaded();
}

/// Signals that the office-picker options finished loading. Like
/// [SupportRelatedBookingsLoaded], the list lives on the cubit; this only
/// nudges the create form to rebuild once the offices are available.
class SupportOfficesLoaded extends SupportState {
  const SupportOfficesLoaded();
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
