import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/related_booking_option.dart';
import '../../domain/usecases/get_my_support_tickets_usecase.dart';
import '../../domain/usecases/create_support_ticket_usecase.dart';
import '../../domain/usecases/get_related_booking_options_usecase.dart';
import '../../domain/usecases/get_ticket_details_usecase.dart';
import '../../domain/repositories/support_repository.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final GetMySupportTicketsUseCase _getMySupportTickets;
  final CreateSupportTicketUseCase _createSupportTicket;
  final GetRelatedBookingOptionsUseCase _getRelatedBookingOptions;
  final GetTicketDetailsUseCase _getTicketDetails;
  final SupportRepository _supportRepository; // To get attachments

  SupportCubit({
    required GetMySupportTicketsUseCase getMySupportTickets,
    required CreateSupportTicketUseCase createSupportTicket,
    required GetRelatedBookingOptionsUseCase getRelatedBookingOptions,
    required GetTicketDetailsUseCase getTicketDetails,
    required SupportRepository supportRepository,
  }) : _getMySupportTickets = getMySupportTickets,
       _createSupportTicket = createSupportTicket,
       _getRelatedBookingOptions = getRelatedBookingOptions,
       _getTicketDetails = getTicketDetails,
       _supportRepository = supportRepository,
       super(SupportInitial());

  List<RelatedBookingOption> _relatedBookingOptions = const [];

  /// Read by the create form; loaded via [loadRelatedBookingOptions]. Kept on
  /// the cubit rather than in a state so transient submit/error states can't
  /// wipe the picker mid-edit.
  List<RelatedBookingOption> get relatedBookingOptions =>
      _relatedBookingOptions;

  /// Loads the client's recent bookings for the optional "related booking"
  /// picker. A linked ticket is routed to the operating office server-side;
  /// an unlinked one goes to platform support — so this failing must never
  /// block filing: on error the picker simply stays hidden.
  Future<void> loadRelatedBookingOptions() async {
    if (_relatedBookingOptions.isNotEmpty) return;
    try {
      _relatedBookingOptions = await _getRelatedBookingOptions();
      if (_relatedBookingOptions.isNotEmpty && !isClosed) {
        emit(const SupportRelatedBookingsLoaded());
      }
    } catch (_) {
      // Optional nicety — the ticket form works without it.
    }
  }

  Future<void> loadTickets() async {
    emit(SupportLoading());
    try {
      final tickets = await _getMySupportTickets();
      emit(SupportLoaded(tickets: tickets));
    } catch (e) {
      emit(SupportError(_friendlyMessage(e)));
    }
  }

  /// Refreshes the ticket list without disturbing the currently displayed
  /// data on failure. A transient network blip during pull-to-refresh should
  /// surface as a toast, not replace the whole screen with a full error.
  /// Callers (the [RefreshIndicator]) should catch and present the rethrown
  /// error themselves.
  Future<void> refreshTickets() async {
    if (state is! SupportLoaded) return;
    try {
      final tickets = await _getMySupportTickets();
      emit((state as SupportLoaded).copyWith(tickets: tickets));
    } catch (e) {
      throw Exception(_friendlyMessage(e));
    }
  }

  /// Files a new ticket. Note this runs on the create screen's own cubit
  /// instance, which is disposed the moment that screen pops — so it must not
  /// reload the list here. The Support Center refreshes itself when the create
  /// screen returns.
  Future<void> createTicket({
    required String category,
    required String title,
    required String description,
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
    } catch (e) {
      emit(SupportError(_friendlyMessage(e)));
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
      emit(SupportError(_friendlyMessage(e)));
    }
  }

  /// Strips the `Exception: ` prefix Dart adds to thrown [Exception]s so the
  /// UI shows a clean, user-facing message. Matches the convention used by
  /// `auth_cubit.dart` and other client cubits.
  String _friendlyMessage(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
}
