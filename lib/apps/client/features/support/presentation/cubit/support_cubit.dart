import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/related_booking_option.dart';
import '../../domain/entities/support_office_option.dart';
import '../../domain/usecases/get_my_support_tickets_usecase.dart';
import '../../domain/usecases/create_support_ticket_usecase.dart';
import '../../domain/usecases/get_related_booking_options_usecase.dart';
import '../../domain/usecases/get_support_office_options_usecase.dart';
import '../../domain/usecases/get_ticket_details_usecase.dart';
import '../../domain/repositories/support_repository.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final GetMySupportTicketsUseCase _getMySupportTickets;
  final CreateSupportTicketUseCase _createSupportTicket;
  final GetRelatedBookingOptionsUseCase _getRelatedBookingOptions;
  final GetSupportOfficeOptionsUseCase _getOfficeOptions;
  final GetTicketDetailsUseCase _getTicketDetails;
  final SupportRepository _supportRepository; 

  SupportCubit({
    required GetMySupportTicketsUseCase getMySupportTickets,
    required CreateSupportTicketUseCase createSupportTicket,
    required GetRelatedBookingOptionsUseCase getRelatedBookingOptions,
    required GetSupportOfficeOptionsUseCase getOfficeOptions,
    required GetTicketDetailsUseCase getTicketDetails,
    required SupportRepository supportRepository,
  }) : _getMySupportTickets = getMySupportTickets,
       _createSupportTicket = createSupportTicket,
       _getRelatedBookingOptions = getRelatedBookingOptions,
       _getOfficeOptions = getOfficeOptions,
       _getTicketDetails = getTicketDetails,
       _supportRepository = supportRepository,
       super(SupportInitial());

  List<RelatedBookingOption> _relatedBookingOptions = const [];
  List<SupportOfficeOption> _officeOptions = const [];

  /// Read by the create form; loaded via [loadRelatedBookingOptions]. Kept on
  /// the cubit rather than in a state so transient submit/error states can't
  /// wipe the picker mid-edit.
  List<RelatedBookingOption> get relatedBookingOptions =>
      _relatedBookingOptions;

  /// The offices a client can direct a complaint to. Loaded via
  /// [loadOfficeOptions]; kept on the cubit for the same reason as the
  /// bookings above.
  List<SupportOfficeOption> get officeOptions => _officeOptions;

  bool _officeLoadFailed = false;

  /// Set once [loadOfficeOptions] fails, so the create form can surface a
  /// retry affordance instead of leaving the required picker silently empty.
  bool get officeLoadFailed => _officeLoadFailed;

  /// Loads the client's recent bookings for the optional "related booking"
  /// picker. A linked ticket is routed to the operating office server-side;
  /// an unlinked one goes to the office the client picks — so this failing must
  /// never block filing: on error the picker simply stays hidden.
  Future<void> loadRelatedBookingOptions() async {
    if (_relatedBookingOptions.isNotEmpty) return;
    try {
      _relatedBookingOptions = await _getRelatedBookingOptions();
      if (_relatedBookingOptions.isNotEmpty && !isClosed) {
        emit(const SupportRelatedBookingsLoaded());
      }
    } catch (_) {
      
    }
  }

  /// Loads the offices the client can direct a complaint to. Unlike the
  /// booking picker this one is required to file, so the form surfaces a
  /// retry (see [officeLoadFailed]) when the list stays empty.
  Future<void> loadOfficeOptions() async {
    if (_officeOptions.isNotEmpty) return;
    try {
      _officeOptions = await _getOfficeOptions();
      _officeLoadFailed = false;
      if (!isClosed) emit(const SupportOfficesLoaded());
    } catch (_) {
      _officeLoadFailed = true;
      if (!isClosed) emit(const SupportOfficesLoadError());
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
    String? officeId,
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
        officeId: officeId,
        relatedBookingId: relatedBookingId,
        relatedTripId: relatedTripId,
      );

      var attachmentFailed = false;
      if (attachment != null) {
        try {
          await _supportRepository.uploadAttachment(
            ticketId: ticket.id,
            file: attachment,
          );
        } catch (_) {
          attachmentFailed = true;
        }
      }

      emit(
        SupportSuccess(
          message: 'Ticket created successfully',
          ticket: ticket,
          attachmentFailed: attachmentFailed,
        ),
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
