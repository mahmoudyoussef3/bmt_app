import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

// --- DATA STRUCTURES ---
class CommutePackage {
  final String name;
  final String durationLabel;
  final int days;
  final int tripsCount;
  final int discountPercent;
  final int startingPrice;
  final int savingsAmount;
  final String description;

  const CommutePackage({
    required this.name,
    required this.durationLabel,
    required this.days,
    required this.tripsCount,
    required this.discountPercent,
    required this.startingPrice,
    required this.savingsAmount,
    required this.description,
  });

  int get basePrice => startingPrice + savingsAmount;
}

class VehicleTypeData {
  final String name;
  final IconData icon;
  final int extraFee;
  final String description;

  const VehicleTypeData({
    required this.name,
    required this.icon,
    required this.extraFee,
    required this.description,
  });
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  int _currentStep = 1; // Steps 1 to 5
  String _selectedCategoryFilter = 'All'; // All, Weekly, Monthly, Quarterly

  // Package Mock Data
  final List<CommutePackage> _packages = const [
    CommutePackage(
      name: 'Weekly Saver',
      durationLabel: '7 Days',
      days: 7,
      tripsCount: 10,
      discountPercent: 10,
      startingPrice: 270,
      savingsAmount: 30,
      description: 'Ideal for short-term commutes and temporary travel needs.',
    ),
    CommutePackage(
      name: 'Bi-Weekly Smart',
      durationLabel: '14 Days',
      days: 14,
      tripsCount: 20,
      discountPercent: 15,
      startingPrice: 510,
      savingsAmount: 90,
      description: 'Great balance of cost and flexibility for mid-term projects.',
    ),
    CommutePackage(
      name: 'Monthly Premium',
      durationLabel: '30 Days',
      days: 30,
      tripsCount: 44,
      discountPercent: 20,
      startingPrice: 1080,
      savingsAmount: 270,
      description: 'Our most popular plan. Lock in your daily commute and seats.',
    ),
    CommutePackage(
      name: 'Quarterly Mega',
      durationLabel: '90 Days',
      days: 90,
      tripsCount: 132,
      discountPercent: 25,
      startingPrice: 2970,
      savingsAmount: 990,
      description: 'Ultimate savings for regular commuters who want zero hassle.',
    ),
  ];

  // Selection state
  CommutePackage? _selectedPackage;
  String _selectedRoute = 'Banha - Cairo Express';
  String _selectedPickup = 'Banha Station';
  String _selectedDestination = 'Smart Village';
  
  final List<String> _routes = const [
    'Banha - Cairo Express',
    'Alexandria - Cairo Highway',
    'Suez Daily Commute',
  ];
  final List<String> _pickupPoints = const [
    'Banha Station',
    'Banha Downtown',
    'Cairo Toll Gate',
  ];
  final List<String> _destinations = const [
    'Smart Village',
    'Nasr City',
    'Heliopolis',
  ];

  // Vehicle Types
  final List<VehicleTypeData> _vehicles = const [
    VehicleTypeData(name: 'Standard Coach', icon: Icons.directions_bus_rounded, extraFee: 0, description: 'Comfortable standard AC travel.'),
    VehicleTypeData(name: 'Comfort Van', icon: Icons.airport_shuttle_rounded, extraFee: 150, description: 'Faster executive mini-vans.'),
    VehicleTypeData(name: 'Premium Luxury', icon: Icons.directions_car_rounded, extraFee: 300, description: 'VIP premium seating and priority route.'),
  ];
  int _selectedVehicleIndex = 0;

  // Seat map state (4x5 grid = 20 seats)
  final Set<int> _selectedSeats = {};
  final Set<int> _occupiedSeats = {3, 7, 12, 16};

  bool _agreeTerms = false;
  late final AnimationController _successController;
  late final String _subscriptionId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _subscriptionId = 'SUB-2026-${_generateRandomSuffix()}';
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  String _generateRandomSuffix() {
    final rng = math.Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(5, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // Pricing calculations
  int get _packageCost => (_selectedPackage?.startingPrice ?? 0);
  int get _vehicleAddonFee => _vehicles[_selectedVehicleIndex].extraFee;
  int get _seatMultiplier => math.max(1, _selectedSeats.length);

  int get _rawSubtotal => (_packageCost + _vehicleAddonFee) * _seatMultiplier;
  int get _discountValue => ((_rawSubtotal * (_selectedPackage?.discountPercent ?? 0)) / 100).round();
  int get _finalPrice => _rawSubtotal - _discountValue;
  int get _totalSavings => ((_selectedPackage?.savingsAmount ?? 0) * _seatMultiplier) + _discountValue;

  // Category filter predicate
  bool _filterPackage(CommutePackage package) {
    if (_selectedCategoryFilter == 'All') return true;
    if (_selectedCategoryFilter == 'Weekly' && package.days <= 14) return true;
    if (_selectedCategoryFilter == 'Monthly' && package.days == 30) return true;
    if (_selectedCategoryFilter == 'Quarterly' && package.days == 90) return true;
    return false;
  }

  void _onBackPress() {
    if (_currentStep > 1 && !_isProcessing) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _simulateSubscriptionActivation() {
    setState(() {
      _isProcessing = true;
    });

    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _currentStep = 5;
      });
      _successController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text(
          _isProcessing ? 'Processing' : _getStepTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          onPressed: _onBackPress,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -80,
            right: -80,
            child: _BackgroundCircleGlow(color: scheme.primary.withAlpha(20)),
          ),
          Positioned(
            bottom: -60,
            left: -80,
            child: _BackgroundCircleGlow(color: scheme.secondary.withAlpha(15)),
          ),

          // Main Step switcher layout
          Positioned.fill(
            child: _isProcessing 
              ? _buildActivationLoader(scheme)
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentStepView(scheme),
                ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Commute Packages';
      case 2:
        return 'Package Details';
      case 3:
        return 'Configure Travel';
      case 4:
        return 'Review Summary';
      case 5:
        return 'Subscribed!';
      default:
        return 'Subscribe Plan';
    }
  }

  Widget _buildCurrentStepView(ColorScheme scheme) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Listing(scheme);
      case 2:
        return _buildStep2Details(scheme);
      case 3:
        return _buildStep3RouteSelection(scheme);
      case 4:
        return _buildStep4Summary(scheme);
      case 5:
        return _buildStep5Success(scheme);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 1: PACKAGES LISTING SCREEN ---
  Widget _buildStep1Listing(ColorScheme scheme) {
    final filtered = _packages.where(_filterPackage).toList();

    return Column(
      key: const ValueKey('step1'),
      children: [
        // Category Filters Tabs
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: scheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterTab('All', scheme),
              _buildFilterTab('Weekly', scheme),
              _buildFilterTab('Monthly', scheme),
              _buildFilterTab('Quarterly', scheme),
            ],
          ),
        ),

        // Scrollable List of Package Cards
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final package = filtered[idx];
              return _buildPackageCard(package, scheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String label, ColorScheme scheme) {
    final isSelected = _selectedCategoryFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? scheme.onPrimary : scheme.onSurface.withAlpha(180),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(CommutePackage package, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withAlpha(45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedPackage = package;
                _currentStep = 2;
                // Add seat 5 as default selection
                _selectedSeats.clear();
                _selectedSeats.add(5);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        package.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.primary.withAlpha(24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Save ${package.discountPercent}%',
                          style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Details Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniDetailColumn('Duration', package.durationLabel),
                      _buildMiniDetailColumn('Total Trips', '${package.tripsCount} Rides'),
                      _buildMiniDetailColumn('Total Savings', 'EGP ${package.savingsAmount}', isHighlight: true, color: scheme.secondary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  // Price Tag & CTA Arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Original: EGP ${package.basePrice}',
                            style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: Colors.grey),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'EGP ${package.startingPrice}',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: scheme.primary),
                              ),
                              const SizedBox(width: 4),
                              const Text('starting', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_forward_rounded, size: 18, color: scheme.primary),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniDetailColumn(String label, String value, {bool isHighlight = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? color : null,
          ),
        ),
      ],
    );
  }

  // --- STEP 2: PACKAGE DETAILS SCREEN ---
  Widget _buildStep2Details(ColorScheme scheme) {
    if (_selectedPackage == null) return const SizedBox.shrink();
    final package = _selectedPackage!;

    return Column(
      key: const ValueKey('step2'),
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Package Header Info
              _buildDetailHeaderCard(package, scheme),
              const SizedBox(height: 18),

              // Benefits
              const Text('What is Included', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildBenefitRow(Icons.event_seat_rounded, 'Reserved Seat Guaranteed', 'Your preferred seat is locked for every daily shuttle ride.', scheme),
              _buildBenefitRow(Icons.schedule_rounded, 'Flexible Ride Timing', 'Adjust your ride booking times anytime without cancellation fees.', scheme),
              _buildBenefitRow(Icons.card_membership_rounded, 'Priority VIP Boarding', 'First access onboarding and customer concierge helpline.', scheme),
              const SizedBox(height: 20),

              // Route details card
              const Text('Route & Booking Limits', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRowDetailText('Route Scope', 'Fixed designated route selected upon checkout.'),
                    const SizedBox(height: 8),
                    _buildRowDetailText('Included Rides', '${package.tripsCount} single shuttle trips.'),
                    const SizedBox(height: 8),
                    _buildRowDetailText('Validity Period', '${package.days} consecutive calendar days.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Terms Conditions
              const Text('Terms & Cancellation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '1. Packages cannot be refunded once activated.\n'
                  '2. Seats must be confirmed at least 2 hours before trip.\n'
                  '3. Package holds up to ${package.tripsCount} reservations for the selected route.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: scheme.onSurface.withAlpha(200)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        // Bottom sticky button
        _buildStickyCTA(
          label: 'Choose Route & Configure',
          onPressed: () {
            setState(() {
              _currentStep = 3;
            });
          },
          scheme: scheme,
        ),
      ],
    );
  }

  Widget _buildDetailHeaderCard(CommutePackage package, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary.withAlpha(30), scheme.secondary.withAlpha(10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                package.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              StatusChip(label: package.durationLabel),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            package.description,
            style: TextStyle(fontSize: 12, color: scheme.onSurface.withAlpha(200), height: 1.4),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Base Price', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(
                    'EGP ${package.basePrice}',
                    style: const TextStyle(fontSize: 13, decoration: TextDecoration.lineThrough, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Package Discount', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(
                    '${package.discountPercent}% Off',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: scheme.primary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Subscription Cost', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(
                    'EGP ${package.startingPrice}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: scheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String desc, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.secondary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: scheme.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRowDetailText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // --- STEP 3: ROUTE & TRAVEL SELECTION SCREEN ---
  Widget _buildStep3RouteSelection(ColorScheme scheme) {
    return Column(
      key: const ValueKey('step3'),
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Route Selection Dropdown
              const Text('Select Target Route', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildDropdownSelector(
                value: _selectedRoute,
                items: _routes,
                onChanged: (val) => setState(() => _selectedRoute = val!),
                scheme: scheme,
              ),
              const SizedBox(height: 18),

              // Pickups and destinations
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pickup Point', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        _buildDropdownSelector(
                          value: _selectedPickup,
                          items: _pickupPoints,
                          onChanged: (val) => setState(() => _selectedPickup = val!),
                          scheme: scheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Destination', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        _buildDropdownSelector(
                          value: _selectedDestination,
                          items: _destinations,
                          onChanged: (val) => setState(() => _selectedDestination = val!),
                          scheme: scheme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Vehicle Type Selector
              const Text('Select Vehicle Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              Row(
                children: List.generate(_vehicles.length, (idx) {
                  final vehicle = _vehicles[idx];
                  final isSelected = _selectedVehicleIndex == idx;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedVehicleIndex = idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: EdgeInsets.only(right: idx == _vehicles.length - 1 ? 0 : 8),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? scheme.primary.withAlpha(20) : scheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? scheme.primary : scheme.outline.withAlpha(45),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(vehicle.icon, color: isSelected ? scheme.primary : Colors.grey, size: 22),
                            const SizedBox(height: 6),
                            Text(
                              vehicle.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vehicle.extraFee > 0 ? '+EGP ${vehicle.extraFee}' : 'Free',
                              style: TextStyle(fontSize: 9, color: isSelected ? scheme.primary : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Seat Selection Map Picker
              const Text('Choose Your Seat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              const Text('Tap to reserve seat. Reserving more seats multiplies the package.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 14),
              _buildSeatMapGrid(scheme),

              const SizedBox(height: 30),
            ],
          ),
        ),

        // Live calculation pricing breakdown panel and sticky button
        _buildStep3CTA(scheme),
      ],
    );
  }

  Widget _buildDropdownSelector({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ColorScheme scheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(55)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: scheme.surface,
        ),
      ),
    );
  }

  Widget _buildSeatMapGrid(ColorScheme scheme) {
    // 5 Rows of seats. Standard 4 seats per row (2-gap-2 layout)
    final rows = 5;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          // Frontend Driver indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_car_rounded, size: 14, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('Front / Driver Cabin', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: scheme.outline.withAlpha(60),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Seat Grid
          Column(
            children: List.generate(rows, (rowIdx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Seat Left 1
                    _buildSeatButton((rowIdx * 4) + 1, scheme),
                    // Seat Left 2
                    _buildSeatButton((rowIdx * 4) + 2, scheme),
                    // Middle Aisle Gap
                    const SizedBox(width: 32, child: Center(child: Text('Aisle', style: TextStyle(fontSize: 9, color: Colors.grey)))),
                    // Seat Right 1
                    _buildSeatButton((rowIdx * 4) + 3, scheme),
                    // Seat Right 2
                    _buildSeatButton((rowIdx * 4) + 4, scheme),
                  ],
                ),
              );
            }),
          ),

          // Legend
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(Colors.transparent, scheme.outline, 'Available'),
              _buildLegendItem(scheme.primary, scheme.primary, 'Selected'),
              _buildLegendItem(scheme.outline.withAlpha(120), scheme.outline.withAlpha(120), 'Occupied'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSeatButton(int seatNo, ColorScheme scheme) {
    final isOccupied = _occupiedSeats.contains(seatNo);
    final isSelected = _selectedSeats.contains(seatNo);

    Color bgColor = Colors.transparent;
    Color borderColor = scheme.outline;
    Color textColor = scheme.onSurface;

    if (isOccupied) {
      bgColor = scheme.outline.withAlpha(80);
      borderColor = scheme.outline.withAlpha(50);
      textColor = Colors.grey.withAlpha(150);
    } else if (isSelected) {
      bgColor = scheme.primary;
      borderColor = scheme.primary;
      textColor = scheme.onPrimary;
    }

    return GestureDetector(
      onTap: isOccupied
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  _selectedSeats.remove(seatNo);
                } else {
                  _selectedSeats.add(seatNo);
                }
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Center(
          child: Text(
            '$seatNo',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color fill, Color border, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStep3CTA(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(55))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pricing Live Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seats Selected: ${_selectedSeats.length}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Row(
                      children: [
                        Text('Cost: EGP $_rawSubtotal', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 8),
                        Text('Savings: EGP $_totalSavings', style: TextStyle(fontSize: 11, color: scheme.secondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                Text(
                  'EGP $_finalPrice',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Continue to Summary',
                    onPressed: _selectedSeats.isEmpty
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select at least one seat to proceed.')),
                            );
                          }
                        : () {
                            setState(() {
                              _currentStep = 4;
                            });
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 4: PACKAGE BOOKING SUMMARY SCREEN ---
  Widget _buildStep4Summary(ColorScheme scheme) {
    if (_selectedPackage == null) return const SizedBox.shrink();
    final package = _selectedPackage!;

    return Column(
      key: const ValueKey('step4'),
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Booking Review Summary Card
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Booking Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.primary.withAlpha(24),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            package.name,
                            style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildSummaryDetailRow('Target Route', _selectedRoute),
                    _buildSummaryDetailRow('Pickup Stop', _selectedPickup),
                    _buildSummaryDetailRow('Destination Stop', _selectedDestination),
                    _buildSummaryDetailRow('Vehicle Category', _vehicles[_selectedVehicleIndex].name),
                    _buildSummaryDetailRow('Selected Seats', _selectedSeats.join(', ')),
                    _buildSummaryDetailRow('Trips Allocated', '${package.tripsCount} Rides'),
                    _buildSummaryDetailRow('Package Validity', '${package.days} Days'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Final pricing card
              const Text('Pricing Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildPricingRow('Base Package Cost', 'EGP $_rawSubtotal'),
                    const SizedBox(height: 8),
                    _buildPricingRow('Plan Discount Value', '-EGP $_discountValue', color: scheme.primary),
                    const SizedBox(height: 8),
                    _buildPricingRow('Effective Savings', 'EGP $_totalSavings', color: scheme.secondary),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Final Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          'EGP $_finalPrice',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: scheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Terms Acceptance Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreeTerms,
                    onChanged: (val) => setState(() => _agreeTerms = val!),
                    activeColor: scheme.primary,
                  ),
                  const Expanded(
                    child: Text(
                      'I agree to the recurring commuter subscription terms and conditions policy.',
                      style: TextStyle(fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),

        // Confirm Action sticky bottom panel
        _buildStickyCTA(
          label: 'Confirm Subscription',
          onPressed: _agreeTerms ? _simulateSubscriptionActivation : () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please agree to terms and conditions to activate.')),
            );
          },
          scheme: scheme,
        ),
      ],
    );
  }

  Widget _buildSummaryDetailRow(String label, String value) {
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

  Widget _buildPricingRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- STEP 5: SUBSCRIPTION SUCCESS SCREEN ---
  Widget _buildStep5Success(ColorScheme scheme) {
    if (_selectedPackage == null) return const SizedBox.shrink();
    final package = _selectedPackage!;

    return SingleChildScrollView(
      key: const ValueKey('step5'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        children: [
          // Animated checkmark and confetti
          Stack(
            alignment: Alignment.center,
            children: [
              ScaleTransition(
                scale: Tween(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withAlpha(45),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.verified_user_rounded, size: 50, color: Colors.white),
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(120, 120),
                painter: _SuccessConfettiPainter(progress: _successController),
              )
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Subscription Activated!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your travel package is now active. Commute securely.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Subscription ticket receipt summary
          AppSurface(
            radius: 24,
            padding: const EdgeInsets.all(20),
            color: scheme.surface,
            border: Border.all(color: scheme.outline.withAlpha(50)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subscription Receipt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied ID: $_subscriptionId')),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            _subscriptionId,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scheme.primary),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.copy_rounded, size: 12, color: scheme.primary),
                        ],
                      ),
                    )
                  ],
                ),
                const Divider(height: 20),
                _buildReceiptRow('Commuter Package', package.name),
                _buildReceiptRow('Duration Limit', package.durationLabel),
                _buildReceiptRow('Total Trips Scope', '${package.tripsCount} Rides'),
                _buildReceiptRow('Selected Seats', _selectedSeats.join(', ')),
                _buildReceiptRow('Travel Route', _selectedRoute),
                _buildReceiptRow('Pickup Stop', _selectedPickup),
                _buildReceiptRow('Destination Stop', _selectedDestination),
                _buildReceiptRow('Vehicle Standard', _vehicles[_selectedVehicleIndex].name),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Paid Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('EGP $_finalPrice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: scheme.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Action button back to home
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Back to Home',
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- GENERAL WIDGETS ---

  Widget _buildStickyCTA({required String label, required VoidCallback onPressed, required ColorScheme scheme}) {
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
              child: AppButton(
                label: label,
                onPressed: onPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationLoader(ColorScheme scheme) {
    return Center(
      child: AppSurface(
        radius: 28,
        padding: const EdgeInsets.all(24),
        color: scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.outline.withAlpha(50)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(strokeWidth: 5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Activating Package...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Confirming commuter credentials and reserving seats.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.onSurface.withAlpha(160)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- DECORATIVE BACKGROUND PAINT GLOW ---
class _BackgroundCircleGlow extends StatelessWidget {
  final Color color;

  const _BackgroundCircleGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 250,
        height: 250,
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

// --- SUCCESS CONFETTI PARTICLES PAINTER ---
class _SuccessConfettiPainter extends CustomPainter {
  final Animation<double> progress;

  _SuccessConfettiPainter({required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress.value == 0) return;

    final random = math.Random(123);
    final center = Offset(size.width / 2, size.height / 2);
    final count = 30;
    final maxRadius = size.width * 0.75;

    for (var i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = progress.value * maxRadius * (0.35 + random.nextDouble() * 0.65);
      
      final offset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      final sizeFactor = (1.0 - progress.value) * (4 + random.nextDouble() * 5);
      final color = _getConfettiColor(random.nextInt(4));
      
      final paint = Paint()
        ..color = color.withAlpha(((1.0 - progress.value).clamp(0.0, 1.0) * 255).toInt())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, sizeFactor, paint);
    }
  }

  Color _getConfettiColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.teal;
      case 2:
        return Colors.amber;
      default:
        return Colors.pink;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
