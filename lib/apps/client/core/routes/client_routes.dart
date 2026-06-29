class ClientRoutes {
  const ClientRoutes._();

  static const home = '/home';

  // Auth Routes
  static const authWelcome = '/auth/welcome';
  static const authSignIn = '/auth/sign-in';
  static const authSignUp = '/auth/sign-up';
  static const authForgotPassword = '/auth/forgot-password';
  static const authSuccess = '/auth/success';

  // Booking Routes
  static const bookingSearch = '/booking/search';
  static const bookingRouteSelection = '/booking/routes';
  static const bookingPopularRoutes = '/booking/popular-routes';
  static const bookingMapSelection = '/booking/map';
  static const bookingAvailableTrips = '/booking/available-trips';
  static const bookingVehicleListing = '/booking/vehicles';
  static const bookingVehicleDetails = '/booking/vehicle-details';
  static const bookingWizard = '/booking/wizard';
  static const bookingApproval = '/booking/approval';
  static const bookingRouteOverview = '/booking/route-overview';

  // Trips Routes
  static const myTrips = '/trips';
  static const tripDetails = '/trips/details';

  // Other Routes
  static const tracking = '/tracking';
  static const subscription = '/subscription';
  static const support = '/support';
  static const createTicket = '/create_ticket';
  static const ticketDetails = '/ticket_details';
  static const createRefund = '/create_refund';
}
