import 'dart:async';
import 'dart:math' as math;
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/seat_release_data.dart';
import '../cubit/seat_release_cubit.dart';
import '../cubit/seat_release_state.dart';

class NotificationItem {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;

  const NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
  });
}

// Particle physics for Confetti celebration
class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.22; // Gravity
    vx *= 0.98; // Drag
    rotation += rotationSpeed;
  }
}

class SeatReleaseScreen extends StatefulWidget {
  const SeatReleaseScreen({super.key});

  @override
  State<SeatReleaseScreen> createState() => _SeatReleaseScreenState();
}

class _SeatReleaseScreenState extends State<SeatReleaseScreen>
    with TickerProviderStateMixin {
  // Views:
  // 1 = Seat Release Dashboard
  // 2 = Release Seat Form
  // 4 = Release Success Screen
  // 5 = Release Details Screen
  // 6 = Compensation Status Screen
  // 7 = Release History Screen
  // 8 = Notifications Feed Panel
  // 9 = Loyalty & Achievements Portal
  int _currentView = 1;

  // Active package details
  String _packageName = '';
  String _packageType = '';
  String _packageRoute = '';
  String _startDate = '';
  String _endDate = '';
  String _packageStatus = '';

  // Stats
  int _remainingDays = 0;
  int _releasedSeatsThisMonth = 0;
  int _successfullyRebookedSeats = 0;
  int _totalCompensationEarned = 0; // EGP

  // Form states
  UpcomingTrip? _selectedTripForRelease;
  String _selectedReason = 'Personal Plans';
  final TextEditingController _notesController = TextEditingController();

  // Active details record
  SeatReleaseRecord? _activeRecord;

  // History states
  String _historyFilter = 'All'; // 'All', 'Waiting', 'Rebooked', 'Rewarded'
  final TextEditingController _historySearchController =
      TextEditingController();
  String _historySearchQuery = '';

  // Confetti celebration particles
  final List<ConfettiParticle> _particles = [];
  Timer? _confettiTimer;

  // Reasons list
  List<String> _reasons = [];

  // Upcoming trips
  List<UpcomingTrip> _upcomingTrips = [];

  // Past release records
  List<SeatReleaseRecord> _pastReleases = [];

  // Seat-release status notifications derived from loaded account state.
  List<NotificationItem> _notifications = [];

  bool _seatReleaseDataApplied = false;
  bool _notificationsSeeded = false;

  @override
  void initState() {
    super.initState();
    context.read<SeatReleaseCubit>().load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notificationsSeeded) return;
    _notificationsSeeded = true;
    final l10n = context.l10n;
    _notifications = [
      NotificationItem(
        title: l10n.seatRelease_notifCompensationAddedTitle,
        body: l10n.seatRelease_notifCompensationAddedBody,
        time: l10n.seatRelease_timeYesterday,
        icon: Icons.payments_outlined,
        color: ClientColors.journeyCyan,
      ),
      NotificationItem(
        title: l10n.seatRelease_notifRebookedTitle,
        body: l10n.seatRelease_notifRebookedBody,
        time: l10n.seatRelease_timeDaysAgo(2),
        icon: Icons.check_circle_outline_rounded,
        color: Colors.blue,
      ),
      NotificationItem(
        title: l10n.seatRelease_notifReleasedTitle,
        body: l10n.seatRelease_notifReleasedBody(
          '6',
          l10n.seatRelease_mockTripDateJun2,
        ),
        time: l10n.seatRelease_timeDaysAgo(3),
        icon: Icons.event_busy_rounded,
        color: Colors.orangeAccent,
      ),
    ];
  }

  @override
  void dispose() {
    _notesController.dispose();
    _historySearchController.dispose();
    _confettiTimer?.cancel();
    super.dispose();
  }

  // --- ACTIONS ---

  void _onBackPress() {
    if (_currentView == 4) {
      // Return from success to dashboard
      setState(() => _currentView = 1);
    } else if (_currentView > 1) {
      setState(() => _currentView = 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  String _getViewTitle() {
    final l10n = context.l10n;
    return switch (_currentView) {
      1 => l10n.seatRelease_hubTitle,
      2 => l10n.seatRelease_formTitle,
      4 => l10n.seatRelease_successTitle,
      5 => l10n.seatRelease_detailsTitle,
      6 => l10n.seatRelease_compensationTitle,
      7 => l10n.seatRelease_historyTitle,
      8 => l10n.seatRelease_notificationsTitle,
      9 => l10n.seatRelease_achievementsTitle,
      _ => l10n.seatRelease_portalTitle,
    };
  }

  void _triggerConfetti() {
    final random = math.Random();
    _particles.clear();
    for (int i = 0; i < 90; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final speed = 4 + random.nextDouble() * 11;
      _particles.add(
        ConfettiParticle(
          x: MediaQuery.of(context).size.width / 2,
          y: MediaQuery.of(context).size.height / 3,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 6,
          size: 6 + random.nextDouble() * 8,
          color: Colors.primaries[random.nextInt(Colors.primaries.length)],
          rotation: random.nextDouble() * math.pi,
          rotationSpeed: -0.1 + random.nextDouble() * 0.2,
        ),
      );
    }

    _confettiTimer?.cancel();
    _confettiTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        for (var p in _particles) {
          p.update();
        }
        _particles.removeWhere((p) => p.y > MediaQuery.of(context).size.height);
      });
      if (_particles.isEmpty) {
        timer.cancel();
      }
    });
  }

  void _openConfirmationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final l10n = context.l10n;
        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.seatRelease_confirmSheetTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.seatRelease_confirmSheetBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ClientColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ClientColors.borderFor(context)),
                ),
                child: Column(
                  children: [
                    _buildConfirmationRow(
                      l10n.seatRelease_tripDateLabel,
                      _selectedTripForRelease!.date,
                    ),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                      l10n.seatRelease_routeSegmentLabel,
                      _packageRoute,
                    ),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                      l10n.seatRelease_seatNumberLabel,
                      l10n.home_seatLabel(_selectedTripForRelease!.seatNumber),
                    ),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                      l10n.seatRelease_packageOriginLabel,
                      _packageName,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.error.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.error.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: scheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.seatRelease_confirmSheetWarning,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.seatRelease_goBack),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClientButton(
                      label: l10n.seatRelease_confirmReleaseButton,
                      expand: true,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _submitRelease();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _submitRelease() {
    if (_selectedTripForRelease == null) return;
    final l10n = context.l10n;

    final newRecord = SeatReleaseRecord(
      releaseId: 'REL-${math.Random().nextInt(90000) + 10000}',
      releaseDate: l10n.seatRelease_mockReleaseDateToday,
      tripDate: _selectedTripForRelease!.date,
      route: _packageRoute,
      seatNumber: _selectedTripForRelease!.seatNumber,
      reason: _selectedReason,
      notes: _notesController.text.trim().isEmpty
          ? l10n.seatRelease_noNotesProvided
          : _notesController.text.trim(),
      status: 'Waiting',
    );

    // Add to history list, remove from upcoming list, trigger confetti
    setState(() {
      _pastReleases.insert(0, newRecord);
      _upcomingTrips.removeWhere((t) => t.id == _selectedTripForRelease!.id);
      _releasedSeatsThisMonth++;
      _activeRecord = newRecord;

      // Add to notifications
      _notifications.insert(
        0,
        NotificationItem(
          title: l10n.seatRelease_notifReleasedTitle,
          body: l10n.seatRelease_notifReleasedBody(
            newRecord.seatNumber,
            newRecord.tripDate,
          ),
          time: l10n.seatRelease_timeJustNow,
          icon: Icons.event_busy_rounded,
          color: Colors.orangeAccent,
        ),
      );

      _notesController.clear();
      _currentView = 4; // success view
    });

    _triggerConfetti();
  }

  // --- RENDERS ---

  void _applySeatReleaseData(SeatReleaseLoaded state) {
    if (_seatReleaseDataApplied) return;

    final data = state.data;
    _packageName = data.packageName;
    _packageType = data.packageType;
    _packageRoute = data.packageRoute;
    _startDate = data.startDate;
    _endDate = data.endDate;
    _packageStatus = data.packageStatus;
    _remainingDays = data.remainingDays;
    _releasedSeatsThisMonth = data.releasedSeatsThisMonth;
    _successfullyRebookedSeats = data.successfullyRebookedSeats;
    _totalCompensationEarned = data.totalCompensationEarned;
    _reasons = List<String>.from(data.reasons);
    _upcomingTrips = List<UpcomingTrip>.from(data.upcomingTrips);
    _pastReleases = List<SeatReleaseRecord>.from(data.pastReleases);
    _seatReleaseDataApplied = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<SeatReleaseCubit, SeatReleaseState>(
      builder: (context, state) {
        if (state is SeatReleaseLoaded) {
          _applySeatReleaseData(state);
        }

        if (state is SeatReleaseError && !_seatReleaseDataApplied) {
          return Scaffold(
            backgroundColor: scheme.surfaceContainerHighest,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        if (!_seatReleaseDataApplied) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        return Scaffold(
          backgroundColor: scheme.surfaceContainerHighest,
          appBar: AppBar(
            title: Text(
              _getViewTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            leading: IconButton(
              onPressed: _onBackPress,
              icon: const DirectionalIcon(Icons.arrow_back_rounded),
            ),
            actions: [
              IconButton(
                tooltip: context.l10n.tracking_refresh,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => context.read<SeatReleaseCubit>().load(),
              ),
            ],
            elevation: 0,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                // Core Screens
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildCurrentView(scheme),
                ),

                // Confetti Overlay
                if (_particles.isNotEmpty)
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: ConfettiPainter(_particles),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentView(ColorScheme scheme) {
    return switch (_currentView) {
      1 => _buildDashboardView(scheme),
      2 => _buildReleaseSeatForm(scheme),
      4 => _buildSuccessView(scheme),
      5 => _buildDetailsView(scheme),
      6 => _buildCompensationStatusView(scheme),
      7 => _buildHistoryView(scheme),
      8 => _buildNotificationsView(scheme),
      9 => _buildLoyaltyAchievementsView(scheme),
      _ => const SizedBox.shrink(),
    };
  }

  // --- SCREEN 1: SEAT RELEASE DASHBOARD ---
  Widget _buildDashboardView(ColorScheme scheme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        // Header active package card
        _buildPackageHeaderCard(scheme),
        const SizedBox(height: 18),

        // Quick Stats Section
        _buildStatsGrid(scheme),
        const SizedBox(height: 20),

        // Custom Quick Links row
        _buildDashboardQuickLinks(scheme),
        const SizedBox(height: 24),

        // Upcoming trips list header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.seatRelease_upcomingReservedSeatsTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildUpcomingTripsList(scheme),
      ],
    );
  }

  Widget _buildPackageHeaderCard(ColorScheme scheme) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(50),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _packageTypeLabel(l10n),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClientColors.journeyCyanStrong.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 3,
                      backgroundColor: ClientColors.journeyCyanStrong,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _packageStatusLabel(l10n),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.journeyCyanStrong,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _packageName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _packageRoute,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const Divider(height: 24, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.seatRelease_validityRangeLabel,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_startDate → $_endDate',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.seatRelease_seatNoLabel,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.home_seatLabel('6'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// [_packageType] is sourced from the data layer as a stable English
  /// label; this maps the known values to localized copy for display.
  String _packageTypeLabel(AppLocalizations l10n) {
    if (_packageType == 'Subscription package') {
      return l10n.seatRelease_packageTypeSubscription;
    }
    return _packageType;
  }

  /// [_packageStatus] is sourced from the data layer as a stable English
  /// label; this maps the known values to localized copy for display.
  String _packageStatusLabel(AppLocalizations l10n) {
    return switch (_packageStatus) {
      'Active' => l10n.seatRelease_packageStatusActive,
      'No subscription' => l10n.seatRelease_packageStatusNone,
      _ => _packageStatus,
    };
  }

  Widget _buildStatsGrid(ColorScheme scheme) {
    final l10n = context.l10n;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildStatCard(
          l10n.seatRelease_statRemainingDays,
          l10n.seatRelease_daysCount(_remainingDays),
          Icons.calendar_month_outlined,
          scheme.secondary,
        ),
        _buildStatCard(
          l10n.seatRelease_statReleasedSeats,
          '$_releasedSeatsThisMonth',
          Icons.event_busy_outlined,
          Colors.orangeAccent,
        ),
        _buildStatCard(
          l10n.seatRelease_statRebookedSeats,
          '$_successfullyRebookedSeats',
          Icons.check_circle_outline_rounded,
          ClientColors.journeyCyan,
        ),
        _buildStatCard(
          l10n.seatRelease_statEarnedReward,
          l10n.seatRelease_egpAmount('$_totalCompensationEarned'),
          Icons.payments_outlined,
          scheme.primary,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDashboardQuickLinks(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickLinkButton(
            icon: Icons.history_rounded,
            label: context.l10n.seatRelease_quickLinkReleaseLogs,
            color: ClientColors.journeyCyan,
            onTap: () => setState(() => _currentView = 7),
            scheme: scheme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickLinkButton(
            icon: Icons.star_border_purple500_rounded,
            label: context.l10n.seatRelease_quickLinkRewardsStats,
            color: Colors.indigo,
            onTap: () => setState(() => _currentView = 9),
            scheme: scheme,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinkButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTripsList(ColorScheme scheme) {
    if (_upcomingTrips.isEmpty) {
      return ClientErrorCard.fullScreen(
        message: context.l10n.seatRelease_noUpcomingTripsMessage,
      );
    }

    return Column(
      children: _upcomingTrips.map((trip) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withAlpha(45)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          trip.date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      trip.departureTime,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Route line
                Row(
                  children: [
                    Column(
                      children: [
                        const CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.grey,
                        ),
                        Container(width: 1, height: 12, color: Colors.grey),
                        const CircleAvatar(
                          radius: 4,
                          backgroundColor: ClientColors.journeyCyan,
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.pickup,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trip.destination,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.airline_seat_recline_normal_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.home_seatLabel(trip.seatNumber),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            // Find and show details of that date if it exists
                            final recordIdx = _pastReleases.indexWhere(
                              (r) => r.tripDate == trip.date,
                            );
                            if (recordIdx != -1) {
                              setState(() {
                                _activeRecord = _pastReleases[recordIdx];
                                _currentView = 5;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context
                                        .l10n
                                        .seatRelease_noPastRecordSnackbar,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            context.l10n.seatRelease_viewLogsButton,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedTripForRelease = trip;
                              _currentView = 2; // form screen
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            backgroundColor: scheme.primary,
                          ),
                          child: Text(
                            context.l10n.seatRelease_releaseSeatButton,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- SCREEN 2: RELEASE SEAT FORM ---
  Widget _buildReleaseSeatForm(ColorScheme scheme) {
    if (_selectedTripForRelease == null) return const SizedBox.shrink();
    final trip = _selectedTripForRelease!;
    final l10n = context.l10n;

    return Column(
      key: const ValueKey('view2'),
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Trip Preview Card
              _buildTripSummaryCard(trip, scheme),
              const SizedBox(height: 18),

              // Release info card explanation
              _buildReleaseExplanationCard(scheme),
              const SizedBox(height: 18),

              // Warning alert
              _buildReleaseWarningAlert(scheme),
              const SizedBox(height: 18),

              // Selectable Chips for Reason
              Text(
                l10n.seatRelease_reasonSectionTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              _buildReasonChips(scheme),
              const SizedBox(height: 18),

              // Multi-line optional notes
              Text(
                l10n.seatRelease_optionalNotesTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.seatRelease_notesHint,
                  fillColor: scheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Benefits section
              Text(
                l10n.seatRelease_whyReleaseTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              _buildBenefitsInfographic(scheme),
            ],
          ),
        ),

        // Sticky bottom action buttons
        _buildReleaseFormActionRow(scheme),
      ],
    );
  }

  Widget _buildTripSummaryCard(UpcomingTrip trip, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trip.date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.home_seatLabel(trip.seatNumber),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _packageRoute,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '${trip.departureTime} • ${trip.vehicle}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseExplanationCard(ColorScheme scheme) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.blueAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.seatRelease_releasingTemporaryTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.seatRelease_releasingTemporaryBody,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseWarningAlert(ColorScheme scheme) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.error.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.error.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.seatRelease_thresholdTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.seatRelease_thresholdBody,
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.error.withAlpha(200),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reason values are sourced from the data layer as stable English
  /// labels; this maps the known values to localized copy for display.
  String _reasonLabel(String reason) {
    final l10n = context.l10n;
    return switch (reason.trim().toLowerCase()) {
      'personal plans' => l10n.seatRelease_reasonPersonalPlans,
      'working from home' => l10n.seatRelease_reasonWorkFromHome,
      'vacation' => l10n.seatRelease_reasonVacation,
      'alternative transport' => l10n.seatRelease_reasonAlternativeTransport,
      'medical reason' => l10n.seatRelease_reasonMedical,
      'other' => l10n.seatRelease_reasonOther,
      _ => reason,
    };
  }

  Widget _buildReasonChips(ColorScheme scheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _reasons.map((reason) {
        final isSelected = _selectedReason == reason;
        return ChoiceChip(
          label: Text(
            _reasonLabel(reason),
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
          selected: isSelected,
          selectedColor: scheme.primary,
          backgroundColor: scheme.surface,
          onSelected: (val) {
            if (val) setState(() => _selectedReason = reason);
          },
        );
      }).toList(),
    );
  }

  Widget _buildBenefitsInfographic(ColorScheme scheme) {
    final l10n = context.l10n;
    return Column(
      children: [
        _buildBenefitItem(
          Icons.volunteer_activism_outlined,
          l10n.seatRelease_benefitCommunityTitle,
          l10n.seatRelease_benefitCommunityBody,
          scheme,
        ),
        const SizedBox(height: 10),
        _buildBenefitItem(
          Icons.card_giftcard_rounded,
          l10n.seatRelease_benefitCompensationTitle,
          l10n.seatRelease_benefitCompensationBody,
          scheme,
        ),
        const SizedBox(height: 10),
        _buildBenefitItem(
          Icons.eco_outlined,
          l10n.seatRelease_benefitOptimizeTitle,
          l10n.seatRelease_benefitOptimizeBody,
          scheme,
        ),
      ],
    );
  }

  Widget _buildBenefitItem(
    IconData icon,
    String title,
    String body,
    ColorScheme scheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseFormActionRow(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(55))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _currentView = 1),
                child: Text(context.l10n.common_cancel),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ClientButton(
                label: context.l10n.seatRelease_releaseSeatButton,
                expand: true,
                onPressed: _openConfirmationSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SCREEN 4: RELEASE SUCCESS SCREEN ---
  Widget _buildSuccessView(ColorScheme scheme) {
    if (_activeRecord == null) return const SizedBox.shrink();
    final rec = _activeRecord!;
    final l10n = context.l10n;

    return Center(
      key: const ValueKey('view4'),
      child: ListView(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          // Elastic checkmark animation simulation
          const CircleAvatar(
            radius: 36,
            backgroundColor: ClientColors.journeyCyan,
            child: Icon(Icons.check_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.seatRelease_successHeadline,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.seatRelease_referenceCodeLabel(rec.releaseId),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Released details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: Column(
              children: [
                _buildConfirmationRow(
                  l10n.seatRelease_releasedDateLabel,
                  rec.tripDate,
                ),
                const SizedBox(height: 8),
                _buildConfirmationRow(
                  l10n.seatRelease_commuteSegmentLabel,
                  rec.route,
                ),
                const SizedBox(height: 8),
                _buildConfirmationRow(
                  l10n.seatRelease_seatNumberLabel,
                  l10n.home_seatLabel(rec.seatNumber),
                ),
                const SizedBox(height: 8),
                _buildConfirmationRow(
                  l10n.seatRelease_packageSourceLabel,
                  _packageName,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Next steps warning card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.primary.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(Icons.stars_rounded, color: scheme.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.seatRelease_autoNotifyBody,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Actions
          ClientButton(
            label: l10n.seatRelease_viewReleaseDetailsButton,
            expand: true,
            onPressed: () => setState(() => _currentView = 5),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _currentView = 1),
            child: Text(l10n.seatRelease_returnToDashboardButton),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 5: RELEASE DETAILS SCREEN ---
  Widget _buildDetailsView(ColorScheme scheme) {
    if (_activeRecord == null) return const SizedBox.shrink();
    final rec = _activeRecord!;
    final l10n = context.l10n;

    return ListView(
      key: const ValueKey('view5'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Main details info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.seatRelease_idLabel(rec.releaseId),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  _buildStatusChip(rec.status, scheme),
                ],
              ),
              const Divider(height: 24),
              _buildDetailInfoRow(l10n.seatRelease_tripDateLabel, rec.tripDate),
              const SizedBox(height: 6),
              _buildDetailInfoRow(l10n.packages_route, rec.route),
              const SizedBox(height: 6),
              _buildDetailInfoRow(
                l10n.seatRelease_releasedSeatLabel,
                l10n.home_seatLabel(rec.seatNumber),
              ),
              const SizedBox(height: 6),
              _buildDetailInfoRow(
                l10n.seatRelease_reasonChosenLabel,
                _reasonLabel(rec.reason),
              ),
              const SizedBox(height: 6),
              _buildDetailInfoRow(
                l10n.seatRelease_submitDateLabel,
                rec.releaseDate,
              ),
              if (rec.notes.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  l10n.seatRelease_notesLabel,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.notes,
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Beautiful vertical status timeline
        Text(
          l10n.seatRelease_statusTimelineTitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 14),
        _buildStatusTimeline(rec.status, scheme),

        const SizedBox(height: 30),
        // Go back CTA
        ClientButton(
          label: l10n.seatRelease_backToDashboardButton,
          expand: true,
          onPressed: () => setState(() => _currentView = 1),
        ),
      ],
    );
  }

  Widget _buildDetailInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Status values are sourced from the data layer as stable English codes
  /// (also used for business-logic comparisons); this maps the known
  /// values to localized copy for display only.
  String _statusLabel(String status) {
    final l10n = context.l10n;
    return switch (status) {
      'Waiting' => l10n.seatRelease_statusWaiting,
      'Rebooked' => l10n.seatRelease_statusRebooked,
      'Rewarded' => l10n.seatRelease_statusRewarded,
      'Closed' => l10n.seatRelease_statusClosed,
      _ => status,
    };
  }

  Widget _buildStatusChip(String status, ColorScheme scheme) {
    Color col = Colors.grey;
    if (status == 'Rewarded') col = scheme.primary;
    if (status == 'Rebooked') col = Colors.blue;
    if (status == 'Waiting') col = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: col.withAlpha(24),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: col),
      ),
    );
  }

  Widget _buildStatusTimeline(String activeStatus, ColorScheme scheme) {
    final l10n = context.l10n;
    final steps = [
      l10n.seatRelease_timelineStepReleased,
      l10n.seatRelease_timelineStepWaiting,
      l10n.seatRelease_timelineStepRebooked,
      l10n.seatRelease_notifCompensationAddedTitle,
    ];

    int activeIdx = 0;
    if (activeStatus == 'Waiting') activeIdx = 1;
    if (activeStatus == 'Rebooked') activeIdx = 2;
    if (activeStatus == 'Rewarded' || activeStatus == 'Closed') activeIdx = 3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: List.generate(steps.length, (idx) {
          final isDone = idx < activeIdx;
          final isCurrent = idx == activeIdx;
          final isFuture = idx > activeIdx;

          Color stepColor = Colors.grey;
          if (isDone) stepColor = ClientColors.journeyCyan;
          if (isCurrent) stepColor = scheme.primary;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? stepColor
                            : isDone
                            ? stepColor
                            : Colors.transparent,
                        border: Border.all(
                          color: stepColor,
                          width: isCurrent ? 4 : 2,
                        ),
                      ),
                      child: isDone
                          ? const Center(
                              child: Icon(
                                Icons.check,
                                size: 8,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    if (idx < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isDone
                              ? ClientColors.journeyCyan
                              : scheme.outline.withAlpha(80),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[idx],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isFuture ? Colors.grey : scheme.onSurface,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 4),
                          Text(
                            _getTimelineStepDescription(idx),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getTimelineStepDescription(int index) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n.seatRelease_timelineReleasedDesc,
      1 => l10n.seatRelease_timelineWaitingDesc,
      2 => l10n.seatRelease_timelineRebookedDesc,
      3 => l10n.seatRelease_timelineRewardedDesc,
      _ => '',
    };
  }

  // --- SCREEN 6: COMPENSATION STATUS SCREEN ---
  Widget _buildCompensationStatusView(ColorScheme scheme) {
    if (_activeRecord == null) return const SizedBox.shrink();
    final rec = _activeRecord!;
    final l10n = context.l10n;

    return ListView(
      key: const ValueKey('view6'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.seatRelease_referenceLabel(rec.releaseId),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.seatRelease_compensationStatusLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildStatusChip(rec.status, scheme),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Status Card type
        _buildCompensationDetailsCard(rec, scheme),
        const SizedBox(height: 24),

        ClientButton(
          label: l10n.seatRelease_backToDashboardButton,
          expand: true,
          onPressed: () => setState(() => _currentView = 1),
        ),
      ],
    );
  }

  Widget _buildCompensationDetailsCard(
    SeatReleaseRecord rec,
    ColorScheme scheme,
  ) {
    final l10n = context.l10n;
    if (rec.status == 'Waiting') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withAlpha(45)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              color: Colors.orangeAccent,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.seatRelease_timelineStepWaiting,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.seatRelease_compWaitingBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    if (rec.status == 'Rebooked') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withAlpha(45)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.blue,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.seatRelease_notifRebookedTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.seatRelease_compRebookedBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    // Rewarded Fintech Voucher Card
    final amt = rec.compensationAmount ?? l10n.seatRelease_egpAmount('50');
    final date = rec.rewardDate ?? l10n.common_today;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withAlpha(30),
            scheme.secondary.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.seatRelease_compensationCreditedLabel,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(Icons.stars_rounded, color: scheme.primary, size: 20),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          const SizedBox(height: 10),
          Text(
            amt,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.seatRelease_creditedToWalletLabel,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.seatRelease_clearingDateLabel(date),
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: ClientColors.journeyCyanStrong,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.seatRelease_transactionClearedLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ClientColors.journeyCyanStrong,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 7: RELEASE HISTORY SCREEN ---
  Widget _buildHistoryView(ColorScheme scheme) {
    final filtered = _pastReleases.where((item) {
      final matchesSearch =
          item.tripDate.toLowerCase().contains(
            _historySearchQuery.toLowerCase(),
          ) ||
          item.route.toLowerCase().contains(_historySearchQuery.toLowerCase());
      if (!matchesSearch) return false;

      return switch (_historyFilter) {
        'Waiting' => item.status == 'Waiting',
        'Rebooked' => item.status == 'Rebooked',
        'Rewarded' => item.status == 'Rewarded',
        'All' || _ => true,
      };
    }).toList();

    return Column(
      key: const ValueKey('view7'),
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            controller: _historySearchController,
            onChanged: (val) => setState(() => _historySearchQuery = val),
            decoration: InputDecoration(
              hintText: context.l10n.seatRelease_historySearchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              fillColor: scheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        // Filter chips row
        _buildHistoryFilterChips(scheme),

        // List
        Expanded(
          child: filtered.isEmpty
              ? ClientErrorCard.fullScreen(
                  message: context.l10n.seatRelease_noHistoryRecordsMessage,
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: ClientColors.borderFor(context)),
                  itemBuilder: (context, idx) {
                    final log = filtered[idx];
                    return _buildHistoryLogTile(log, scheme);
                  },
                ),
        ),
      ],
    );
  }

  /// 'All' is a filter-only value with no matching status code.
  String _historyFilterLabel(String filter) {
    if (filter == 'All') return context.l10n.seatRelease_filterAll;
    return _statusLabel(filter);
  }

  Widget _buildHistoryFilterChips(ColorScheme scheme) {
    final filters = ['All', 'Waiting', 'Rebooked', 'Rewarded'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSel = _historyFilter == f;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8.0),
            child: ChoiceChip(
              label: Text(
                _historyFilterLabel(f),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              selected: isSel,
              selectedColor: scheme.primary,
              backgroundColor: scheme.surface,
              onSelected: (val) {
                if (val) setState(() => _historyFilter = f);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryLogTile(SeatReleaseRecord log, ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _activeRecord = log;
                _currentView = 5; // details
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_busy_rounded,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.tripDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.route,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        log.compensationAmount != null
                            ? '+ ${log.compensationAmount}'
                            : context.l10n.seatRelease_egpAmount('0'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: log.compensationAmount != null
                              ? scheme.primary
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(log.status, scheme),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- SCREEN 8: NOTIFICATION PANEL ---
  Widget _buildNotificationsView(ColorScheme scheme) {
    return ListView(
      key: const ValueKey('view8'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.seatRelease_alertHistoryLogTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _notifications.clear()),
              child: Text(
                context.l10n.seatRelease_clearAllButton,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_notifications.isEmpty)
          ClientErrorCard.fullScreen(
            message: context.l10n.seatRelease_noNotificationsMessage,
          )
        else
          ..._notifications.map((n) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outline.withAlpha(45)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: n.color.withAlpha(20),
                    child: Icon(n.icon, color: n.color, size: 16),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.body,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n.time,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // --- SCREEN 9: LOYALTY & ACHIEVEMENTS ---
  Widget _buildLoyaltyAchievementsView(ColorScheme scheme) {
    final l10n = context.l10n;
    return ListView(
      key: const ValueKey('view9'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Achievements summary box
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary.withAlpha(40),
                scheme.secondary.withAlpha(20),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.primary.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.seatRelease_achievementsHeaderTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAchievementCountTile(
                    l10n.seatRelease_tileSeatsReleased,
                    '$_releasedSeatsThisMonth',
                    Icons.event_busy_outlined,
                  ),
                  _buildAchievementCountTile(
                    l10n.seatRelease_tileRebookedSuccessfully,
                    '$_successfullyRebookedSeats',
                    Icons.check_circle_outline_rounded,
                  ),
                  _buildAchievementCountTile(
                    l10n.seatRelease_tileRewardsEarned,
                    l10n.seatRelease_egpAmount('$_totalCompensationEarned'),
                    Icons.payments_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          l10n.seatRelease_unlockableBadgesTitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),

        // Badges progress indicators
        _buildAchievementProgressTile(
          title: l10n.seatRelease_badgeEcoTitle,
          subtitle: l10n.seatRelease_badgeEcoSubtitle,
          progress: _releasedSeatsThisMonth / 5,
          progressText: l10n.seatRelease_badgeProgressReleased(
            _releasedSeatsThisMonth,
          ),
          icon: Icons.eco_outlined,
          color: ClientColors.journeyCyan,
          scheme: scheme,
        ),
        const SizedBox(height: 12),
        _buildAchievementProgressTile(
          title: l10n.seatRelease_badgeCommunityTitle,
          subtitle: l10n.seatRelease_badgeCommunitySubtitle,
          progress: _successfullyRebookedSeats / 3,
          progressText: l10n.seatRelease_badgeProgressRebooked(
            _successfullyRebookedSeats,
          ),
          icon: Icons.volunteer_activism_outlined,
          color: Colors.pinkAccent,
          scheme: scheme,
        ),
        const SizedBox(height: 12),
        _buildAchievementProgressTile(
          title: l10n.seatRelease_badgeRewardTitle,
          subtitle: l10n.seatRelease_badgeRewardSubtitle,
          progress: _totalCompensationEarned / 200,
          progressText: l10n.seatRelease_badgeProgressReward(
            '$_totalCompensationEarned',
          ),
          icon: Icons.emoji_events_outlined,
          color: Colors.orangeAccent,
          scheme: scheme,
        ),
      ],
    );
  }

  Widget _buildAchievementCountTile(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
      ],
    );
  }

  Widget _buildAchievementProgressTile({
    required String title,
    required String subtitle,
    required double progress,
    required String progressText,
    required IconData icon,
    required Color color,
    required ColorScheme scheme,
  }) {
    final double boundedProgress = math.min(progress, 1.0);
    final isDone = boundedProgress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isDone)
                      const Icon(
                        Icons.verified_rounded,
                        color: ClientColors.journeyCyan,
                        size: 14,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: boundedProgress,
                    minHeight: 5,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    progressText,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Confetti painter canvas particle renderer
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size / 1.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}
