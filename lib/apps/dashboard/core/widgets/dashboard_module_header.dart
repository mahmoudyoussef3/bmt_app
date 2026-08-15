import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// Unified page header used by every dashboard module (Trips, Fleet, Routes…).
///
/// One **compact identity bar** — a tinted glyph, the module's name, its line of
/// explanation and the module's actions — with two optional bodies under it:
///
/// * [summary] is what the module *reports*: KPI strips, stat grids, headline
///   figures. It **folds away by default** and the operator opens it with the
///   «الملخص» toggle. A summary is read once at the start of a shift and then
///   ignored; leaving it permanently unfolded cost every module a third of the
///   first screen and pushed the actual work below the fold.
/// * [pinned] is whatever the screen cannot work without — a tab bar, a period
///   selector, the search field that is the only way to find a row. It never
///   folds, because a control the operator cannot see is a control that does
///   not exist.
///
/// Which slot a body belongs in is the one decision a caller makes here: if
/// hiding it would break the screen it is [pinned], otherwise it is [summary].
/// The foldable slot is named [summary] rather than `child` so a call site
/// cannot pass it out of habit without deciding.
///
/// The fold is remembered per [sectionId] for the session by
/// [DashboardSectionStateStore] — the same store [DashboardCollapsibleSection]
/// uses — so an operator who opens the Trips summary and walks to Fleet and back
/// finds it still open. Like that widget, the body is not built until its first
/// expansion and is parked under an [Offstage] with muted tickers once folded,
/// so a collapsed summary costs no layout, paint or animation while keeping its
/// state.
class DashboardModuleHeader extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Module actions. They sit in their own subtree, so pressing one never folds
  /// or unfolds the header.
  final List<Widget> actions;

  /// The foldable body. Folded on first view.
  final Widget? summary;

  /// Controls that must stay on screen. Rendered under [summary] so a tab bar or
  /// a search field sits directly against the content it drives, and does not
  /// move when the summary folds.
  final Widget? pinned;

  /// Session memory key for the fold. Use a [DashboardSectionIds] constant.
  /// Without one the header still folds, it just forgets on the next rebuild of
  /// its element.
  final String? sectionId;

  /// Overrides the folded-by-default rule the first time this header is seen in
  /// a session. A remembered [sectionId] state always wins over it.
  final bool initiallyExpanded;

  /// Shown in place of [summary] while folded — one line answering "do I need to
  /// open this?". Use [DashboardSectionSummary] for the standard chip row.
  final Widget? collapsedSummary;

  /// Names what the toggle opens. Only change it when «الملخص» would be a lie.
  final String detailsLabel;

  const DashboardModuleHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.summary,
    this.pinned,
    this.sectionId,
    this.initiallyExpanded = false,
    this.collapsedSummary,
    this.detailsLabel = 'الملخص',
  });

  @override
  State<DashboardModuleHeader> createState() => _DashboardModuleHeaderState();
}

class _DashboardModuleHeaderState extends State<DashboardModuleHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late final Animation<double> _inverseCurve;

  /// False until the summary has been opened once, so a header that starts
  /// folded never pays to build a body nobody asked for.
  bool _bodyEverBuilt = false;

  bool _settledCollapsed = false;
  bool _settledExpanded = false;

  /// The operator's intent, flipped on tap rather than read off the controller,
  /// so the chevron and the accessibility flag lead the animation instead of
  /// lagging it.
  late bool _expanded;

  bool get _foldable => widget.summary != null;

  @override
  void initState() {
    super.initState();
    _expanded = _resolveInitialState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTokens.motionSlow,
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
    if (!mounted) return;
    final collapsed = status == AnimationStatus.dismissed;
    final expanded = status == AnimationStatus.completed;
    if (collapsed == _settledCollapsed && expanded == _settledExpanded) return;
    setState(() {
      _settledCollapsed = collapsed;
      _settledExpanded = expanded;
    });
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
  }

  /// The radius the surrounding [AppCard] was themed with.
  ///
  /// Read rather than assumed: the tinted bar paints to the card's edge, and a
  /// constant that is merely close to the card's radius shows as a squared-off
  /// corner poking past a rounded one.
  double _cardRadius(ThemeData theme) =>
      (theme.extension<AppSurfaceStyle>() ??
              AppSurfaceStyle.flat(theme.colorScheme))
          .radius;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        // Clipping the whole stack — rather than rounding the bar's own bottom
        // corners — is what keeps the card's shape right in every state: bar
        // alone, bar over a folded summary, or bar over an open one.
        borderRadius: BorderRadius.circular(_cardRadius(Theme.of(context))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBar(context),
            if (_foldable) ...[_buildSummary(), _buildBody()],
            if (widget.pinned != null)
              _Divided(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: widget.pinned!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The identity bar. Tappable as a whole when there is something to unfold —
  /// a 22px chevron is a poor target on a console meant to be driven quickly.
  Widget _buildBar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final topCorners = BorderRadius.vertical(
      top: Radius.circular(_cardRadius(theme)),
    );
    final bar = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            // Same tint ladder the KPI tiles use, so the bar reads as the same
            // wash in both themes rather than vanishing on the dark page.
            DashboardColors.kpiTint(context, scheme.primary),
            scheme.primary.withAlpha(0),
          ],
        ),
        borderRadius: topCorners,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = _TitleBlock(
            icon: widget.icon,
            title: widget.title,
            subtitle: widget.subtitle,
          );
          final toggle = _foldable
              ? _FoldToggle(
                  animation: _curve,
                  expanded: _expanded,
                  label: widget.detailsLabel,
                  onPressed: _toggle,
                )
              : null;

          if (widget.actions.isEmpty) {
            return Row(
              children: [
                Expanded(child: identity),
                if (toggle != null) ...[
                  const SizedBox(width: AppSpacing.small),
                  toggle,
                ],
              ],
            );
          }

          final actionBar = Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [...widget.actions, ?toggle],
          );

          // Narrow consoles stack the action bar under the identity rather than
          // squeezing both onto one line and eliding the title to nothing.
          if (constraints.maxWidth < 780) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: AppSpacing.small),
                actionBar,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.medium),
              actionBar,
            ],
          );
        },
      ),
    );

    if (!_foldable) return bar;

    return Semantics(
      button: true,
      expanded: _expanded,
      child: Material(
        color: Colors.transparent,
        borderRadius: topCorners,
        child: InkWell(onTap: _toggle, borderRadius: topCorners, child: bar),
      ),
    );
  }

  /// Grows in as the body folds away, on the same controller, so the card never
  /// jumps between the two states.
  Widget _buildSummary() {
    final summary = widget.collapsedSummary;
    if (summary == null || _settledExpanded) return const SizedBox.shrink();
    return SizeTransition(
      sizeFactor: _inverseCurve,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _inverseCurve,
        child: _Divided(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: summary,
          ),
        ),
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
              child: _Divided(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: widget.summary!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A body separated from what sits above it by a hairline.
///
/// The rule belongs to the body rather than to the bar so it fades and slides
/// away with the content it separates — a divider left hanging under a folded
/// summary is the one thing that makes a collapsed card look broken.
class _Divided extends StatelessWidget {
  const _Divided({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: DashboardColors.divider(context)),
        ),
      ),
      child: child,
    );
  }
}

/// Glyph, name, and the one line that says what the module is for.
///
/// The glyph sits in a tinted tile rather than floating beside the text: it
/// gives the bar a fixed leading rhythm every module shares, and it is what
/// keeps a header this short from reading as a bare paragraph.
class _TitleBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TitleBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: DashboardColors.kpiTint(context, scheme.primary),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            border: Border.all(
              color: DashboardColors.kpiBorder(context, scheme.primary),
            ),
          ),
          child: Icon(icon, color: scheme.primary, size: 19),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              // One line, always: the subtitle explains the module once and is
              // never read again, so it gets the height of a caption. The full
              // sentence stays reachable as a tooltip.
              Tooltip(
                message: subtitle,
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The fold control: a named button, not a bare chevron.
///
/// «الملخص ⌄» says what is behind the fold; a lone arrow at the end of a bar
/// full of buttons says only that something is hidden. It carries its own tap
/// so it works identically whether the operator aims at it or anywhere else on
/// the bar.
class _FoldToggle extends StatelessWidget {
  const _FoldToggle({
    required this.animation,
    required this.expanded,
    required this.label,
    required this.onPressed,
  });

  final Animation<double> animation;
  final bool expanded;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: expanded ? 'إخفاء $label' : 'إظهار $label',
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.xSmall,
          ),
        ),
        icon: RotationTransition(
          turns: Tween<double>(begin: 0, end: 0.5).animate(animation),
          child: const Icon(Icons.expand_more_rounded, size: 20),
        ),
        label: Text(label),
      ),
    );
  }
}
