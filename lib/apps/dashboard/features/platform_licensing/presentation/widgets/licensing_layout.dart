import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/ui_state/dashboard_section_state_store.dart';
import '../../../../core/widgets/dashboard_module_header.dart';

/// The layout vocabulary the platform console screens share.
///
/// It exists because the three screens under «المنصة» had each grown their own
/// chrome — a KPI grid folded inside a header folded inside a card, three rows
/// of unlabelled chips, six stacked panels per detail pane — and the operator
/// was spending more attention on the furniture than on the decision. Every
/// widget here is deliberately *flat*: one surface, one purpose, no nesting.
///
/// The rules these pieces encode:
///
/// - **A number belongs on a line, not in a tile.** Four KPI cards for four
///   figures nobody drills into is a header that eats a third of the console.
///   [LicensingStatStrip] says the same thing in one row.
/// - **A control names itself.** No filter is a bare chip whose axis you infer.
/// - **An action is visible.** Nothing important hides behind `⋯`.
/// - **A card grid, not a squeezed pane.** Plans are products; they are read the
///   way a pricing page is read.

/// The one header every platform console screen opens with.
///
/// Four screens under «المنصة» used to be seven, each with its own banner, its
/// own stat block and its own filter bar stacked on top of one another. The
/// console now has four destinations, and the sections that used to be separate
/// destinations are a [tabBar] *inside* this header — so switching «الباقات»
/// and «الميزات» costs one press in the place the operator is already looking,
/// instead of a trip back to the sidebar.
///
/// Order is deliberate: identity, then the figures, then the switch. The
/// figures fold away with the rest of the module summaries, and the switch sits
/// on the card's bottom edge — against the section it opens, and in a place
/// that does not move when the figures are folded.
class LicensingConsoleHeader extends StatelessWidget {
  const LicensingConsoleHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.tabBar,
    this.stats = const [],
    this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  /// The section switch for this destination — a [LicensingTabs] built by the
  /// screen and handed to whichever section is on show, so every section of a
  /// destination renders the identical control in the identical place.
  final Widget? tabBar;

  /// Figures for the selected section.
  final List<LicensingStat> stats;

  /// Anything the selected section wants directly under its figures — an
  /// enforcement-mode bar, a notice. Kept to one slot so a header cannot grow
  /// back into the wall of chrome this replaced.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tabs = tabBar;
    if (tabs == null && stats.isEmpty && child == null) {
      return DashboardModuleHeader(
        icon: icon,
        title: title,
        subtitle: subtitle,
        actions: actions,
      );
    }

    // Order still runs identity → switch → figures, but the figures now fold:
    // they *describe* the selected section, and a console read all day should
    // not re-state its four totals above every table.
    return DashboardModuleHeader(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actions: actions,
      sectionId: DashboardSectionIds.platformLicensingHeader,
      summary: stats.isEmpty ? null : LicensingStatStrip(stats: stats),
      pinned: tabs == null && child == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (child != null) ...[
                  child!,
                  if (tabs != null) const SizedBox(height: AppSpacing.medium),
                ],
                if (tabs != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: tabs,
                  ),
              ],
            ),
    );
  }
}

/// One figure in a [LicensingStatStrip].
class LicensingStat {
  const LicensingStat({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });

  final String value;
  final String label;
  final IconData? icon;

  /// Only for a figure that carries a warning of its own. A strip where every
  /// number is coloured is a strip where none of them are.
  final Color? color;
}

/// The header's numbers, on one line.
class LicensingStatStrip extends StatelessWidget {
  const LicensingStatStrip({
    super.key,
    required this.stats,
    this.spread = false,
  });

  final List<LicensingStat> stats;

  /// Divide the full width between the figures instead of bunching them at the
  /// start edge. A five-figure strip left-packed inside a 1300px card is half a
  /// bar of numbers and half of nothing, which reads as an unfinished layout
  /// rather than as a deliberate one. Only honoured when there is room for it;
  /// below the breakpoint the strip stays a wrap.
  final bool spread;

  @override
  Widget build(BuildContext context) {
    if (!spread) return _wrap(context);

    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < MediaQuery.textScalerOf(context).scale(1000)
          ? _wrap(context)
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, stat) in stats.indexed) ...[
                    if (index > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.medium,
                        ),
                        child: VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: DashboardColors.border(context),
                        ),
                      ),
                    Expanded(child: _entry(context, stat, constrained: true)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _wrap(BuildContext context) => Wrap(
    spacing: AppSpacing.xLarge,
    runSpacing: AppSpacing.medium,
    children: [for (final stat in stats) _entry(context, stat)],
  );

  Widget _entry(
    BuildContext context,
    LicensingStat stat, {
    bool constrained = false,
  }) {
    final text = Theme.of(context).textTheme;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat.value,
          maxLines: 1,
          overflow: constrained ? TextOverflow.ellipsis : TextOverflow.clip,
          style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: stat.color,
          ),
        ),
        Text(
          stat.label,
          maxLines: constrained ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
            height: 1.4,
          ),
        ),
      ],
    );

    return Row(
      mainAxisSize: constrained ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (stat.icon != null) ...[
          Icon(
            stat.icon,
            size: 20,
            color: stat.color ?? DashboardColors.mutedInk(context),
          ),
          const SizedBox(width: AppSpacing.small),
        ],
        if (constrained) Expanded(child: body) else body,
      ],
    );
  }
}

/// Cards laid out in equal-height rows.
///
/// Rows are built by hand rather than with a `GridView` for two reasons: the
/// grid usually sits inside a page that already scrolls, and a fixed aspect
/// ratio clips whichever card has the most to say — which is invariably the one
/// the operator opened the screen for.
class LicensingCardGrid extends StatelessWidget {
  const LicensingCardGrid({
    super.key,
    required this.children,
    this.minCardWidth = 330,
    this.maxColumns = 4,
    this.spacing = AppSpacing.medium,
  });

  final List<Widget> children;
  final double minCardWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth.isFinite
            ? math.max(
                1,
                math.min(
                  maxColumns,
                  ((constraints.maxWidth + spacing) / (minCardWidth + spacing))
                      .floor(),
                ),
              )
            : 1;

        final rows = <List<Widget>>[
          for (var i = 0; i < children.length; i += columns)
            children.sublist(i, math.min(i + columns, children.length)),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, row) in rows.indexed)
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : spacing),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var column = 0; column < columns; column++) ...[
                        if (column > 0) SizedBox(width: spacing),
                        Expanded(
                          child: column < row.length
                              ? row[column]
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A bordered fact — «١٢ مكتب مشترك», «تجربة ١٤ يوم». Reads as data, not as a
/// control, which is why it is not a chip.
class LicensingFact extends StatelessWidget {
  const LicensingFact({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? DashboardColors.mutedInk(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color == null
            ? DashboardColors.well(context)
            : color!.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(
          color: color == null
              ? DashboardColors.border(context)
              : color!.withAlpha(70),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tinted, bordered sentence — for the one thing on a panel the operator must
/// not skim past.
class LicensingNotice extends StatelessWidget {
  const LicensingNotice({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// One labelled read-only value.
typedef LicensingFieldEntry = ({String label, String value});

/// Labelled values in two columns, collapsing to one when the pane is narrow.
///
/// Two columns rather than a single stack because a licence summary is nine
/// short facts, and nine stacked rows is a scroll for something that fits in a
/// glance.
class LicensingFieldGrid extends StatelessWidget {
  const LicensingFieldGrid({
    super.key,
    required this.fields,
    this.twoColumnBreakpoint = 460,
  });

  final List<LicensingFieldEntry> fields;
  final double twoColumnBreakpoint;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= twoColumnBreakpoint ? 2 : 1;
        final rows = <List<LicensingFieldEntry>>[
          for (var i = 0; i < fields.length; i += columns)
            fields.sublist(i, math.min(i + columns, fields.length)),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final row in rows)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: column < row.length
                          ? _Field(entry: row[column])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.entry});

  final LicensingFieldEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.label,
            style: text.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            entry.value,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class LicensingTab {
  const LicensingTab({required this.label, required this.icon, this.count});

  final String label;
  final IconData icon;

  /// Rendered as a badge. Zero is shown as nothing rather than as "0": a tab
  /// that says zero invites a click that answers nothing.
  final int? count;
}

/// A pill tab bar, sized for a workspace rather than for a phone.
///
/// A `TabBar` was doing this before, inside a card, inside a split pane — three
/// nested scroll contexts for three sections. This is a plain selector: the
/// caller keeps the index and swaps the body.
class LicensingTabs extends StatelessWidget {
  const LicensingTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<LicensingTab> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final (index, tab) in tabs.indexed)
            _TabPill(
              tab: tab,
              selected: index == selected,
              onTap: () => onChanged(index),
            ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final LicensingTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final ink = selected ? scheme.onPrimary : DashboardColors.ink(context);

    return Material(
      color: selected ? scheme.primary : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.small,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, size: 18, color: ink),
              const SizedBox(width: AppSpacing.small),
              Text(
                tab.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if ((tab.count ?? 0) > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.onPrimary.withAlpha(50)
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${tab.count}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The unsaved-changes bar that floats over the plan workspace.
///
/// It carries the note field *inline* rather than opening a modal on save. The
/// old flow asked for a reason of at least eight characters in a dialog before
/// every single save — `platform_save_plan` requires none, the revision
/// snapshot is written either way, and the modal was the single biggest reason
/// this console felt hostile to touch. The note is now optional, one field,
/// right where the decision is being made.
class LicensingSaveBar extends StatelessWidget {
  const LicensingSaveBar({
    super.key,
    required this.changedCount,
    required this.noteController,
    required this.onDiscard,
    required this.onSave,
    this.message,
  });

  final int changedCount;
  final TextEditingController noteController;
  final VoidCallback onDiscard;
  final VoidCallback onSave;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$changedCount تعديل غير محفوظ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          message ?? 'لا يسري أي منها على أي مكتب قبل الحفظ.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
      ],
    );

    final note = TextField(
      controller: noteController,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSave(),
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'ملاحظة للسجل (اختيارية)',
        border: OutlineInputBorder(),
      ),
    );

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: onDiscard, child: const Text('تجاهل')),
        const SizedBox(width: AppSpacing.small),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('حفظ'),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.tertiary.withAlpha(120), width: 1.5),
        boxShadow: DashboardColors.floatingShadow(context),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                headline,
                const SizedBox(height: AppSpacing.small),
                note,
                const SizedBox(height: AppSpacing.small),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: buttons,
                ),
              ],
            );
          }
          return Row(
            children: [
              Icon(Icons.edit_note_rounded, color: scheme.tertiary),
              const SizedBox(width: AppSpacing.small),
              headline,
              const SizedBox(width: AppSpacing.large),
              Expanded(child: note),
              const SizedBox(width: AppSpacing.medium),
              buttons,
            ],
          );
        },
      ),
    );
  }
}

/// A search field and its filters on one line.
///
/// The screens it replaced stacked a search row, three labelled chip rows and a
/// KPI grid above the list — roughly 300px of chrome before the first row of
/// data. One line, and the filters that are *on* say so.
class LicensingToolbar extends StatelessWidget {
  const LicensingToolbar({
    super.key,
    required this.search,
    this.filters = const [],
    this.trailing,
    this.searchWidth = 300,
  });

  final Widget search;
  final List<Widget> filters;
  final Widget? trailing;
  final double searchWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: searchWidth, child: search),
          ...filters,
          ?trailing,
        ],
      ),
    );
  }
}

/// A named dropdown filter — the console's answer to a row of bare chips.
///
/// Lifted out of the feature catalog when the plan editor turned out to need
/// the identical control: its category filter was eight `FilterChip`s sharing a
/// wrap with a modified-only toggle, so two unrelated axes wore identical
/// clothes and the row ran the width of the console. One named control says
/// more in less space, and — unlike a bare chip — *says which axis it narrows*.
class LicensingFilterDropdown extends StatelessWidget {
  const LicensingFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.isActive = false,
  });

  final String label;
  final String value;
  final List<({String? value, String label})> options;
  final ValueChanged<String?> onSelected;

  /// Tints the control while it is actually narrowing the list. A filter that
  /// is *on* and looks exactly like one that is off is how a narrowed list gets
  /// read as a whole one.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final ink = isActive ? scheme.primary : DashboardColors.mutedInk(context);

    return PopupMenuButton<String>(
      tooltip: label,
      onSelected: (picked) => onSelected(picked == '' ? null : picked),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(value: option.value ?? '', child: Text(option.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? scheme.primary.withAlpha(18) : theme.cardColor,
          borderRadius: radius,
          border: Border.all(
            color: isActive
                ? scheme.primary.withAlpha(90)
                : DashboardColors.border(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: theme.textTheme.labelMedium?.copyWith(color: ink),
            ),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isActive ? scheme.primary : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 18, color: ink),
          ],
        ),
      ),
    );
  }
}

/// The line between a toolbar and the list it narrows.
///
/// It answers three things the old trailing label could not: how much of the
/// list is showing, *which* filters are doing the narrowing — spelled out, not
/// counted — and one way to undo all of them. [note] carries the one sentence a
/// list needs to be read correctly, placed where it is read *before* the rows
/// rather than under them.
class LicensingResultsBar extends StatelessWidget {
  const LicensingResultsBar({
    super.key,
    required this.summary,
    this.activeFilters = const [],
    this.onReset,
    this.note,
  });

  final String summary;

  /// Named filters currently applied. Naming them is the point: "٢ فلتر" makes
  /// the operator reopen the toolbar to find out which two.
  final List<String> activeFilters;

  final VoidCallback? onReset;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = DashboardColors.mutedInk(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.xSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    summary,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: muted,
                    ),
                  ),
                  for (final filter in activeFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(16),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusSmall,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (onReset != null)
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: const Text('مسح التصفية'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.xSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  note!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
