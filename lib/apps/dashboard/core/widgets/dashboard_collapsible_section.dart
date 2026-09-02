import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// The one collapsible section used across every dashboard module.
///
/// Renders a titled card whose body the operator can fold away — filters, KPI
/// strips, charts, tables, activity feeds. Having a single widget (rather than
/// each module hand-rolling an `ExpansionTile`) is what keeps the interaction
/// identical everywhere: same header shape, same chevron, same motion, same
/// session memory.
///
/// Three behaviours are worth knowing about:
///
/// **Session memory.** Pass a [sectionId] and the expanded/collapsed choice is
/// remembered in [DashboardSectionStateStore] for the rest of the session, so
/// navigating Trips → Fleet → Trips brings the operator's layout back. Without a
/// [sectionId] the section is uncontrolled and simply starts at
/// [initiallyExpanded].
///
/// **Collapsed summaries.** [collapsedSummary] renders in place of the body
/// while collapsed, so a folded section still answers "do I need to open this?"
/// — "٣ عوامل تصفية مطبقة", "إيراد اليوم ١٢٬٤٠٠ ج.م". Use [DashboardSectionSummary]
/// for the standard chip row.
///
/// **Cheap while collapsed.** The body is not built at all until its first
/// expansion, and once collapsed it is parked under an [Offstage] with its
/// tickers muted — it keeps its state (scroll offsets, chart selections, table
/// pagination) but costs no layout, paint or animation. That is the difference
/// between this and swapping the child for a `SizedBox.shrink()`, which would
/// throw the operator's state away every time they folded a panel.
class DashboardCollapsibleSection extends StatefulWidget {
  /// Stable key for session memory. Use a [DashboardSectionIds] constant.
  /// When null the section does not remember anything across rebuilds.
  final String? sectionId;

  /// Leading glyph. Prefer a `DashboardIcons` entry over a bare `Icons.*`.
  final IconData? icon;

  final String title;
  final String? subtitle;

  /// Header-trailing widgets (buttons, menus, chips). They sit before the
  /// chevron and handle their own taps — pressing one never toggles the section.
  final List<Widget> actions;

  /// State used the first time this section is seen in a session. A remembered
  /// [sectionId] state always wins over this.
  final bool initiallyExpanded;

  final Widget child;

  /// Shown instead of [child] while collapsed. Keep it to one line.
  final Widget? collapsedSummary;

  final Duration animationDuration;

  /// Fired on every operator-driven toggle with the new expanded state.
  final ValueChanged<bool>? onExpansionChanged;

  /// Full padding around [child]. The default matches [DashboardPanel]'s inset;
  /// pass [EdgeInsets.zero] for bodies that draw their own edges, such as a
  /// table frame that should meet the card border.
  final EdgeInsetsGeometry bodyPadding;

  /// Padding around the header row. Zero it when the section is nested in a
  /// container that already insets its children — a `DashboardModuleHeader`
  /// child slot, say — where the default would read as a double inset.
  final EdgeInsetsGeometry headerPadding;

  /// Whether to draw the surrounding [AppCard].
  ///
  /// False for sections nested inside a card that already exists — a filters row
  /// under a queue tab bar, say. Card-in-card is the one way this widget can
  /// look wrong, so the nested case gets its own constructor rather than
  /// leaving each caller to remember.
  final bool card;

  const DashboardCollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.sectionId,
    this.icon,
    this.subtitle,
    this.actions = const [],
    this.initiallyExpanded = true,
    this.collapsedSummary,
    this.animationDuration = AppTokens.motionSlow,
    this.onExpansionChanged,
    this.bodyPadding = const EdgeInsets.fromLTRB(
      AppSpacing.medium,
      0,
      AppSpacing.medium,
      AppSpacing.medium,
    ),
    this.headerPadding = const EdgeInsets.all(AppSpacing.medium),
  }) : card = true;

  /// A collapsible section without its own card surface, for nesting inside one.
  const DashboardCollapsibleSection.bare({
    super.key,
    required this.title,
    required this.child,
    this.sectionId,
    this.icon,
    this.subtitle,
    this.actions = const [],
    this.initiallyExpanded = true,
    this.collapsedSummary,
    this.animationDuration = AppTokens.motionSlow,
    this.onExpansionChanged,
    this.bodyPadding = const EdgeInsets.fromLTRB(
      AppSpacing.medium,
      0,
      AppSpacing.medium,
      AppSpacing.medium,
    ),
    this.headerPadding = const EdgeInsets.all(AppSpacing.medium),
  }) : card = false;

  @override
  State<DashboardCollapsibleSection> createState() =>
      _DashboardCollapsibleSectionState();
}

class _DashboardCollapsibleSectionState
    extends State<DashboardCollapsibleSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  /// The summary's transform is the exact inverse of the body's, built once
  /// rather than per frame so a collapsed section allocates nothing while idle.
  late final Animation<double> _inverseCurve;

  /// False until the body has been expanded at least once. Guards the lazy
  /// first build so a section that starts collapsed never pays for its content.
  bool _bodyEverBuilt = false;

  /// True only when the collapse animation has fully settled. While it is true
  /// the body is offstage; the extra bit (rather than reading
  /// `_controller.isDismissed` inline) is what lets a status listener drive a
  /// single rebuild at the moment of settling instead of one per frame.
  bool _settledCollapsed = false;

  /// The mirror of [_settledCollapsed], used to take the collapsed summary out
  /// of the tree once the section is fully open. Without it the summary would
  /// linger at zero height — invisible, but still real to a screen reader and
  /// to anything walking the widget tree.
  bool _settledExpanded = false;

  /// The operator's current intent, flipped the instant they tap. Kept separate
  /// from the controller's value so the chevron and the accessibility `expanded`
  /// flag reflect the new state immediately rather than lagging the animation.
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = _resolveInitialState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: _expanded ? 1 : 0,
    )..addStatusListener(_handleStatusChange);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _inverseCurve = Tween<double>(begin: 1, end: 0).animate(_curve);
    _bodyEverBuilt = _expanded;
    _settledCollapsed = !_expanded;
    _settledExpanded = _expanded;
  }

  bool _resolveInitialState() {
    final id = widget.sectionId;
    if (id == null) return widget.initiallyExpanded;
    return DashboardSectionStateStore.instance.isExpanded(
      id,
      fallback: widget.initiallyExpanded,
    );
  }

  void _handleStatusChange(AnimationStatus status) {
    final collapsed = status == AnimationStatus.dismissed;
    final expanded = status == AnimationStatus.completed;
    if (!mounted) return;
    if (collapsed == _settledCollapsed && expanded == _settledExpanded) return;
    setState(() {
      _settledCollapsed = collapsed;
      _settledExpanded = expanded;
    });
  }

  @override
  void didUpdateWidget(covariant DashboardCollapsibleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationDuration != oldWidget.animationDuration) {
      _controller.duration = widget.animationDuration;
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    final willExpand = !_expanded;
    setState(() {
      _expanded = willExpand;
      if (willExpand) _bodyEverBuilt = true;
    });
    if (willExpand) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    final id = widget.sectionId;
    if (id != null) {
      DashboardSectionStateStore.instance.setExpanded(id, willExpand);
    }
    widget.onExpansionChanged?.call(willExpand);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionHeader(
          icon: widget.icon,
          title: widget.title,
          subtitle: widget.subtitle,
          actions: widget.actions,
          expanded: _expanded,
          animation: _curve,
          onToggle: _toggle,
          padding: widget.headerPadding,
        ),
        _buildSummary(),
        _buildBody(),
      ],
    );

    if (!widget.card) return content;
    return AppCard(padding: EdgeInsets.zero, child: content);
  }

  /// The collapsed summary mirrors the body: it grows in as the body folds
  /// away, driven by the same controller so the card never jumps.
  Widget _buildSummary() {
    final summary = widget.collapsedSummary;
    if (summary == null || _settledExpanded) return const SizedBox.shrink();
    return SizeTransition(
      sizeFactor: _inverseCurve,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _inverseCurve,

        child: Padding(padding: widget.bodyPadding, child: summary),
      ),
    );
  }

  Widget _buildBody() {
    if (!_bodyEverBuilt) return const SizedBox.shrink();

    return Offstage(
      offstage: _settledCollapsed,
      child: TickerMode(
        enabled: !_settledCollapsed,
        child: ClipRect(
          child: SizeTransition(
            sizeFactor: _curve,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: _curve,
              child: Padding(padding: widget.bodyPadding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header row: icon + title/subtitle + actions + chevron.
///
/// The whole row is the hit target (not just the chevron) because a 20px icon is
/// a poor click target on a dense operations screen — but [actions] sit in their
/// own subtree so their taps never bubble into a toggle.
class _SectionHeader extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool expanded;
  final Animation<double> animation;
  final VoidCallback onToggle;
  final EdgeInsetsGeometry padding;

  const _SectionHeader({
    required this.title,
    required this.actions,
    required this.expanded,
    required this.animation,
    required this.onToggle,
    required this.padding,
    this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,

      expanded: expanded,
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: InkWell(
          onTap: onToggle,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  DashboardSectionGlyph(icon: icon!),
                  const SizedBox(width: AppSpacing.small),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.small),
                  Wrap(
                    spacing: AppSpacing.xSmall,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: actions,
                  ),
                ],
                const SizedBox(width: AppSpacing.xSmall),
                _Chevron(animation: animation, scheme: scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The chip a panel or section wears in place of a bare header icon.
///
/// A titled card and a KPI tile are the console's two containers, and until
/// this existed they announced themselves in two different ways — the tile with
/// a glyph on a wash, the panel with a loose 18px icon floating beside its
/// title. One shape for both is what makes a page of cards read as one system;
/// it also gives the header a fixed-width leading column, so titles line up
/// down a column of stacked panels instead of starting wherever their glyph
/// happened to end.
///
/// Deliberately **neutral**, not status-tinted: a console screen carries up to
/// nine panels at once, and nine coloured squares down a page would spend the
/// whole colour budget on furniture. Colour stays where it means something —
/// the status chips, the queue tiles, the KPI glyphs.
class DashboardSectionGlyph extends StatelessWidget {
  const DashboardSectionGlyph({super.key, required this.icon, this.size = 30});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DashboardColors.nested(context),
        borderRadius: BorderRadius.circular(size * 0.27),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Icon(
        icon,
        size: size * 0.56,
        color: DashboardColors.mutedInk(context),
      ),
    );
  }
}

/// Chevron that rotates a half-turn between states.
///
/// One rotating glyph rather than swapping `expand_more`/`expand_less` icons:
/// the rotation *is* the affordance, and it stays legible mid-animation. The
/// icon is vertically symmetric, so RTL needs no special handling.
class _Chevron extends StatelessWidget {
  final Animation<double> animation;
  final ColorScheme scheme;

  const _Chevron({required this.animation, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween<double>(begin: 0, end: 0.5).animate(animation),
      child: Icon(
        Icons.expand_more_rounded,
        size: 22,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Standard one-line summary for a collapsed section: a wrap of small chips.
///
/// Exists so "٣ عوامل تصفية مطبقة" looks the same in Bookings as it does in
/// Finance instead of every module inventing its own collapsed-state typography.
class DashboardSectionSummary extends StatelessWidget {
  final List<String> items;

  const DashboardSectionSummary({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.xSmall,
      children: [
        for (final item in items)
          Container(
            padding: AppSpacing.chip,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              border: Border.all(color: scheme.outline.withAlpha(30)),
            ),
            child: Text(
              item,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
