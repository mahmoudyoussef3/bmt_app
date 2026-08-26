import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/referrals/domain/entities/referral_rewards.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/cubit/referral_rewards_cubit.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/cubit/referral_rewards_state.dart';
import 'package:bmt_app/apps/client/features/referrals/presentation/widgets/referral_share_sheet.dart';
import 'package:bmt_app/apps/client/features/wallet/presentation/routes/wallet_routes.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

/// Localized label for a referral's lifecycle status. Statuses are computed
/// server-side (see `_statusLabel` in the Supabase datasource) from a fixed
/// set of canonical English values — this maps those to a translated label
/// and falls back to the raw value for anything unrecognized.
String _historyStatusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  return switch (status) {
    'Registered' => l10n.referral_statusRegistered,
    'First Order Completed' => l10n.referral_statusFirstOrderCompleted,
    'Reward Granted' => l10n.referral_statusRewardGranted,
    'Pending Registration' => l10n.referral_statusPendingRegistration,
    _ => status,
  };
}

/// Locale-aware display for a `yyyy-MM-dd` date from the datasource. Falls
/// back to the raw value if it isn't parseable (defensive against legacy or
/// malformed data).
String _displayDate(BuildContext context, String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;
  return FormatUtil.date(context, parsed);
}

class ReferralRewardsScreen extends StatefulWidget {
  const ReferralRewardsScreen({super.key});

  @override
  State<ReferralRewardsScreen> createState() => _ReferralRewardsScreenState();
}

class _ReferralRewardsScreenState extends State<ReferralRewardsScreen> {
  int _currentView = 1;

  ReferralRewardsData? _data;

  String get _referralCode => _data?.referralCode ?? '';

  int get _totalInvites => _data?.totalInvites ?? 0;

  int get _successfulReferrals => _data?.successfulReferrals ?? 0;

  int get _pendingReferrals => _data?.pendingReferrals ?? 0;

  List<ReferralLeaderboardEntry> get _leaderboard =>
      _data?.leaderboard ?? const [];

  int get _earnedRewardsTotal => _data?.earnedRewardsTotal ?? 0;

  int get _walletBalance => _data?.walletBalance ?? 0;

  List<ReferralHistoryItem> get _history => _data?.history ?? const [];

  List<ScratchVoucher> get _vouchers => _data?.vouchers ?? const [];

  final ConfettiController _confetti = ConfettiController();

  final List<Offset?> _scratchPoints = [];
  bool _scratchCompleted = false;

  @override
  void initState() {
    super.initState();

    context.read<ReferralRewardsCubit>().load();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

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

  String _getViewTitle(BuildContext context) {
    final l10n = context.l10n;
    return switch (_currentView) {
      1 => l10n.referral_titleMain,
      2 => l10n.referral_titleInvite,
      3 => l10n.referral_titleHistory,
      4 => l10n.referral_titleWallet,
      _ => l10n.referral_titleHub,
    };
  }

  void _copyReferralCode() {
    final code = _referralCode;
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.referral_codeCopiedSnack),
        backgroundColor: ClientColors.journeyCyan,
      ),
    );
  }

  void _shareReferralLink() {
    final code = _referralCode;
    if (code.isEmpty) return;
    ReferralShareSheet.show(context, code);
  }

  /// Opens the real wallet.
  ///
  /// This used to be `_redeemRewards()`, which called a datasource that zeroed
  /// `loyalty_accounts.wallet_balance` client-side and celebrated a payout the
  /// database had silently refused (RLS denied the write without throwing).
  /// Referral rewards now land as a real wallet entry granted by the office
  /// that owes them, so the only honest action here is to go and look at it.
  void _openWallet() {
    Navigator.of(context).pushNamed(WalletRoutes.wallet);
  }

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
                      color: ClientColors.borderStrongFor(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    voucher.title,
                    style: ClientTypography.bodyLarge(
                      context,
                    ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.referral_scratchSubtitle,
                    style: ClientTypography.labelSmall(context).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                      color: ClientColors.textSecondaryFor(context),
                    ),
                  ),
                  const SizedBox(height: 24),

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
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    voucher.amount,
                                    style: ClientTypography.priceHero(context)
                                        .copyWith(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: scheme.primary,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    voucher.description,
                                    textAlign: TextAlign.center,
                                    style: ClientTypography.labelSmall(context)
                                        .copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.normal,
                                          color: ClientColors.textSecondaryFor(
                                            context,
                                          ),
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
                                          style:
                                              ClientTypography.bodyMedium(
                                                context,
                                              ).copyWith(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: scheme.primary,
                                                letterSpacing: 1,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.copy,
                                          size: 14,
                                          color: ClientColors.textSecondaryFor(
                                            context,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (!_scratchCompleted)
                              GestureDetector(
                                onPanUpdate: (details) {
                                  final renderBox =
                                      context.findRenderObject() as RenderBox?;
                                  if (renderBox != null) {
                                    final localPos = renderBox.globalToLocal(
                                      details.globalPosition,
                                    );

                                    final cardOffset = Offset(
                                      localPos.dx - 48,
                                      localPos.dy - 100,
                                    );
                                    setModalState(() {
                                      _scratchPoints.add(cardOffset);

                                      if (_scratchPoints.length > 80) {
                                        _scratchCompleted = true;
                                        _confetti.fire();

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
                                    _scratchPoints.add(null);
                                  });
                                },
                                child: CustomPaint(
                                  size: const Size(280, 180),
                                  painter: ScratchCardPainter(
                                    _scratchPoints,
                                    scheme,
                                    context.l10n.referral_scratchWithFinger,
                                    context.isRtl
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
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
                        ? context.l10n.referral_claimReward
                        : context.l10n.referral_scratchToReveal,
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (!_scratchCompleted) {
                        setState(() {
                          _scratchCompleted = true;
                          context.read<ReferralRewardsCubit>().reveal(voucher);
                          _confetti.fire();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<ReferralRewardsCubit, ReferralRewardsState>(
      builder: (context, state) {
        if (state is ReferralRewardsLoaded) {
          _data = state.data;
        }

        return PopScope(
          canPop: _currentView == 1,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _onBackPress();
          },
          child: Scaffold(
            backgroundColor: scheme.surfaceContainerHighest,
            appBar: ClientAppBar(
              title: _getViewTitle(context),
              onBack: _onBackPress,
              actions: [
                IconButton(
                  tooltip: context.l10n.referral_refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => context.read<ReferralRewardsCubit>().load(),
                ),
              ],
            ),
            body: SafeArea(
              child: switch (state) {
                ReferralRewardsLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ReferralRewardsError(:final message) => EmptyState(
                  title: context.l10n.referral_rewardsUnavailable,
                  subtitle: message,
                ),
                ReferralRewardsLoaded() => Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildCurrentView(scheme),
                    ),

                    ConfettiOverlay(controller: _confetti),
                  ],
                ),
              },
            ),
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

  Widget _buildDashboardView(ColorScheme scheme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        _buildMilestoneProgressCard(scheme),
        const SizedBox(height: 18),

        _buildStatsGrid(scheme),
        const SizedBox(height: 18),

        _buildReferralCodeCard(scheme),
        const SizedBox(height: 18),

        if (_leaderboard.isNotEmpty) ...[
          _buildLeaderboardCard(scheme),
          const SizedBox(height: 18),
        ],

        _buildQuickNavOptions(scheme),
      ],
    );
  }

  Widget _buildLeaderboardCard(ColorScheme scheme) {
    final entries = _leaderboard.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: ClientColors.journeyAmber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.referral_leaderboardTitle,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in entries) _buildLeaderboardRow(entry, scheme),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(
    ReferralLeaderboardEntry entry,
    ColorScheme scheme,
  ) {
    final medal = switch (entry.rank) {
      1 => ClientColors.journeyAmber,
      2 => Colors.blueGrey.shade300,
      3 => Colors.brown.shade400,
      _ => scheme.surfaceContainerHighest,
    };
    final highlight = entry.isCurrentUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? scheme.primary.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: highlight
            ? Border.all(color: scheme.primary.withAlpha(70))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: medal, shape: BoxShape.circle),
            child: Text(
              '${entry.rank}',
              style: ClientTypography.labelMedium(context).copyWith(
                fontWeight: FontWeight.w900,
                color: entry.rank <= 3 ? Colors.white : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              highlight
                  ? '${entry.name} (${context.l10n.referral_you})'
                  : entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.bodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.l10n.referral_referralsCount(entry.successfulCount),
                style: ClientTypography.labelMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                context.l10n.referral_egpTotal(entry.totalRewards),
                style: ClientTypography.labelSmall(context).copyWith(
                  fontWeight: FontWeight.normal,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
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

    final l10n = context.l10n;
    final milestoneLabel = current == 0
        ? l10n.referral_milestoneFirst
        : remaining == 0
        ? l10n.referral_milestoneReached
        : l10n.referral_milestoneNext;

    final milestoneDesc = current == 0
        ? l10n.referral_milestoneDescFirst(target)
        : remaining == 0
        ? l10n.referral_milestoneDescReached
        : l10n.referral_milestoneDescNext(remaining);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(38),
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
                  color: ClientColors.journeyAmber,
                ),
              ),
              Icon(
                remaining == 0
                    ? Icons.emoji_events_rounded
                    : Icons.people_alt_rounded,
                color: ClientColors.journeyAmber,
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
                  style: ClientTypography.bodyLarge(context).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  milestoneDesc,
                  style: ClientTypography.bodySmall(context).copyWith(
                    fontSize: 11,
                    color: scheme.onSurface.withAlpha(180),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.referral_progressCount(current, target),
                  style: ClientTypography.labelSmall(context).copyWith(
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
      crossAxisCount: 2,
      childAspectRatio: 1.7,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildStatCard(
          context.l10n.referral_statTotalInvites,
          '$_totalInvites',
          Icons.people_outline_rounded,
          scheme.secondary,
        ),
        _buildStatCard(
          context.l10n.referral_statSuccessful,
          '$_successfulReferrals',
          Icons.check_circle_outline_rounded,
          ClientColors.journeyCyan,
        ),
        _buildStatCard(
          context.l10n.referral_pending,
          '$_pendingReferrals',
          Icons.hourglass_bottom_rounded,
          ClientColors.journeyAmber,
        ),
        _buildStatCard(
          context.l10n.referral_statTotalEarned,
          context.l10n.referral_egpTotal(_earnedRewardsTotal),
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
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ClientTypography.labelSmall(context).copyWith(
              fontSize: 9,
              fontWeight: FontWeight.normal,
              color: ClientColors.textSecondaryFor(context),
            ),
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
          Text(
            context.l10n.referral_yourCodeLabel,
            style: ClientTypography.labelMedium(context).copyWith(
              fontSize: 11,
              color: ClientColors.textSecondaryFor(context),
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
                        style: ClientTypography.bodyMedium(context).copyWith(
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
                  label: context.l10n.referral_inviteFriendsNow,
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
          title: context.l10n.referral_titleWallet,
          subtitle: context.l10n.referral_walletSubtitle,
          badgeText: _walletBalance > 0
              ? context.l10n.referral_claimableBadge(_walletBalance)
              : null,
          color: ClientColors.journeyAmber,
          onTap: () => setState(() => _currentView = 4),
          scheme: scheme,
        ),
        const SizedBox(height: 10),
        _buildQuickNavTile(
          icon: Icons.history_rounded,
          title: context.l10n.referral_logsHistoryTitle,
          subtitle: context.l10n.referral_logsHistorySubtitle,
          color: ClientColors.journeyCyan,
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
                              style: ClientTypography.bodyMedium(context)
                                  .copyWith(
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
                                  color: ClientColors.journeyAmber.withAlpha(
                                    40,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badgeText,
                                  style: ClientTypography.labelSmall(context)
                                      .copyWith(
                                        fontSize: 8,
                                        color: ClientColors.journeyAmber,
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
                          style: ClientTypography.labelSmall(context).copyWith(
                            fontWeight: FontWeight.normal,
                            color: ClientColors.textSecondaryFor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DirectionalIcon(
                    Icons.chevron_right_rounded,
                    color: ClientColors.textSecondaryFor(context),
                  ),
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
          title: Center(
            child: Text(
              context.l10n.referral_scanToJoin,
              style: ClientTypography.bodyLarge(
                context,
              ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                context.l10n.referral_qrHint,
                textAlign: TextAlign.center,
                style: ClientTypography.bodySmall(context).copyWith(
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
                child: Text(context.l10n.referral_close),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInviteView(ColorScheme scheme) {
    return ListView(
      key: const ValueKey('view2'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
      children: [
        _buildInviteShareHeader(scheme),
        const SizedBox(height: 16),

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
              Text(
                context.l10n.referral_yourCodeLabel,
                style: ClientTypography.labelMedium(context).copyWith(
                  fontSize: 11,
                  color: ClientColors.textSecondaryFor(context),
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
                            style: ClientTypography.bodyMedium(context)
                                .copyWith(
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
              Text(
                context.l10n.referral_howItWorks,
                style: ClientTypography.labelMedium(context).copyWith(
                  fontSize: 12,
                  color: ClientColors.textSecondaryFor(context),
                ),
              ),
              const SizedBox(height: 14),
              _buildHowItWorksStep(
                scheme,
                number: '1',
                title: context.l10n.referral_step1Title,
                subtitle: context.l10n.referral_step1Subtitle,
                color: scheme.primary,
              ),
              const SizedBox(height: 12),
              _buildHowItWorksStep(
                scheme,
                number: '2',
                title: context.l10n.referral_step2Title,
                subtitle: context.l10n.referral_step2Subtitle,
                color: ClientColors.journeyAmber,
              ),
              const SizedBox(height: 12),
              _buildHowItWorksStep(
                scheme,
                number: '3',
                title: context.l10n.referral_step3Title,
                subtitle: context.l10n.referral_step3Subtitle,
                color: ClientColors.journeyCyan,
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
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w900, color: color),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ClientTypography.labelMedium(
                  context,
                ).copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: ClientTypography.labelSmall(context).copyWith(
                  fontWeight: FontWeight.normal,
                  color: ClientColors.textSecondaryFor(context),
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
          Text(
            context.l10n.referral_directShareOptions,
            style: ClientTypography.labelMedium(context).copyWith(
              fontSize: 11,
              color: ClientColors.textSecondaryFor(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInviteOptionButton(
                Icons.share_rounded,
                context.l10n.referral_shareLink,
                _shareReferralLink,
                scheme,
              ),
              _buildInviteOptionButton(
                Icons.qr_code_2_rounded,
                context.l10n.referral_showQr,
                _showQRDialog,
                scheme,
              ),
              _buildInviteOptionButton(
                Icons.copy_rounded,
                context.l10n.referral_copyCode,
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
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView(ColorScheme scheme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.referral_referralsLog,
              style: ClientTypography.bodyMedium(context).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: ClientColors.textSecondaryFor(context),
              ),
            ),
            Text(
              context.l10n.referral_totalReferralsCount(_history.length),
              style: ClientTypography.labelSmall(context).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: ClientColors.textSecondaryFor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ..._history.map((item) {
          Color statusColor = ClientColors.textSecondaryFor(context);
          if (item.status == 'Reward Granted') {
            statusColor = ClientColors.journeyCyan;
          } else if (item.status == 'Pending Registration') {
            statusColor = ClientColors.journeyAmber;
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
                        style: ClientTypography.bodyMedium(
                          context,
                        ).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.referral_invitedOn(
                          _displayDate(context, item.date),
                        ),
                        style: ClientTypography.labelSmall(context).copyWith(
                          fontWeight: FontWeight.normal,
                          color: ClientColors.textSecondaryFor(context),
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
                          ? context.l10n.referral_egpEarned(item.rewardAmount)
                          : context.l10n.referral_egpZero,
                      style: ClientTypography.labelMedium(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: item.rewardAmount > 0
                            ? scheme.primary
                            : ClientColors.textSecondaryFor(context),
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
                        _historyStatusLabel(context, item.status),
                        style: ClientTypography.labelSmall(
                          context,
                        ).copyWith(fontSize: 8, color: statusColor),
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

  Widget _buildWalletView(ColorScheme scheme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _buildWalletBalancesCard(scheme),
        const SizedBox(height: 24),

        Text(
          context.l10n.referral_claimVouchersTitle,
          style: ClientTypography.bodyMedium(context).copyWith(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ClientColors.textSecondaryFor(context),
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
        color: scheme.primary.withAlpha(20),
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
                  Text(
                    context.l10n.referral_walletLabel,
                    style: ClientTypography.labelMedium(context).copyWith(
                      fontSize: 11,
                      color: ClientColors.textSecondaryFor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasBalance
                        ? context.l10n.referral_walletAvailable(_walletBalance)
                        : context.l10n.referral_noBalanceYet,
                    style: ClientTypography.priceMedium(context).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: hasBalance
                          ? scheme.primary
                          : ClientColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hasBalance
                ? context.l10n.referral_walletCreditHint
                : context.l10n.referral_earnBalanceHint,
            style: ClientTypography.bodySmall(context).copyWith(
              fontSize: 11,
              color: scheme.onSurface.withAlpha(155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: scheme.outline.withAlpha(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.l10n.referral_openWallet,
                style: ClientTypography.bodyMedium(context).copyWith(
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
                          : ClientColors.journeyAmber.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      voucher.isRevealed
                          ? Icons.card_giftcard_rounded
                          : Icons.lock_outline_rounded,
                      color: voucher.isRevealed
                          ? scheme.primary
                          : ClientColors.journeyAmber,
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
                          style: ClientTypography.bodyMedium(
                            context,
                          ).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          voucher.isRevealed
                              ? context.l10n.referral_revealedCode(
                                  voucher.promoCode,
                                )
                              : context.l10n.referral_lockedScratchToReveal,
                          style: ClientTypography.labelSmall(context).copyWith(
                            color: voucher.isRevealed
                                ? ClientColors.journeyCyan
                                : ClientColors.textSecondaryFor(context),
                            fontWeight: voucher.isRevealed
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DirectionalIcon(
                    Icons.chevron_right_rounded,
                    color: ClientColors.textSecondaryFor(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScratchCardPainter extends CustomPainter {
  final List<Offset?> points;
  final ColorScheme scheme;
  final String label;
  final TextDirection textDirection;

  ScratchCardPainter(this.points, this.scheme, this.label, this.textDirection);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.fill;

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ),
      paint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: textDirection,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

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

class QRPainter extends CustomPainter {
  final Color primaryColor;

  QRPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawRect(const Rect.fromLTWH(0, 0, 40, 40), paint);
    canvas.drawRect(
      const Rect.fromLTWH(8, 8, 24, 24),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      const Rect.fromLTWH(12, 12, 16, 16),
      Paint()..color = primaryColor,
    );

    canvas.drawRect(Rect.fromLTWH(size.width - 40, 0, 40, 40), paint);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 32, 8, 24, 24),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 28, 12, 16, 16),
      Paint()..color = primaryColor,
    );

    canvas.drawRect(Rect.fromLTWH(0, size.height - 40, 40, 40), paint);
    canvas.drawRect(
      Rect.fromLTWH(8, size.height - 32, 24, 24),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(12, size.height - 28, 16, 16),
      Paint()..color = primaryColor,
    );

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
