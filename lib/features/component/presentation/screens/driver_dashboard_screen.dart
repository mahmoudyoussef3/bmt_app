import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/widgets/widgets.dart' hide AppSpacing;

class CaptainDashboardScreen extends StatefulWidget {
  const CaptainDashboardScreen({super.key});

  @override
  State<CaptainDashboardScreen> createState() => _CaptainDashboardScreenState();
}

class _CaptainDashboardScreenState extends State<CaptainDashboardScreen> {
  String _activeTab = 'home';
  String _activeFlow = 'none';

  bool _isOnline = true;
  bool _hasAssignedTrips = true;

  // Selected trip mock details
  final String _assignedRoute = 'Banha Station → Smart Village';
  final String _departureTime = '8:40 AM';
  final String _vehicleSummary = 'Toyota Coaster · MT-2847';

  // Issue Reporting States
  String _selectedIssueCategory = '';
  final TextEditingController _issueDescriptionController =
      TextEditingController();
  bool _photoUploaded = false;

  // Mock list of passengers with check-in state
  late List<_Passenger> _passengers;
  _Passenger? _scannedPassenger;

  // Selected Filter for Passengers manifest: 'All', 'Checked In', 'Waiting', 'Absent'
  String _passengersFilter = 'All';

  // Mock earnings detailed view state
  _TripEarnings? _selectedEarnings;

  // Stop progression for live trip
  int _currentStopIndex =
      1; // 0: Banha Station, 1: Banha Downtown, 2: Smart Village
  final List<String> _stops = [
    'Banha Station',
    'Banha Downtown',
    'Smart Village',
  ];

  @override
  void initState() {
    super.initState();
    _resetData();
  }

  void _resetData() {
    _passengers = [
      _Passenger(
        name: 'Ahmed Hassan',
        seatNumber: '01',
        pickupStop: 'Banha Center',
        status: 'Boarded',
      ),
      _Passenger(
        name: 'Fatima Ali',
        seatNumber: '02',
        pickupStop: 'Banha Station',
        status: 'Boarded',
      ),
      _Passenger(
        name: 'Mohamed Karim',
        seatNumber: '03',
        pickupStop: 'Banha Center',
        status: 'Boarded',
      ),
      _Passenger(
        name: 'Noor Ibrahim',
        seatNumber: '04',
        pickupStop: 'Banha Downtown',
        status: 'Waiting',
      ),
      _Passenger(
        name: 'Hassan Youssef',
        seatNumber: '05',
        pickupStop: 'Banha Station',
        status: 'Waiting',
      ),
      _Passenger(
        name: 'Yasmine Amr',
        seatNumber: '06',
        pickupStop: 'Banha Station',
        status: 'Absent',
      ),
      _Passenger(
        name: 'Kareem Soliman',
        seatNumber: '07',
        pickupStop: 'Banha Center',
        status: 'Waiting',
      ),
      _Passenger(
        name: 'Mariam Ali',
        seatNumber: '08',
        pickupStop: 'Banha Downtown',
        status: 'Waiting',
      ),
      _Passenger(
        name: 'Tarek Mahmoud',
        seatNumber: '09',
        pickupStop: 'Banha Station',
        status: 'Waiting',
      ),
    ];
    _scannedPassenger = null;
    _selectedEarnings = null;
    _currentStopIndex = 1;
    _photoUploaded = false;
    _issueDescriptionController.clear();
  }

  @override
  void dispose() {
    _issueDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Check if we are inside a sub-flow (boarding manifest, scanner, active trip, etc.)
    if (_activeFlow != 'none') {
      return _buildSubFlow(context);
    }

    return Scaffold(
      backgroundColor: scheme.brightness == Brightness.light
          ? AppColors.background
          : AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.spaceLg,
                AppLayout.spaceXl,
                AppLayout.spaceLg,
                AppLayout.spaceLg,
              ),
              child: _CaptainHomeHeader(scheme),
            ),
            Expanded(
              child: IndexedStack(
                index: _indexForTab(_activeTab),
                children: [
                  _buildHomeTab(context, scheme),
                  _buildPassengersTab(context, scheme),
                  _buildEarningsTab(context, scheme),
                  _buildProfileTab(context, scheme),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, scheme),
    );
  }

  int _indexForTab(String tab) {
    switch (tab) {
      case 'passengers':
        return 1;
      case 'earnings':
        return 2;
      case 'profile':
        return 3;
      case 'home':
      default:
        return 0;
    }
  }

  // --- APP BAR ---

  Widget _buildStatusToggle(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.small + 2,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: _isOnline
            ? scheme.primary.withAlpha(20)
            : scheme.outline.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isOnline
              ? scheme.primary.withAlpha(80)
              : scheme.outline.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: AppTypography.caption(scheme).copyWith(
              fontWeight: FontWeight.w800,
              color: _isOnline
                  ? scheme.primary
                  : scheme.onSurface.withAlpha(150),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM NAVIGATION ---
  Widget _buildBottomNav(BuildContext context, ColorScheme scheme) {
    final tabs = <({String id, String label, IconData icon})>[
      (id: 'home', label: 'Home', icon: Icons.dashboard_rounded),
      (id: 'passengers', label: 'Passengers', icon: Icons.people_rounded),
      (id: 'earnings', label: 'Earnings', icon: Icons.payments_rounded),
      (id: 'profile', label: 'Profile', icon: Icons.person_rounded),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSpacing.large,
        0,
        AppSpacing.large,
        AppSpacing.medium,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppSpacing.small),
      child: Row(
        children: tabs.map((tab) {
          final isActive = _activeTab == tab.id;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = tab.id),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: AppSpacing.small),
                decoration: BoxDecoration(
                  color: isActive
                      ? scheme.primary.withAlpha(20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 22,
                      color: isActive
                          ? scheme.primary
                          : scheme.onSurface.withAlpha(140),
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      tab.label,
                      style: AppTypography.caption(scheme).copyWith(
                        color: isActive
                            ? scheme.primary
                            : scheme.onSurface.withAlpha(140),
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, ColorScheme scheme) {
    if (!_hasAssignedTrips) {
      return _buildNewDriverEmptyState(scheme);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.xSmall,
        AppSpacing.large,
        AppSpacing.xLarge,
      ),
      children: [
        // Driver Status card
        /* AppCard(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _isOnline
                    ? Colors.green.withAlpha(25)
                    : Colors.grey.withAlpha(25),
                child: Icon(
                  _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: _isOnline ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.medium + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnline ? 'Online Operational Mode' : 'Offline Mode',
                      style: AppTypography.subheading(
                        scheme,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      _isOnline
                          ? 'Receiving trip updates and passenger manifests.'
                          : 'Go online to view active trip assignments.',
                      style: AppTypography.caption(
                        scheme,
                      ).copyWith(color: scheme.onSurface.withAlpha(140)),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isOnline,
                activeColor: scheme.primary,
                onChanged: (val) => setState(() => _isOnline = val),
              ),
            ],
          ),
        ),
        */
        //  const SizedBox(height: AppSpacing.large),

        // Active / Current Assignment
        SectionHeader(
          title: 'Current Assignment',
          subtitle: _isOnline
              ? 'Assigned trip execution'
              : 'Offline (connect to start)',
        ),
        const SizedBox(height: AppSpacing.small),
        _buildCurrentAssignmentCard(scheme),
        const SizedBox(height: AppSpacing.xLarge),

        // Upcoming Assignment
        const SectionHeader(
          title: 'Upcoming Trip',
          subtitle: 'Scheduled next for today',
        ),
        const SizedBox(height: AppSpacing.small),
        _buildUpcomingAssignmentCard(scheme),
        const SizedBox(height: AppSpacing.xLarge),
        /*
        // Quick Actions
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppSpacing.small),
        _buildQuickActions(scheme),
       
        const SizedBox(height: AppSpacing.xLarge),
        */

        // Summary
        const SectionHeader(title: "Today's Summary"),
        const SizedBox(height: AppSpacing.small),
        _buildSummaryStats(scheme),
      ],
    );
  }

  Widget _buildCurrentAssignmentCard(ColorScheme scheme) {
    if (!_isOnline) {
      return AppCard(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.xLarge,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.lock_rounded,
                size: 28,
                color: scheme.onSurface.withAlpha(90),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Trip Locked',
                style: AppTypography.subheading(
                  scheme,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'Please toggle Online status to access active trips.',
                style: AppTypography.caption(
                  scheme,
                ).copyWith(color: scheme.onSurface.withAlpha(130)),
              ),
            ],
          ),
        ),
      );
    }

    final boardedCount = _passengers.where((p) => p.status == 'Boarded').length;
    final totalCount = _passengers.length;

    return AppCard(
      padding: EdgeInsets.all(AppSpacing.large + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.small + 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _assignedRoute,
                      style: AppTypography.subheading(
                        scheme,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      _vehicleSummary,
                      style: AppTypography.caption(
                        scheme,
                      ).copyWith(color: scheme.onSurface.withAlpha(140)),
                    ),
                  ],
                ),
              ),
              const AppBadge(text: 'On Time'),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Divider(height: 1, color: scheme.outline.withAlpha(50)),
          const SizedBox(height: AppSpacing.large),
          Row(
            children: [
              Expanded(
                child: _buildSmallDetailTile(
                  icon: Icons.access_time_rounded,
                  label: 'Departure',
                  val: _departureTime,
                  scheme: scheme,
                ),
              ),
              Expanded(
                child: _buildSmallDetailTile(
                  icon: Icons.people_rounded,
                  label: 'Passengers',
                  val: '$boardedCount / $totalCount Booked',
                  scheme: scheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large - 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Boarding Progress',
                style: AppTypography.caption(scheme).copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withAlpha(150),
                ),
              ),
              Text(
                '${(boardedCount / totalCount * 100).toInt()}% Checked In',
                style: AppTypography.caption(
                  scheme,
                ).copyWith(fontWeight: FontWeight.w800, color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          AppProgressBar(progress: boardedCount / totalCount),
          const SizedBox(height: AppSpacing.xLarge - 4),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Verify Boarding',
                  onPressed: () => setState(() => _activeFlow = 'boarding'),
                  height: 46,
                ),
              ),
              const SizedBox(width: AppSpacing.small + 2),
              Expanded(
                child: AppButton(
                  label: 'Start Trip',
                  onPressed: () => setState(() => _activeFlow = 'live_trip'),
                  outline: true,
                  height: 46,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDetailTile({
    required IconData icon,
    required String label,
    required String val,
    required ColorScheme scheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurface.withAlpha(120)),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption(scheme).copyWith(
                  color: scheme.onSurface.withAlpha(130),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                val,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  scheme,
                ).copyWith(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAssignmentCard(ColorScheme scheme) {
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.large),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.small + 2),
            decoration: BoxDecoration(
              color: scheme.onSurface.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: scheme.onSurface.withAlpha(140),
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Village → Banha Station',
                  style: AppTypography.subheading(
                    scheme,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'Departs 5:30 PM · Assigned Coaster',
                  style: AppTypography.caption(
                    scheme,
                  ).copyWith(color: scheme.onSurface.withAlpha(130)),
                ),
              ],
            ),
          ),
          const AppBadge(text: 'Assigned'),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme scheme) {
    final actions = [
      (
        label: 'Call Ops',
        icon: Icons.headset_mic_rounded,
        color: scheme.primary,
        action: () => _dialOps(context),
      ),
      (
        label: 'Report Issue',
        icon: Icons.report_problem_rounded,
        color: scheme.error,
        action: () => setState(() => _activeFlow = 'issue_categories'),
      ),
      (
        label: 'Support',
        icon: Icons.contact_support_rounded,
        color: scheme.secondary,
        action: () => _openSupportCenter(context),
      ),
    ];

    return Row(
      children: actions.map((act) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AppCard(
              padding: EdgeInsets.zero,
              onTap: act.action,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    Icon(act.icon, color: act.color, size: 24),
                    const SizedBox(height: AppSpacing.small - 2),
                    Text(
                      act.label,
                      style: AppTypography.caption(scheme).copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface.withAlpha(190),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryStats(ColorScheme scheme) {
    final stats = [
      (label: 'Trips Today', val: '1 / 2'),
      (label: 'Passengers', val: '9'),
      (label: 'Earnings', val: 'EGP 450'),
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Text(
                    stat.label,
                    style: AppTypography.caption(scheme).copyWith(
                      color: scheme.onSurface.withAlpha(140),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    stat.val,
                    style: AppTypography.subheading(scheme).copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNewDriverEmptyState(ColorScheme scheme) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xLarge),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyState(
              title: 'No trips assigned yet',
              subtitle:
                  'You do not have any trips assigned to you for today. Contact operations if this is an issue.',
              emoji: '🚍',
            ),
            const SizedBox(height: AppSpacing.xLarge),
            AppButton(
              label: 'Contact Operations',
              onPressed: () => _dialOps(context),
            ),
            const SizedBox(height: AppSpacing.small + 2),
            AppButton(
              label: 'Open Support Center',
              outline: true,
              onPressed: () => _openSupportCenter(context),
            ),
          ],
        ),
      ),
    );
  }

  void _dialOps(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Operations'),
        content: const Text(
          'Connecting to transportation operations and captain dispatch desk...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dial Now'),
          ),
        ],
      ),
    );
  }

  void _openSupportCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Captain Support Center'),
        content: const Text(
          'Loading help guides, documentation, FAQs, and ticket desk...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: PASSENGERS MANIFEST
  // ==========================================
  Widget _buildPassengersTab(BuildContext context, ColorScheme scheme) {
    final filtered = _passengers.where((p) {
      if (_passengersFilter == 'All') return true;
      if (_passengersFilter == 'Checked In') return p.status == 'Boarded';
      if (_passengersFilter == 'Waiting') return p.status == 'Waiting';
      if (_passengersFilter == 'Absent') return p.status == 'Absent';
      return true;
    }).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.large),
          // Filter Row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Checked In', 'Waiting', 'Absent'].map((
                      filter,
                    ) {
                      final isSel = _passengersFilter == filter;
                      return Padding(
                        padding: EdgeInsets.only(right: AppSpacing.small - 2),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _passengersFilter = filter);
                            }
                          },
                          selectedColor: scheme.primary.withAlpha(40),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? scheme.primary
                                : scheme.onSurface.withAlpha(160),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => setState(() => _resetData()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            'MANIFEST: ${filtered.length} Passengers (${_passengers.where((p) => p.status == 'Boarded').length} checked in)',
            style: AppTypography.caption(scheme).copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withAlpha(140),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: EmptyState(
                      title: 'No passengers found',
                      subtitle: 'Try changing the filters above.',
                      emoji: '👥',
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    padding: EdgeInsets.only(bottom: AppSpacing.xLarge),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.small),
                    itemBuilder: (context, index) {
                      return _buildPassengerCardItem(
                        context,
                        filtered[index],
                        scheme,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCardItem(
    BuildContext context,
    _Passenger passenger,
    ColorScheme scheme,
  ) {
    Color statusColor;
    switch (passenger.status) {
      case 'Boarded':
        statusColor = Colors.green;
        break;
      case 'Waiting':
        statusColor = Colors.orange;
        break;
      case 'Absent':
      default:
        statusColor = Colors.red;
    }

    return AppCard(
      padding: EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          // Seat Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withAlpha(80)),
            ),
            alignment: Alignment.center,
            child: Text(
              passenger.seatNumber,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: statusColor,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          // Name and station
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passenger.name,
                  style: AppTypography.body(
                    scheme,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'Pickup: ${passenger.pickupStop}',
                  style: AppTypography.caption(scheme).copyWith(
                    color: scheme.onSurface.withAlpha(130),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),

          // Check-in shortcut trigger if waiting
          if (passenger.status == 'Waiting')
            IconButton(
              icon: Icon(
                Icons.check_circle_outline_rounded,
                color: scheme.primary,
              ),
              onPressed: () {
                setState(() {
                  passenger.status = 'Boarded';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${passenger.name} checked in successfully'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),

          // Communication Buttons
          IconButton(
            icon: Icon(
              Icons.phone_rounded,
              color: scheme.primary.withAlpha(190),
              size: 20,
            ),
            onPressed: () {},
          ),
          StatusChip(label: passenger.status),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: EARNINGS MODULE
  // ==========================================
  Widget _buildEarningsTab(BuildContext context, ColorScheme scheme) {
    final tripEarnings = [
      _TripEarnings(
        route: 'Banha → Smart Village',
        date: 'Jun 4, 2026',
        time: '8:40 AM',
        base: 120,
        bonus: 30,
        passengersCount: 9,
      ),
      _TripEarnings(
        route: 'Smart Village → Banha',
        date: 'Jun 3, 2026',
        time: '5:30 PM',
        base: 120,
        bonus: 40,
        passengersCount: 12,
      ),
      _TripEarnings(
        route: 'Banha → Smart Village',
        date: 'Jun 3, 2026',
        time: '8:40 AM',
        base: 120,
        bonus: 30,
        passengersCount: 9,
      ),
      _TripEarnings(
        route: 'Smart Village → Banha',
        date: 'Jun 2, 2026',
        time: '5:30 PM',
        base: 120,
        bonus: 35,
        passengersCount: 11,
      ),
      _TripEarnings(
        route: 'Banha → Smart Village',
        date: 'Jun 2, 2026',
        time: '8:40 AM',
        base: 120,
        bonus: 25,
        passengersCount: 8,
      ),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.xLarge,
      ),
      children: [
        // Balance card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withAlpha(45)),
            gradient: LinearGradient(
              colors: [scheme.primary.withAlpha(25), scheme.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Total Month Earnings',
                style: AppTypography.caption(scheme).copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withAlpha(130),
                ),
              ),
              const SizedBox(height: AppSpacing.small - 2),
              Text(
                'EGP 11,200',
                style: AppTypography.display(scheme).copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'Calculated payout: Jun 10, 2026',
                style: AppTypography.caption(
                  scheme,
                ).copyWith(color: scheme.onSurface.withAlpha(120)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),

        // Summary row cards
        Row(
          children: [
            Expanded(
              child: _buildEarningStat(
                label: 'Today',
                val: 'EGP 450',
                scheme: scheme,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: _buildEarningStat(
                label: 'This Week',
                val: 'EGP 2,800',
                scheme: scheme,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: _buildEarningStat(
                label: 'This Month',
                val: 'EGP 11,200',
                scheme: scheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xLarge),

        // History
        SectionHeader(
          title: 'Trip Earnings History',
          subtitle: 'Detailed revenue records',
          action: TextButton(onPressed: () {}, child: const Text('Statements')),
        ),
        const SizedBox(height: AppSpacing.small),
        ...tripEarnings.map((earn) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.small),
            child: AppCard(
              padding: EdgeInsets.all(AppSpacing.medium + 2),
              onTap: () => setState(() => _selectedEarnings = earn),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primary.withAlpha(15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: scheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          earn.route,
                          style: AppTypography.subheading(
                            scheme,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          '${earn.date} · ${earn.time} · ${earn.passengersCount} passengers',
                          style: AppTypography.caption(
                            scheme,
                          ).copyWith(color: scheme.onSurface.withAlpha(130)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    'EGP ${earn.total}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xSmall),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurface.withAlpha(100),
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEarningStat({
    required String label,
    required String val,
    required ColorScheme scheme,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.caption(scheme).copyWith(
              color: scheme.onSurface.withAlpha(130),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            val,
            style: AppTypography.subheading(
              scheme,
            ).copyWith(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: PROFILE & SETTINGS
  // ==========================================
  Widget _buildProfileTab(BuildContext context, ColorScheme scheme) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.xLarge,
      ),
      children: [
        // Personal profile card
        AppCard(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Row(
            children: [
              AppAvatar(
                initials: 'AH',
                radius: 28,
                backgroundColor: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.medium + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahmed Hassan',
                      style: AppTypography.heading(
                        scheme,
                      ).copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      'Driver ID: CAPT-19482',
                      style: AppTypography.caption(scheme).copyWith(
                        color: scheme.onSurface.withAlpha(145),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Phone: +20 102 345 6789',
                      style: AppTypography.caption(
                        scheme,
                      ).copyWith(color: scheme.onSurface.withAlpha(120)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),

        // Settings Category Card
        const SectionHeader(title: 'App Settings'),
        const SizedBox(height: AppSpacing.small),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTile(
                icon: Icons.language_rounded,
                title: 'Language',
                trailing: Text(
                  'English',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    fontSize: 13,
                  ),
                ),
                scheme: scheme,
              ),
              Divider(height: 1, color: scheme.outline.withAlpha(40)),
              _buildListTile(
                icon: Icons.notifications_active_rounded,
                title: 'Push Notifications',
                trailing: Switch.adaptive(
                  value: true,
                  onChanged: (val) {},
                  activeColor: scheme.primary,
                ),
                scheme: scheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xLarge),

        // IDE Reviewer Panel
        const SectionHeader(
          title: 'IDE Review Config',
          subtitle: 'Switch application states for preview',
        ),
        const SizedBox(height: AppSpacing.small),
        AppCard(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simulation Panel',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.tertiary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'Toggle the state below to preview the empty dashboard state ("No trips assigned yet") during review.',
                style: AppTypography.caption(
                  scheme,
                ).copyWith(color: scheme.onSurface.withAlpha(130)),
              ),
              const SizedBox(height: AppSpacing.medium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trip Assignment State',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: scheme.onSurface,
                    ),
                  ),
                  ChoiceChip(
                    label: Text(
                      _hasAssignedTrips ? 'Active Assigned' : 'No Trips Empty',
                    ),
                    selected: _hasAssignedTrips,
                    onSelected: (val) {
                      setState(() {
                        _hasAssignedTrips = val;
                      });
                    },
                    selectedColor: scheme.primary.withAlpha(40),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xLarge),

        // Support desk
        const SectionHeader(title: 'Support & Help'),
        const SizedBox(height: AppSpacing.small),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTile(
                icon: Icons.contact_mail_rounded,
                title: 'Contact Operations Dispatch',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _dialOps(context),
                scheme: scheme,
              ),
              Divider(height: 1, color: scheme.outline.withAlpha(40)),
              _buildListTile(
                icon: Icons.help_center_rounded,
                title: 'Help Center & Guides',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openSupportCenter(context),
                scheme: scheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xLarge + 4),

        // Logout
        AppButton(
          label: 'Logout Captain Account',
          onPressed: () => Navigator.pop(context),
          outline: true,
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
    required ColorScheme scheme,
  }) {
    return ListTile(
      leading: Icon(icon, color: scheme.primary, size: 20),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  // ==========================================
  // SUB-FLOW ROUTING AND BUILDERS
  // ==========================================
  Widget _buildSubFlow(BuildContext context) {
    if (_selectedEarnings != null) {
      // Overridden by Earnings detail sheet popup
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEarningsDetailsSheet(context, _selectedEarnings!);
        setState(() {
          _selectedEarnings = null;
        });
      });
    }

    switch (_activeFlow) {
      case 'boarding':
        return _buildBoardingScreen(context);
      case 'qr_scanner':
        return _buildQRScannerScreen(context);
      case 'live_trip':
        return _buildLiveTripScreen(context);
      case 'issue_categories':
        return _buildIssueCategoriesScreen(context);
      case 'issue_details':
        return _buildIssueDetailsScreen(context);
      case 'issue_submitted':
        return _buildIssueSubmittedScreen(context);
      default:
        return Container();
    }
  }

  // --- SUB-FLOW 1: BOARDING MANIFEST SCREEN ---
  Widget _buildBoardingScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final waiting = _passengers.where((p) => p.status == 'Waiting').toList();
    final boarded = _passengers.where((p) => p.status == 'Boarded').toList();
    final absent = _passengers.where((p) => p.status == 'Absent').toList();

    return Scaffold(
      backgroundColor: scheme.brightness == Brightness.light
          ? AppColors.background
          : AppColors.backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _activeFlow = 'none'),
        ),
        title: const Text('Boarding Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _resetData()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar stats
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.large,
                vertical: AppSpacing.medium,
              ),
              color: scheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBoardingMetric(
                    'Waiting',
                    '${waiting.length}',
                    Colors.orange,
                    scheme,
                  ),
                  _buildBoardingMetric(
                    'Boarded',
                    '${boarded.length}',
                    Colors.green,
                    scheme,
                  ),
                  _buildBoardingMetric(
                    'Absent',
                    '${absent.length}',
                    Colors.red,
                    scheme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            // Trip overview
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.large),
              child: Text(
                'MANIFEST LIST · Tap passenger to quickly verify',
                style: AppTypography.caption(scheme).copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withAlpha(130),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            // Passengers List
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.large,
                  0,
                  AppSpacing.large,
                  AppSpacing.xLarge,
                ),
                itemCount: _passengers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.small),
                itemBuilder: (context, index) {
                  final passenger = _passengers[index];
                  Color stateColor = passenger.status == 'Boarded'
                      ? Colors.green
                      : passenger.status == 'Waiting'
                      ? Colors.orange
                      : Colors.red;

                  return AppCard(
                    padding: EdgeInsets.all(AppSpacing.medium),
                    onTap: () {
                      setState(() {
                        if (passenger.status == 'Waiting') {
                          passenger.status = 'Boarded';
                        } else if (passenger.status == 'Boarded') {
                          passenger.status = 'Absent';
                        } else {
                          passenger.status = 'Waiting';
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: stateColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: stateColor.withAlpha(80)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            passenger.seatNumber,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: stateColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                passenger.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                'Stop: ${passenger.pickupStop}',
                                style: TextStyle(
                                  color: scheme.onSurface.withAlpha(130),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              passenger.status,
                              style: TextStyle(
                                color: stateColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Icon(
                              passenger.status == 'Boarded'
                                  ? Icons.check_circle_rounded
                                  : passenger.status == 'Waiting'
                                  ? Icons.hourglass_empty_rounded
                                  : Icons.cancel_rounded,
                              color: stateColor,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Action buttons
            Container(
              padding: EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(color: scheme.outline.withAlpha(40)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Scan QR Ticket',
                      onPressed: () =>
                          setState(() => _activeFlow = 'qr_scanner'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small + 2),
                  Expanded(
                    child: AppButton(
                      label: 'Start Live Trip',
                      onPressed: () =>
                          setState(() => _activeFlow = 'live_trip'),
                      outline: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardingMetric(
    String label,
    String val,
    Color color,
    ColorScheme scheme,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption(scheme).copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withAlpha(140),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- SUB-FLOW 2: QR CODE VERIFIER SCANNER ---
  Widget _buildQRScannerScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final waiting = _passengers.where((p) => p.status == 'Waiting').toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() {
            _scannedPassenger = null;
            _activeFlow = 'boarding';
          }),
        ),
        title: const Text(
          'Scan Boarding Ticket',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xLarge),
            Text(
              'Verify Boarding Pass',
              style: AppTypography.heading(
                scheme,
              ).copyWith(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              'Align ticket QR code inside the box guide',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12.5,
              ),
            ),
            const Spacer(),

            // Viewfinder square guides
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.primary, width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  // Animated Scanning Line Mock
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Positioned(
                        top: 25 + (200 * value),
                        child: Container(
                          width: 230,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary,
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Simulation Controls
            if (_scannedPassenger == null) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.xLarge),
                padding: EdgeInsets.all(AppSpacing.medium + 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'MOCK SCAN SIMULATION',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    if (waiting.isEmpty)
                      const Text(
                        'All passengers checked in! Reset data to simulate.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.small,
                        runSpacing: AppSpacing.small,
                        children: waiting.take(3).map((p) {
                          return ActionChip(
                            label: Text(
                              'Scan ${p.name} (Seat ${p.seatNumber})',
                            ),
                            onPressed: () {
                              setState(() {
                                _scannedPassenger = p;
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large * 2),
            ] else ...[
              // Scanned Success Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.xLarge),
                padding: EdgeInsets.all(AppSpacing.large),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Text(
                          'Ticket Verified',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Seat 04',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.green,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium + 2),
                    Text(
                      _scannedPassenger!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    const Text(
                      'Route: Banha Station → Smart Village\nTrip ID: TRIP-MT-2847',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    AppButton(
                      label: 'Confirm Boarding Check-In',
                      onPressed: () {
                        setState(() {
                          _scannedPassenger!.status = 'Boarded';
                          _scannedPassenger = null;
                          _activeFlow = 'boarding';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passenger checked in successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xLarge),
            ],
          ],
        ),
      ),
    );
  }

  // --- SUB-FLOW 3: LIVE TRIP TRACKING EXPERIENCE ---
  Widget _buildLiveTripScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalPassengers = _passengers
        .where((p) => p.status == 'Boarded')
        .length;

    return Scaffold(
      backgroundColor: scheme.brightness == Brightness.light
          ? AppColors.background
          : AppColors.backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _activeFlow = 'none'),
        ),
        title: const Text('Live Trip Execution'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency_rounded, color: Colors.red),
            onPressed: () => _triggerEmergencySOS(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Trip route header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.large,
                vertical: AppSpacing.medium,
              ),
              color: scheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _assignedRoute,
                          style: AppTypography.subheading(
                            scheme,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Toyota Coaster MT-2847 · $totalPassengers onboard',
                          style: AppTypography.caption(
                            scheme,
                          ).copyWith(color: scheme.onSurface.withAlpha(140)),
                        ),
                      ],
                    ),
                  ),
                  const AppBadge(text: 'LIVE TRIP'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xSmall),

            // Map Placeholder
            const MapPlaceholder(height: 180),

            // Timeline Progression
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.large,
                AppSpacing.medium + 2,
                AppSpacing.large,
                AppSpacing.xSmall,
              ),
              child: Text(
                'STOPS TIMELINE PROGRESSION',
                style: AppTypography.caption(scheme).copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withAlpha(140),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.large),
                itemCount: _stops.length,
                itemBuilder: (context, index) {
                  final stop = _stops[index];
                  final isCompleted = index < _currentStopIndex;
                  final isActive = index == _currentStopIndex;

                  Color dotColor = isCompleted
                      ? Colors.green
                      : isActive
                      ? scheme.primary
                      : scheme.outline;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dots and vertical connector line
                      Column(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive
                                    ? scheme.primary.withAlpha(120)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          if (index < _stops.length - 1)
                            Container(
                              width: 2,
                              height: 38,
                              color: isCompleted
                                  ? Colors.green
                                  : scheme.outline.withAlpha(80),
                            ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.medium + 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop,
                              style: TextStyle(
                                fontWeight: (isActive || isCompleted)
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: (isActive || isCompleted)
                                    ? scheme.onSurface
                                    : scheme.onSurface.withAlpha(120),
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xSmall),
                            Text(
                              isCompleted
                                  ? 'Departed stop'
                                  : isActive
                                  ? 'Arrived / Passenger pickup active'
                                  : 'Upcoming Stop',
                              style: TextStyle(
                                color: isActive
                                    ? scheme.primary
                                    : scheme.onSurface.withAlpha(120),
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Operational controls panel
            Container(
              padding: EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(color: scheme.outline.withAlpha(45)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: _currentStopIndex == _stops.length - 1
                              ? 'Complete Active Trip'
                              : 'Arrive At Stop',
                          onPressed: () {
                            if (_currentStopIndex < _stops.length - 1) {
                              setState(() {
                                _currentStopIndex++;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Arrived at ${_stops[_currentStopIndex]}',
                                  ),
                                  backgroundColor: scheme.primary,
                                ),
                              );
                            } else {
                              setState(() {
                                _resetData();
                                _activeFlow = 'none';
                              });
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Trip Completed'),
                                  content: const Text(
                                    'Route Banha → Smart Village has been marked completed. Passengers dispatched successfully.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Done'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small + 2),
                      IconButton(
                        padding: EdgeInsets.all(AppSpacing.medium),
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.onSurface.withAlpha(15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          Icons.report_problem_rounded,
                          color: scheme.error,
                        ),
                        onPressed: () =>
                            setState(() => _activeFlow = 'issue_categories'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small + 2),
                  ElevatedButton(
                    onPressed: () => _triggerEmergencySOS(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'TRIGGER EMERGENCY SOS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerEmergencySOS(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirm Emergency SOS'),
          ],
        ),
        content: const Text(
          'Triggering Emergency SOS will alert dispatch Operations, safety teams, and emergency contacts. Are you in immediate danger?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'SOS Triggered. Operations dispatch team calling you immediately.',
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Trigger SOS'),
          ),
        ],
      ),
    );
  }

  // --- SUB-FLOW 4: ISSUE REPORTING FLOW ---
  Widget _buildIssueCategoriesScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = [
      (
        label: 'Vehicle Problem',
        desc: 'Engine failure, mechanical issue, tire puncture',
        icon: Icons.directions_bus_rounded,
      ),
      (
        label: 'Traffic Delay',
        desc: 'Accident block, congestion, slow road works',
        icon: Icons.traffic_rounded,
      ),
      (
        label: 'Passenger Problem',
        desc: 'Unruly behavior, passenger did not show up',
        icon: Icons.person_off_rounded,
      ),
      (
        label: 'Route Problem',
        desc: 'Closed highway, detour required, wrong mapping',
        icon: Icons.map_rounded,
      ),
      (
        label: 'Technical Problem',
        desc: 'App crashed, scanner failed, GPS issue',
        icon: Icons.phone_android_rounded,
      ),
      (
        label: 'Other',
        desc: 'Unforeseen incident, weather alert',
        icon: Icons.help_outline_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.brightness == Brightness.light
          ? AppColors.background
          : AppColors.backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _activeFlow = 'none'),
        ),
        title: const Text('Report an Issue'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.large),
              child: Text(
                'SELECT ISSUE CATEGORY',
                style: AppTypography.caption(scheme).copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withAlpha(140),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.large,
                  0,
                  AppSpacing.large,
                  AppSpacing.xLarge,
                ),
                itemCount: categories.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.small),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return AppCard(
                    padding: EdgeInsets.all(AppSpacing.medium + 2),
                    onTap: () {
                      setState(() {
                        _selectedIssueCategory = cat.label;
                        _activeFlow = 'issue_details';
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.primary.withAlpha(15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            cat.icon,
                            color: scheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium + 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xSmall),
                              Text(
                                cat.desc,
                                style: TextStyle(
                                  color: scheme.onSurface.withAlpha(130),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurface.withAlpha(100),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueDetailsScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.brightness == Brightness.light
          ? AppColors.background
          : AppColors.backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _activeFlow = 'issue_categories'),
        ),
        title: const Text('Incident Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'REPORTING CATEGORY',
                style: AppTypography.caption(scheme).copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withAlpha(140),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.large - 2,
                  vertical: AppSpacing.medium,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.primary.withAlpha(35)),
                ),
                child: Text(
                  _selectedIssueCategory,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                    fontSize: 14.5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xLarge),

              Text(
                'DESCRIPTION OF INCIDENT',
                style: AppTypography.caption(scheme).copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withAlpha(140),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              TextField(
                controller: _issueDescriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Describe details of the issue, delays, vehicle status...',
                  fillColor: scheme.surface,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: scheme.outline.withAlpha(50)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xLarge),

              Text(
                'ATTACH PHOTO (OPTIONAL)',
                style: AppTypography.caption(scheme).copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withAlpha(140),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              InkWell(
                onTap: () {
                  setState(() {
                    _photoUploaded = true;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.outline.withAlpha(40),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: _photoUploaded
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                              ),
                              const SizedBox(width: AppSpacing.small),
                              Text(
                                'Photo Attached successfully',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_a_photo_rounded,
                                color: scheme.primary,
                                size: 28,
                              ),
                              const SizedBox(height: AppSpacing.small),
                              Text(
                                'Upload incident picture',
                                style: TextStyle(
                                  color: scheme.onSurface.withAlpha(140),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xLarge * 1.3),

              AppButton(
                label: 'Submit Incident Report',
                onPressed: () {
                  setState(() {
                    _activeFlow = 'issue_submitted';
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueSubmittedScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.brightness == Brightness.light
          ? AppColors.background
          : AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xLarge),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.xLarge),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
                const SizedBox(height: AppSpacing.xLarge),
                Text(
                  'Issue Report Submitted',
                  style: AppTypography.heading(scheme).copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.small + 2),
                Text(
                  'The dispatch desk and customer operations team have been notified. We will review your submission and contact you via dispatcher interface shortly.',
                  style: AppTypography.caption(scheme).copyWith(
                    color: scheme.onSurface.withAlpha(140),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xLarge * 1.3),
                AppButton(
                  label: 'Return to console dashboard',
                  onPressed: () {
                    setState(() {
                      _resetData();
                      _activeFlow = 'none';
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- EARNINGS DETAIL SHEET MODAL ---
  void _showEarningsDetailsSheet(BuildContext context, _TripEarnings earn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet handle indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline.withAlpha(90),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              Text(
                'Trip Revenue Breakdown',
                style: AppTypography.heading(scheme).copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xLarge),

              _buildDetailSheetRow(
                'Route',
                earn.route,
                scheme,
                boldValue: true,
              ),
              _buildDetailSheetRow('Scheduled Date', earn.date, scheme),
              _buildDetailSheetRow('Time Of Trip', earn.time, scheme),
              _buildDetailSheetRow(
                'Passengers Transported',
                '${earn.passengersCount} passengers',
                scheme,
              ),
              _buildDetailSheetRow(
                'Assigned Vehicle',
                'Toyota Coaster MT-2847',
                scheme,
              ),

              const SizedBox(height: AppSpacing.medium),
              Divider(height: 1, color: scheme.outline.withAlpha(50)),
              const SizedBox(height: AppSpacing.medium),

              _buildDetailSheetRow(
                'Base Earning',
                'EGP ${earn.base}.00',
                scheme,
              ),
              _buildDetailSheetRow(
                'Boarding Completion Bonus',
                'EGP ${earn.bonus}.00',
                scheme,
              ),

              const SizedBox(height: AppSpacing.medium),
              Container(
                padding: EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL EARNINGS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'EGP ${earn.total}.00',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              AppButton(
                label: 'Close Details',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSheetRow(
    String label,
    String value,
    ColorScheme scheme, {
    bool boldValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface.withAlpha(130),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: boldValue ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// --- DATA CLASSES MOCKS ---
class _Passenger {
  final String name;
  final String seatNumber;
  final String pickupStop;
  String status; // 'Boarded', 'Waiting', 'Absent'

  _Passenger({
    required this.name,
    required this.seatNumber,
    required this.pickupStop,
    required this.status,
  });
}

class _TripEarnings {
  final String route;
  final String date;
  final String time;
  final double base;
  final double bonus;
  final int passengersCount;

  _TripEarnings({
    required this.route,
    required this.date,
    required this.time,
    required this.base,
    required this.bonus,
    required this.passengersCount,
  });

  double get total => base + bonus;
}

class _CaptainHomeHeader extends StatelessWidget {
  const _CaptainHomeHeader(this.scheme);
  final ColorScheme scheme;
  final String captainName = 'Captain Ahmed';
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $captainName 👋',
                style: AppTypography.display(
                  scheme,
                ).copyWith(fontSize: 24, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 4),

              Text(
                'You have 3 scheduled trips today',
                style: AppTypography.caption(
                  scheme,
                ).copyWith(color: scheme.onSurface.withAlpha(160)),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outline.withAlpha(60)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
