import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/support_message.dart';
import '../../domain/usecases/get_support_workspace_usecase.dart';
import '../../domain/usecases/get_my_support_tickets_usecase.dart';
import '../../domain/usecases/create_support_ticket_usecase.dart';
import '../../domain/usecases/get_ticket_details_usecase.dart';
import '../../domain/usecases/get_ticket_timeline_usecase.dart';
import '../../domain/usecases/send_ticket_message_usecase.dart';
import '../../domain/usecases/create_refund_request_usecase.dart';
import '../../domain/usecases/upload_support_attachment_usecase.dart';
import '../../domain/usecases/subscribe_to_ticket_updates_usecase.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final GetSupportWorkspaceUseCase _getSupportWorkspace;
  final GetMySupportTicketsUseCase _getMySupportTickets;
  final CreateSupportTicketUseCase _createSupportTicket;
  final GetTicketDetailsUseCase _getTicketDetails;
  final GetTicketTimelineUseCase _getTicketTimeline;
  final SendTicketMessageUseCase _sendTicketMessage;
  final CreateRefundRequestUseCase _createRefundRequest;
  final UploadSupportAttachmentUseCase _uploadSupportAttachment;
  final SubscribeToTicketUpdatesUseCase _subscribeToTicketUpdates;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _ticketSubscription;

  SupportCubit({
    required GetSupportWorkspaceUseCase getSupportWorkspace,
    required GetMySupportTicketsUseCase getMySupportTickets,
    required CreateSupportTicketUseCase createSupportTicket,
    required GetTicketDetailsUseCase getTicketDetails,
    required GetTicketTimelineUseCase getTicketTimeline,
    required SendTicketMessageUseCase sendTicketMessage,
    required CreateRefundRequestUseCase createRefundRequest,
    required UploadSupportAttachmentUseCase uploadSupportAttachment,
    required SubscribeToTicketUpdatesUseCase subscribeToTicketUpdates,
  })  : _getSupportWorkspace = getSupportWorkspace,
        _getMySupportTickets = getMySupportTickets,
        _createSupportTicket = createSupportTicket,
        _getTicketDetails = getTicketDetails,
        _getTicketTimeline = getTicketTimeline,
        _sendTicketMessage = sendTicketMessage,
        _createRefundRequest = createRefundRequest,
        _uploadSupportAttachment = uploadSupportAttachment,
        _subscribeToTicketUpdates = subscribeToTicketUpdates,
        super(SupportInitial());

  Future<void> loadWorkspace() async {
    emit(SupportLoading());
    try {
      final workspace = await _getSupportWorkspace();
      emit(SupportLoaded(
        categories: workspace.categories,
        tickets: workspace.tickets,
      ));
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
        // Upload initial attachment linking to the ticket
        await _uploadSupportAttachment(
          ticketId: ticket.id,
          file: attachment,
        );
      }

      emit(SupportSuccess(message: 'Ticket created successfully', ticket: ticket));
      loadWorkspace(); // Reload workspace to show new ticket
    } catch (e) {
      emit(SupportError(e.toString()));
      loadWorkspace(); // Revert back to loaded state safely
    }
  }

  Future<void> openTicketDetails(String ticketId) async {
    emit(SupportLoading());
    _cancelSubscriptions();

    try {
      final ticket = await _getTicketDetails(ticketId);
      final timeline = await _getTicketTimeline(ticketId);
      
      emit(SupportTicketDetailsLoaded(
        ticket: ticket,
        messages: [], // Realtime will handle populating this
        timeline: timeline,
      ));

      _setupRealtimeSubscriptions(ticketId);
    } catch (e) {
      emit(SupportError(e.toString()));
    }
  }

  void _setupRealtimeSubscriptions(String ticketId) {
    _messagesSubscription = _subscribeToTicketUpdates.messages(ticketId).listen(
      (List<SupportMessage> messages) {
        if (state is SupportTicketDetailsLoaded) {
          emit((state as SupportTicketDetailsLoaded).copyWith(messages: messages));
        }
      },
      onError: (err) => print('Message subscription error: $err'),
    );

    _ticketSubscription = _subscribeToTicketUpdates.ticketUpdates(ticketId).listen(
      (ticketUpdate) {
        if (state is SupportTicketDetailsLoaded) {
           // We might also fetch timeline again here if needed, 
           // but for now just update the ticket header status.
           emit((state as SupportTicketDetailsLoaded).copyWith(ticket: ticketUpdate));
        }
      },
      onError: (err) => print('Ticket subscription error: $err'),
    );
  }

  Future<void> sendUserMessage(String ticketId, String text, File? attachment) async {
    final currentState = state;
    if (currentState is! SupportTicketDetailsLoaded) return;

    try {
      final message = await _sendTicketMessage(
        ticketId: ticketId,
        message: text,
      );

      if (attachment != null) {
        await _uploadSupportAttachment(
          ticketId: ticketId,
          messageId: message.id,
          file: attachment,
        );
      }
      
      // We don't emit a new message list immediately because Realtime subscription 
      // will pick it up and emit the new state automatically!
    } catch (e) {
      emit(SupportError(e.toString()));
      // Optionally restore details view
      emit(currentState);
    }
  }

  Future<void> createRefundRequest({
    required String reason,
    String? description,
    required double amount,
    String? bookingId,
    String? tripId,
    File? evidenceFile,
  }) async {
    final currentState = state;
    emit(const SupportActionLoading('Submitting refund request...'));
    try {
      await _createRefundRequest(
        reason: reason,
        description: description,
        amount: amount,
        bookingId: bookingId,
        tripId: tripId,
        evidenceFile: evidenceFile,
      );
      emit(const SupportSuccess(message: 'Refund request submitted successfully.'));
      if (currentState is SupportLoaded) loadWorkspace();
    } catch (e) {
      emit(SupportError(e.toString()));
      if (currentState is SupportLoaded) emit(currentState);
    }
  }

  void _cancelSubscriptions() {
    _messagesSubscription?.cancel();
    _ticketSubscription?.cancel();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
