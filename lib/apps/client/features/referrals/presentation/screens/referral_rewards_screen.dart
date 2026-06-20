import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/features/referrals/domain/entities/referral_rewards.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/cubit/referral_rewards_cubit.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/cubit/referral_rewards_state.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

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
    vy += 0.2; // Gravity
    vx *= 0.98; // Air resistance
    rotation += rotationSpeed;
  }
}

class ReferralRewardsScreen extends StatefulWidget {
  const ReferralRewardsScreen({super.key});

  @override
  State<ReferralRewardsScreen> createState() => _ReferralRewardsScreenState();
}

class _ReferralRewardsScreenState extends State<ReferralRewardsScreen>
    with TickerProviderStateMixin {
  // Views:
  // 1 = Referral Dashboard
  // 2 = Invite Friends Screen
  // 3 = Referral History Screen
  // 4 = Rewards Wallet Screen
  int _currentView = 1;

  ReferralRewardsData? _data;

  String get _referralCode => _data?.referralCode ?? '';

  int get _totalInvites => _data?.totalInvites ?? 0;

  int get _successfulReferrals => _data?.successfulReferrals ?? 0;

  int get _earnedRewardsTotal => _data?.earnedRewardsTotal ?? 0;

  int get _walletBalance => _data?.walletBalance ?? 0;

  List<ReferralHistoryItem> get _history => _data?.history ?? const [];

  List<ScratchVoucher> get _vouchers => _data?.vouchers ?? const [];

  // Confetti Animation Controller & loop
  late AnimationController _confettiController;
  final List<ConfettiParticle> _particles = [];
  Timer? _confettiTimer;

  // Scratch card parameters
  final List<Offset?> _scratchPoints = [];
  bool _scratchCompleted = false;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    context.read<ReferralRewardsCubit>().load();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _confettiTimer?.cancel();
    super.dispose();
  }

  // --- ACTIONS ---

  void _onBackPress() {
    if (_currentView > 1) {
      setState(() {
        _currentView = 1;
        _scratchPoints.clear();
        _scratchCompleted = false;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  String _getViewTitle() {
    return switch (_currentView) {
      1 => 'Referrals & Rewards',
      2 => 'Invite Friends',
      3 => 'Referral History',
      4 => 'Rewards Wallet',
      _ => 'Referral Hub',
    };
  }

  void _copyReferralCode() {
    final code = _referralCode;
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareReferralLink() {
    final code = _referralCode;
    if (code.isEmpty) return;
    final message =
        'Join me on BMT and book your daily commute! '
        'Use my referral code $code to get started.';
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite message copied — share it with your friends!'),
      ),
    );
  }

  // Trigger custom confetti explosion
  void _triggerConfetti() {
    final random = math.Random();
    _particles.clear();
    for (int i = 0; i < 80; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final speed = 4 + random.nextDouble() * 10;
      _particles.add(
        ConfettiParticle(
          x: MediaQuery.of(context).size.width / 2,
          y: MediaQuery.of(context).size.height / 3,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 5, // Upward bias
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
        // Remove particles offscreen
        _particles.removeWhere((p) => p.y > MediaQuery.of(context).size.height);
      });
      if (_particles.isEmpty) {
        timer.cancel();
      }
    });
  }

  // Redeem Available points
  void _redeemRewards() {
    if (_walletBalance == 0) return;
    final redeemed = context.read<ReferralRewardsCubit>().redeem();

    _triggerConfetti();

    showDialog(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Center(child: Text('Redemption Successful! 🎉')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Rewards have been converted and transferred directly to your Main Wallet Balance!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              Text(
                'Successfully Transferred',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withAlpha(150),
                ),
              ),
              Text(
                'EGP $redeemed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: AppButton(
                label: 'Awesome',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }

  // Scratch card interaction
  void _openScratchCard(ScratchVoucher voucher) {
    setState(() {
      _scratchPoints.clear();
      _scratchCompleted = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final scheme = Theme.of(context).colorScheme;
            return Container(
              height: 480,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    voucher.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scratch card to reveal your promotional reward code!',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Scratch area stack
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 280,
                        height: 180,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: scheme.outline.withAlpha(50),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Back layer (Reward details)
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    voucher.amount,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    voucher.description,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withAlpha(30),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: scheme.primary.withAlpha(80),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          voucher.promoCode,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: scheme.primary,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.copy,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Scratch Layer Custom paint
                            if (!_scratchCompleted)
                              GestureDetector(
                                onPanUpdate: (details) {
                                  final renderBox =
                                      context.findRenderObject() as RenderBox?;
                                  if (renderBox != null) {
                                    final localPos = renderBox.globalToLocal(
                                      details.globalPosition,
                                    );
                                    // Adjust for modal layout offset
                                    final cardOffset = Offset(
                                      localPos.dx - 48,
                                      localPos.dy - 100,
                                    );
                                    setModalState(() {
                                      _scratchPoints.add(cardOffset);
                                      // If scratched enough, automatically resolve
                                      if (_scratchPoints.length > 80) {
                                        _scratchCompleted = true;
                                        _triggerConfetti();
                                        // Update state of voucher
                                        setState(() {
                                          context
                                              .read<ReferralRewardsCubit>()
                                              .reveal(voucher);
                                        });
                                      }
                                    });
                                  }
                                },
                                onPanEnd: (_) {
                                  setModalState(() {
                                    _scratchPoints.add(null); // break line
                                  });
                                },
                                child: CustomPaint(
                                  size: const Size(280, 180),
                                  painter: ScratchCardPainter(
                                    _scratchPoints,
                                    scheme,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  AppButton(
                    label: _scratchCompleted
                        ? 'Claim Reward'
                        : 'Scratch card to reveal',
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (!_scratchCompleted) {
                        setState(() {
                          _scratchCompleted = true;
                          context.read<ReferralRewardsCubit>().reveal(voucher);
                          _triggerConfetti();
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- RENDERS ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<ReferralRewardsCubit, ReferralRewardsState>(
      builder: (context, state) {
        if (state is ReferralRewardsLoaded) {
          _data = state.data;
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
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            elevation: 0,
          ),
          body: SafeArea(
            child: switch (state) {
              ReferralRewardsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              ReferralRewardsError(:final message) => EmptyState(
                title: 'Rewards unavailable',
                subtitle: message,
              ),
              ReferralRewardsLoaded() => Stack(
                children: [
                  // Core view
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
            },
          ),
        );
      },
    );
  }

  Widget _buildCurrentView(ColorScheme scheme) {
    return switch (_currentView) {
      1 => _buildDashboardView(scheme),
      2 => _buildInviteView(scheme),
      3 => _buildHistoryView(scheme),
      4 => _buildWalletView(scheme),
      _ => const SizedBox.shrink(),
    };
  }

  // --- SCREEN 1: REFERRAL DASHBOARD ---
  Widget _buildDashboardView(ColorScheme scheme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        // Gamified Milestone Ring
        _buildMilestoneProgressCard(scheme),
        const SizedBox(height: 18),

        // Metrics Grid (Stats)
        _buildStatsGrid(scheme),
        const SizedBox(height: 18),

        // Referral Code Card
        _buildReferralCodeCard(scheme),
        const SizedBox(height: 18),

        // Quick Navigation rows
        _buildQuickNavOptions(scheme),
      ],
    );
  }

  static int _nextMilestone(int current) {
    if (current < 3) return 3;
    if (current < 5) return 5;
    if (current < 10) return 10;
    return ((current ~/ 10) + 1) * 10;
  }

  Widget _buildMilestoneProgressCard(ColorScheme scheme) {
    final current = _successfulReferrals;
    final target = _nextMilestone(current);
    final remaining = (target - current).clamp(0, target);
    final progress = (current / target).clamp(0.0, 1.0);

    final milestoneLabel = current == 0
        ? 'First Referral Milestone'
        : remaining == 0
        ? 'Milestone Reached!'
        : 'Next Referral Milestone';

    final milestoneDesc = current == 0
        ? 'Invite $target friends to unlock your first referral bonus.'
        : remaining == 0
        ? 'Great work! You have reached the current milestone.'
        : 'Invite $remaining more friend${remaining == 1 ? '' : 's'} to unlock your next reward.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary.withAlpha(50), scheme.tertiary.withAlpha(20)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withAlpha(80)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: scheme.surface.withAlpha(100),
                  color: Colors.orangeAccent,
                ),
              ),
              Icon(
                remaining == 0
                    ? Icons.emoji_events_rounded
                    : Icons.people_alt_rounded,
                color: Colors.orangeAccent,
                size: 28,
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestoneLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  milestoneDesc,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withAlpha(180),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Progress: $current / $target referrals',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ColorScheme scheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 0.9,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildStatCard(
          'Total Invites',
          '$_totalInvites',
          Icons.people_outline_rounded,
          scheme.secondary,
        ),
        _buildStatCard(
          'Successful',
          '$_successfulReferrals',
          Icons.check_circle_outline_rounded,
          Colors.green,
        ),
        _buildStatCard(
          'Total Earned',
          'EGP $_earnedRewardsTotal',
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
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard(ColorScheme scheme) {
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
          const Text(
            'Your Referral Code',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outline.withAlpha(45)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _referralCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: _copyReferralCode,
                        child: Icon(
                          Icons.copy_rounded,
                          color: scheme.primary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showQRDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Invite Friends Now',
                  onPressed: () => setState(() => _currentView = 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNavOptions(ColorScheme scheme) {
    return Column(
      children: [
        _buildQuickNavTile(
          icon: Icons.wallet_giftcard_rounded,
          title: 'Rewards Wallet',
          subtitle: 'Scratch vouchers & redeem balances',
          badgeText: _walletBalance > 0
              ? 'EGP $_walletBalance Claimable'
              : null,
          color: Colors.orangeAccent,
          onTap: () => setState(() => _currentView = 4),
          scheme: scheme,
        ),
        const SizedBox(height: 10),
        _buildQuickNavTile(
          icon: Icons.history_rounded,
          title: 'Referral Logs & History',
          subtitle: 'Track status of invites and code claims',
          color: Colors.teal,
          onTap: () => setState(() => _currentView = 3),
          scheme: scheme,
        ),
      ],
    );
  }

  Widget _buildQuickNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badgeText,
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (badgeText != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withAlpha(40),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badgeText,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQRDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Center(
            child: Text(
              'Scan to Join BMT',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Beautiful simulated QR Code vector
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outline, width: 2),
                ),
                padding: const EdgeInsets.all(12),
                child: CustomPaint(
                  size: const Size(160, 160),
                  painter: QRPainter(scheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Let friends scan this QR to automatically register with your code!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withAlpha(150),
                  height: 1.3,
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- SCREEN 2: INVITE FRIENDS ---
  Widget _buildInviteView(ColorScheme scheme) {
    return ListView(
      key: const ValueKey('view2'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
      children: [
        // Quick Share Header Card
        _buildInviteShareHeader(scheme),
        const SizedBox(height: 16),

        // Referral code highlight
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outline.withAlpha(50)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your referral code',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.outline.withAlpha(45)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _referralCode,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          GestureDetector(
                            onTap: _copyReferralCode,
                            child: Icon(
                              Icons.copy_rounded,
                              color: scheme.primary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showQRDialog,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // How it works
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outline.withAlpha(50)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How it works',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 14),
              _buildHowItWorksStep(
                scheme,
                number: '1',
                title: 'Share your code',
                subtitle: 'Send your unique code to friends via any channel.',
                color: scheme.primary,
              ),
              const SizedBox(height: 12),
              _buildHowItWorksStep(
                scheme,
                number: '2',
                title: 'Friend registers',
                subtitle:
                    'They sign up and complete their first trip using your code.',
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 12),
              _buildHowItWorksStep(
                scheme,
                number: '3',
                title: 'You both earn',
                subtitle:
                    'You receive a referral reward credited to your wallet.',
                color: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksStep(
    ColorScheme scheme, {
    required String number,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(22),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
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
                subtitle,
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
    );
  }

  Widget _buildInviteShareHeader(ColorScheme scheme) {
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Direct Share Options',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInviteOptionButton(
                Icons.share_rounded,
                'Share Link',
                _shareReferralLink,
                scheme,
              ),
              _buildInviteOptionButton(
                Icons.qr_code_2_rounded,
                'Show QR',
                _showQRDialog,
                scheme,
              ),
              _buildInviteOptionButton(
                Icons.copy_rounded,
                'Copy Code',
                _copyReferralCode,
                scheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInviteOptionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    ColorScheme scheme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primary.withAlpha(24),
            child: Icon(icon, color: scheme.primary, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 3: REFERRAL HISTORY SCREEN ---
  Widget _buildHistoryView(ColorScheme scheme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Referrals Log',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            Text(
              '${_history.length} total referrals',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ..._history.map((item) {
          Color statusColor = Colors.grey;
          if (item.status == 'Completed') {
            statusColor = Colors.green;
          } else if (item.status == 'Pending') {
            statusColor = Colors.amber;
          }

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
                AppAvatar(
                  initials: item.name.split(' ').map((e) => e[0]).join(),
                  radius: 18,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invited: ${item.date}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.rewardAmount > 0
                          ? '+ EGP ${item.rewardAmount}'
                          : 'EGP 0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: item.rewardAmount > 0
                            ? scheme.primary
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(24),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- SCREEN 4: REWARDS WALLET SCREEN ---
  Widget _buildWalletView(ColorScheme scheme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Available Balances Box
        _buildWalletBalancesCard(scheme),
        const SizedBox(height: 24),

        // Unscratched Cards
        const Text(
          'Claim Reward Vouchers',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ..._vouchers.map((voucher) => _buildVoucherCard(voucher, scheme)),
      ],
    );
  }

  Widget _buildWalletBalancesCard(ColorScheme scheme) {
    final hasBalance = _walletBalance > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withAlpha(18),
            scheme.secondaryContainer.withAlpha(22),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Referral Wallet',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasBalance
                        ? 'EGP $_walletBalance available'
                        : 'No balance yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: hasBalance ? scheme.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hasBalance
                ? 'You can transfer this balance to your main wallet.'
                : 'Earn balance by inviting friends with your referral code.',
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withAlpha(155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasBalance ? _redeemRewards : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: scheme.outline.withAlpha(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                hasBalance ? 'Redeem to Wallet' : 'No balance to redeem',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(ScratchVoucher voucher, ColorScheme scheme) {
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
            onTap: () => _openScratchCard(voucher),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: voucher.isRevealed
                          ? scheme.primary.withAlpha(20)
                          : Colors.orangeAccent.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      voucher.isRevealed
                          ? Icons.card_giftcard_rounded
                          : Icons.lock_outline_rounded,
                      color: voucher.isRevealed
                          ? scheme.primary
                          : Colors.orangeAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          voucher.isRevealed
                              ? 'Revealed Code: ${voucher.promoCode}'
                              : 'Locked - Scratch to reveal',
                          style: TextStyle(
                            fontSize: 10,
                            color: voucher.isRevealed
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: voucher.isRevealed
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painter to draw scratch card metallic layer
class ScratchCardPainter extends CustomPainter {
  final List<Offset?> points;
  final ColorScheme scheme;

  ScratchCardPainter(this.points, this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.fill;

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Draw card background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ),
      paint,
    );

    // Draw scratch text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Scratch with finger!',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    // Draw clear lines
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 32.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, clearPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScratchCardPainter oldDelegate) => true;
}

// Confetti particle painter overlay
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

// Custom Painter to draw a simulated QR Code
class QRPainter extends CustomPainter {
  final Color primaryColor;

  QRPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Outer framing squares (simulating standard QR finder patterns)
    // Top Left
    canvas.drawRect(const Rect.fromLTWH(0, 0, 40, 40), paint);
    canvas.drawRect(
      const Rect.fromLTWH(8, 8, 24, 24),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      const Rect.fromLTWH(12, 12, 16, 16),
      Paint()..color = primaryColor,
    );

    // Top Right
    canvas.drawRect(Rect.fromLTWH(size.width - 40, 0, 40, 40), paint);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 32, 8, 24, 24),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 28, 12, 16, 16),
      Paint()..color = primaryColor,
    );

    // Bottom Left
    canvas.drawRect(Rect.fromLTWH(0, size.height - 40, 40, 40), paint);
    canvas.drawRect(
      Rect.fromLTWH(8, size.height - 32, 24, 24),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(12, size.height - 28, 16, 16),
      Paint()..color = primaryColor,
    );

    // Draw some random dot grids representing data
    final random = math.Random(12345);
    paint.color = Colors.black;
    const dotSize = 8.0;
    for (double x = 48.0; x < size.width - 48.0; x += dotSize) {
      for (double y = 48.0; y < size.height - 48.0; y += dotSize) {
        if (random.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x, y, dotSize - 2, dotSize - 2), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant QRPainter oldDelegate) => false;
}
