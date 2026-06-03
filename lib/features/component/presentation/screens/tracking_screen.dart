import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/widgets/live_status_badge.dart';

enum TripState {
  notStarted,
  driverOnWay,
  boarding,
  inProgress,
  completed,
}

class TrackingScreen extends StatefulWidget {
  final bool shellMode;

  const TrackingScreen({super.key, this.shellMode = false});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {
  TripState _currentState = TripState.notStarted;
  late final AnimationController _mapAnimationController;
  late final AnimationController _pulseController;
  
  // Interactive ratings for State 5
  int _driverRating = 0;
  int _vehicleRating = 0;
  int _routeRating = 0;

  // Mock Route Points for winding path across the map
  final List<Offset> _routePoints = const [
    Offset(0.15, 0.85), // 0: Driver Start
    Offset(0.22, 0.72), // 1
    Offset(0.35, 0.65), // 2: Pickup (Banha Station)
    Offset(0.48, 0.58), // 3
    Offset(0.55, 0.45), // 4: Stop 1 (Nasr City)
    Offset(0.62, 0.38), // 5
    Offset(0.72, 0.30), // 6: Stop 2 (Heliopolis)
    Offset(0.82, 0.22), // 7
    Offset(0.90, 0.12), // 8: Destination (Smart Village)
  ];

  // Map state to human-readable labels
  String get _stateTitle {
    switch (_currentState) {
      case TripState.notStarted:
        return 'Trip Status';
      case TripState.driverOnWay:
        return 'Driver on the Way';
      case TripState.boarding:
        return 'Boarding Started';
      case TripState.inProgress:
        return 'Trip in Progress';
      case TripState.completed:
        return 'Trip Completed';
    }
  }

  @override
  void initState() {
    super.initState();
    _mapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mapAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _changeState(TripState state) {
    setState(() {
      _currentState = state;
      // Reset ratings when entering completed state
      if (state == TripState.completed) {
        _driverRating = 0;
        _vehicleRating = 0;
        _routeRating = 0;
      }
    });
  }

  // Calculate current driver position based on state & animation
  Offset _getDriverPosition(double animValue) {
    switch (_currentState) {
      case TripState.notStarted:
        return _routePoints[2]; // Placed at pickup point or not shown
      case TripState.driverOnWay:
        // Move from Driver Start (0) to Pickup (2)
        final segmentPoints = _routePoints.sublist(0, 3);
        return _interpolatePosition(segmentPoints, animValue);
      case TripState.boarding:
        return _routePoints[2]; // Parked at Pickup
      case TripState.inProgress:
        // Move from Pickup (2) to Destination (8)
        final segmentPoints = _routePoints.sublist(2, 9);
        return _interpolatePosition(segmentPoints, animValue);
      case TripState.completed:
        return _routePoints[8]; // Arrived at Destination
    }
  }

  Offset _interpolatePosition(List<Offset> points, double t) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;
    
    final clampedT = t.clamp(0.0, 1.0);
    final totalSegments = points.length - 1;
    final positionOnSegment = clampedT * totalSegments;
    final segmentIndex = positionOnSegment.floor().clamp(0, totalSegments - 1);
    final segmentProgress = positionOnSegment - segmentIndex;
    
    final start = points[segmentIndex];
    final end = points[segmentIndex + 1];
    
    return Offset(
      lerpDouble(start.dx, end.dx, segmentProgress)!,
      lerpDouble(start.dy, end.dy, segmentProgress)!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text(
          _stateTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: LiveStatusBadge(),
          )
        ],
        elevation: 0,
        backgroundColor: scheme.surface,
      ),
      body: Stack(
        children: [
          // Background subtle gradients
          Positioned(
            top: -100,
            right: -100,
            child: _BackgroundGlow(color: scheme.primary.withAlpha(20), size: 300),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _BackgroundGlow(color: scheme.secondary.withAlpha(15), size: 250),
          ),

          // Main Layout Content
          Positioned.fill(
            child: isTablet 
              ? _buildTabletLayout(context, scheme)
              : _buildMobileLayout(context, scheme),
          ),

          // Floating State Switcher for demo purposes
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: _buildDemoStateController(scheme),
          ),
        ],
      ),
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileLayout(BuildContext context, ColorScheme scheme) {
    if (_currentState == TripState.notStarted) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 84, 16, 24),
        children: [
          _buildCountdownCard(scheme),
          const SizedBox(height: 16),
          _buildQuickActions(scheme),
          const SizedBox(height: 20),
          _buildSectionTitle('Trip Status Timeline', Icons.linear_scale),
          _buildStatusTimeline(scheme),
          const SizedBox(height: 20),
          _buildSectionTitle('Trip Details', Icons.info_outline),
          _buildRouteInfoCard(scheme),
          const SizedBox(height: 16),
          _buildVehicleInfoCard(scheme),
          const SizedBox(height: 16),
          _buildDriverInfoCard(scheme),
        ],
      );
    }

    // Active tracking states: Map at top (60-70%), sheet at bottom
    return Column(
      children: [
        // Map Area
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.only(top: 76.0), // space for state switcher
            child: _buildMapArea(scheme),
          ),
        ),
        // Scrollable/Swipeable bottom details panel
        Expanded(
          flex: 4,
          child: _buildActiveStateDetails(scheme),
        ),
      ],
    );
  }

  // --- TABLET/DESKTOP LAYOUT ---
  Widget _buildTabletLayout(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 84.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Map or Countdown Card depending on state
          Expanded(
            flex: 5,
            child: _currentState == TripState.notStarted
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCountdownCard(scheme),
                        const SizedBox(height: 20),
                        _buildRouteInfoCard(scheme),
                        const SizedBox(height: 20),
                        _buildQuickActions(scheme),
                      ],
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 12, 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _buildMapArea(scheme),
                    ),
                  ),
          ),
          // Right side: Active sheet, driver info, and timeline
          Expanded(
            flex: 4,
            child: _currentState == TripState.notStarted
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle('Trip Status Timeline', Icons.linear_scale),
                        _buildStatusTimeline(scheme),
                        const SizedBox(height: 24),
                        _buildDriverInfoCard(scheme),
                        const SizedBox(height: 16),
                        _buildVehicleInfoCard(scheme),
                      ],
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 24, 24),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: scheme.outline.withAlpha(50)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _buildActiveStateDetails(scheme),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- MAP COMPONENT ---
  Widget _buildMapArea(ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _mapAnimationController,
      builder: (context, child) {
        final driverPos = _getDriverPosition(_mapAnimationController.value);
        return PremiumMap(
          routePoints: _routePoints,
          driverPos: driverPos,
          currentState: _currentState,
          pulseValue: _pulseController.value,
        );
      },
    );
  }

  // --- FLOATING STATE SWITCHER PANEL ---
  Widget _buildDemoStateController(ColorScheme scheme) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: scheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Demo Controller (Simulate Trip States)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface.withAlpha(200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStateTab('1. Waiting', TripState.notStarted, scheme),
                _buildStateTab('2. Heading', TripState.driverOnWay, scheme),
                _buildStateTab('3. Arrived', TripState.boarding, scheme),
                _buildStateTab('4. In Route', TripState.inProgress, scheme),
                _buildStateTab('5. Arrived/Done', TripState.completed, scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateTab(String label, TripState state, ColorScheme scheme) {
    final isSelected = _currentState == state;
    return GestureDetector(
      onTap: () => _changeState(state),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surfaceContainerHighest.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outline.withAlpha(60),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? scheme.onPrimary : scheme.onSurface.withAlpha(170),
          ),
        ),
      ),
    );
  }

  // --- SCREEN 1 COMPONENTS ---

  // Countdown Card
  Widget _buildCountdownCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withAlpha(45),
            scheme.secondary.withAlpha(25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withAlpha(90), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(30),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPulseIndicator(scheme.primary),
              const SizedBox(width: 8),
              Text(
                'UPCOMING RIDE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Trip starts in 24 Minutes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scheduled departure at 08:30 AM',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withAlpha(180),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface.withAlpha(180),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_filled_rounded, size: 16, color: scheme.secondary),
                const SizedBox(width: 6),
                Text(
                  'Expected pickup: 08:32 AM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: scheme.secondary,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Quick Actions Card
  Widget _buildQuickActions(ColorScheme scheme) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionItem(
            Icons.map_outlined,
            'View Route',
            scheme.primary,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Showing full route layout. Set to "Heading" state to track!'),
                  backgroundColor: scheme.primary,
                ),
              );
            },
          ),
          _buildQuickActionItem(
            Icons.chat_bubble_outline_rounded,
            'Contact Driver',
            scheme.secondary,
            () {
              _showMockContactDialog(context, scheme, 'Driver');
            },
          ),
          _buildQuickActionItem(
            Icons.support_agent_rounded,
            'Support',
            scheme.tertiary,
            () {
              _showMockContactDialog(context, scheme, 'Support Desk');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(50)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }

  // Trip Timeline Component
  Widget _buildStatusTimeline(ColorScheme scheme) {
    final timelineSteps = [
      'Booking Confirmed',
      'Driver Assigned',
      'Driver Heading To Pickup',
      'Boarding Started',
      'Trip Started',
      'Trip Completed',
    ];
    
    // We are currently in "Booking Confirmed" or "Driver Assigned" stage
    const currentActiveStep = 1; 

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(timelineSteps.length, (index) {
          final isCompleted = index < currentActiveStep;
          final isActive = index == currentActiveStep;
          final isRemaining = index > currentActiveStep;

          Color stepColor;
          if (isCompleted) {
            stepColor = scheme.secondary;
          } else if (isActive) {
            stepColor = scheme.primary;
          } else {
            stepColor = scheme.outline.withAlpha(120);
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive 
                            ? stepColor.withAlpha(40) 
                            : isCompleted 
                                ? stepColor 
                                : Colors.transparent,
                        border: Border.all(
                          color: stepColor,
                          width: isActive ? 5 : 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Center(
                              child: Icon(Icons.check, size: 10, color: Colors.white),
                            )
                          : null,
                    ),
                    if (index < timelineSteps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted 
                              ? scheme.secondary 
                              : scheme.outline.withAlpha(80),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timelineSteps[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive 
                                ? scheme.primary 
                                : isRemaining 
                                    ? scheme.onSurface.withAlpha(120) 
                                    : scheme.onSurface,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Driver Ahmed Mohamed is scheduled for your pickup.',
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurface.withAlpha(160),
                            ),
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

  // Route Info
  Widget _buildRouteInfoCard(ColorScheme scheme) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Banha Express Route',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildMapTimelineRow(
            Icons.trip_origin_rounded,
            scheme.secondary,
            'Pickup Location',
            'Banha Station',
            'Scheduled departure: 08:30 AM',
          ),
          _buildLineConnector(scheme),
          _buildMapTimelineRow(
            Icons.location_on_rounded,
            scheme.tertiary,
            'Destination',
            'Smart Village (Gate 4)',
            'Expected arrival: 09:20 AM',
          ),
        ],
      ),
    );
  }

  Widget _buildMapTimelineRow(
    IconData icon,
    Color color,
    String type,
    String location,
    String timeInfo,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeInfo,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withAlpha(140),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildLineConnector(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Container(
        width: 2,
        height: 24,
        color: scheme.outline.withAlpha(60),
      ),
    );
  }

  // Vehicle Info
  Widget _buildVehicleInfoCard(ColorScheme scheme) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusChip(label: 'Premium Shuttle'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.outline.withAlpha(100),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MB-15-2847',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Mercedes Sprinter Luxury',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFeatureIconBadge(Icons.ac_unit_rounded, 'A/C Active', scheme),
              const SizedBox(width: 8),
              _buildFeatureIconBadge(Icons.airline_seat_recline_extra_rounded, 'Leather Seats', scheme),
              const SizedBox(width: 8),
              _buildFeatureIconBadge(Icons.wifi_rounded, 'WiFi', scheme),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFeatureIconBadge(IconData icon, String label, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Driver Info
  Widget _buildDriverInfoCard(ColorScheme scheme) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const AppAvatar(initials: 'AM', radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ahmed Mohamed',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: scheme.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      '4.9',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      ' (1,200+ rides)',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.phone_in_talk_rounded, color: scheme.primary),
            onPressed: () => _showMockContactDialog(context, scheme, 'Ahmed Mohamed'),
          )
        ],
      ),
    );
  }

  // --- SCREEN 2 COMPONENTS ---

  // Live Bottom details widget containing status description, buttons, cards, etc.
  Widget _buildActiveStateDetails(ColorScheme scheme) {
    Widget stateContent;

    switch (_currentState) {
      case TripState.driverOnWay:
        stateContent = _buildDriverOnWayView(scheme);
        break;
      case TripState.boarding:
        stateContent = _buildBoardingView(scheme);
        break;
      case TripState.inProgress:
        stateContent = _buildInProgressView(scheme);
        break;
      case TripState.completed:
        stateContent = _buildCompletedView(scheme);
        break;
      default:
        stateContent = const SizedBox.shrink();
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _buildSheetStatusIndicator(scheme),
        const SizedBox(height: 16),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: stateContent,
        ),
      ],
    );
  }

  Widget _buildSheetStatusIndicator(ColorScheme scheme) {
    String title = '';
    String subtitle = '';
    Color toneColor = scheme.primary;

    switch (_currentState) {
      case TripState.driverOnWay:
        title = 'Driver On The Way';
        subtitle = 'Captain Ahmed is driving towards Banha Station';
        toneColor = scheme.secondary;
        break;
      case TripState.boarding:
        title = 'Boarding Started';
        subtitle = 'Shuttle is at the station. Board now.';
        toneColor = scheme.primary;
        break;
      case TripState.inProgress:
        title = 'Trip In Progress';
        subtitle = 'Heading to next stop: Nasr City';
        toneColor = scheme.primary;
        break;
      case TripState.completed:
        title = 'Arrived Safely';
        subtitle = 'Trip completed at 09:22 AM';
        toneColor = scheme.secondary;
        break;
      default:
        break;
    }

    return Row(
      children: [
        _buildPulseIndicator(toneColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(160),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STATE 2: Driver on the way UI
  Widget _buildDriverOnWayView(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildETACard('12', 'minutes away', 'Pickup distance: 2.1 km', scheme),
        const SizedBox(height: 16),
        _buildDriverActionCard(scheme),
        const SizedBox(height: 16),
        _buildVehicleInfoCard(scheme),
      ],
    );
  }

  // STATE 3: Boarding started UI
  Widget _buildBoardingView(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildETACard('4', 'minutes left to board', 'Departure: 08:30 AM', scheme),
        const SizedBox(height: 16),
        // Boarding instructions & OTP Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withAlpha(50)),
          ),
          child: Column(
            children: [
              const Text(
                'Show Boarding QR code or share PIN with driver',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Simulated QR code
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustomPaint(
                  painter: MockQRCodePainter(scheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PIN: 5839',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDriverActionCard(scheme),
      ],
    );
  }

  // STATE 4: Trip in progress UI
  Widget _buildInProgressView(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildETACard('28', 'minutes remaining', 'Expected Arrival: 09:20 AM', scheme),
        const SizedBox(height: 16),
        // Remaining Stops section
        _buildRemainingStopsHeader(scheme),
        const SizedBox(height: 8),
        _buildStopsProgressTimeline(scheme),
        const SizedBox(height: 16),
        // Live Speed/Metric Card
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(Icons.speed_rounded, 'Speed', '58 km/h', scheme.primary),
              _buildMetricItem(Icons.ac_unit_rounded, 'Climate', '22°C', scheme.secondary),
              _buildMetricItem(Icons.network_wifi_3_bar_rounded, 'WiFi', 'Connected', scheme.tertiary),
            ],
          ),
        ),
      ],
    );
  }

  // STATE 5: Trip completed UI
  Widget _buildCompletedView(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.green.withAlpha(70)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You Have Arrived!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Thank you for riding with Mega Transportation.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Summary
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trip Summary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20),
              _buildSummaryRow('Total Duration', '42 Minutes'),
              _buildSummaryRow('Distance Traveled', '28.5 km'),
              _buildSummaryRow('Average Speed', '55 km/h'),
              _buildSummaryRow('Arrival Time', '09:22 AM'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Rating Controls
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate Your Ride Experience',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInteractiveRatingRow('Rate Captain', _driverRating, (rating) {
                setState(() => _driverRating = rating);
              }, scheme),
              const SizedBox(height: 10),
              _buildInteractiveRatingRow('Rate Shuttle Vehicle', _vehicleRating, (rating) {
                setState(() => _vehicleRating = rating);
              }, scheme),
              const SizedBox(height: 10),
              _buildInteractiveRatingRow('Rate Route & Smoothness', _routeRating, (rating) {
                setState(() => _routeRating = rating);
              }, scheme),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Book Another Trip',
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
      ],
    );
  }

  // --- REUSABLE CARD COMPONENTS ---

  // ETA Card
  Widget _buildETACard(String boldValue, String label, String details, ColorScheme scheme) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      boldValue,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.av_timer_rounded, size: 28, color: scheme.primary),
          )
        ],
      ),
    );
  }

  // Interactive Rate Row
  Widget _buildInteractiveRatingRow(String label, int currentRating, Function(int) onRatingChanged, ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= currentRating;
            return GestureDetector(
              onTap: () => onRatingChanged(starIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFilled ? scheme.tertiary : Colors.grey.withAlpha(150),
                  size: 20,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Summary Row helper
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Driver Card with Actions for Active screen
  Widget _buildDriverActionCard(ColorScheme scheme) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const AppAvatar(initials: 'AM', radius: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahmed Mohamed',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: scheme.tertiary),
                        const SizedBox(width: 4),
                        const Text(
                          '4.9',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Call Driver',
                  outline: true,
                  height: 40,
                  onPressed: () => _showMockContactDialog(context, scheme, 'Ahmed Mohamed (Phone)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Chat Driver',
                  height: 40,
                  onPressed: () => _showMockContactDialog(context, scheme, 'Ahmed Mohamed (Chat)'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Stops progress section
  Widget _buildRemainingStopsHeader(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.event_seat_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            const Text(
              '3 Stops Remaining',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          'Next stop: Nasr City',
          style: TextStyle(fontSize: 12, color: scheme.secondary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStopsProgressTimeline(ColorScheme scheme) {
    final stops = [
      'Banha Station',
      'Nasr City Station',
      'Heliopolis Station',
      'Smart Village',
    ];
    // Index representing where we are
    const currentStopIndex = 1;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: List.generate(stops.length, (index) {
          final isPast = index < currentStopIndex;
          final isCurrent = index == currentStopIndex;
          final isFuture = index > currentStopIndex;

          Color dotColor;
          if (isPast) {
            dotColor = scheme.secondary;
          } else if (isCurrent) {
            dotColor = scheme.primary;
          } else {
            dotColor = scheme.outline.withAlpha(120);
          }

          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent ? dotColor : Colors.transparent,
                        border: Border.all(
                          color: dotColor,
                          width: isCurrent ? 4 : 2,
                        ),
                      ),
                    ),
                    if (index < stops.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isPast ? scheme.secondary : scheme.outline.withAlpha(80),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stops[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent 
                                ? scheme.primary 
                                : isFuture 
                                    ? Colors.grey 
                                    : scheme.onSurface,
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Current Loc',
                              style: TextStyle(fontSize: 9, color: scheme.primary, fontWeight: FontWeight.bold),
                            ),
                          )
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

  Widget _buildMetricItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- GENERAL WIDGETS ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(120),
            blurRadius: 6,
            spreadRadius: 2,
          )
        ],
      ),
    );
  }

  // Mock contact actions dialogue
  void _showMockContactDialog(BuildContext context, ColorScheme scheme, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Contact $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This is a mock UI component. Contact channels (VOIP, chat, phone dialer) will trigger here in production.',
                style: TextStyle(fontSize: 13, color: scheme.onSurface.withAlpha(200)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: scheme.primary)),
            )
          ],
        );
      },
    );
  }
}

// --- BACKGOUND GLOW DECORATIVE PAINTER ---
class _BackgroundGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _BackgroundGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withAlpha(0)],
          ),
        ),
      ),
    );
  }
}

// --- PREMIUM MOCK MAP PAINTER ---
class PremiumMap extends StatelessWidget {
  final List<Offset> routePoints;
  final Offset driverPos;
  final TripState currentState;
  final double pulseValue;

  const PremiumMap({
    super.key,
    required this.routePoints,
    required this.driverPos,
    required this.currentState,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // Background grids & streets painting
          Positioned.fill(
            child: CustomPaint(
              painter: _MapGridAndStreetsPainter(scheme),
            ),
          ),
          // Route path drawing
          Positioned.fill(
            child: CustomPaint(
              painter: _MapRouteLinePainter(
                routePoints: routePoints,
                driverPos: driverPos,
                currentState: currentState,
                scheme: scheme,
              ),
            ),
          ),
          // Interactive dynamic overlays (Markers)
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              final pickupOffset = Offset(routePoints[2].dx * w, routePoints[2].dy * h);
              final stop1Offset = Offset(routePoints[4].dx * w, routePoints[4].dy * h);
              final stop2Offset = Offset(routePoints[6].dx * w, routePoints[6].dy * h);
              final destOffset = Offset(routePoints[8].dx * w, routePoints[8].dy * h);
              final driverOffset = Offset(driverPos.dx * w, driverPos.dy * h);

              final showDriver = currentState != TripState.completed || 
                                 (math.sin(pulseValue * math.pi) > 0.0); // blinking/pulsing at destination

              return Stack(
                children: [
                  // Pickup Pin
                  Positioned(
                    left: pickupOffset.dx - 12,
                    top: pickupOffset.dy - 32,
                    child: _buildMapPin(Icons.trip_origin_rounded, scheme.secondary, 'Pickup', pulseValue),
                  ),
                  // Stops Pins
                  Positioned(
                    left: stop1Offset.dx - 6,
                    top: stop1Offset.dy - 6,
                    child: _buildMapStopCircle(scheme.outline, 'Nasr City'),
                  ),
                  Positioned(
                    left: stop2Offset.dx - 6,
                    top: stop2Offset.dy - 6,
                    child: _buildMapStopCircle(scheme.outline, 'Heliopolis'),
                  ),
                  // Destination Pin
                  Positioned(
                    left: destOffset.dx - 12,
                    top: destOffset.dy - 32,
                    child: _buildMapPin(Icons.location_on_rounded, scheme.tertiary, 'Destination', pulseValue),
                  ),

                  // Driver Pin (Moving Shuttle)
                  if (showDriver)
                    Positioned(
                      left: driverOffset.dx - 18,
                      top: driverOffset.dy - 18,
                      child: _buildDriverMarker(scheme, pulseValue),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(IconData icon, Color color, String label, double pulse) {
    final scale = 1.0 + 0.1 * math.sin(pulse * math.pi);
    return Transform.scale(
      scale: scale,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(200),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withAlpha(120)),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(100),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Center(
              child: Icon(Icons.navigation_rounded, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapStopCircle(Color color, String name) {
    return Tooltip(
      message: name,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }

  Widget _buildDriverMarker(ColorScheme scheme, double pulse) {
    final alpha = (80 + 100 * math.sin(pulse * math.pi)).toInt().clamp(0, 255);
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing glow
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withAlpha(alpha),
          ),
        ),
        // Driver Shuttle Card
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(150),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Center(
            child: Icon(
              Icons.directions_bus_rounded,
              size: 14,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// Painting grids, background color, block streets for city simulation
class _MapGridAndStreetsPainter extends CustomPainter {
  final ColorScheme scheme;
  _MapGridAndStreetsPainter(this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background with elegant charcoal color
    final bgPaint = Paint()..color = scheme.surfaceContainerHighest;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final streetPaint = Paint()
      ..color = scheme.surface.withAlpha(60)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw some city background streets winding around to simulate layout
    final streetPath1 = Path()
      ..moveTo(0, size.height * 0.2)
      ..lineTo(size.width, size.height * 0.2);
    final streetPath2 = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.7, size.width, size.height * 0.5);
    final streetPath3 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.2, size.height);
    final streetPath4 = Path()
      ..moveTo(size.width * 0.8, 0)
      ..lineTo(size.width * 0.8, size.height);

    canvas.drawPath(streetPath1, streetPaint);
    canvas.drawPath(streetPath2, streetPaint);
    canvas.drawPath(streetPath3, streetPaint);
    canvas.drawPath(streetPath4, streetPaint);

    // Draw minor grid overlays
    final gridPaint = Paint()
      ..color = scheme.outline.withAlpha(12)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Drawing route path segment and highlighting progress
class _MapRouteLinePainter extends CustomPainter {
  final List<Offset> routePoints;
  final Offset driverPos;
  final TripState currentState;
  final ColorScheme scheme;

  _MapRouteLinePainter({
    required this.routePoints,
    required this.driverPos,
    required this.currentState,
    required this.scheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.isEmpty) return;

    final w = size.width;
    final h = size.height;

    // Convert relative points to absolute coordinates
    final points = routePoints.map((p) => Offset(p.dx * w, p.dy * h)).toList();
    final driverAbsolutePos = Offset(driverPos.dx * w, driverPos.dy * h);

    // 1. Draw Remaining Route (Dotted/Dashed Line or Dim Line)
    final remainingPaint = Paint()
      ..color = scheme.outline.withAlpha(120)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fullPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      fullPath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(fullPath, remainingPaint);

    // 2. Draw Traveled Route (Highlighted neon line up to Driver position)
    final traveledPaint = Paint()
      ..color = scheme.primary
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final traveledPath = Path()..moveTo(points.first.dx, points.first.dy);

    // Identify which point segments the driver has passed
    // Find segment on full route closest to driver position
    var segmentIdx = 0;
    var minDist = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final d = (points[i] - driverAbsolutePos).distance;
      if (d < minDist) {
        minDist = d;
        segmentIdx = i;
      }
    }

    // Draw up to that closest segment
    for (var i = 1; i <= segmentIdx; i++) {
      traveledPath.lineTo(points[i].dx, points[i].dy);
    }
    // Connect remaining distance to exact driver position
    traveledPath.lineTo(driverAbsolutePos.dx, driverAbsolutePos.dy);

    canvas.drawPath(traveledPath, traveledPaint);
  }

  @override
  bool shouldRepaint(covariant _MapRouteLinePainter old) =>
      old.driverPos != driverPos || old.currentState != currentState || old.scheme != scheme;
}

// Draw a mock QR code layout utilizing CustomPainter lines
class MockQRCodePainter extends CustomPainter {
  final Color qrColor;
  MockQRCodePainter(this.qrColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = qrColor
      ..style = PaintingStyle.fill;

    // Corner squares
    canvas.drawRect(const Rect.fromLTWH(0, 0, 30, 30), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 30, 0, 30, 30), paint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 30, 30, 30), paint);

    // Inner holes in corner squares
    paint.color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(6, 6, 18, 18), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 24, 6, 18, 18), paint);
    canvas.drawRect(Rect.fromLTWH(6, size.height - 24, 18, 18), paint);

    paint.color = qrColor;
    canvas.drawRect(const Rect.fromLTWH(10, 10, 10, 10), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 20, 10, 10, 10), paint);
    canvas.drawRect(Rect.fromLTWH(10, size.height - 20, 10, 10), paint);

    // Winding random QR pixels/lines in center
    final random = math.Random(101);
    const cellSize = 5.0;
    for (double x = 35; x < size.width - 35; x += cellSize) {
      for (double y = 0; y < size.height; y += cellSize) {
        if (random.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x, y, cellSize, cellSize), paint);
        }
      }
    }
    for (double x = 0; x < 35; x += cellSize) {
      for (double y = 35; y < size.height - 35; y += cellSize) {
        if (random.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x, y, cellSize, cellSize), paint);
        }
      }
    }
    for (double x = size.width - 35; x < size.width; x += cellSize) {
      for (double y = 35; y < size.height - 35; y += cellSize) {
        if (random.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x, y, cellSize, cellSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
