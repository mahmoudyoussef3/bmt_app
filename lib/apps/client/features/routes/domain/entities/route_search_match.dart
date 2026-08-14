import 'route_summary.dart';

/// One route in the catalog's search results, together with the reason it is
/// there.
///
/// A rider searching "بنها" gets back corridors that merely pass through
/// Banha, and the list has to say so — showing `القاهرة → المنصورة` with no
/// explanation reads as a mistake, and showing Banha where an endpoint goes
/// would be a lie.
class RouteSearchMatch {
  const RouteSearchMatch(this.route, {this.viaStop = ''});

  final RouteSummary route;

  /// The intermediate stop whose name matched the query.
  ///
  /// Empty when the route matched on its own identity — its name, either
  /// endpoint, its operating office, or a terminal stop, all of which the card
  /// already shows. Only a stop the rider cannot otherwise see needs naming.
  final String viaStop;

  bool get isVia => viaStop.isNotEmpty;
}
