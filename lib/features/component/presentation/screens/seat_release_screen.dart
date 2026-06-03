import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

// --- DATA STRUCTURES ---
class UpcomingTrip {
  final String id;
  final String date;
  final String pickup;
  final String destination;
  final String departureTime;
  final String vehicle;
  final String seatNumber;
  final bool isReleased;

  const UpcomingTrip({
    required this.id,
    required this.date,
    required this.pickup,
    required this.destination,
    required this.departureTime,
    required this.vehicle,
    required this.seatNumber,
    this.isReleased = false,
  });
}

class SeatReleaseRecord {
  final String releaseId;
  final String releaseDate;
  final String tripDate;
  final String route;
  final String seatNumber;
  final String reason;
  final String notes;
  final String status; // 'Waiting', 'Rebooked', 'Rewarded', 'Closed'
  final String? compensationType; // 'Cashback', 'WalletCredit', 'LoyaltyPoints'
  final String? compensationAmount;
  final String? rewardDate;

  const SeatReleaseRecord({
    required this.releaseId,
    required this.releaseDate,
    required this.tripDate,
    required this.route,
    required this.seatNumber,
    required this.reason,
    required this.notes,
    required this.status,
    this.compensationType,
    this.compensationAmount,
    this.rewardDate,
  });
}

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
  final String _packageName = 'Monthly VIP Commute';
  final String _packageType = 'Premium Package';
  final String _packageRoute = 'Cairo Center ↔ Banha Express';
  final String _startDate = 'May 20, 2026';
  final String _endDate = 'Jun 20, 2026';
  final String _packageStatus = 'Active';

  // Stats
  final int _remainingDays = 16;
  int _releasedSeatsThisMonth = 3;
  final int _successfullyRebookedSeats = 2;
  final int _totalCompensationEarned = 150; // EGP

  // Empty state simulator toggle
  bool _showEmptyState = false;

  // Form states
  UpcomingTrip? _selectedTripForRelease;
  String _selectedReason = 'Personal Plans';
  final TextEditingController _notesController = TextEditingController();

  // Active details record
  SeatReleaseRecord? _activeRecord;

  // History states
  String _historyFilter = 'All'; // 'All', 'Waiting', 'Rebooked', 'Rewarded'
  final TextEditingController _historySearchController = TextEditingController();
  String _historySearchQuery = '';

  // Confetti celebration particles
  final List<ConfettiParticle> _particles = [];
  Timer? _confettiTimer;

  // Reasons list
  final List<String> _reasons = const [
    'Personal Plans',
    'Working From Home',
    'Vacation',
    'Transportation Alternative',
    'Medical Reason',
    'Other',
  ];

  // Mock list of upcoming trips
  late List<UpcomingTrip> _upcomingTrips;

  // Mock list of past release records
  late List<SeatReleaseRecord> _pastReleases;

  // Mock list of notifications
  late List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();

    _upcomingTrips = [
      const UpcomingTrip(id: 't1', date: 'Tomorrow, Jun 4', pickup: 'Cairo Center (Tahrir SQ)', destination: 'Banha Station (Gate 2)', departureTime: '08:00 AM', vehicle: 'MB-15-2847 (Comfort Van)', seatNumber: '6'),
      const UpcomingTrip(id: 't2', date: 'Friday, Jun 5', pickup: 'Cairo Center (Tahrir SQ)', destination: 'Banha Station (Gate 2)', departureTime: '08:00 AM', vehicle: 'MB-15-2847 (Comfort Van)', seatNumber: '6'),
      const UpcomingTrip(id: 't3', date: 'Monday, Jun 8', pickup: 'Cairo Center (Tahrir SQ)', destination: 'Banha Station (Gate 2)', departureTime: '08:00 AM', vehicle: 'MB-15-2847 (Comfort Van)', seatNumber: '6'),
      const UpcomingTrip(id: 't4', date: 'Tuesday, Jun 9', pickup: 'Cairo Center (Tahrir SQ)', destination: 'Banha Station (Gate 2)', departureTime: '08:00 AM', vehicle: 'MB-15-2847 (Comfort Van)', seatNumber: '6'),
    ];

    _pastReleases = [
      const SeatReleaseRecord(
        releaseId: 'REL-82049',
        releaseDate: 'Jun 01, 2026',
        tripDate: 'Jun 02, 2026',
        route: 'Cairo Center → Banha Station',
        seatNumber: '6',
        reason: 'Working From Home',
        notes: 'Decided to stay home on Tuesday.',
        status: 'Rewarded',
        compensationType: 'Cashback',
        compensationAmount: 'EGP 50',
        rewardDate: 'Jun 02, 2026, 09:30 AM',
      ),
      const SeatReleaseRecord(
        releaseId: 'REL-19385',
        releaseDate: 'May 24, 2026',
        tripDate: 'May 25, 2026',
        route: 'Cairo Center → Banha Station',
        seatNumber: '6',
        reason: 'Personal Plans',
        notes: 'Had a dentist appointment.',
        status: 'Rewarded',
        compensationType: 'WalletCredit',
        compensationAmount: 'EGP 100',
        rewardDate: 'May 25, 2026, 08:45 AM',
      ),
      const SeatReleaseRecord(
        releaseId: 'REL-28401',
        releaseDate: 'May 19, 2026',
        tripDate: 'May 20, 2026',
        route: 'Cairo Center → Banha Station',
        seatNumber: '6',
        reason: 'Vacation',
        notes: 'Short family getaway. Seat was not rebooked.',
        status: 'Closed',
      ),
    ];

    _notifications = [
      const NotificationItem(
        title: 'Compensation Added',
        body: 'Your released seat on Jun 2 was rebooked. EGP 50 cashback credited to your wallet!',
        time: 'Yesterday',
        icon: Icons.payments_outlined,
        color: Colors.green,
      ),
      const NotificationItem(
        title: 'Seat Rebooked Successfully',
        body: 'A passenger has booked your released seat for the trip on Jun 2.',
        time: '2 days ago',
        icon: Icons.check_circle_outline_rounded,
        color: Colors.blue,
      ),
      const NotificationItem(
        title: 'Seat Released Successfully',
        body: 'You successfully released your seat (Seat 6) for the Jun 2 trip.',
        time: '3 days ago',
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
    return switch (_currentView) {
      1 => 'Seat Release Hub',
      2 => 'Release Reserved Seat',
      4 => 'Seat Released Successfully',
      5 => 'Release Record Details',
      6 => 'Compensation Tracking',
      7 => 'Seat Release Logs',
      8 => 'Alerts Notifications',
      9 => 'Milestones & Achievements',
      _ => 'Seat Release Portal',
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
        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text('Confirm Seat Release', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Please confirm you want to release your seat for this specific trip. Released seats cannot be reclaimed once booked by other passengers.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 20),
              AppSurface(
                color: scheme.surface,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildConfirmationRow('Trip Date', _selectedTripForRelease!.date),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Route Segment', _packageRoute),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Seat Number', 'Seat ${_selectedTripForRelease!.seatNumber}'),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Package Origin', _packageName),
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
                    Icon(Icons.warning_amber_rounded, color: scheme.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This action affects only this selected trip date. Future commute dates remain unaffected.',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: scheme.error),
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
                      child: const Text('Go Back'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppButton(
                      label: 'Confirm Release',
                      onPressed: () {
                        Navigator.of(context).pop();
                        _submitRelease();
                      },
                    ),
                  ),
                ],
              )
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
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _submitRelease() {
    if (_selectedTripForRelease == null) return;

    final newRecord = SeatReleaseRecord(
      releaseId: 'REL-${math.Random().nextInt(90000) + 10000}',
      releaseDate: 'Today, Jun 3',
      tripDate: _selectedTripForRelease!.date,
      route: _packageRoute,
      seatNumber: _selectedTripForRelease!.seatNumber,
      reason: _selectedReason,
      notes: _notesController.text.trim().isEmpty ? 'No notes provided' : _notesController.text.trim(),
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
          title: 'Seat Released Successfully',
          body: 'You successfully released your seat (Seat ${newRecord.seatNumber}) for the ${newRecord.tripDate} trip.',
          time: 'Just now',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text(
          _getViewTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          onPressed: _onBackPress,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
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
            const Text(
              'Upcoming Reserved Seats',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
            ),
            // Simulator toggle
            TextButton.icon(
              onPressed: () => setState(() => _showEmptyState = !_showEmptyState),
              icon: Icon(_showEmptyState ? Icons.visibility : Icons.visibility_off, size: 14),
              label: Text(_showEmptyState ? 'Show Trips' : 'Mock Empty State', style: const TextStyle(fontSize: 10)),
            )
          ],
        ),
        const SizedBox(height: 10),
        _buildUpcomingTripsList(scheme),
      ],
    );
  }

  Widget _buildPackageHeaderCard(ColorScheme scheme) {
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
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  _packageType,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.greenAccent.withAlpha(50), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 3, backgroundColor: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text(
                      _packageStatus,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _packageName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
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
                  const Text('VALIDITY RANGE', style: TextStyle(fontSize: 8, color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                   Text('$_startDate → $_endDate', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('SEAT NO.', style: TextStyle(fontSize: 8, color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text('Seat 6', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ColorScheme scheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildStatCard('Remaining Days', '$_remainingDays Days', Icons.calendar_month_outlined, scheme.secondary),
        _buildStatCard('Released Seats', '$_releasedSeatsThisMonth', Icons.event_busy_outlined, Colors.orangeAccent),
        _buildStatCard('Rebooked Seats', '$_successfullyRebookedSeats', Icons.check_circle_outline_rounded, Colors.green),
        _buildStatCard('Earned Reward', 'EGP $_totalCompensationEarned', Icons.payments_outlined, scheme.primary),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
            label: 'Release Logs',
            color: Colors.teal,
            onTap: () => setState(() => _currentView = 7),
            scheme: scheme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickLinkButton(
            icon: Icons.star_border_purple500_rounded,
            label: 'Rewards & Stats',
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
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTripsList(ColorScheme scheme) {
    if (_showEmptyState || _upcomingTrips.isEmpty) {
      return const EmptyState(
        title: 'No upcoming package trips',
        subtitle: 'All upcoming seats are active, or no remaining days remain.',
        emoji: '📅',
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
                        const Icon(Icons.event_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(trip.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Text(trip.departureTime, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                // Route line
                Row(
                  children: [
                    Column(
                      children: [
                        const CircleAvatar(radius: 4, backgroundColor: Colors.grey),
                        Container(width: 1, height: 12, color: Colors.grey),
                        const CircleAvatar(radius: 4, backgroundColor: Colors.green),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trip.pickup, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(trip.destination, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
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
                        const Icon(Icons.airline_seat_recline_normal_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Seat ${trip.seatNumber}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            // Find and show details of that date if it exists
                            final recordIdx = _pastReleases.indexWhere((r) => r.tripDate == trip.date);
                            if (recordIdx != -1) {
                              setState(() {
                                _activeRecord = _pastReleases[recordIdx];
                                _currentView = 5;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No past release record exists for this date.')),
                              );
                            }
                          },
                          child: const Text('View Logs', style: TextStyle(fontSize: 11)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            backgroundColor: scheme.primary,
                          ),
                          child: const Text('Release Seat', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    )
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
              const Text('Reason for Releasing Seat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildReasonChips(scheme),
              const SizedBox(height: 18),

              // Multi-line optional notes
              const Text('Optional Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'E.g., Working from home on Thursday...',
                  fillColor: scheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),

              // Benefits section
              const Text('Why release your seat?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
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
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(trip.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: scheme.primary.withAlpha(24), borderRadius: BorderRadius.circular(8)),
                child: Text('Seat ${trip.seatNumber}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: scheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_packageRoute, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('${trip.departureTime} • ${trip.vehicle}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildReleaseExplanationCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Releasing is Temporary',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'You are releasing your reserved seat for this trip date only. Your package subscription remains active and future trip bookings return automatically.',
                  style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.35),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReleaseWarningAlert(ColorScheme scheme) {
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
                  '12-Hour Threshold Requirement',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: scheme.error),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seat release is only available if submitted at least 12 hours before trip departure. Late requests will not be accepted.',
                  style: TextStyle(fontSize: 10, color: scheme.error.withAlpha(200), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonChips(ColorScheme scheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _reasons.map((reason) {
        final isSelected = _selectedReason == reason;
        return ChoiceChip(
          label: Text(
            reason,
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
    return Column(
      children: [
        _buildBenefitItem(Icons.volunteer_activism_outlined, 'Help the Community', 'Released seats become available for other passengers needing daily rides.', scheme),
        const SizedBox(height: 10),
        _buildBenefitItem(Icons.card_giftcard_rounded, 'Earn Compensation', 'Receive wallet cashback or loyalty rewards if another commuter books your seat.', scheme),
        const SizedBox(height: 10),
        _buildBenefitItem(Icons.eco_outlined, 'Optimize Route Utilization', 'Helps BMT optimize fleet load and reduce carbon emissions.', scheme),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String body, ColorScheme scheme) {
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
            decoration: BoxDecoration(color: scheme.primary.withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, color: scheme.primary, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.3)),
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
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppButton(
                label: 'Release Seat',
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
            backgroundColor: Colors.green,
            child: Icon(Icons.check_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 24),
          const Text(
            'Seat Released Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Reference Code: ${rec.releaseId}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Released details card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildConfirmationRow('Released Date', rec.tripDate),
                const SizedBox(height: 8),
                _buildConfirmationRow('Commute Segment', rec.route),
                const SizedBox(height: 8),
                _buildConfirmationRow('Seat Number', 'Seat ${rec.seatNumber}'),
                const SizedBox(height: 8),
                _buildConfirmationRow('Package Source', _packageName),
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
                const Expanded(
                  child: Text(
                    'We will automatically notify you and credit rewards to your wallet once your seat gets rebooked by other commuters.',
                    style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Actions
          AppButton(
            label: 'View Release Details',
            onPressed: () => setState(() => _currentView = 5),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _currentView = 1),
            child: const Text('Return to Dashboard'),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 5: RELEASE DETAILS SCREEN ---
  Widget _buildDetailsView(ColorScheme scheme) {
    if (_activeRecord == null) return const SizedBox.shrink();
    final rec = _activeRecord!;

    return ListView(
      key: const ValueKey('view5'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Main details info card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ID: ${rec.releaseId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  _buildStatusChip(rec.status, scheme),
                ],
              ),
              const Divider(height: 24),
              _buildDetailInfoRow('Trip Date', rec.tripDate),
              const SizedBox(height: 6),
              _buildDetailInfoRow('Route', rec.route),
              const SizedBox(height: 6),
              _buildDetailInfoRow('Released Seat', 'Seat ${rec.seatNumber}'),
              const SizedBox(height: 6),
              _buildDetailInfoRow('Reason Chosen', rec.reason),
              const SizedBox(height: 6),
              _buildDetailInfoRow('Submit Date', rec.releaseDate),
              if (rec.notes.isNotEmpty) ...[
                const Divider(height: 24),
                const Text('Notes', style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(rec.notes, style: const TextStyle(fontSize: 12, height: 1.35)),
              ]
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Beautiful vertical status timeline
        const Text('Release Status Timeline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 14),
        _buildStatusTimeline(rec.status, scheme),

        const SizedBox(height: 30),
        // Go back CTA
        AppButton(
          label: 'Back to Dashboard',
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
          child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, ColorScheme scheme) {
    Color col = Colors.grey;
    if (status == 'Rewarded') col = scheme.primary;
    if (status == 'Rebooked') col = Colors.blue;
    if (status == 'Waiting') col = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: col.withAlpha(24), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: col)),
    );
  }

  Widget _buildStatusTimeline(String activeStatus, ColorScheme scheme) {
    final steps = [
      'Seat Released',
      'Waiting For Rebooking',
      'Rebooked Successfully',
      'Compensation Added',
    ];

    int activeIdx = 0;
    if (activeStatus == 'Waiting') activeIdx = 1;
    if (activeStatus == 'Rebooked') activeIdx = 2;
    if (activeStatus == 'Rewarded' || activeStatus == 'Closed') activeIdx = 3;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(steps.length, (idx) {
          final isDone = idx < activeIdx;
          final isCurrent = idx == activeIdx;
          final isFuture = idx > activeIdx;

          Color stepColor = Colors.grey;
          if (isDone) stepColor = Colors.green;
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
                        color: isCurrent ? stepColor : isDone ? stepColor : Colors.transparent,
                        border: Border.all(color: stepColor, width: isCurrent ? 4 : 2),
                      ),
                      child: isDone
                          ? const Center(child: Icon(Icons.check, size: 8, color: Colors.white))
                          : null,
                    ),
                    if (idx < steps.length - 1)
                      Expanded(
                        child: Container(width: 2, color: isDone ? Colors.green : scheme.outline.withAlpha(80)),
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
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isFuture ? Colors.grey : scheme.onSurface,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 4),
                          Text(
                            _getTimelineStepDescription(idx),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ]
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
    return switch (index) {
      0 => 'Your seat has been released for commute pools.',
      1 => 'Seat is currently listed. Waiting for other daily passenger bookings.',
      2 => 'Seat was successfully rebooked by another commuter.',
      3 => 'Compensation reward credited directly to your wallet account.',
      _ => '',
    };
  }

  // --- SCREEN 6: COMPENSATION STATUS SCREEN ---
  Widget _buildCompensationStatusView(ColorScheme scheme) {
    if (_activeRecord == null) return const SizedBox.shrink();
    final rec = _activeRecord!;

    return ListView(
      key: const ValueKey('view6'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reference: ${rec.releaseId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  const Text('Compensation status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

        AppButton(
          label: 'Back to Dashboard',
          onPressed: () => setState(() => _currentView = 1),
        ),
      ],
    );
  }

  Widget _buildCompensationDetailsCard(SeatReleaseRecord rec, ColorScheme scheme) {
    if (rec.status == 'Waiting') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withAlpha(45)),
        ),
        child: const Column(
          children: [
            Icon(Icons.hourglass_empty_rounded, color: Colors.orangeAccent, size: 48),
            SizedBox(height: 14),
            Text('Waiting For Rebooking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 6),
            Text(
              'Your seat is listed for daily commuters. If another passenger books this seat prior to departure, you will unlock your reward instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
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
        child: const Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.blue, size: 48),
            SizedBox(height: 14),
            Text('Seat Rebooked Successfully', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 6),
            Text(
              'Your seat was successfully purchased. We are currently processing your compensation points clearance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      );
    }

    // Rewarded Fintech Voucher Card
    final amt = rec.compensationAmount ?? 'EGP 50';
    final date = rec.rewardDate ?? 'Today';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary.withAlpha(30), scheme.secondary.withAlpha(20)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('COMPENSATION CREDITED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Icon(Icons.stars_rounded, color: scheme.primary, size: 20),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          const SizedBox(height: 10),
          Text(amt, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: scheme.primary)),
          const SizedBox(height: 4),
          const Text('Credited to Account Wallet', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('Clearing date: $date', style: const TextStyle(fontSize: 9, color: Colors.grey)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withAlpha(24), borderRadius: BorderRadius.circular(10)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, color: Colors.greenAccent, size: 14),
                SizedBox(width: 6),
                Text('Transaction Cleared Successfully', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- SCREEN 7: RELEASE HISTORY SCREEN ---
  Widget _buildHistoryView(ColorScheme scheme) {
    final filtered = _pastReleases.where((item) {
      final matchesSearch = item.tripDate.toLowerCase().contains(_historySearchQuery.toLowerCase()) ||
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
              hintText: 'Search release logs by date, route...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              fillColor: scheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),

        // Filter chips row
        _buildHistoryFilterChips(scheme),

        // List
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  title: 'No release records found',
                  subtitle: 'Try adjusting your filters or search query.',
                  emoji: '📂',
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const AppSeparator(),
                  itemBuilder: (context, idx) {
                    final log = filtered[idx];
                    return _buildHistoryLogTile(log, scheme);
                  },
                ),
        ),
      ],
    );
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
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                f,
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
                    decoration: BoxDecoration(color: scheme.primary.withAlpha(20), shape: BoxShape.circle),
                    child: const Icon(Icons.event_busy_rounded, color: Colors.grey, size: 16),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.tripDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(log.route, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        log.compensationAmount != null ? '+ ${log.compensationAmount}' : 'EGP 0',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: log.compensationAmount != null ? scheme.primary : Colors.grey,
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
            const Text('Alert History Log', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
            TextButton(
              onPressed: () => setState(() => _notifications.clear()),
              child: const Text('Clear All', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_notifications.isEmpty)
          const EmptyState(
            title: 'No new notifications',
            subtitle: 'You are completely caught up.',
            emoji: '🔔',
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
                        Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(n.body, style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.35)),
                        const SizedBox(height: 6),
                        Text(n.time, style: const TextStyle(fontSize: 9, color: Colors.grey)),
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
    return ListView(
      key: const ValueKey('view9'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Achievements summary box
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [scheme.primary.withAlpha(40), scheme.secondary.withAlpha(20)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.primary.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Seat Release Achievements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAchievementCountTile('Seats Released', '$_releasedSeatsThisMonth', Icons.event_busy_outlined),
                  _buildAchievementCountTile('Rebooked Successfully', '$_successfullyRebookedSeats', Icons.check_circle_outline_rounded),
                  _buildAchievementCountTile('Rewards Earned', 'EGP $_totalCompensationEarned', Icons.payments_outlined),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text('Unlockable Badges', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),

        // Badges progress indicators
        _buildAchievementProgressTile(
          title: 'Eco Commuter Tier I',
          subtitle: 'Release 5 seats to reduce shuttle overhead fuel.',
          progress: _releasedSeatsThisMonth / 5,
          progressText: '$_releasedSeatsThisMonth/5 Released',
          icon: Icons.eco_outlined,
          color: Colors.green,
          scheme: scheme,
        ),
        const SizedBox(height: 12),
        _buildAchievementProgressTile(
          title: 'Community Helper Gold',
          subtitle: 'Help 3 other commuters find seats.',
          progress: _successfullyRebookedSeats / 3,
          progressText: '$_successfullyRebookedSeats/3 Rebooked',
          icon: Icons.volunteer_activism_outlined,
          color: Colors.pinkAccent,
          scheme: scheme,
        ),
        const SizedBox(height: 12),
        _buildAchievementProgressTile(
          title: 'Reward Collector Level 2',
          subtitle: 'Accumulate EGP 200 in released rewards.',
          progress: _totalCompensationEarned / 200,
          progressText: 'EGP $_totalCompensationEarned/EGP 200',
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
        Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
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
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
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
                    Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    if (isDone)
                      const Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                  alignment: Alignment.centerRight,
                  child: Text(
                    progressText,
                    style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
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
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size / 1.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}
