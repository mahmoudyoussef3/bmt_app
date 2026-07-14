/// Which legal document the reader asked for.
enum LegalDocument { terms, privacy }

/// One titled clause of a legal document.
class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}
