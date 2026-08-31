/// The reporting period the executive page is read through.
///
/// ## Why the page needed one at all
///
/// Before this, every block picked its own window and none of them said so out
/// loud: the KPI strip compared today with yesterday, the money block was a
/// fixed rolling 30 days, the customer block another fixed 30, and the health
/// grades were graded over a week. An owner reading "الإيراد 128,400" directly
/// above "عملاء نشطون 412" had no way to know the two figures did not cover the
/// same days — and no way to ask the page a different question.
///
/// So there is one control, and everything measured *over time* answers to it.
/// What deliberately does **not** answer to it is live state — trips running
/// now, drivers rostered today, queues waiting for a decision. Those are facts
/// about this minute, and re-scoping them to "last 90 days" would be
/// meaningless rather than more informative; the blocks that hold them are
/// labelled «اليوم» so the split is visible rather than assumed.
enum OverviewWindow {
  week(
    days: 7,
    label: '٧ أيام',
    title: 'آخر ٧ أيام',
    previous: 'الأسبوع السابق',
  ),
  month(
    days: 30,
    label: '٣٠ يوماً',
    title: 'آخر ٣٠ يوماً',
    previous: 'الشهر السابق',
  ),
  quarter(
    days: 90,
    label: '٩٠ يوماً',
    title: 'آخر ٩٠ يوماً',
    previous: 'الفترة السابقة',
  );

  const OverviewWindow({
    required this.days,
    required this.label,
    required this.title,
    required this.previous,
  });

  /// The window length in days, ending today inclusive.
  final int days;

  /// The segment's own text — short, because three of them share a bar.
  final String label;

  /// How the window is named in a sentence, on a panel subtitle or beside a
  /// figure that will be screenshotted on its own.
  final String title;

  /// What the comparison is against, for a trend caption. Never "الفترة
  /// السابقة" where a real name exists: an owner checking a 12% drop wants to
  /// know it is against last month, not against "before".
  final String previous;

  /// The caption a trend chip carries: `مقارنة بالشهر السابق`.
  String get comparisonCaption => 'مقارنة بـ$previous';
}
