import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

// --- DATA STRUCTURES ---
class LoyaltyTier {
  final String name;
  final String pointsRequired;
  final List<String> perks;
  final List<Color> gradientColors;
  final IconData icon;

  const LoyaltyTier({
    required this.name,
    required this.pointsRequired,
    required this.perks,
    required this.gradientColors,
    required this.icon,
  });
}

class PointsTransaction {
  final String title;
  final String date;
  final int points;
  final bool isEarned;
  final String? expirationDate;

  const PointsTransaction({
    required this.title,
    required this.date,
    required this.points,
    required this.isEarned,
    this.expirationDate,
  });
}

class RedeemableReward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String valueLabel;
  final String category; // 'Discount', 'FreeRide', 'Cashback', 'Package'
  final String couponCode;

  const RedeemableReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.valueLabel,
    required this.category,
    required this.couponCode,
  });
}

// Particle physics for celebration confetti
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
    vx *= 0.97; // Drag
    rotation += rotationSpeed;
  }
}

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen>
    with TickerProviderStateMixin {
  // Views:
  // 1 = Loyalty Dashboard
  // 2 = Points History
  // 3 = Rewards Catalog
  int _currentView = 1;

  // Gamified Loyalty State
  int _currentPoints = 2450;
  String _currentTierName = 'Gold'; // Bronze, Silver, Gold, Platinum

  // Confetti Particle state
  final List<ConfettiParticle> _particles = [];
  Timer? _confettiTimer;

  // Mock Tiers
  final List<LoyaltyTier> _tiers = const [
    LoyaltyTier(
      name: 'Bronze',
      pointsRequired: '0 pts',
      icon: Icons.workspace_premium_rounded,
      gradientColors: [Color(0xFF8C5A3C), Color(0xFF5C3A21)],
      perks: [
        'Earn 1x points on standard commutes',
        'Standard customer support ticket queues',
      ],
    ),
    LoyaltyTier(
      name: 'Silver',
      pointsRequired: '1,000 pts',
      icon: Icons.shield_rounded,
      gradientColors: [Color(0xFFB0BEC5), Color(0xFF607D8B)],
      perks: [
        'Earn 1.2x points on comfort rides',
        'Priority seating allocations',
        'Dedicated Silver support queue hotline',
      ],
    ),
    LoyaltyTier(
      name: 'Gold',
      pointsRequired: '2,000 pts',
      icon: Icons.stars_rounded,
      gradientColors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
      perks: [
        'Earn 1.5x points on luxury coaches',
        'Free shuttle scheduling adjustments',
        'VIP boarding privileges',
        'No service fees on refund transactions',
      ],
    ),
    LoyaltyTier(
      name: 'Platinum',
      pointsRequired: '3,000 pts',
      icon: Icons.diamond_rounded,
      gradientColors: [Color(0xFFE2E8F0), Color(0xFF475569)],
      perks: [
        'Earn 2x points on all shuttle rides',
        'Complimentary cabin beverage selection',
        'Guaranteed reserved seat on commute lines',
        'Priority executive ticket desk helpline',
        'Free trip voucher every 15 rides',
      ],
    ),
  ];

  // Mock Transactions
  final List<PointsTransaction> _transactions = const [
    PointsTransaction(title: 'Trip to Smart Village (Luxury Coach)', date: 'Jun 2, 2026', points: 150, isEarned: true),
    PointsTransaction(title: 'Redeemed EGP 50 Trip Coupon', date: 'May 30, 2026', points: 500, isEarned: false),
    PointsTransaction(title: 'Trip to Banha Station (Comfort Van)', date: 'May 28, 2026', points: 120, isEarned: true),
    PointsTransaction(title: 'Welcome Points Bonus', date: 'May 24, 2026', points: 500, isEarned: true),
    PointsTransaction(title: 'Referral Bonus: Invited Ahmed', date: 'May 20, 2026', points: 300, isEarned: true),
    PointsTransaction(title: 'Loyalty Monthly Tier Boost', date: 'May 01, 2026', points: 200, isEarned: true, expirationDate: 'Jun 30, 2026'),
  ];

  // Mock redeemable catalog items
  final List<RedeemableReward> _rewards = const [
    RedeemableReward(
      id: 'r1',
      title: 'EGP 30 Off Shuttle Ride',
      description: 'Get EGP 30 off standard or comfort daily runs.',
      pointsCost: 300,
      valueLabel: 'EGP 30',
      category: 'Discount',
      couponCode: 'DISC30PTS',
    ),
    RedeemableReward(
      id: 'r2',
      title: 'EGP 60 Off Commute',
      description: 'Save EGP 60 on your next booking seat fare.',
      pointsCost: 500,
      valueLabel: 'EGP 60',
      category: 'Discount',
      couponCode: 'DISC60PTS',
    ),
    RedeemableReward(
      id: 'r3',
      title: '1 Free Commute Ticket',
      description: 'Free single ride voucher valid on any shuttle coach.',
      pointsCost: 1000,
      valueLabel: 'FREE TRIP',
      category: 'FreeRide',
      couponCode: 'FREETRIPPTS',
    ),
    RedeemableReward(
      id: 'r4',
      title: 'EGP 100 Cashback',
      description: 'Claim EGP 100 directly to your main BMT account wallet.',
      pointsCost: 1500,
      valueLabel: 'EGP 100 CASH',
      category: 'Cashback',
      couponCode: 'CASHBACK100',
    ),
    RedeemableReward(
      id: 'r5',
      title: 'EGP 200 Package Discount',
      description: 'Get EGP 200 off your next weekly/monthly subscription bundle.',
      pointsCost: 2000,
      valueLabel: 'EGP 200 OFF',
      category: 'Package',
      couponCode: 'PKGDIST200',
    ),
    RedeemableReward(
      id: 'r6',
      title: 'Free Month Upgrade',
      description: 'Upgrade your weekly package to VIP comfort tier package.',
      pointsCost: 2800, // gold points not enough
      valueLabel: 'FREE UPGRADE',
      category: 'Package',
      couponCode: 'VIPUPGRADEFREE',
    ),
  ];

  // --- ACTIONS ---

  void _onBackPress() {
    if (_currentView > 1) {
      setState(() => _currentView = 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  String _getViewTitle() {
    return switch (_currentView) {
      1 => 'Loyalty Portal',
      2 => 'Points Ledger Logs',
      3 => 'Redeem Points Catalog',
      _ => 'Loyalty Hub',
    };
  }

  void _triggerConfetti() {
    final random = math.Random();
    _particles.clear();
    for (int i = 0; i < 90; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final speed = 3 + random.nextDouble() * 12;
      _particles.add(
        ConfettiParticle(
          x: MediaQuery.of(context).size.width / 2,
          y: MediaQuery.of(context).size.height / 3,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 6,
          size: 5 + random.nextDouble() * 9,
          color: Colors.primaries[random.nextInt(Colors.primaries.length)],
          rotation: random.nextDouble() * math.pi,
          rotationSpeed: -0.12 + random.nextDouble() * 0.24,
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

  void _confirmRedeem(RedeemableReward reward) {
    if (_currentPoints < reward.pointsCost) return;

    showDialog(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Confirm Redemption', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to redeem this reward?',
                style: TextStyle(fontSize: 12, color: scheme.onSurface.withAlpha(180)),
              ),
              const SizedBox(height: 14),
              AppSurface(
                color: scheme.surfaceContainerHighest.withAlpha(120),
                padding: const EdgeInsets.all(12),
                radius: 18,
                child: Row(
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reward.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('Cost: ${reward.pointsCost} points', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Balance:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('$_currentPoints pts', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Balance After Redemption:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    '${_currentPoints - reward.pointsCost} pts',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scheme.primary),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processRedeem(reward);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
              ),
              child: const Text('Redeem Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _processRedeem(RedeemableReward reward) {
    setState(() {
      _currentPoints -= reward.pointsCost;
      // Re-evaluate tier
      if (_currentPoints >= 3000) {
        _currentTierName = 'Platinum';
      } else if (_currentPoints >= 2000) {
        _currentTierName = 'Gold';
      } else if (_currentPoints >= 1000) {
        _currentTierName = 'Silver';
      } else {
        _currentTierName = 'Bronze';
      }
    });

    _triggerConfetti();

    // Show Success Voucher Modal
    showDialog(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(child: Text('Voucher Unlocked! 🎫')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 54),
              const SizedBox(height: 12),
              const Text(
                'Coupon code generated successfully. You can use it during payment checkout.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outline.withAlpha(50)),
                ),
                child: Column(
                  children: [
                    Text(
                      reward.valueLabel,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: scheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reward.title,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            reward.couponCode,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: AppButton(
                label: 'Copy & Close',
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voucher code copied to clipboard!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            )
          ],
        );
      },
    );
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
            // Current View
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
      2 => _buildHistoryView(scheme),
      3 => _buildCatalogView(scheme),
      _ => const SizedBox.shrink(),
    };
  }

  // --- SCREEN 1: LOYALTY DASHBOARD ---
  Widget _buildDashboardView(ColorScheme scheme) {
    // Determine active tier properties
    final activeTier = _tiers.firstWhere((t) => t.name == _currentTierName);

    // Calculate progression details to Platinum
    const platinumThreshold = 3000;
    final double progress = math.min(_currentPoints / platinumThreshold, 1.0);
    final ptsToPlatinum = math.max(0, platinumThreshold - _currentPoints);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        // Metallic Tier card
        _buildMetallicTierCard(activeTier, scheme),
        const SizedBox(height: 18),

        // Progress indicators
        _buildProgressionCard(progress, ptsToPlatinum, scheme),
        const SizedBox(height: 18),

        // Quick action grids
        Row(
          children: [
            Expanded(
              child: _buildDashboardNavCard(
                icon: Icons.wallet_giftcard_rounded,
                title: 'Redeem Points',
                subtitle: 'Browse Catalog',
                color: Colors.orangeAccent,
                onTap: () => setState(() => _currentView = 3),
                scheme: scheme,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDashboardNavCard(
                icon: Icons.receipt_long_rounded,
                title: 'Points History',
                subtitle: 'Ledger Logs',
                color: Colors.teal,
                onTap: () => setState(() => _currentView = 2),
                scheme: scheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tier Perks list
        Text(
          'Active ${activeTier.name} Perks',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        ...activeTier.perks.map((perk) => _buildPerkTile(perk, scheme)),

        const SizedBox(height: 24),
        // Explore Tiers
        const Text(
          'Explore Membership Levels',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        _buildMembershipTiersCarousel(scheme),
      ],
    );
  }

  Widget _buildMetallicTierCard(LoyaltyTier tier, ColorScheme scheme) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tier.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tier.gradientColors.first.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.white.withAlpha(40), width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          // Background large vector icon
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              tier.icon,
              size: 150,
              color: Colors.white.withAlpha(25),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(tier.icon, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '${tier.name} member',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Text('MEGA LOYALTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8)),
                ],
              ),
              const Spacer(),
              const Text(
                'COMMUTE POINTS BALANCE',
                style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '$_currentPoints',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'pts',
                    style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionCard(double progress, int ptsToNext, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Next Goal: Platinum Tier',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                '$ptsToNext pts to go',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: scheme.primary),
              )
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: Colors.indigoAccent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '* Platinum tier rewards earn double points on all travels.',
            style: TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(height: 14),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerkTile(String perk, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              perk,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipTiersCarousel(ColorScheme scheme) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tiers.length,
        itemBuilder: (context, idx) {
          final t = _tiers[idx];
          final isCurrent = t.name == _currentTierName;
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: t.gradientColors),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent ? Colors.white : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(t.icon, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      t.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isCurrent ? 'Current Tier' : 'Needs ${t.pointsRequired}',
                  style: const TextStyle(fontSize: 9, color: Colors.white70),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // --- SCREEN 2: POINTS HISTORY ---
  Widget _buildHistoryView(ColorScheme scheme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Points Transaction Ledger', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('Active logs', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 12),

        ..._transactions.map((tx) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline.withAlpha(45)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tx.isEarned ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tx.isEarned ? Icons.add_circle_outline : Icons.remove_circle_outline,
                    color: tx.isEarned ? Colors.green : Colors.redAccent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(tx.date, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      if (tx.expirationDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 10, color: Colors.redAccent),
                            const SizedBox(width: 4),
                            Text(
                              'Expiring on ${tx.expirationDate}',
                              style: const TextStyle(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
                Text(
                  tx.isEarned ? '+${tx.points} pts' : '-${tx.points} pts',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: tx.isEarned ? Colors.green : Colors.redAccent,
                  ),
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- SCREEN 3: REWARDS CATALOG ---
  Widget _buildCatalogView(ColorScheme scheme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Balance Banner
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Redeemable points balance', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.stars_rounded, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$_currentPoints pts',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: scheme.primary.withAlpha(24), borderRadius: BorderRadius.circular(10)),
                child: Text('Gold Level Member', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: scheme.primary)),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Catalog Rewards', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),

        ..._rewards.map((reward) {
          final bool isEligible = _currentPoints >= reward.pointsCost;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                  onTap: isEligible ? () => _confirmRedeem(reward) : null,
                  child: Opacity(
                    opacity: isEligible ? 1.0 : 0.5,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _getRewardCategoryColor(reward.category, scheme).withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _getRewardCategoryIcon(reward.category),
                              color: _getRewardCategoryColor(reward.category, scheme),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(reward.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getRewardCategoryColor(reward.category, scheme).withAlpha(30),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        reward.category,
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: _getRewardCategoryColor(reward.category, scheme),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(reward.description, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${reward.pointsCost}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: isEligible ? Colors.orangeAccent : Colors.grey,
                                ),
                              ),
                              const Text('pts', style: TextStyle(fontSize: 9, color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getRewardCategoryColor(String cat, ColorScheme scheme) {
    return switch (cat) {
      'Discount' => scheme.primary,
      'FreeRide' => Colors.green,
      'Cashback' => Colors.amber,
      'Package' => Colors.teal,
      _ => Colors.grey,
    };
  }

  IconData _getRewardCategoryIcon(String cat) {
    return switch (cat) {
      'Discount' => Icons.local_offer_rounded,
      'FreeRide' => Icons.confirmation_number_rounded,
      'Cashback' => Icons.monetization_on_rounded,
      'Package' => Icons.subscriptions_rounded,
      _ => Icons.stars_rounded,
    };
  }
}

// Custom Confetti physics painter
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
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size / 1.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}
