import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_support_workspace_usecase.dart';
import '../../domain/usecases/get_my_support_tickets_usecase.dart';
import '../../domain/usecases/create_support_ticket_usecase.dart';
import '../../domain/usecases/get_ticket_details_usecase.dart';
import '../../domain/repositories/support_repository.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final GetSupportWorkspaceUseCase _getSupportWorkspace;
  final GetMySupportTicketsUseCase _getMySupportTickets;
  final CreateSupportTicketUseCase _createSupportTicket;
  final GetTicketDetailsUseCase _getTicketDetails;
  final SupportRepository _supportRepository; // To get attachments

  SupportCubit({
    required GetSupportWorkspaceUseCase getSupportWorkspace,
    required GetMySupportTicketsUseCase getMySupportTickets,
    required CreateSupportTicketUseCase createSupportTicket,
    required GetTicketDetailsUseCase getTicketDetails,
    required SupportRepository supportRepository,
  }) : _getSupportWorkspace = getSupportWorkspace,
       _getMySupportTickets = getMySupportTickets,
       _createSupportTicket = createSupportTicket,
       _getTicketDetails = getTicketDetails,
       _supportRepository = supportRepository,
       super(SupportInitial());

  Future<void> loadWorkspace() async {
    emit(SupportLoading());
    try {
      final workspace = await _getSupportWorkspace();
      emit(
        SupportLoaded(
          categories: workspace.categories,
          tickets: workspace.tickets,
        ),
      );
    } catch (e) {
      emit(SupportError(e.toString()));
    }
  }

  Future<void> refreshTickets() async {
    if (state is SupportLoaded) {
      try {
        final tickets = await _getMySupportTickets();
        emit((state as SupportLoaded).copyWith(tickets: tickets));
      } catch (e) {
        emit(SupportError(e.toString()));
      }
    }
  }

  Future<void> createTicket({
    required String category,
    required String title,
    required String description,
    required String priority,
    String? relatedBookingId,
    String? relatedTripId,
    File? attachment,
  }) async {
    emit(const SupportActionLoading('Creating ticket...'));
    try {
      final ticket = await _createSupportTicket(
        category: category,
        title: title,
        description: description,
        priority: priority,
        relatedBookingId: relatedBookingId,
        relatedTripId: relatedTripId,
      );

      if (attachment != null) {
        await _supportRepository.uploadAttachment(
          ticketId: ticket.id,
          file: attachment,
        );
      }

      emit(
        SupportSuccess(message: 'Ticket created successfully', ticket: ticket),
      );
      loadWorkspace();
    } catch (e) {
      emit(SupportError(e.toString()));
      loadWorkspace();
    }
  }

  Future<void> openTicketDetails(String ticketId) async {
    emit(SupportLoading());

    try {
      final ticket = await _getTicketDetails(ticketId);
      final attachments = await _supportRepository.getTicketAttachments(
        ticketId,
      );

      emit(
        SupportTicketDetailsLoaded(ticket: ticket, attachments: attachments),
      );
    } catch (e) {
      emit(SupportError(e.toString()));
    }
  }
}
