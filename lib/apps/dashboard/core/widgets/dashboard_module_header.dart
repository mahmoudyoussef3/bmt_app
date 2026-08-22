import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Unified page header used by every dashboard module (Trips, Fleet, Routes…).
///
/// A bare title block on the page — the module's name at 21/800, its line of
/// explanation underneath and the module's actions on the same baseline — with
/// two optional bodies under it:
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
///
/// The identity card the EWT redesign retired — a gradient-tinted bar with a
/// glyph tile — is gone: the title sits directly on the page, which is what
/// gave every module back the vertical space the card used to spend on saying
/// its own name.
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBar(context),
          if (_foldable) ...[_buildSummary(), _buildBody()],
          if (widget.pinned != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.medium),
              child: widget.pinned!,
            ),
        ],
      ),
    );
  }

  /// The bare title row: name, subtitle, actions on the same baseline. Tappable
  /// as a whole when there is something to unfold — a 22px chevron is a poor
  /// target on a console meant to be driven quickly.
  Widget _buildBar(BuildContext context) {
    final bar = LayoutBuilder(
      builder: (context, constraints) {
        final identity = _TitleBlock(
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
            crossAxisAlignment: CrossAxisAlignment.end,
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: identity),
            const SizedBox(width: AppSpacing.medium),
            actionBar,
          ],
        );
      },
    );

    if (!_foldable) return bar;

    return Semantics(
      button: true,
      expanded: _expanded,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: _toggle, child: bar),
      ),
    );
  }

  /// Grows in as the body folds away, on the same controller, so the header
  /// never jumps between the two states.
  Widget _buildSummary() {
    final summary = widget.collapsedSummary;
    if (summary == null || _settledExpanded) return const SizedBox.shrink();
    return SizeTransition(
      sizeFactor: _inverseCurve,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _inverseCurve,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.small),
          child: summary,
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
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.medium),
                child: widget.summary!,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Name and the one line that says what the module is for. No glyph tile — the
/// EWT redesign spends colour on the trend chip and the primary action, not on
/// a page restating its own icon.
class _TitleBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TitleBlock({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Tooltip(
          message: subtitle,
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
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
    return Tooltip(
      message: expanded ? 'إخفاء $label' : 'إظهار $label',
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: DashboardColors.mutedInk(context),
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
