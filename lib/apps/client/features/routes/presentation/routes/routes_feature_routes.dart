/// Route names owned by the `routes` feature.
///
/// The catalog itself has no top-level route — it lives at the shell's
/// `routes` tab — so only the pushed detail screen needs a name here.
abstract final class RoutesFeatureRoutes {
  const RoutesFeatureRoutes._();

  static const details = '/routes/details';
}
