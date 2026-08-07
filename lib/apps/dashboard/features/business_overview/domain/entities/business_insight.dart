/// Insights: the layer that says what a number *means*, not just what it is.
///
/// ## Why this shape, and how AI arrives later
///
/// Everything the overview produces today is [InsightSource.derived] — a rule
/// over rows the dashboard already loaded, with the arithmetic stated in the
/// text so an owner can check it. Nothing here is generated, and nothing here
/// is a guess.
///
/// The eventual AI copilot does not need a new section, a new panel or a new
/// layout: it needs to append [BusinessInsight]s carrying
/// [InsightSource.assistant]. That is why the *text* is open (free-form
/// [title]/[detail] the producer writes) while the *vocabulary* is closed
/// ([kind] picks the glyph, [severity] picks the tint, [action] picks the
/// destination). A model can say anything; it cannot invent a new colour, a new
/// icon or a link to a screen that does not exist — and the badge on the card
/// always tells the owner which of the two wrote the sentence they are reading.
library;

/// Where an insight came from. Rendered as a badge, never hidden: an owner
/// deciding on a sentence deserves to know whether it was measured or inferred.
enum InsightSource {
  /// Computed from loaded rows by a rule in this file's neighbours.
  derived,

  /// Produced by a model. No producer exists yet; the case is declared so the
  /// UI is already written for it.
  assistant,
}

/// How an insight should read. Not a severity ladder — [positive] is not
/// "less bad than warning", it is a different kind of statement.
enum InsightSeverity { positive, informational, warning, critical }

/// The closed glyph/topic vocabulary. An assistant-authored insight picks the
/// nearest member rather than supplying its own icon.
enum InsightKind {
  routePerformance,
  demandPattern,
  revenueComparison,
  refundTrend,
  driverPerformance,
  occupancyOpportunity,
  customerRetention,
  general,
}

/// Where an insight sends the owner next. [route] is a `DashboardRoutes`
/// constant — a plain string here so the domain stays free of the shell.
class InsightAction {
  final String label;
  final String route;

  const InsightAction({required this.label, required this.route});
}

/// One sentence about the business, with its evidence and its next step.
class BusinessInsight {
  /// Stable within a load, so the list can be keyed without reordering jitter.
  final String id;

  final InsightKind kind;
  final InsightSeverity severity;
  final InsightSource source;

  /// The finding, in one line.
  final String title;

  /// The evidence behind it — the figures, the window, the comparison. This is
  /// the half that makes the finding checkable rather than merely confident.
  final String detail;

  final InsightAction? action;

  const BusinessInsight({
    required this.id,
    required this.kind,
    required this.severity,
    required this.title,
    required this.detail,
    this.source = InsightSource.derived,
    this.action,
  });

  /// Problems before opportunities before observations — the order an owner
  /// with thirty seconds reads them in.
  static int compare(BusinessInsight a, BusinessInsight b) {
    int rank(BusinessInsight i) => switch (i.severity) {
      InsightSeverity.critical => 0,
      InsightSeverity.warning => 1,
      InsightSeverity.positive => 2,
      InsightSeverity.informational => 3,
    };
    return rank(a).compareTo(rank(b));
  }
}
