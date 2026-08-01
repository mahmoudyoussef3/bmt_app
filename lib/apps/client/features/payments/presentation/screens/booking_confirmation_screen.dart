import 'package:bmt_app/apps/client/features/support/presentation/routes/support_routes.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/booking_verification_status_card.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/get_trip_details_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/routes/tracking_routes.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String seat;
  final String vehicleId;
  final String driver;
  final String departureTime;
  final String destination;
  final String? bookingReference;
  final String? bookingId;
  final bool requiresVerification;

  const BookingConfirmationScreen({
    super.key,
    required this.seat,
    required this.vehicleId,
    required this.driver,
    required this.departureTime,
    required this.destination,
    this.bookingReference,
    this.bookingId,
    this.requiresVerification = false,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with TickerProviderStateMixin {
  bool _processing = true;
  late final AnimationController _checkController;

  Timer? _statusPollTimer;
  PaymentStatus? _livePaymentStatus;
  String? _rejectionReason;
  bool _statusFetchInFlight = false;

  bool get _isApproved => _livePaymentStatus == PaymentStatus.paid;
  bool get _isRejected => _livePaymentStatus == PaymentStatus.failed;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _processing = false);
      _checkController.forward();
      if (widget.requiresVerification) _startStatusPolling();
    });
  }

  /// The real reference/id the RPC handed back — never a fabricated one. When
  /// neither is available, callers show the honest "pending" copy instead.
  String? get _realBookingReference =>
      widget.bookingReference ?? widget.bookingId;

  /// While the receipt is under manual review, the vehicle must stay
  /// untrackable, so this keeps re-fetching the real booking/payment status
  /// from Supabase (the source of truth) until it resolves to approved or
  /// rejected instead of leaving the client on a stale "pending" screen.
  void _startStatusPolling() {
    final bookingId = widget.bookingId;
    if (bookingId == null || bookingId.isEmpty) return;
    _fetchStatus(bookingId);
    _statusPollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _fetchStatus(bookingId),
    );
  }

  Future<void> _fetchStatus(String bookingId) async {
    if (_statusFetchInFlight) return;
    _statusFetchInFlight = true;
    try {
      final trip = await clientGetIt<GetTripDetailsUseCase>()(bookingId);
      if (!mounted || trip == null) return;
      setState(() {
        _livePaymentStatus = trip.paymentStatus;
        _rejectionReason = trip.cancellationReason;
      });
      if (trip.paymentStatus == PaymentStatus.paid ||
          trip.paymentStatus == PaymentStatus.failed) {
        _statusPollTimer?.cancel();
      }
    } catch (_) {
      // Best-effort refresh — keep showing the last known status.
    } finally {
      _statusFetchInFlight = false;
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    _statusPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      // The booking is already written by the time this screen shows: there is
      // nothing left mid-flow to abandon back into, so the arrow is drawn but
      // inert rather than popping into the wizard/route screens underneath.
      appBar: ClientAppBar(
        title: context.l10n.payments_bookingTitle,
        navigationIcon: Icons.close_rounded,
        backEnabled: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  child: _processing
                      ? _buildProcessing(context)
                      : (widget.requiresVerification
                            ? _buildVerificationWaiting(context)
                            : _buildSuccess(context)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildFooterActions(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessing(BuildContext context) {
    return Column(
      key: const ValueKey('processing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            color: ClientColors.primary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.l10n.payments_processingBookingTitle,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.payments_processingBookingSubtitle,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }

  Widget _buildVerificationWaiting(BuildContext context) {
    final bookingReference =
        _realBookingReference ?? context.l10n.payments_bookingReferencePending;
    final bookingId = widget.bookingId;
    return SingleChildScrollView(
      key: const ValueKey('verification'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ScaleTransition(
        scale: Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
        ),
        child: BookingVerificationStatusCard(
          bookingReference: bookingReference,
          paymentStatus: _livePaymentStatus,
          rejectionReason: _rejectionReason,
          onViewBookingStatus: bookingId == null
              ? null
              : () => Navigator.of(context).pushNamed(
                  TripsRoutes.tripDetails,
                  arguments: {'tripId': bookingId},
                ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final bookingReference =
        _realBookingReference ?? context.l10n.payments_bookingReferencePending;
    final driverInitials = widget.driver
        .split(' ')
        .map((s) => s.isEmpty ? '' : s[0])
        .take(2)
        .join();

    return SingleChildScrollView(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _checkController,
                curve: Curves.elasticOut,
              ),
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: ClientColors.primaryGradientFor(context),
                boxShadow: [
                  BoxShadow(
                    color: ClientColors.primary.withAlpha(55),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.check_rounded, size: 60, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.payments_bookingConfirmedTitle,
            style: ClientTypography.headingLarge(
              context,
            ).copyWith(color: ClientColors.textPrimaryFor(context)),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.payments_bookingConfirmedSubtitle,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.payments_bookingReferenceLabel,
                        style: ClientTypography.bodySmall(context).copyWith(
                          color: ClientColors.textSecondaryFor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        bookingReference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: ClientTypography.labelMedium(context).copyWith(
                          color: ClientColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.destination,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.headingSmall(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.payments_seatNumber(widget.seat),
                            style: ClientTypography.bodySmall(context).copyWith(
                              color: ClientColors.textSecondaryFor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.l10n.payments_departsLabel,
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                          ),
                        ),
                        Text(
                          widget.departureTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.bodyMedium(
                            context,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: ClientColors.borderFor(context)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: ClientColors.primaryLight,
                      child: Text(
                        driverInitials,
                        style: ClientTypography.labelMedium(
                          context,
                        ).copyWith(color: ClientColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.driver,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.bodyMedium(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.payments_vehicleNumberLabel(
                              widget.vehicleId,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTypography.bodySmall(context).copyWith(
                              color: ClientColors.textSecondaryFor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: ClientColors.borderFor(context)),
                const SizedBox(height: 10),
                Text(
                  context.l10n.payments_notesLabel,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.payments_bookingNotesBody,
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  /// The vehicle must stay untrackable until the payment is actually
  /// approved, so "Track Vehicle" only appears once [_livePaymentStatus] is
  /// [PaymentStatus.paid] (or verification was never required, e.g. cash/card).
  /// "Back to Home" is always available so the client is never stuck here.
  Widget _buildFooterActions(BuildContext context) {
    if (!widget.requiresVerification || _isApproved) {
      return Row(
        children: [
          Expanded(
            child: ClientButton.secondary(
              label: context.l10n.payments_backToHome,
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClientButton(
              label: context.l10n.payments_trackVehicle,
              onPressed: () => Navigator.of(context).pushNamed(
                TrackingRoutes.tracking,
                arguments: {
                  if (widget.bookingId != null) 'bookingId': widget.bookingId,
                },
              ),
            ),
          ),
        ],
      );
    }
    if (_isRejected) {
      return Row(
        children: [
          Expanded(
            child: ClientButton.secondary(
              label: context.l10n.payments_backToHome,
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClientButton(
              label: context.l10n.payments_contactSupport,
              onPressed: () =>
                  Navigator.of(context).pushNamed(SupportRoutes.center),
            ),
          ),
        ],
      );
    }
    return ClientButton.secondary(
      label: context.l10n.payments_backToHome,
      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
    );
  }
}
