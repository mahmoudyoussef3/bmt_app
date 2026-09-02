import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

/// The opening block of the console's two overview screens — الرئيسية and
/// نظرة تنفيذية.
///
/// Both are opened one after the other by the same person all day, and until
/// this existed each carried its own private copy of the same three parts: a
/// monogram-less title, a dot-joined context line clipped to one line, and an
/// action pair. Two copies of one block is how two screens drift; one widget is
/// how they stop.
///
/// ## Why a monogram
///
/// The EWT redesign retired the full-bleed gradient hero — a brand sweep whose
/// only content was a name cost the top of every session's first screen a
/// card's worth of height. A 44px mark is the opposite trade: it says *whose*
/// console this is in the corner of one line, it anchors the eye at the start
/// of the page, and it costs nothing vertically because the greeting was
/// already that tall. It is also the one place a multi-office operator can tell
/// at a glance which office they are looking at, which used to be buried
/// mid-sentence in the grey line underneath.
///
/// ## Why the context line is a wrap, not a sentence
///
/// It used to be `parts.join(' · ')` inside a single `maxLines: 1` `Text`. On a
/// narrow console — and on every console at 1.6× text — that clipped, and what
/// clipped first was the end of the line, which is where «آخر تحديث 21:49»
/// lives. A screen whose whole claim is "these numbers are current" cannot be
/// allowed to drop the timestamp to save a few pixels, so the facts wrap onto a
/// second line instead, each carrying its own separator.
class DashboardPageTitleBlock extends StatelessWidget {
  const DashboardPageTitleBlock({
    super.key,
    required this.title,
    required this.meta,
    this.monogramSource,
    this.actions = const [],
    this.trailingMeta,
  });

  /// The greeting or the page's name. One line, at headline weight.
  final String title;

  /// The facts under the title, in reading order — office, date, scope, when
  /// the figures were taken. Empty entries are dropped by the caller, not here.
  final List<String> meta;

  /// The name the monogram takes its letters from, normally the office's. Null
  /// draws no mark, for a page that has no owner to name.
  final String? monogramSource;

  /// Primary then secondary, on the title's own baseline.
  final List<Widget> actions;

  /// A widget appended after [meta] — a live badge, a refreshing spinner.
  final Widget? trailingMeta;

  /// Below this the actions stack under the identity rather than squeezing onto
  /// the title's line and eliding it to nothing.
  static const double _stackBreakpoint = 640;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final identity = _Identity(
          title: title,
          meta: meta,
          monogramSource: monogramSource,
          trailingMeta: trailingMeta,
        );
        final actionBar = actions.isEmpty
            ? null
            : Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              );

        if (actionBar == null) return identity;

        final stacked =
            constraints.maxWidth <
            MediaQuery.textScalerOf(context).scale(_stackBreakpoint);
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identity,
              const SizedBox(height: AppSpacing.medium),
              actionBar,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: identity),
            const SizedBox(width: AppSpacing.large),
            actionBar,
          ],
        );
      },
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.title,
    required this.meta,
    this.monogramSource,
    this.trailingMeta,
  });

  final String title;
  final List<String> meta;
  final String? monogramSource;
  final Widget? trailingMeta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = monogramSource?.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (source != null && source.isNotEmpty) ...[
          _Monogram(source: source),
          const SizedBox(width: AppSpacing.medium),
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
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              _MetaLine(items: meta, trailing: trailingMeta),
            ],
          ),
        ),
      ],
    );
  }
}

/// The facts under the title, each with its own separator so a wrap never
/// leaves a bullet stranded at the head of a line.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.items, this.trailing});

  final List<String> items;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: DashboardColors.mutedInk(context),
    );
    final separator = theme.textTheme.bodySmall?.copyWith(
      color: DashboardColors.faintInk(context),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 2,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Text('  ·  ', style: separator),
          Text(items[i], style: style),
        ],
        if (trailing != null) ...[
          if (items.isNotEmpty) Text('  ·  ', style: separator),
          trailing!,
        ],
      ],
    );
  }
}

/// Up to two letters of the office's name on the brand mark.
///
/// Two words give their initials; one word gives its first letter alone rather
/// than its first two, because an Arabic word's second glyph is usually a
/// joined medial form and reads as a fragment, not an initial.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: DashboardColors.heroGradient(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _initials(source),
        maxLines: 1,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: DashboardColors.onHero(context),
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }

  static String _initials(String source) {
    final words = source
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    // «مكتب» tells a reader nothing — every office is one. The mark is worth
    // more built from the words that actually name this office.
    final named = words.where((w) => !_generic.contains(w)).toList();
    final useful = named.isEmpty ? words : named;
    if (useful.length == 1) return useful.first.characters.first;
    return useful.take(2).map((w) => w.characters.first).join();
  }

  static const _generic = {'مكتب', 'شركة', 'مؤسسة', 'ال'};
}
