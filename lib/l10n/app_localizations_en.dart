// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get common_retry => 'Retry';

  @override
  String get common_view => 'View';

  @override
  String get common_dismiss => 'Dismiss';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_error => 'Something went wrong';

  @override
  String home_goodMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String get home_readyForCommute => 'Ready for your commute today?';

  @override
  String get home_tripStarted => 'Your trip has started';

  @override
  String get home_upcomingTrip => 'Your upcoming trip';

  @override
  String get home_trackBus => 'Track the bus and current stop';

  @override
  String get home_reviewTrip => 'Review trip details before departure';

  @override
  String get home_tripRoute => 'Trip Route';

  @override
  String get home_liveTracking => 'Live tracking';

  @override
  String home_stationsCount(int count) {
    return '$count stations';
  }

  @override
  String home_moreStations(int count) {
    return 'There are $count more stations in trip details';
  }

  @override
  String get home_pointPassed => 'Passed';

  @override
  String get home_pointCurrent => 'Bus is here';

  @override
  String get home_pointStart => 'Start Point';

  @override
  String get home_pointEnd => 'End Point';

  @override
  String get home_pointStation => 'Station';

  @override
  String get home_trackTrip => 'Track Trip';

  @override
  String get home_tripDetails => 'Details';

  @override
  String get home_whereTo => 'Where to?';

  @override
  String get home_searchDestination => 'Search destination...';

  @override
  String get home_quickDestinations => 'Quick destinations';

  @override
  String get home_packagesTitle => 'Packages';

  @override
  String get home_packagesSubtitle => 'Built for daily commuters';

  @override
  String get home_seeAll => 'See all';

  @override
  String get home_popularRoutesTitle => 'Popular routes';

  @override
  String get home_popularRoutesSubtitle => 'Frequent commutes from your area';

  @override
  String get home_viewAll => 'View all';

  @override
  String get home_contactSupport => 'Need help? Contact support';

  @override
  String get auth_welcomeTitle => 'Welcome to EasyWay';

  @override
  String get auth_welcomeSubtitle =>
      'Your premium daily commute and transportation manager.';

  @override
  String get auth_login => 'Log In';

  @override
  String get auth_createAccount => 'Create an Account';

  @override
  String get auth_termsPrefix => 'By continuing, you agree to our ';

  @override
  String get auth_termsOfService => 'Terms of Service';

  @override
  String get auth_termsAnd => ' and ';

  @override
  String get auth_privacyPolicy => 'Privacy Policy';

  @override
  String get auth_signInFailed => 'Sign in failed.';

  @override
  String get auth_rememberMe => 'Remember me';

  @override
  String get auth_welcomeBack => 'Welcome Back';

  @override
  String get auth_signInSubtitle => 'Sign in to book your next trip';

  @override
  String get auth_email => 'Email Address';

  @override
  String get auth_required => 'Required';

  @override
  String get auth_invalidEmail => 'Enter a valid email';

  @override
  String get auth_password => 'Password';

  @override
  String get auth_forgotPassword => 'Forgot Password?';

  @override
  String get auth_signIn => 'Sign In';

  @override
  String get auth_noAccount => 'Don\'t have an account? ';

  @override
  String get auth_signUp => 'Sign Up';

  @override
  String get auth_registrationFailed => 'Registration failed.';

  @override
  String get auth_createAccountTitle => 'Create Account';

  @override
  String get auth_signUpSubtitle => 'Join EasyWay to book and track your trips';

  @override
  String get auth_fullName => 'Full Name';

  @override
  String get auth_invalidFullName => 'Enter your full name';

  @override
  String get auth_phoneNumber => 'Phone Number';

  @override
  String get auth_invalidPhone => 'Enter a valid phone number';

  @override
  String get auth_invalidPassword => 'Password must be at least 6 characters';

  @override
  String get auth_forgotPasswordTitle => 'Forgot your password?';

  @override
  String get auth_forgotPasswordSubtitle =>
      'No worries. Enter your email and we’ll send you a secure link to reset your password.';

  @override
  String get auth_sendResetLink => 'Send reset link';

  @override
  String get auth_backToLogin => 'Back to Login';

  @override
  String get auth_checkEmailTitle => 'Check your email';

  @override
  String auth_checkEmailMessage(String email) {
    return 'We sent a secure reset link to $email. Open it to create a new password.';
  }

  @override
  String get auth_resendLink => 'Resend link';

  @override
  String auth_resendIn(int seconds) {
    return 'Resend link in ${seconds}s';
  }

  @override
  String get auth_rateLimited =>
      'Please wait before requesting another reset link.';

  @override
  String get auth_unknownError =>
      'An unexpected error occurred. Please try again later.';

  @override
  String get auth_alreadyHaveAccount => 'Already have an account? ';

  @override
  String get booking_title => 'Bookings';

  @override
  String get booking_subtitle => 'Choose how you want to book your commute';

  @override
  String get booking_today => 'Today';

  @override
  String get booking_month => 'Month';

  @override
  String get booking_dailyBooking => 'Daily Booking';

  @override
  String get booking_dailyBookingDesc => 'Book a trip step by step for today';

  @override
  String get booking_monthlySubscription => 'Monthly Subscription';

  @override
  String get booking_monthlySubscriptionDesc =>
      'Reserve your permanent route and seat';

  @override
  String get booking_summary => 'Summary';

  @override
  String get booking_activeTrips => 'Active trips';

  @override
  String get booking_upcomingBookings => 'Upcoming bookings';

  @override
  String get booking_reservedSeats => 'Reserved seats';

  @override
  String get booking_selectPickupDestination =>
      'Select pickup and destination to continue';

  @override
  String get booking_searchTrip => 'Search Trip';

  @override
  String get booking_pickupLocation => 'Pickup location';

  @override
  String get booking_destination => 'Destination';

  @override
  String get booking_selectDate => 'Select date';

  @override
  String get booking_selectTime => 'Select time';

  @override
  String get booking_otherWaysToSearch => 'Other ways to search';

  @override
  String get booking_browseOrPickMap => 'Browse or pick on map';

  @override
  String get booking_popularRoutes => 'Popular Routes';

  @override
  String get booking_popularRoutesSubtitle =>
      'Most used commutes in your network';

  @override
  String get booking_selectOnMap => 'Route Map';

  @override
  String get booking_selectOnMapSubtitle =>
      'Zoom in or out to view trip routes';

  @override
  String get booking_selectPickupPoint => 'Select Pickup Point';

  @override
  String get booking_selectDestination => 'Select Destination';

  @override
  String get booking_availableVehicles => 'Available Vehicles';

  @override
  String get booking_pickBestShuttle => 'Pick the best shuttle for your trip';

  @override
  String get booking_bookYourRide => 'Book Your Ride';

  @override
  String booking_stepOf4(int step) {
    return 'Step $step of 4';
  }

  @override
  String get booking_selectVehicle => 'Select Vehicle';

  @override
  String booking_availableOptions(int count) {
    return '$count options available now';
  }

  @override
  String get booking_sortRecommended => 'Recommended';

  @override
  String get booking_sortPriceLow => 'Price Low';

  @override
  String get booking_sortRating => 'Rating';

  @override
  String get booking_searchingBestOptions => 'Searching for best options...';

  @override
  String get booking_errorLoadingVehicles => 'Could not load vehicles';

  @override
  String get common_tryAgain => 'Try again';

  @override
  String get booking_noVehiclesAvailable => 'No vehicles available';

  @override
  String get booking_noVehiclesDesc =>
      'No vehicles available for this time. Try a different arrival time or search again.';

  @override
  String get booking_searchAgain => 'Search Again';

  @override
  String get booking_selectRoute => 'Select Route';

  @override
  String get booking_compareVehicles => 'Compare Vehicles';

  @override
  String get booking_availableRoutes => 'Available routes';

  @override
  String booking_optionsForSearch(int count) {
    return '$count options for your search';
  }

  @override
  String get booking_map => 'Map';

  @override
  String get booking_vehicleDetails => 'Vehicle Details';

  @override
  String get booking_recommendedForYou => 'Recommended for you';

  @override
  String get booking_comfortAndAmenities => 'Comfort & Amenities';

  @override
  String get booking_comfortDesc =>
      'Check comfort level before selecting your seat';

  @override
  String get booking_driver => 'Driver';

  @override
  String get booking_driverDesc => 'Captain details and rating';

  @override
  String get booking_priceAndAvailability => 'Price & Availability';

  @override
  String get booking_priceDesc => 'Cost and number of available seats';

  @override
  String get booking_ac => 'AC';

  @override
  String get booking_available => 'Available';

  @override
  String get booking_unavailable => 'Unavailable';

  @override
  String get booking_seatType => 'Seat Type';

  @override
  String get booking_recliningSeats => 'Reclining Seats';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get booking_vehicleCondition => 'Vehicle Condition';

  @override
  String get booking_legRoom => 'Leg Room';

  @override
  String get booking_ratingExcellent => 'Excellent';

  @override
  String get booking_ratingVeryGood => 'Very Good';

  @override
  String get booking_ratingGood => 'Good';

  @override
  String get booking_ratingNormal => 'Normal';

  @override
  String get booking_certified => 'Certified';

  @override
  String get booking_completedTrips => 'completed trips';

  @override
  String get booking_yearsExperience => 'years exp';

  @override
  String get booking_tripPrice => 'Trip Price';

  @override
  String get booking_remaining => 'remaining';

  @override
  String get booking_selectPickupDestMap =>
      'Pickup and destination are set by the selected trip';

  @override
  String get booking_popular => 'Popular';

  @override
  String get booking_pickup => 'Pickup';

  @override
  String get booking_tapMapPickup => 'Zoom in or out to view pickup points';

  @override
  String get booking_tapMapDest => 'Zoom in or out to view destination points';

  @override
  String get booking_pickupPoint => 'Pickup Point';

  @override
  String get booking_notSet => 'Not set';

  @override
  String get booking_destinationPoint => 'Destination Point';

  @override
  String get booking_confirmRoute => 'Confirm Route';

  @override
  String get booking_availableSeats => 'Available Seats';

  @override
  String get packages_commutePackages => 'Commute Packages';

  @override
  String get packages_packageDetails => 'Package Details';

  @override
  String get packages_all => 'All';

  @override
  String get packages_weekly => 'Weekly';

  @override
  String get packages_monthly => 'Monthly';

  @override
  String get packages_quarterly => 'Quarterly';

  @override
  String get packages_perRide => 'Per ride';

  @override
  String get packages_emptyTitle => 'No packages in this range';

  @override
  String get packages_emptyBody =>
      'Try another duration, or pull to refresh to load the latest plans.';

  @override
  String get packages_duration => 'Duration';

  @override
  String get packages_totalTrips => 'Total Trips';

  @override
  String packages_ridesCount(int count) {
    return '$count Rides';
  }

  @override
  String packages_egpAmount(String amount) {
    return 'EGP $amount';
  }

  @override
  String get packages_startingPrice => 'starting';

  @override
  String get packages_whatIsIncluded => 'What is Included';

  @override
  String get packages_reservedSeatGuaranteed => 'Reserved Seat Guaranteed';

  @override
  String get packages_reservedSeatDesc =>
      'Your preferred seat is locked for every daily shuttle ride.';

  @override
  String get packages_flexibleTiming => 'Flexible Ride Timing';

  @override
  String get packages_flexibleTimingDesc =>
      'Adjust your ride booking times anytime without cancellation fees.';

  @override
  String get packages_routeLimits => 'Route & Booking Limits';

  @override
  String get packages_routeScope => 'Route Scope';

  @override
  String get packages_routeScopeDesc =>
      'Fixed designated route selected upon checkout.';

  @override
  String get packages_includedRides => 'Included Rides';

  @override
  String packages_singleTripsDesc(int count) {
    return '$count single shuttle trips.';
  }

  @override
  String get packages_validityPeriod => 'Validity Period';

  @override
  String packages_consecutiveDaysDesc(int days) {
    return '$days consecutive calendar days.';
  }

  @override
  String get packages_termsCancellation => 'Terms & Cancellation';

  @override
  String get packages_termsText1 =>
      'Packages cannot be refunded once activated.';

  @override
  String get packages_termsText2 =>
      'Seats must be confirmed at least 2 hours before trip.';

  @override
  String packages_termsText3(int count) {
    return 'Package holds up to $count reservations for the selected route.';
  }

  @override
  String get packages_subscriptionCost => 'Subscription Cost';

  @override
  String get packages_route => 'Route';

  @override
  String get packages_marketplaceSubtitle =>
      'Discover packages from transport offices';

  @override
  String get packages_allOffices => 'All offices';

  @override
  String get packages_filterByOffice => 'Choose office';

  @override
  String get packages_officeSearchHint => 'Search by office name';

  @override
  String packages_noOfficeMatch(String query) {
    return 'No office matches \"$query\"';
  }

  @override
  String packages_fromOffice(String office) {
    return '$office packages';
  }

  @override
  String get packages_showAllOffices => 'Show all';

  @override
  String packages_officePackagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count packages',
      one: '1 package',
    );
    return '$_temp0';
  }

  @override
  String get packages_emptyMarketplaceTitle => 'No packages available yet';

  @override
  String get packages_emptyMarketplaceBody =>
      'No office has listed packages for booking yet. Explore the available trips instead.';

  @override
  String get packages_exploreTrips => 'Explore available trips';

  @override
  String get packages_emptyOfficeTitle => 'No packages from this office yet';

  @override
  String get packages_emptyOfficeBody =>
      'Try another office, or browse every package in the marketplace.';

  @override
  String get packages_viewAllOffices => 'View all offices';

  @override
  String get packages_providedBy => 'Provided by';

  @override
  String get packages_viewOffice => 'View office';

  @override
  String get packages_chooseTripToSubscribe => 'Choose a trip to subscribe';

  @override
  String get error_timeout => 'Connection timed out. Please try again.';

  @override
  String get error_cancelled => 'Request was cancelled.';

  @override
  String get error_noInternet => 'No internet connection.';

  @override
  String get error_badRequest => 'Invalid request.';

  @override
  String get error_unauthorized => 'Unauthorized access.';

  @override
  String get error_forbidden =>
      'You do not have permission to access this resource.';

  @override
  String get error_notFound => 'Resource not found.';

  @override
  String get error_validation => 'Invalid data provided.';

  @override
  String get error_server => 'Server error. Please try again later.';

  @override
  String get error_unknown => 'An unknown error occurred.';

  @override
  String get dashboard_home => 'Home';

  @override
  String get dashboard_bookings => 'Bookings';

  @override
  String get dashboard_trips => 'Trips';

  @override
  String get dashboard_fleet => 'Fleet Management';

  @override
  String get dashboard_routes => 'Routes';

  @override
  String get dashboard_subscriptions => 'Subscriptions';

  @override
  String get dashboard_payments => 'Finance';

  @override
  String get dashboard_tickets => 'Tickets';

  @override
  String get dashboard_reports => 'Reports';

  @override
  String get dashboard_settings => 'Settings';

  @override
  String get dashboard_permissions => 'Permissions';

  @override
  String get dashboard_panel => 'Operation Panel';

  @override
  String get dashboard_system => 'Transportation Ops System';

  @override
  String get dashboard_menu => 'Menu';

  @override
  String get dashboard_lightMode => 'Light Mode';

  @override
  String get dashboard_darkMode => 'Dark Mode';

  @override
  String get dashboard_unauthorized =>
      'This page is not available for the current role';

  @override
  String get onboarding_skip => 'Skip';

  @override
  String get onboarding_next => 'Next';

  @override
  String get onboarding_getStarted => 'Get Started';

  @override
  String get onboarding_page1Title => 'Travel With Confidence';

  @override
  String get onboarding_page1Body =>
      'Book your trip in seconds, choose your seat, and track your vehicle live until you reach your destination safely.';

  @override
  String get onboarding_page1FeatureA => 'Trip booking';

  @override
  String get onboarding_page1FeatureB => 'Route discovery';

  @override
  String get onboarding_page2Title => 'Comfort In Every Ride';

  @override
  String get onboarding_page2Body =>
      'Modern vehicles, comfortable seating, and a seamless booking experience designed for your daily commute.';

  @override
  String get onboarding_page2FeatureA => 'Live tracking';

  @override
  String get onboarding_page2FeatureB => 'Arrival ETA';

  @override
  String get onboarding_page3Title => 'Every Journey Starts With Trust';

  @override
  String get onboarding_page3Body =>
      'Professional drivers, live tracking, and real-time updates keep you informed from departure to arrival.';

  @override
  String get onboarding_page3FeatureA => 'Subscriptions';

  @override
  String get onboarding_page3FeatureB => 'Discounted packages';

  @override
  String get onboarding_page4Title => 'Pay securely, get help anytime';

  @override
  String get onboarding_page4Body =>
      'Pay safely with trusted methods and reach our support team whenever you need.';

  @override
  String get onboarding_page4FeatureA => 'Secure payments';

  @override
  String get onboarding_page4FeatureB => '24/7 support';

  @override
  String get welcome_trustSecure => 'Secure payments';

  @override
  String get welcome_trustLive => 'Real-time tracking';

  @override
  String get welcome_trustDaily => 'Trusted daily commute';

  @override
  String get authSuccess_createdTitle => 'You\'re all set!';

  @override
  String get authSuccess_createdSubtitle =>
      'Your account is ready. Let\'s get you moving.';

  @override
  String get authSuccess_verifyTitle => 'Verify your email';

  @override
  String authSuccess_verifySubtitle(String email) {
    return 'We sent a confirmation link to $email. Confirm it to activate your account, then sign in.';
  }

  @override
  String get authSuccess_getStarted => 'Get started';

  @override
  String get authSuccess_backToSignIn => 'Back to sign in';

  @override
  String get authSuccess_perkBooking => 'Book trips instantly';

  @override
  String get authSuccess_perkTracking => 'Track rides live';

  @override
  String get authSuccess_perkPasses => 'Save with passes';

  @override
  String get auth_passwordStrengthLabel => 'Password strength';

  @override
  String get auth_passwordWeak => 'Weak';

  @override
  String get auth_passwordFair => 'Fair';

  @override
  String get auth_passwordGood => 'Good';

  @override
  String get auth_passwordStrong => 'Strong';

  @override
  String get auth_passwordHint =>
      'Use 8+ characters with letters, numbers and a symbol.';

  @override
  String auth_policyComingSoon(String title) {
    return '$title will open when published.';
  }

  @override
  String get auth_referralCodeSection => 'Referral code (optional)';

  @override
  String get auth_referralCodeLabel => 'Enter a referral code';

  @override
  String get auth_referralCodeHint =>
      'Have a code from a friend? Add it to earn a welcome reward.';

  @override
  String get referral_pending => 'Pending';

  @override
  String get referral_leaderboardTitle => 'Top referrers';

  @override
  String get referral_leaderboardEmpty =>
      'Be the first to climb the leaderboard.';

  @override
  String get referral_you => 'You';

  @override
  String get tracking_title => 'Track your trip';

  @override
  String get tracking_loading => 'Loading your trip…';

  @override
  String get tracking_refresh => 'Refresh';

  @override
  String get tracking_errorTitle => 'We couldn\'t load your tracking';

  @override
  String get tracking_emptyTitle => 'No trip to track';

  @override
  String get tracking_emptyBody =>
      'Live tracking appears here once a booking of yours is confirmed.';

  @override
  String get tracking_emptyAction => 'Browse trips';

  @override
  String get tracking_stateNotStarted => 'Your trip hasn\'t started yet';

  @override
  String get tracking_stateDriverOnWay => 'The captain is on the way';

  @override
  String get tracking_stateBoarding => 'Boarding now';

  @override
  String get tracking_stateInProgress => 'On the road';

  @override
  String get tracking_stateCompleted => 'Trip completed';

  @override
  String get tracking_signalLive => 'Live';

  @override
  String get tracking_signalStale => 'Signal delayed';

  @override
  String get tracking_signalNone => 'Waiting for the captain\'s signal';

  @override
  String get tracking_signalOffRoute => 'Off route';

  @override
  String get tracking_updatedJustNow => 'just now';

  @override
  String tracking_updatedMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String get tracking_etaToYourStop => 'Arrives at your stop';

  @override
  String get tracking_etaToDestination => 'You arrive at';

  @override
  String get tracking_etaNow => 'Now';

  @override
  String get tracking_etaUnavailable => 'Not available yet';

  @override
  String tracking_etaMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String tracking_etaHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get tracking_sourceLive => 'From live GPS';

  @override
  String get tracking_sourceEstimated => 'Estimated';

  @override
  String get tracking_sourceScheduled => 'From the schedule';

  @override
  String tracking_departsAt(String time) {
    return 'Departs at $time';
  }

  @override
  String tracking_stopsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops left',
      one: '1 stop left',
      zero: 'No stops left',
    );
    return '$_temp0';
  }

  @override
  String get tracking_yourBooking => 'Your booking';

  @override
  String tracking_seat(String label) {
    return 'Seat $label';
  }

  @override
  String get tracking_boarded => 'You\'re on board';

  @override
  String get tracking_notBoarded => 'Not boarded yet';

  @override
  String get tracking_boardAt => 'Board at';

  @override
  String get tracking_alightAt => 'Get off at';

  @override
  String get tracking_stopsTitle => 'Trip stops';

  @override
  String get tracking_yourStopBadge => 'Your stop';

  @override
  String get tracking_yourDropoffBadge => 'Your drop-off';

  @override
  String get tracking_stopDeparted => 'Departed';

  @override
  String get tracking_stopArrived => 'At the stop';

  @override
  String get tracking_stopNext => 'Next';

  @override
  String get tracking_captain => 'Captain';

  @override
  String get tracking_vehicle => 'Vehicle';

  @override
  String get tracking_call => 'Call';

  @override
  String get tracking_noRating => 'No ratings yet';

  @override
  String tracking_ratingWithCount(String rating, int count) {
    return '$rating ($count)';
  }

  @override
  String get tracking_noPhone => 'The captain\'s number isn\'t available';

  @override
  String get tracking_completedTitle => 'You arrived safely';

  @override
  String get tracking_completedBody => 'We hope the ride was comfortable.';

  @override
  String get tracking_rateTrip => 'Rate this trip';

  @override
  String get tracking_alreadyReviewed =>
      'Thanks — you\'ve already rated this trip.';

  @override
  String get tracking_bookAgain => 'Book another trip';

  @override
  String get tracking_mapUnavailableTitle => 'Map data unavailable';

  @override
  String get tracking_mapUnavailableBody =>
      'No route coordinates were found for this trip.';

  @override
  String get tracking_recenter => 'Recenter';

  @override
  String get tracking_followVehicle => 'Follow the vehicle';

  @override
  String get profile_title => 'Profile';

  @override
  String profile_memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get profile_guestName => 'Your account';

  @override
  String get profile_noEmail => 'No email added';

  @override
  String get profile_completeTitle => 'Finish setting up your account';

  @override
  String get profile_completeBody =>
      'Add your missing details so your captain and support can reach you.';

  @override
  String get profile_completeAction => 'Complete now';

  @override
  String get profile_statTrips => 'Trips taken';

  @override
  String get profile_statUpcoming => 'Upcoming';

  @override
  String get profile_statPackage => 'Package';

  @override
  String get profile_packageNone => 'None';

  @override
  String get profile_packageActive => 'Active';

  @override
  String profile_packageExpiringSoon(String name, String route, int days) {
    return 'Your $name package on $route ends in $days days.';
  }

  @override
  String get profile_packageRenew => 'Renew';

  @override
  String get profile_sectionAccount => 'Account';

  @override
  String get profile_sectionPreferences => 'Preferences';

  @override
  String get profile_sectionSupport => 'Support';

  @override
  String get profile_sectionLegal => 'Legal';

  @override
  String get profile_editProfile => 'Personal details';

  @override
  String get profile_editProfileSubtitle => 'Name, phone and email';

  @override
  String get profile_wallet => 'My wallet';

  @override
  String get profile_walletSubtitle => 'Your balance at each office';

  @override
  String get profile_subscription => 'My package';

  @override
  String get profile_subscriptionSubtitle => 'Plans, renewals and billing';

  @override
  String get profile_myTrips => 'My trips';

  @override
  String get profile_myTripsSubtitle => 'Upcoming, active and past trips';

  @override
  String get profile_language => 'Language';

  @override
  String get profile_languageEnglish => 'English';

  @override
  String get profile_languageArabic => 'العربية';

  @override
  String get profile_selectLanguage => 'Choose a language';

  @override
  String get profile_selectLanguageBody =>
      'The app switches immediately, including the layout direction.';

  @override
  String get profile_theme => 'Appearance';

  @override
  String get profile_themeSystem => 'System';

  @override
  String get profile_themeLight => 'Light';

  @override
  String get profile_themeDark => 'Dark';

  @override
  String get profile_selectTheme => 'Choose an appearance';

  @override
  String get profile_selectThemeBody => 'System follows your device setting.';

  @override
  String get profile_themeLightBody => 'Best in daylight';

  @override
  String get profile_themeDarkBody => 'Easier on the eyes at night';

  @override
  String get profile_helpCenter => 'Help centre';

  @override
  String get profile_helpCenterSubtitle => 'FAQs, tickets and refunds';

  @override
  String get profile_terms => 'Terms & conditions';

  @override
  String get profile_privacy => 'Privacy policy';

  @override
  String profile_lastUpdated(String date) {
    return 'Last updated $date';
  }

  @override
  String get profile_editTitle => 'Personal details';

  @override
  String get profile_editBody =>
      'Your captain uses these details to reach you about a trip.';

  @override
  String get profile_fieldName => 'Full name';

  @override
  String get profile_fieldPhone => 'Phone number';

  @override
  String get profile_fieldEmail => 'Email address';

  @override
  String get profile_errorRequired => 'This field is required';

  @override
  String get profile_errorNameTooShort => 'Enter your full name';

  @override
  String get profile_errorInvalidPhone =>
      'Enter a valid Egyptian mobile number';

  @override
  String get profile_errorInvalidEmail => 'Enter a valid email address';

  @override
  String get profile_saved => 'Your details were saved';

  @override
  String get profile_logout => 'Log out';

  @override
  String get profile_logoutTitle => 'Log out?';

  @override
  String get profile_logoutBody =>
      'You\'ll need to sign in again to book or track a trip.';

  @override
  String get profile_logoutFailed =>
      'We couldn\'t log you out. Please try again.';

  @override
  String get profile_refreshFailed => 'We couldn\'t refresh your profile.';

  @override
  String get profile_signInRequiredTitle => 'Sign in to view your profile';

  @override
  String get profile_signInRequiredBody =>
      'You\'re browsing as a guest. Sign in to see your trips, packages and account details.';

  @override
  String get profile_signInCta => 'Sign in';

  @override
  String get welcome_continueWithEmail => 'Continue with Email';

  @override
  String get welcome_createAccount => 'Create an account';

  @override
  String get welcome_continueAsGuest => 'Continue as guest';

  @override
  String get welcome_heroTagline =>
      'Smart, comfortable transport.\nBook, track, and ride — all in one place.';

  @override
  String get welcome_valueSeats => 'Reserve seats';

  @override
  String get welcome_valueTracking => 'Live bus tracking';

  @override
  String get welcome_valuePasses => 'Manage passes';

  @override
  String get auth_termsAndConditions => 'Terms & Conditions';

  @override
  String get welcome_languageName => 'English';

  @override
  String get auth_signInHeroSubtitle =>
      'Log in to track your trips, manage subscriptions, and follow buses in real time.';

  @override
  String get auth_signingIn => 'Signing in...';

  @override
  String get auth_signInInfoCard =>
      'All your trips and bookings in one place — log in and follow your day easily.';

  @override
  String get auth_signInSecurityNote =>
      'Make sure to use the email associated with your account to access your bookings and subscriptions.';

  @override
  String get auth_signUpHeroSubtitle =>
      'Register your details once and enjoy booking trips, tracking buses, and managing subscriptions easily.';

  @override
  String get auth_accountDetails => 'Account Details';

  @override
  String get auth_loginDetails => 'Login Details';

  @override
  String get auth_creatingAccount => 'Creating Account...';

  @override
  String get auth_signUpTrustBanner =>
      'Your data is secure and used only to manage your trips and bookings.';

  @override
  String get auth_signUpSecurityNote =>
      'By clicking Create Account, a confirmation will be sent to your email.';

  @override
  String get auth_sendingLink => 'Sending link...';

  @override
  String get auth_recoveryLinkFailed => 'Failed to send recovery link';

  @override
  String get auth_resetInfoCard =>
      'We will send a temporary link to your email. Open it soon to set a new password.';

  @override
  String get auth_recoveryLinkSent => 'Recovery link sent';

  @override
  String get auth_openEmailToReset =>
      'Open the email and tap the link to reset your password.';

  @override
  String get auth_emailHelp =>
      'Didn\'t find the email? Check your spam folder or wait a bit before resending.';

  @override
  String get auth_forgotSecurityNote =>
      'For your security, the system may prevent sending multiple links in a short period.';

  @override
  String get auth_help => 'Help?';

  @override
  String get auth_resetPasswordTitle => 'Set a new password';

  @override
  String get auth_resetPasswordSubtitle =>
      'Choose a new password for your account.';

  @override
  String get auth_newPassword => 'New Password';

  @override
  String get auth_confirmPassword => 'Confirm Password';

  @override
  String get auth_passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get auth_updatePassword => 'Update Password';

  @override
  String get auth_updatingPassword => 'Updating...';

  @override
  String get auth_passwordUpdatedSnack =>
      'Your password has been updated. Please sign in.';

  @override
  String get auth_resetPasswordFailed => 'Failed to update password';

  @override
  String get auth_resetLinkInvalid =>
      'This reset link is invalid or has expired. Please request a new one.';

  @override
  String get auth_verifyingResetLink => 'Verifying your reset link...';

  @override
  String get auth_enterPhoneTitle => 'Enter your phone number';

  @override
  String get auth_enterPhoneSubtitle =>
      'We\'ll send a verification code to the number you enter.';

  @override
  String get auth_or => 'or';

  @override
  String get auth_continue => 'Continue';

  @override
  String get auth_verifyNumberTitle => 'Verify number';

  @override
  String get auth_enterOtpTitle => 'Enter the 6-digit code';

  @override
  String auth_otpSentTo(String phone) {
    return 'The code was sent by SMS to:\n$phone';
  }

  @override
  String get auth_verify => 'Verify';

  @override
  String get auth_didntReceiveCode => 'Didn\'t receive the code?';

  @override
  String auth_resendCountdown(int seconds) {
    return 'Resend ($seconds)';
  }

  @override
  String get auth_resendCode => 'Resend code';

  @override
  String get auth_mustAcceptTerms => 'You must accept the Terms & Conditions.';

  @override
  String get auth_completeProfileTitle => 'Complete your profile';

  @override
  String get auth_welcomeToApp => 'Welcome to BMT';

  @override
  String get auth_completeProfileSubtitle =>
      'We need a few details to give you the best service.';

  @override
  String get auth_nameHint => 'Ahmed Hassan';

  @override
  String get auth_nameRequired => 'Name is required';

  @override
  String get auth_emailOptional => 'Email (optional)';

  @override
  String get auth_gender => 'Gender';

  @override
  String get auth_genderMale => 'Male';

  @override
  String get auth_genderFemale => 'Female';

  @override
  String get auth_acceptTermsCheckbox =>
      'I agree to the Terms of Service and Privacy Policy.';

  @override
  String get auth_createAccountAndStart => 'Create account and get started';

  @override
  String get auth_invalidPhoneShort => 'Invalid number';

  @override
  String get splash_tagline => 'Your journey, simplified.';

  @override
  String get common_today => 'Today';

  @override
  String get common_date => 'Date';

  @override
  String get common_time => 'Time';

  @override
  String get common_seats => 'Seats';

  @override
  String get common_soldOut => 'Sold out';

  @override
  String get common_notSet => 'Not set';

  @override
  String get common_notifications => 'Notifications';

  @override
  String get common_support => 'Support';

  @override
  String get common_manage => 'Manage';

  @override
  String get common_pickup => 'Pickup';

  @override
  String get common_destination => 'Destination';

  @override
  String get common_dropOff => 'Drop-off';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_routes => 'Routes';

  @override
  String get nav_trips => 'Trips';

  @override
  String get nav_profile => 'Profile';

  @override
  String get home_myTrips => 'My trips';

  @override
  String get home_greetingMorning => 'Good morning';

  @override
  String get home_greetingAfternoon => 'Good afternoon';

  @override
  String get home_greetingEvening => 'Good evening';

  @override
  String get home_welcomeAboard => 'Welcome aboard';

  @override
  String get home_popularDestinations => 'POPULAR DESTINATIONS';

  @override
  String get home_searchRoutesTimesSeats => 'Search routes, times and seats';

  @override
  String get home_expiresToday => 'Expires today';

  @override
  String get home_trackYourBus => 'Track your bus';

  @override
  String get home_yourBooking => 'Your booking';

  @override
  String get home_yourBookings => 'Your bookings';

  @override
  String get home_yourJourney => 'Your journey';

  @override
  String get home_seatsYouHold => 'Seats you hold, and where each one stands.';

  @override
  String get home_bookASeat => 'Book a seat';

  @override
  String get home_nextDepartures => 'Next departures';

  @override
  String get home_tripsOpenSoonest => 'Trips open for booking, soonest first.';

  @override
  String get home_allRoutes => 'All routes';

  @override
  String get home_yourPackage => 'Your package';

  @override
  String get home_activeSubscription => 'Active subscription';

  @override
  String get home_bookAnotherSeat => 'Book another seat';

  @override
  String get home_bookSeat => 'Book seat';

  @override
  String get home_fareNotPublished => 'Fare not published yet';

  @override
  String get home_fareFrom => 'FARE FROM';

  @override
  String get home_departureToBeSet => 'Departure time to be set';

  @override
  String get home_boarding => 'Boarding';

  @override
  String get home_rideTime => 'Ride time';

  @override
  String home_youBookedSeats(int seats) {
    return 'You booked $seats seats';
  }

  @override
  String get home_youBookedThis => 'You booked this';

  @override
  String get home_pickupShort => 'Pickup';

  @override
  String get home_stopNotSet => 'Stop not set';

  @override
  String get home_noDepartures => 'No departures scheduled';

  @override
  String get home_noDeparturesBody =>
      'Nothing is open for booking right now. Browse the routes to see what runs and when.';

  @override
  String get home_browseRoutes => 'Browse routes';

  @override
  String get home_travelWith => 'Travel with';

  @override
  String get home_companies => 'Transport companies';

  @override
  String get home_companiesSubtitle =>
      'Pick an operator to see everything it runs.';

  @override
  String home_departuresOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips open for booking',
      one: '1 trip open for booking',
    );
    return '$_temp0';
  }

  @override
  String get home_searchTripTitle => 'Search Trip';

  @override
  String get home_searchTripSubtitle => 'Find your next commute in seconds';

  @override
  String get home_pickupLocation => 'Pickup Location';

  @override
  String get home_selectPickupPoint => 'Select pickup point';

  @override
  String get home_whereAreYouGoing => 'Where are you going?';

  @override
  String get home_selectTime => 'Select time';

  @override
  String get home_searchTrips => 'Search Trips';

  @override
  String home_seatsOnlyLeft(int count) {
    return 'Only $count left';
  }

  @override
  String home_seatsAvailable(int count) {
    return '$count available';
  }

  @override
  String get home_statusUnderReview => 'Under review';

  @override
  String get home_statusConfirmed => 'Confirmed';

  @override
  String get home_statusOnBoard => 'On board';

  @override
  String get home_statusUnderReviewExplanation =>
      'We are checking your payment. You will be notified as soon as your seat is confirmed.';

  @override
  String get home_statusConfirmedExplanation =>
      'Your seat is held. Be at the pickup point 10 minutes before departure.';

  @override
  String get home_statusOnBoardExplanation =>
      'You are on board. Have a good trip.';

  @override
  String get home_yourBookingFallback => 'Your booking';

  @override
  String get home_amountPaid => 'Paid';

  @override
  String home_seatLabel(String label) {
    return 'Seat $label';
  }

  @override
  String home_daysLeft(int days) {
    return '$days days left';
  }

  @override
  String get home_dayLeft => '1 day left';

  @override
  String home_validUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String booking_searchHint(String title) {
    return 'Search $title';
  }

  @override
  String get booking_noPickupPointsAvailable =>
      'No pickup points available yet. Please check back soon.';

  @override
  String get booking_noDestinationsAvailable =>
      'No destinations available yet.';

  @override
  String get booking_noDepartureTimesAvailable =>
      'No departure times available for this route yet.';

  @override
  String get map_livePreviewTitle => 'Live route preview';

  @override
  String get map_livePreviewSubtitle =>
      'Real-time vehicle position and route flow';

  @override
  String get notifications_markAllRead => 'Mark all read';

  @override
  String get notifications_emptyTitle => 'No notifications yet';

  @override
  String get notifications_emptyBody =>
      'Trip updates, booking confirmations and reminders will appear here when they arrive.';

  @override
  String get notifications_categoryEmptyTitle => 'Nothing in this category';

  @override
  String get notifications_categoryEmptyBody =>
      'Pick another category to see the rest of your notifications.';

  @override
  String get notifications_newBadge => 'New';

  @override
  String get notifications_categoryAll => 'All';

  @override
  String get notifications_categoryBooking => 'Booking';

  @override
  String get notifications_categoryPayment => 'Payment';

  @override
  String get notifications_categoryTrip => 'Trip';

  @override
  String get notifications_categoryNews => 'News';

  @override
  String get notifications_categoryOffers => 'Offers';

  @override
  String get notifications_categoryAlerts => 'Alerts';

  @override
  String get trips_headerSubtitle => 'Upcoming, active, and past commutes';

  @override
  String get trips_bookNewTripTooltip => 'Book new trip';

  @override
  String get trips_filterUpcoming => 'Upcoming';

  @override
  String get trips_filterActive => 'Active';

  @override
  String get trips_filterCompleted => 'Completed';

  @override
  String get trips_filterCancelled => 'Cancelled';

  @override
  String get trips_sectionUpcoming => 'Upcoming trips';

  @override
  String get trips_sectionActive => 'In progress trips';

  @override
  String get trips_sectionCompleted => 'Completed trips';

  @override
  String get trips_sectionCancelled => 'Cancelled trips';

  @override
  String get trips_emptyUpcomingTitle => 'No upcoming trips scheduled';

  @override
  String get trips_emptyUpcomingSubtitle =>
      'Book a trip and it will show up here.';

  @override
  String get trips_emptyActiveTitle => 'No trips in progress right now';

  @override
  String get trips_emptyActiveSubtitle =>
      'Trips currently on the road will appear here.';

  @override
  String get trips_emptyCompletedTitle => 'No completed trips yet';

  @override
  String get trips_emptyCompletedSubtitle =>
      'Trips you finish will show up here.';

  @override
  String get trips_emptyCancelledTitle => 'No cancelled trips';

  @override
  String get trips_emptyCancelledSubtitle =>
      'Trips you cancel will show up here.';

  @override
  String get payments_checkoutTitle => 'Checkout';

  @override
  String get payments_encrypted => 'Encrypted';

  @override
  String get payments_fareSummary => 'Fare summary';

  @override
  String get payments_ticketFare => 'Ticket fare';

  @override
  String get payments_serviceFee => 'Service fee';

  @override
  String get payments_tax => 'Tax';

  @override
  String get payments_promoDiscount => 'Promo discount';

  @override
  String get payments_total => 'Total';

  @override
  String get payments_assuranceCardDetails =>
      'Card details are entered on the bank\'s page, never stored by BMT.';

  @override
  String get payments_assuranceSeatHeld =>
      'Your seat is held for you now and released only if the payment fails.';

  @override
  String get payments_assuranceTransferChecked =>
      'Transfers are checked by our team, and you will be notified once confirmed.';

  @override
  String get payments_assuranceSupportReference =>
      'Something looks wrong? Support can see this booking by its reference.';

  @override
  String payments_bookingMissingItems(String items) {
    return 'This booking is missing $items';
  }

  @override
  String get payments_completeBeforePaying =>
      'Go back and complete it before paying.';

  @override
  String get payments_goBack => 'Go back';

  @override
  String get payments_howToPay => 'How would you like to pay?';

  @override
  String payments_balanceAmount(String amount) {
    return 'Balance $amount';
  }

  @override
  String payments_shortByAmount(String amount) {
    return 'Short by $amount — top up or pick another method.';
  }

  @override
  String get payments_noMethodsAvailable =>
      'No payment method is switched on right now. Your seat is still held — contact support and we will take it from there.';

  @override
  String get payments_nextStepCard =>
      'You will finish on Paymob\'s encrypted card page.';

  @override
  String get payments_nextStepInstapay =>
      'Transfer, then attach the receipt on the next step.';

  @override
  String get payments_nextStepBankTransfer =>
      'Bank details come next — attach the receipt after you transfer.';

  @override
  String get payments_nextStepVodafoneCash =>
      'Send from your wallet, then attach the receipt on the next step.';

  @override
  String get payments_nextStepWallet =>
      'Deducted from your balance the moment you confirm.';

  @override
  String get payments_fastestBadge => 'Fastest';

  @override
  String get payments_seatHeldWhilePaying => 'Your seat is held while you pay.';

  @override
  String get payments_stepSeat => 'Seat';

  @override
  String get payments_stepPayment => 'Payment';

  @override
  String get payments_stepTicket => 'Ticket';

  @override
  String get payments_havePromoCode => 'Have a promo code?';

  @override
  String get payments_enterCodeHint => 'Enter code';

  @override
  String get payments_promoCodeInvalid => 'That code is not valid';

  @override
  String get payments_apply => 'Apply';

  @override
  String payments_promoApplied(String code, String amount) {
    return '$code applied — you save $amount';
  }

  @override
  String get payments_removePromoCode => 'Remove promo code';

  @override
  String get payments_yourSeat => 'Your seat';

  @override
  String get payments_seatNotSelected => 'Seat not selected';

  @override
  String payments_seatNumber(String seat) {
    return 'Seat $seat';
  }

  @override
  String get payments_vehicle => 'Vehicle';

  @override
  String get payments_driver => 'Driver';

  @override
  String get payments_directTrip => 'Direct';

  @override
  String get booking_bookYourSeat => 'Book your seat';

  @override
  String get booking_bookingFailed => 'Booking Failed';

  @override
  String get booking_seatJustTaken =>
      'This seat was just taken. Please go back and choose another seat.';

  @override
  String get booking_seatHoldExpired =>
      'Your seat hold expired. Please select your seat again.';

  @override
  String get booking_duplicateActiveBooking =>
      'You already have a pending booking for this trip. Please continue payment from your existing booking.';

  @override
  String get booking_openMyBookings => 'Open My Bookings';

  @override
  String get booking_ok => 'OK';

  @override
  String get booking_referenceNotCreated =>
      'The booking reference was not created.';

  @override
  String get booking_cardPaymentUnavailable =>
      'Card payment is not available right now.';

  @override
  String get booking_cardPaymentNotCompleted =>
      'Card payment was not completed. Your booking remains pending.';

  @override
  String get booking_cardPaymentDeclined =>
      'Your card was declined and you have not been charged. Your seat is still held — try another card or payment method.';

  @override
  String get booking_viewVehicleAndPhotos => 'Vehicle & photos';

  @override
  String get booking_vehiclePhotosUnavailable =>
      'No photos of this vehicle yet';

  @override
  String get booking_noRatingsYet => 'Not rated yet';

  @override
  String booking_ratingWithCount(String rating, int count) {
    return '$rating ($count)';
  }

  @override
  String get booking_vehicleCapacityLabel => 'Capacity';

  @override
  String booking_vehicleSeatsCount(int count) {
    return '$count seats';
  }

  @override
  String get booking_vehiclePlate => 'Plate';

  @override
  String get booking_vehicleYear => 'Year';

  @override
  String get booking_vehicleColor => 'Colour';

  @override
  String get trips_statusInProgress => 'In progress';

  @override
  String get trips_paymentPaid => 'Paid';

  @override
  String get trips_paymentPending => 'Pending';

  @override
  String get trips_paymentUnderReview => 'Under Review';

  @override
  String get trips_paymentRefunded => 'Refunded';

  @override
  String get trips_paymentFailed => 'Failed';

  @override
  String get trips_driverBadgeAssigned => 'Assigned';

  @override
  String get trips_driverBadgeEnRoute => 'En route';

  @override
  String get trips_driverBadgeCompleted => 'Trip complete';

  @override
  String get trips_driverBadgeCancelled => 'Trip cancelled';

  @override
  String get trips_liveLoadingPosition => 'Loading live position…';

  @override
  String get trips_livePositionUnavailable =>
      'Live position unavailable right now.';

  @override
  String get trips_liveWaitingForVehicle =>
      'Waiting for the vehicle\'s live position…';

  @override
  String trips_liveRouteCoveredPercent(int percent) {
    return '$percent% of the route covered';
  }

  @override
  String get trips_liveTripInProgress => 'Your trip is in progress';

  @override
  String get trips_liveTrackButton => 'Track';

  @override
  String get payments_continueLabel => 'Continue';

  @override
  String get payments_payNow => 'Pay now';

  @override
  String get payments_missingBookingDetails =>
      'Some booking details are missing.';

  @override
  String get payments_choosePaymentMethod =>
      'Choose a payment method to continue.';

  @override
  String payments_walletShortByAmount(String amount) {
    return 'Your wallet is $amount short of this fare.';
  }

  @override
  String get support_minLengthHint => 'Please add a bit more detail';

  @override
  String get support_refresh => 'Refresh';

  @override
  String get support_centerTitle => 'Support Center';

  @override
  String get support_categoryBooking => 'Booking Issue';

  @override
  String get support_categoryPayment => 'Payment Issue';

  @override
  String get support_categoryTripDelay => 'Trip Delay';

  @override
  String get support_categoryDriverVehicle => 'Driver or Vehicle Issue';

  @override
  String get support_categorySubscription => 'Subscription Issue';

  @override
  String get support_categoryLostItem => 'Lost Item';

  @override
  String get support_categoryOther => 'Other';

  @override
  String get support_emptyTitle => 'No tickets yet';

  @override
  String get support_emptyBody =>
      'When you open a ticket it will appear here, along with its status and every reply from our team.';

  @override
  String get support_uploadPrompt => 'Upload image or document';

  @override
  String get support_uploadHint => 'JPG, PNG, or PDF up to 5MB';

  @override
  String get support_removeAttachment => 'Remove attachment';

  @override
  String get support_myTickets => 'My tickets';

  @override
  String get support_statusSubmitted => 'Submitted';

  @override
  String get support_statusUnderReview => 'Under Review';

  @override
  String get support_statusContacted => 'Contacted';

  @override
  String get support_statusResolved => 'Resolved';

  @override
  String get support_statusClosed => 'Closed';

  @override
  String get support_statusRejected => 'Rejected';

  @override
  String get support_timelineEmpty => 'No timeline events available.';

  @override
  String get support_heroTitle => 'How can we help?';

  @override
  String get support_heroBody =>
      'Tell us what went wrong and our team will follow up on your ticket. We usually reply within a few hours.';

  @override
  String get support_createTicket => 'Create a ticket';

  @override
  String get support_topicLabel => 'What is this about?';

  @override
  String get support_topicHint => 'Pick the topic closest to your issue.';

  @override
  String get support_officeLabel => 'Which office is this about?';

  @override
  String get support_officeHint =>
      'Pick the office your complaint concerns so it reaches their team.';

  @override
  String get support_officePlaceholder => 'Select an office';

  @override
  String get support_officeRequired => 'Please choose an office';

  @override
  String get support_officeLoadError => 'Couldn\'t load offices.';

  @override
  String get support_attachmentOpenFailed => 'Couldn\'t open attachment.';

  @override
  String get support_subjectLabel => 'Subject';

  @override
  String get support_subjectHint => 'A short summary of the problem.';

  @override
  String get support_subjectPlaceholder => 'e.g. Charged twice for one booking';

  @override
  String get support_subjectRequired => 'Subject is required';

  @override
  String get support_detailsLabel => 'Details';

  @override
  String get support_detailsHint =>
      'What happened, and when? Add your trip or booking reference if you have it.';

  @override
  String get support_detailsPlaceholder => 'Describe the issue…';

  @override
  String get support_detailsRequired => 'Details are required';

  @override
  String get support_relatedBookingLabel => 'Related booking';

  @override
  String get support_relatedBookingHint =>
      'Optional — pick the booking this is about so it reaches the right office.';

  @override
  String get support_relatedBookingNone => 'Not about a specific booking';

  @override
  String get support_attachmentLabel => 'Attachment';

  @override
  String get support_attachmentHint =>
      'Optional — a screenshot or receipt helps us a lot.';

  @override
  String get support_submitting => 'Submitting…';

  @override
  String get support_submitTicket => 'Submit ticket';

  @override
  String get support_newTicketTitle => 'New ticket';

  @override
  String get support_ticketCreatedSnack =>
      'Ticket created. Our team will get back to you shortly.';

  @override
  String get support_ticketCreatedAttachmentFailedSnack =>
      'Ticket submitted, but the attachment failed to upload.';

  @override
  String support_ticketNumberTitle(String number) {
    return 'Ticket $number';
  }

  @override
  String get support_ticketDetailsTitle => 'Ticket details';

  @override
  String get support_failedToLoad => 'Failed to load ticket details';

  @override
  String get support_reviewingNotice =>
      'Our customer service team is reviewing your ticket and may contact you shortly.';

  @override
  String get support_currentStatus => 'Current Status';

  @override
  String get support_assignedTo => 'Assigned to';

  @override
  String get support_description => 'Description';

  @override
  String get support_customerServiceNote => 'Customer Service Note';

  @override
  String get support_attachments => 'Attachments';

  @override
  String get booking_tapToChoosePickupStation =>
      'Tap to choose a pickup station';

  @override
  String get booking_noMappedPickupStations =>
      'No mapped pickup stations are available';

  @override
  String get booking_tapToChooseDestination => 'Tap to choose a destination';

  @override
  String get booking_noMappedDestinations =>
      'No mapped destinations are available';

  @override
  String get booking_mapCouldNotBeLoaded => 'Map could not be loaded';

  @override
  String get common_tomorrow => 'Tomorrow';

  @override
  String common_durationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String common_durationHours(int hours) {
    return '${hours}h';
  }

  @override
  String common_durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get seatSelection_selectYourSeat => 'Select Your Seat';

  @override
  String seatSelection_seatsFreeCount(int count) {
    return '$count free';
  }

  @override
  String get seatSelection_chooseASeat => 'Choose a seat';

  @override
  String get seatSelection_tapSeatToContinue =>
      'Tap an available seat to continue';

  @override
  String seatSelection_seatsOpenCount(int count) {
    return '$count open';
  }

  @override
  String get seatSelection_microbusCapacity => '15-seat microbus';

  @override
  String get seatSelection_frontOfVehicle => 'FRONT OF VEHICLE';

  @override
  String get seatSelection_cabinLayout => 'Cabin layout';

  @override
  String get seatSelection_cabinDoor => 'Door';

  @override
  String get seatSelection_cabinRear => 'REAR';

  @override
  String get seatSelection_driverCabinNote =>
      'Seats 1 and 2 are reserved for the driver cabin';

  @override
  String get seatSelection_driverCabinLabel => 'Driver Cabin';

  @override
  String get seatSelection_selectSeatToContinue =>
      'Select one seat to continue';

  @override
  String get seatSelection_tapAvailableSeatHint =>
      'Tap one available seat on the layout above.';

  @override
  String seatSelection_seatSelectedTitle(String seatNum) {
    return 'Seat $seatNum selected';
  }

  @override
  String seatSelection_seatSummaryLine(String price, String total) {
    return '1 seat · EGP $price each · Total EGP $total';
  }

  @override
  String get seatSelection_hintCardBody =>
      'Middle rows use a pair on the left and a single seat on the right for a more realistic shuttle layout.';

  @override
  String seatSelection_departsAt(String time) {
    return 'Departs $time';
  }

  @override
  String get seatSelection_selectedSeatLabel => 'Selected seat';

  @override
  String get seatSelection_seatNumbersLabel => 'Seat numbers';

  @override
  String get seatSelection_perSeatLabel => 'Per seat';

  @override
  String get seatSelection_reservingSeat => 'Reserving seat...';

  @override
  String get seatSelection_continueBooking => 'Continue Booking';

  @override
  String get seatSelection_selectASeat => 'Select a Seat';

  @override
  String seatSelection_seatCountSelected(int count) {
    return '$count seat selected';
  }

  @override
  String get seatSelection_passengerInformation => 'Passenger information';

  @override
  String get seatSelection_contactDetails => 'Contact details';

  @override
  String get seatSelection_passengerNameLabel => 'Passenger name';

  @override
  String get seatSelection_fullNameHint => 'Full name as on ID';

  @override
  String get seatSelection_passengerPhoneLabel => 'Passenger phone number';

  @override
  String get seatSelection_phoneHint => '+20 10 1234 5678';

  @override
  String get seatSelection_phoneUsageNote =>
      'We will use this number for trip updates.';

  @override
  String get seatSelection_saveDetails => 'Save details';

  @override
  String get seatSelection_bookingSummaryTitle => 'Booking summary';

  @override
  String get seatSelection_pricePerSeatLabel => 'Price per seat';

  @override
  String get seatSelection_totalAmountLabel => 'Total amount';

  @override
  String get seatSelection_seatLegendTitle => 'Seat legend';

  @override
  String get seatSelection_seatStatusSelected => 'Selected';

  @override
  String get seatSelection_seatStatusReserved => 'Reserved';

  @override
  String get seatSelection_passengersTitle => 'Passengers';

  @override
  String get seatSelection_oneSeatBadge => '1 seat';

  @override
  String get seatSelection_addPassengerHint =>
      'Select another seat to add a passenger (UI preview)';

  @override
  String get seatSelection_awaitingSeatSelection => 'Awaiting seat selection';

  @override
  String seatSelection_passengerIndexLabel(int index) {
    return 'Passenger $index';
  }

  @override
  String get seatSelection_seatsLeftLabel => 'seats left';

  @override
  String seatSelection_acStatusLabel(String status) {
    return 'A/C · $status';
  }

  @override
  String get seatSelection_lockErrorSeatUnavailable =>
      'Seat is no longer available. Please choose another seat.';

  @override
  String get payments_stepFintechConnection =>
      'Establishing secure fintech connection...';

  @override
  String get payments_stepVerifyingAccount =>
      'Verifying account status and limit...';

  @override
  String get payments_stepReservingSeat =>
      'Reserving seat and finalising ticket metadata...';

  @override
  String get payments_pendingLabel => 'Pending';

  @override
  String get payments_methodLabel => 'Method:';

  @override
  String get payments_transactionIdLabel => 'Transaction ID:';

  @override
  String payments_driverSeatSummary(String driver, String seat) {
    return 'Driver: $driver • Seat: $seat';
  }

  @override
  String get payments_processingPaymentTitle => 'Processing Payment';

  @override
  String get payments_doNotCloseScreen =>
      'Please do not close this screen or press back button.';

  @override
  String get payments_secureCheckoutTitle => 'Secure Checkout';

  @override
  String get payments_paymobCheckoutOpened => 'Paymob Checkout Opened';

  @override
  String get payments_paymentSubmitted => 'Payment Submitted';

  @override
  String get payments_completeCardPaymentPaymob =>
      'Complete card payment in the secure Paymob page.';

  @override
  String get payments_receiptSentForReview =>
      'Your receipt was sent for operations review.';

  @override
  String get payments_bookingRefLabel => 'Booking Ref:';

  @override
  String get payments_paidAmountLabel => 'Paid Amount:';

  @override
  String get payments_paymentMethodLabel => 'Payment Method:';

  @override
  String get payments_viewTicket => 'View Ticket';

  @override
  String get payments_backToHome => 'Back to Home';

  @override
  String get payments_paymentFailedTitle => 'Payment Failed';

  @override
  String get payments_transactionNotProcessed =>
      'Your transaction could not be processed.';

  @override
  String get payments_reasonForFailure => 'Reason for Failure';

  @override
  String get payments_paymentNotCompleted => 'Payment could not be completed.';

  @override
  String get payments_retryPayment => 'Retry Payment';

  @override
  String get payments_contactSupport => 'Contact Support';

  @override
  String get payments_contactCustomerSupportTitle => 'Contact Customer Support';

  @override
  String payments_supportDialogBody(String ticketNumber) {
    return 'Our customer support agents are ready to assist you. Reference ticket number: $ticketNumber';
  }

  @override
  String get payments_close => 'Close';

  @override
  String get trips_newCaptain => 'New captain';

  @override
  String trips_ratingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ratings',
      one: '1 rating',
    );
    return '$_temp0';
  }

  @override
  String get trips_verifiedCaptain => 'Verified captain';

  @override
  String get trips_factDeparts => 'Departs';

  @override
  String get trips_factSeat => 'Seat';

  @override
  String get trips_seatNotAssigned => 'Not assigned';

  @override
  String trips_completedAt(String date) {
    return 'Completed $date';
  }

  @override
  String get trips_boardingPassTitle => 'Boarding pass';

  @override
  String get trips_boardingOnBoard => 'On board';

  @override
  String get trips_boardingReady => 'Ready';

  @override
  String get trips_bookingRefLabel => 'Booking ref';

  @override
  String get trips_boardingOnBoardNote =>
      'Enjoy your ride — the captain has your seat on the manifest.';

  @override
  String get trips_boardingReadyNote =>
      'Show this reference to the captain when you board.';

  @override
  String get trips_detailsTitle => 'Trip details';

  @override
  String get trips_cancellationReasonTitle => 'Cancellation Reason';

  @override
  String get trips_completedRatedNote =>
      'You rated this trip. Tap to see the review you left.';

  @override
  String trips_completedRateInvite(String driverName) {
    return 'Help us improve by rating your trip with $driverName.';
  }

  @override
  String get trips_actionChat => 'Chat';

  @override
  String get trips_driverPhoneUnavailable =>
      'Driver phone number is not available.';

  @override
  String trips_callFailed(String phone) {
    return 'Could not start a call to $phone.';
  }

  @override
  String get trips_seatLegendYours => 'Your seat';

  @override
  String get trips_seatLegendAvailable => 'Available';

  @override
  String get trips_seatLegendTaken => 'Taken';

  @override
  String get trips_seatMapDriverLabel => 'Driver';

  @override
  String get trips_yourSeatsPlural => 'Your seats';

  @override
  String get trips_seatPending => 'Seat pending';

  @override
  String get trips_driverPending => 'Driver Pending';

  @override
  String get trips_vehiclePending => 'Vehicle Pending';

  @override
  String get trips_routePointUnknown => 'Unknown';

  @override
  String get trips_awaitingConfirmation => 'Awaiting confirmation';

  @override
  String trips_seatsAvailableOfTotal(int available, int total) {
    return '$available of $total';
  }

  @override
  String get trips_seatsFreeLabel => 'seats free';

  @override
  String get trips_viewFullSeatMap => 'View full seat map';

  @override
  String get trips_seatPendingAssignment =>
      'A seat will be assigned once your booking is confirmed.';

  @override
  String trips_vehicleCode(String code) {
    return 'Vehicle code: $code';
  }

  @override
  String get trips_trackVehicleButton => 'Track Vehicle';

  @override
  String get trips_cancellingInFlight => 'Cancelling…';

  @override
  String get trips_cancelTripButton => 'Cancel Trip';

  @override
  String get trips_captainSubtitleFinished => 'Who drove you';

  @override
  String get trips_captainSubtitleActive => 'Who is driving you';

  @override
  String get trips_vehicleSubtitle => 'The bus on this trip';

  @override
  String get trips_seatsSubtitle => 'Your seats on the cabin map';

  @override
  String get trips_paymentSubtitle => 'Status and fare breakdown';

  @override
  String get trips_paymentNotePaid => 'Your payment is confirmed.';

  @override
  String get trips_paymentNotePending => 'Waiting for your payment.';

  @override
  String get trips_paymentNoteUnderReview =>
      'Our team is reviewing your payment.';

  @override
  String get trips_paymentNoteRefunded => 'This fare was refunded to you.';

  @override
  String get trips_paymentNoteFailed => 'The payment did not go through.';

  @override
  String get trips_paymentNoteCancelled => 'This booking was cancelled.';

  @override
  String get trips_discountLabel => 'Discount';

  @override
  String get trips_seatMapTitle => 'Seat map';

  @override
  String trips_seatMapTitleWithVehicle(String vehicle) {
    return 'Seat map · $vehicle';
  }

  @override
  String trips_cancelSuccessMessage(String reference) {
    return 'Trip $reference was cancelled and your seat is available again.';
  }

  @override
  String get seatRelease_hubTitle => 'Seat Release Hub';

  @override
  String get seatRelease_formTitle => 'Release Reserved Seat';

  @override
  String get seatRelease_successTitle => 'Seat Released Successfully';

  @override
  String get seatRelease_detailsTitle => 'Release Record Details';

  @override
  String get seatRelease_compensationTitle => 'Compensation Tracking';

  @override
  String get seatRelease_historyTitle => 'Seat Release Logs';

  @override
  String get seatRelease_notificationsTitle => 'Alerts Notifications';

  @override
  String get seatRelease_achievementsTitle => 'Milestones & Achievements';

  @override
  String get seatRelease_portalTitle => 'Seat Release Portal';

  @override
  String get seatRelease_notifCompensationAddedTitle => 'Compensation Added';

  @override
  String get seatRelease_notifCompensationAddedBody =>
      'Your released seat on Jun 2 was rebooked. EGP 50 cashback credited to your wallet!';

  @override
  String get seatRelease_timeYesterday => 'Yesterday';

  @override
  String get seatRelease_notifRebookedTitle => 'Seat Rebooked Successfully';

  @override
  String get seatRelease_notifRebookedBody =>
      'A passenger has booked your released seat for the trip on Jun 2.';

  @override
  String seatRelease_timeDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get seatRelease_notifReleasedTitle => 'Seat Released Successfully';

  @override
  String seatRelease_notifReleasedBody(String seat, String date) {
    return 'You successfully released your seat (Seat $seat) for the $date trip.';
  }

  @override
  String get seatRelease_tripDateLabel => 'Trip Date';

  @override
  String get seatRelease_seatNumberLabel => 'Seat Number';

  @override
  String get seatRelease_actionUnavailable =>
      'Seat release isn\'t available yet';

  @override
  String get seatRelease_statusWaiting => 'Waiting';

  @override
  String get seatRelease_statusRebooked => 'Rebooked';

  @override
  String get seatRelease_statusRewarded => 'Rewarded';

  @override
  String get seatRelease_statusClosed => 'Closed';

  @override
  String get seatRelease_filterAll => 'All';

  @override
  String get seatRelease_timelineStepReleased => 'Seat Released';

  @override
  String get seatRelease_timelineStepWaiting => 'Waiting For Rebooking';

  @override
  String get seatRelease_timelineStepRebooked => 'Rebooked Successfully';

  @override
  String get seatRelease_timelineReleasedDesc =>
      'Your seat has been released for commute pools.';

  @override
  String get seatRelease_timelineWaitingDesc =>
      'Seat is currently listed. Waiting for other daily passenger bookings.';

  @override
  String get seatRelease_timelineRebookedDesc =>
      'Seat was successfully rebooked by another commuter.';

  @override
  String get seatRelease_timelineRewardedDesc =>
      'Compensation reward credited directly to your wallet account.';

  @override
  String get seatRelease_upcomingReservedSeatsTitle =>
      'Upcoming Reserved Seats';

  @override
  String get seatRelease_noUpcomingTripsMessage =>
      'No upcoming package trips\nAll upcoming seats are active, or no remaining days remain.';

  @override
  String get seatRelease_validityRangeLabel => 'VALIDITY RANGE';

  @override
  String get seatRelease_seatNoLabel => 'SEAT NO.';

  @override
  String get seatRelease_statRemainingDays => 'Remaining Days';

  @override
  String get seatRelease_statReleasedSeats => 'Released Seats';

  @override
  String get seatRelease_statRebookedSeats => 'Rebooked Seats';

  @override
  String get seatRelease_statEarnedReward => 'Earned Reward';

  @override
  String seatRelease_daysCount(int days) {
    return '$days Days';
  }

  @override
  String seatRelease_egpAmount(String amount) {
    return 'EGP $amount';
  }

  @override
  String get seatRelease_quickLinkReleaseLogs => 'Release Logs';

  @override
  String get seatRelease_quickLinkRewardsStats => 'Rewards & Stats';

  @override
  String get seatRelease_viewLogsButton => 'View Logs';

  @override
  String get seatRelease_releaseSeatButton => 'Release Seat';

  @override
  String get seatRelease_noPastRecordSnackbar =>
      'No past release record exists for this date.';

  @override
  String get seatRelease_reasonSectionTitle => 'Reason for Releasing Seat';

  @override
  String get seatRelease_optionalNotesTitle => 'Optional Notes';

  @override
  String get seatRelease_notesHint => 'E.g., Working from home on Thursday...';

  @override
  String get seatRelease_whyReleaseTitle => 'Why release your seat?';

  @override
  String get seatRelease_releasingTemporaryTitle => 'Releasing is Temporary';

  @override
  String get seatRelease_releasingTemporaryBody =>
      'You are releasing your reserved seat for this trip date only. Your package subscription remains active and future trip bookings return automatically.';

  @override
  String get seatRelease_thresholdTitle => '12-Hour Threshold Requirement';

  @override
  String get seatRelease_thresholdBody =>
      'Seat release is only available if submitted at least 12 hours before trip departure. Late requests will not be accepted.';

  @override
  String get seatRelease_reasonPersonalPlans => 'Personal plans';

  @override
  String get seatRelease_reasonWorkFromHome => 'Working from home';

  @override
  String get seatRelease_reasonVacation => 'Vacation';

  @override
  String get seatRelease_reasonAlternativeTransport => 'Alternative transport';

  @override
  String get seatRelease_reasonMedical => 'Medical reason';

  @override
  String get seatRelease_reasonOther => 'Other';

  @override
  String get seatRelease_benefitCommunityTitle => 'Help the Community';

  @override
  String get seatRelease_benefitCommunityBody =>
      'Released seats become available for other passengers needing daily rides.';

  @override
  String get seatRelease_benefitCompensationTitle => 'Earn Compensation';

  @override
  String get seatRelease_benefitCompensationBody =>
      'Receive wallet cashback or loyalty rewards if another commuter books your seat.';

  @override
  String get seatRelease_benefitOptimizeTitle => 'Optimize Route Utilization';

  @override
  String get seatRelease_benefitOptimizeBody =>
      'Helps BMT optimize fleet load and reduce carbon emissions.';

  @override
  String get seatRelease_successHeadline => 'Seat Released Successfully!';

  @override
  String seatRelease_referenceCodeLabel(String code) {
    return 'Reference Code: $code';
  }

  @override
  String get seatRelease_releasedDateLabel => 'Released Date';

  @override
  String get seatRelease_commuteSegmentLabel => 'Commute Segment';

  @override
  String get seatRelease_packageSourceLabel => 'Package Source';

  @override
  String get seatRelease_autoNotifyBody =>
      'We will automatically notify you and credit rewards to your wallet once your seat gets rebooked by other commuters.';

  @override
  String get seatRelease_viewReleaseDetailsButton => 'View Release Details';

  @override
  String get seatRelease_returnToDashboardButton => 'Return to Dashboard';

  @override
  String seatRelease_idLabel(String id) {
    return 'ID: $id';
  }

  @override
  String get seatRelease_releasedSeatLabel => 'Released Seat';

  @override
  String get seatRelease_reasonChosenLabel => 'Reason Chosen';

  @override
  String get seatRelease_submitDateLabel => 'Submit Date';

  @override
  String get seatRelease_notesLabel => 'Notes';

  @override
  String get seatRelease_statusTimelineTitle => 'Release Status Timeline';

  @override
  String get seatRelease_backToDashboardButton => 'Back to Dashboard';

  @override
  String seatRelease_referenceLabel(String code) {
    return 'Reference: $code';
  }

  @override
  String get seatRelease_compensationStatusLabel => 'Compensation status';

  @override
  String get seatRelease_compWaitingBody =>
      'Your seat is listed for daily commuters. If another passenger books this seat prior to departure, you will unlock your reward instantly.';

  @override
  String get seatRelease_compRebookedBody =>
      'Your seat was successfully purchased. We are currently processing your compensation points clearance.';

  @override
  String get seatRelease_compensationCreditedLabel => 'COMPENSATION CREDITED';

  @override
  String get seatRelease_creditedToWalletLabel => 'Credited to Account Wallet';

  @override
  String seatRelease_clearingDateLabel(String date) {
    return 'Clearing date: $date';
  }

  @override
  String get seatRelease_transactionClearedLabel =>
      'Transaction Cleared Successfully';

  @override
  String get seatRelease_historySearchHint =>
      'Search release logs by date, route...';

  @override
  String get seatRelease_noHistoryRecordsMessage =>
      'No release records found\nTry adjusting your filters or search query.';

  @override
  String get seatRelease_alertHistoryLogTitle => 'Alert History Log';

  @override
  String get seatRelease_clearAllButton => 'Clear All';

  @override
  String get seatRelease_noNotificationsMessage =>
      'No new notifications\nYou are completely caught up.';

  @override
  String get seatRelease_achievementsHeaderTitle => 'Seat Release Achievements';

  @override
  String get seatRelease_tileSeatsReleased => 'Seats Released';

  @override
  String get seatRelease_tileRebookedSuccessfully => 'Rebooked Successfully';

  @override
  String get seatRelease_tileRewardsEarned => 'Rewards Earned';

  @override
  String get seatRelease_unlockableBadgesTitle => 'Unlockable Badges';

  @override
  String get seatRelease_badgeEcoTitle => 'Eco Commuter Tier I';

  @override
  String get seatRelease_badgeEcoSubtitle =>
      'Release 5 seats to reduce shuttle overhead fuel.';

  @override
  String seatRelease_badgeProgressReleased(int count) {
    return '$count/5 Released';
  }

  @override
  String get seatRelease_badgeCommunityTitle => 'Community Helper Gold';

  @override
  String get seatRelease_badgeCommunitySubtitle =>
      'Help 3 other commuters find seats.';

  @override
  String seatRelease_badgeProgressRebooked(int count) {
    return '$count/3 Rebooked';
  }

  @override
  String get seatRelease_badgeRewardTitle => 'Reward Collector Level 2';

  @override
  String get seatRelease_badgeRewardSubtitle =>
      'Accumulate EGP 200 in released rewards.';

  @override
  String seatRelease_badgeProgressReward(String amount) {
    return 'EGP $amount/EGP 200';
  }

  @override
  String get seatRelease_packageStatusActive => 'Active';

  @override
  String get seatRelease_packageStatusNone => 'No subscription';

  @override
  String get seatRelease_packageTypeSubscription => 'Subscription package';

  @override
  String get booking_routeDetails => 'Route details';

  @override
  String booking_allStopsCount(int count) {
    return 'All Stops ($count)';
  }

  @override
  String get booking_departure => 'Departure';

  @override
  String get booking_routeSummary => 'Route Summary';

  @override
  String booking_seatsAvailableCount(int count) {
    return '$count seats available';
  }

  @override
  String get booking_selectSeat => 'Select Seat';

  @override
  String get booking_unableToLoadVehicleDetails =>
      'Unable to load vehicle details';

  @override
  String get booking_vehicleNotFound => 'Vehicle not found';

  @override
  String get payments_attachReceiptTitle => 'Attach Receipt';

  @override
  String payments_uploadReceiptError(String error) {
    return 'Unable to upload receipt: $error';
  }

  @override
  String get payments_transferInstructionsTitle => 'Transfer Instructions';

  @override
  String get payments_transferInstructionsBody =>
      'Transfer the exact booking amount to the address below and upload the transaction screenshot.';

  @override
  String get payments_amountToSendLabel => 'Amount to send:';

  @override
  String get payments_instapayIpaLabel => 'InstaPay IPA:';

  @override
  String get payments_notConfigured => 'Not configured';

  @override
  String get payments_accountHolderLabel => 'Account Holder:';

  @override
  String get payments_mobileWalletNoLabel => 'Mobile Wallet No:';

  @override
  String get payments_walletTypeLabel => 'Wallet Type:';

  @override
  String get payments_defaultWalletChannels =>
      'Vodafone / Orange / Etisalat / WE';

  @override
  String payments_copiedToClipboard(String value) {
    return '$value copied to clipboard';
  }

  @override
  String get payments_uploadReceiptScreenshot => 'Upload Receipt Screenshot';

  @override
  String get payments_tapToSelectFile => 'Tap to select a file (PNG, JPG)';

  @override
  String get payments_receiptAttachedTitle => 'Receipt Attached';

  @override
  String get payments_receiptAttachedBody =>
      'Submit payment to reserve your selected seat and send the receipt for verification.';

  @override
  String get payments_uploading => 'Uploading...';

  @override
  String get payments_submitPayment => 'Submit Payment';

  @override
  String get booking_chooseTripAndVehicle => 'Choose trip and vehicle';

  @override
  String get booking_availableTripsLabel => 'Available trips';

  @override
  String booking_tripOptionsWithVehicles(int count) {
    return '$count trip options with assigned vehicles';
  }

  @override
  String get booking_sortEarliest => 'Earliest';

  @override
  String get booking_sortLowestPrice => 'Lowest price';

  @override
  String get booking_sortMostSeats => 'Most seats';

  @override
  String get payments_closeCheckoutTooltip => 'Close checkout';

  @override
  String get payments_paymobCheckoutTitle => 'Paymob Checkout';

  @override
  String get payments_reloadTooltip => 'Reload';

  @override
  String get payments_unableToLoadCheckout => 'Unable to load checkout';

  @override
  String get payments_bookingTitle => 'Booking';

  @override
  String get payments_processingBookingTitle => 'Processing your booking...';

  @override
  String get payments_processingBookingSubtitle =>
      'This should only take a moment';

  @override
  String get payments_bookingConfirmedTitle => 'Booking Confirmed';

  @override
  String get payments_bookingConfirmedSubtitle =>
      'Your seat is reserved — confirmation below';

  @override
  String get payments_bookingReferenceLabel => 'Booking Reference';

  @override
  String get payments_bookingReferencePending => 'Reference pending';

  @override
  String get payments_departsLabel => 'Departs';

  @override
  String payments_vehicleNumberLabel(String vehicle) {
    return 'Vehicle $vehicle';
  }

  @override
  String get payments_notesLabel => 'Notes';

  @override
  String get payments_bookingNotesBody =>
      'Please arrive 10 minutes before departure. Cancellation allowed up to 1 hour before departure.';

  @override
  String get payments_trackVehicle => 'Track Vehicle';

  @override
  String get trips_notFoundTitle => 'Trip not found';

  @override
  String get trips_notFoundBody =>
      'This trip may have been removed or the link is no longer valid. Browse routes to plan your next ride.';

  @override
  String trips_starRatingSemantic(int star, String title) {
    return '$star of 5 for $title';
  }

  @override
  String get payments_viewFullTripStatus => 'View Full Trip & Payment Status';

  @override
  String get payments_rejectedHelpText =>
      'You can contact support for help or try booking another trip.';

  @override
  String get payments_pendingApprovalNotice =>
      'You will receive a notification once your payment has been approved.';

  @override
  String get payments_bookingStatusLabel => 'Booking Status';

  @override
  String get payments_reasonLabel => 'Reason';

  @override
  String get payments_estimatedReviewTimeLabel => 'Estimated Review Time';

  @override
  String get payments_estimatedReviewTimeValue => '5–15 Minutes';

  @override
  String get payments_paymentApprovedTitle => 'Payment Approved';

  @override
  String get payments_paymentApprovedSubtitle =>
      'Your payment was verified. Your seat is confirmed and ready to track.';

  @override
  String get payments_statusApproved => 'Approved';

  @override
  String get payments_paymentRejectedTitle => 'Payment Rejected';

  @override
  String get payments_paymentRejectedSubtitle =>
      'We couldn\'t verify this payment. Contact support or try booking again.';

  @override
  String get payments_statusRejected => 'Rejected';

  @override
  String get payments_paymentReceiptSubmittedTitle =>
      'Payment Receipt Submitted';

  @override
  String get payments_paymentReceiptSubmittedSubtitle =>
      'Your booking request has been received. Our finance team is reviewing your payment.';

  @override
  String get payments_statusPendingVerification => 'Pending Verification';

  @override
  String get booking_from => 'From';

  @override
  String get booking_to => 'To';

  @override
  String booking_seatsCountLabel(int count) {
    return '$count seats';
  }

  @override
  String booking_routeStopsCount(int count) {
    return '$count route stops';
  }

  @override
  String get booking_directTripNoStops =>
      'Direct trip with no intermediate stops';

  @override
  String booking_intermediateStopsCount(int count) {
    return '$count intermediate stops';
  }

  @override
  String booking_moreStopsCount(int count) {
    return '+ $count more stops';
  }

  @override
  String get loyalty_titlePortal => 'Loyalty Portal';

  @override
  String get loyalty_titleLedger => 'Points Ledger Logs';

  @override
  String get loyalty_titleCatalog => 'Redeem Points Catalog';

  @override
  String get loyalty_titleHub => 'Loyalty Hub';

  @override
  String get loyalty_refresh => 'Refresh';

  @override
  String get loyalty_confirmRedemptionTitle => 'Confirm Redemption';

  @override
  String get loyalty_confirmRedemptionBody =>
      'Are you sure you want to redeem this reward?';

  @override
  String loyalty_costPoints(int points) {
    return 'Cost: $points points';
  }

  @override
  String get loyalty_currentBalance => 'Current Balance:';

  @override
  String get loyalty_balanceAfterRedemption => 'Balance After Redemption:';

  @override
  String get loyalty_redeemNow => 'Redeem Now';

  @override
  String get loyalty_voucherUnlocked => 'Voucher Unlocked! 🎫';

  @override
  String get loyalty_couponGeneratedBody =>
      'Coupon code generated successfully. You can use it during payment checkout.';

  @override
  String get loyalty_copyAndClose => 'Copy & Close';

  @override
  String get loyalty_voucherCopiedSnack => 'Voucher code copied to clipboard!';

  @override
  String get loyalty_navRedeemTitle => 'Redeem Points';

  @override
  String get loyalty_navRedeemSubtitle => 'Browse Catalog';

  @override
  String get loyalty_navHistoryTitle => 'Points History';

  @override
  String get loyalty_navHistorySubtitle => 'Ledger Logs';

  @override
  String loyalty_activeTierPerks(String tier) {
    return 'Active $tier Perks';
  }

  @override
  String get loyalty_exploreMembership => 'Explore Membership Levels';

  @override
  String loyalty_tierMemberBadge(String tier) {
    return '$tier member';
  }

  @override
  String get loyalty_megaLoyaltyBadge => 'MEGA LOYALTY';

  @override
  String get loyalty_pointsBalanceLabel => 'COMMUTE POINTS BALANCE';

  @override
  String get loyalty_ptsUnit => 'pts';

  @override
  String get loyalty_nextGoalPlatinum => 'Next Goal: Platinum Tier';

  @override
  String loyalty_ptsToGo(int points) {
    return '$points pts to go';
  }

  @override
  String get loyalty_platinumFootnote =>
      '* Platinum tier rewards earn double points on all travels.';

  @override
  String get loyalty_currentTier => 'Current Tier';

  @override
  String loyalty_needsPoints(String points) {
    return 'Needs $points';
  }

  @override
  String get loyalty_transactionLedger => 'Points Transaction Ledger';

  @override
  String get loyalty_activeLogs => 'Active logs';

  @override
  String get loyalty_redeemableBalance => 'Redeemable points balance';

  @override
  String loyalty_tierLevelMember(String tier) {
    return '$tier Level Member';
  }

  @override
  String get loyalty_catalogRewards => 'Catalog Rewards';

  @override
  String get loyalty_tiersUnavailable =>
      'Membership levels aren\'t available right now.';

  @override
  String get loyalty_historyEmptyTitle => 'No points activity yet';

  @override
  String get loyalty_historyEmptyBody => 'Book a trip to start earning points.';

  @override
  String get loyalty_rewardsEmptyTitle => 'No rewards available';

  @override
  String get loyalty_rewardsEmptyBody =>
      'Check back soon for new ways to spend your points.';

  @override
  String get loyalty_transactionFallbackTitle => 'Points activity';

  @override
  String loyalty_redeemFailed(String reason) {
    return 'Redemption failed. $reason';
  }

  @override
  String get loyalty_categoryDiscount => 'Discount';

  @override
  String get loyalty_categoryFreeRide => 'FreeRide';

  @override
  String get loyalty_categoryCashback => 'Cashback';

  @override
  String get loyalty_categoryPackage => 'Package';

  @override
  String get loyalty_tierBronze => 'Bronze';

  @override
  String get loyalty_tierSilver => 'Silver';

  @override
  String get loyalty_tierGold => 'Gold';

  @override
  String get loyalty_tierPlatinum => 'Platinum';

  @override
  String get trips_cancelReasonTitle => 'Cancellation reason';

  @override
  String trips_cancelReasonTripRef(String reference) {
    return 'Trip $reference';
  }

  @override
  String get trips_reasonScheduleChange => 'Schedule change';

  @override
  String get trips_reasonAlternativeTransport => 'Found alternative transport';

  @override
  String get trips_reasonDriverDelay => 'Driver delay concern';

  @override
  String get trips_reasonPersonalEmergency => 'Personal emergency';

  @override
  String get trips_reasonDuplicateBooking => 'Duplicate booking';

  @override
  String get trips_cancelDialogTitle => 'Cancel this trip?';

  @override
  String get trips_cancelDialogBody =>
      'Your booking will be cancelled, your seat released back to the trip, and your payment will no longer be reviewed. This cannot be undone — you would have to book again.';

  @override
  String trips_cancelReasonPrefix(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get trips_keepTrip => 'Keep trip';

  @override
  String get trips_confirmCancellation => 'Confirm cancellation';

  @override
  String get booking_resetAllFilters => 'Reset all';

  @override
  String get booking_licensedCaptain => 'Licensed captain';

  @override
  String get booking_eta => 'ETA';

  @override
  String get booking_bookNow => 'Book Now';

  @override
  String booking_seatsLeftShort(int count) {
    return '$count left';
  }

  @override
  String get seatRelease_mockTripDateJun2 => 'Jun 2';

  @override
  String get packages_refreshTooltip => 'Refresh';

  @override
  String get packages_continueToPayment => 'Continue to Payment';

  @override
  String packages_daysCount(int days) {
    return '$days Days';
  }

  @override
  String get trips_reviewFormTitle => 'Rate your trip';

  @override
  String get trips_ratingOffice => 'Office rating';

  @override
  String get trips_ratingDriver => 'Driver rating';

  @override
  String get trips_ratingVehicle => 'Vehicle rating';

  @override
  String get trips_ratingRoute => 'Route rating';

  @override
  String get trips_reviewCommentHint => 'Share feedback (optional)';

  @override
  String get trips_reviewSubmitting => 'Submitting…';

  @override
  String get trips_submitReviewButton => 'Submit review';

  @override
  String get trips_reviewIncompleteHint =>
      'Give the driver, vehicle, and route a star rating to continue.';

  @override
  String get trips_reviewThankYouTitle => 'Thank you for your review';

  @override
  String trips_reviewThankYouBody(String reference) {
    return 'Your feedback on $reference went straight to our operations team. Only they can see it.';
  }

  @override
  String get trips_reviewYourFeedbackLabel => 'Your feedback';

  @override
  String get trips_reviewOpening => 'Opening your review…';

  @override
  String get trips_reviewOpenError => 'We could not open your review';

  @override
  String get trips_reviewErrorSignIn => 'Please sign in to review your trip.';

  @override
  String get trips_reviewErrorBookingMissing =>
      'This booking no longer exists.';

  @override
  String get trips_reviewErrorNotYourTrip =>
      'You can only review your own trips.';

  @override
  String get trips_reviewErrorCancelled =>
      'This booking was cancelled, so there is nothing to review.';

  @override
  String get trips_reviewErrorNotCompleted =>
      'You can only review a trip once it has been completed.';

  @override
  String get trips_reviewErrorInvalidRating =>
      'Please give the driver, vehicle, and route 1–5 stars.';

  @override
  String get trips_reviewErrorUnknown =>
      'Could not submit your review. Please try again.';

  @override
  String get booking_price => 'Price';

  @override
  String get booking_mapCoordinatesUnavailable => 'Map coordinates unavailable';

  @override
  String booking_saveDiscountPercent(int percent) {
    return 'Save $percent%';
  }

  @override
  String get booking_bestValue => 'BEST VALUE';

  @override
  String booking_ridesValidForDays(String rides, String days) {
    return '$rides · valid $days';
  }

  @override
  String booking_pricePerRide(String amount) {
    return 'EGP $amount per ride';
  }

  @override
  String get booking_yourSelectedTrip => 'Your selected trip';

  @override
  String get booking_startsWithYourTrip => 'Starts with your trip';

  @override
  String get booking_couldNotLoadFares => 'Could not load fares';

  @override
  String get booking_chooseTripTimeAndVehicle => 'Choose trip time and vehicle';

  @override
  String get booking_viewRouteDetails => 'View route details';

  @override
  String booking_tripsCountToday(int count) {
    return '$count trips today';
  }

  @override
  String get booking_noTripsToday => 'No trips today';

  @override
  String get referral_titleMain => 'Referrals & Rewards';

  @override
  String get referral_titleInvite => 'Invite Friends';

  @override
  String get referral_titleHistory => 'Referral History';

  @override
  String get referral_titleWallet => 'Rewards Wallet';

  @override
  String get referral_titleHub => 'Referral Hub';

  @override
  String get referral_codeCopiedSnack => 'Referral code copied to clipboard!';

  @override
  String get referral_refresh => 'Refresh';

  @override
  String get referral_redemptionSuccessTitle => 'Redemption Successful! 🎉';

  @override
  String get referral_redemptionSuccessBody =>
      'Rewards have been converted and transferred directly to your Main Wallet Balance!';

  @override
  String get referral_successfullyTransferred => 'Successfully Transferred';

  @override
  String get referral_awesome => 'Awesome';

  @override
  String get referral_scratchSubtitle =>
      'Scratch card to reveal your promotional reward code!';

  @override
  String get referral_claimReward => 'Claim Reward';

  @override
  String get referral_scratchToReveal => 'Scratch card to reveal';

  @override
  String get referral_scratchWithFinger => 'Scratch with finger!';

  @override
  String get referral_rewardsUnavailable => 'Rewards unavailable';

  @override
  String referral_referralsCount(int count) {
    return '$count referrals';
  }

  @override
  String get referral_milestoneFirst => 'First Referral Milestone';

  @override
  String get referral_milestoneReached => 'Milestone Reached!';

  @override
  String get referral_milestoneNext => 'Next Referral Milestone';

  @override
  String referral_milestoneDescFirst(int target) {
    return 'Invite $target friends to unlock your first referral bonus.';
  }

  @override
  String get referral_milestoneDescReached =>
      'Great work! You have reached the current milestone.';

  @override
  String referral_milestoneDescNext(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining more friends',
      one: '1 more friend',
    );
    return 'Invite $_temp0 to unlock your next reward.';
  }

  @override
  String referral_progressCount(int current, int target) {
    return 'Progress: $current / $target referrals';
  }

  @override
  String get referral_statTotalInvites => 'Total Invites';

  @override
  String get referral_statSuccessful => 'Successful';

  @override
  String get referral_statTotalEarned => 'Total Earned';

  @override
  String get referral_yourCodeLabel => 'Your Referral Code';

  @override
  String get referral_inviteFriendsNow => 'Invite Friends Now';

  @override
  String get referral_walletSubtitle => 'Scratch vouchers & redeem balances';

  @override
  String referral_claimableBadge(int amount) {
    return 'EGP $amount Claimable';
  }

  @override
  String get referral_logsHistoryTitle => 'Referral Logs & History';

  @override
  String get referral_logsHistorySubtitle =>
      'Track status of invites and code claims';

  @override
  String get referral_scanToJoin => 'Scan to Join BMT';

  @override
  String get referral_qrHint =>
      'Let friends scan this QR to automatically register with your code!';

  @override
  String get referral_close => 'Close';

  @override
  String get referral_howItWorks => 'How it works';

  @override
  String get referral_step1Title => 'Share your code';

  @override
  String get referral_step1Subtitle =>
      'Send your unique code to friends via any channel.';

  @override
  String get referral_step2Title => 'Friend registers';

  @override
  String get referral_step2Subtitle =>
      'They sign up and complete their first trip using your code.';

  @override
  String get referral_step3Title => 'You both earn';

  @override
  String get referral_step3Subtitle =>
      'You receive a referral reward credited to your wallet.';

  @override
  String get referral_directShareOptions => 'Direct Share Options';

  @override
  String get referral_shareLink => 'Share Link';

  @override
  String get referral_showQr => 'Show QR';

  @override
  String get referral_copyCode => 'Copy Code';

  @override
  String get referral_referralsLog => 'Referrals Log';

  @override
  String referral_totalReferralsCount(int count) {
    return '$count total referrals';
  }

  @override
  String referral_invitedOn(String date) {
    return 'Invited: $date';
  }

  @override
  String get referral_statusRegistered => 'Registered';

  @override
  String get referral_statusFirstOrderCompleted => 'First Order Completed';

  @override
  String get referral_statusRewardGranted => 'Reward Granted';

  @override
  String get referral_statusPendingRegistration => 'Pending Registration';

  @override
  String referral_egpTotal(int amount) {
    return 'EGP $amount';
  }

  @override
  String referral_egpEarned(int amount) {
    return '+ EGP $amount';
  }

  @override
  String get referral_egpZero => 'EGP 0';

  @override
  String get referral_claimVouchersTitle => 'Claim Reward Vouchers';

  @override
  String get referral_walletLabel => 'Referral Wallet';

  @override
  String referral_walletAvailable(int amount) {
    return 'EGP $amount available';
  }

  @override
  String get referral_noBalanceYet => 'No balance yet';

  @override
  String get referral_transferHint =>
      'You can transfer this balance to your main wallet.';

  @override
  String get referral_earnBalanceHint =>
      'Earn balance by inviting friends with your referral code.';

  @override
  String get referral_openWallet => 'Open my wallet';

  @override
  String get referral_walletCreditHint =>
      'Referral rewards are paid straight into your wallet at the office that granted them.';

  @override
  String get referral_redeemToWallet => 'Redeem to Wallet';

  @override
  String get referral_noBalanceToRedeem => 'No balance to redeem';

  @override
  String get referral_redeemFailed => 'Redemption failed. Please try again.';

  @override
  String referral_revealedCode(String code) {
    return 'Revealed Code: $code';
  }

  @override
  String get referral_lockedScratchToReveal => 'Locked - Scratch to reveal';

  @override
  String get referral_inviteCopiedSnack => 'Invite copied to clipboard';

  @override
  String get referral_shareYourInvite => 'Share your invite';

  @override
  String referral_shareSheetSubtitle(String code) {
    return 'Invite friends with code $code and earn rewards.';
  }

  @override
  String get referral_channelWhatsapp => 'WhatsApp';

  @override
  String get referral_channelFacebook => 'Facebook';

  @override
  String get referral_channelMessenger => 'Messenger';

  @override
  String get referral_channelInstagram => 'Instagram';

  @override
  String get referral_copyLink => 'Copy link';

  @override
  String get referral_more => 'More';

  @override
  String get booking_filters => 'Filters';

  @override
  String booking_filtersCount(int count) {
    return 'Filters ($count)';
  }

  @override
  String booking_filtersActiveSemantics(String label) {
    return '$label active';
  }

  @override
  String get booking_faresFrom => 'Fares from';

  @override
  String get booking_chooseThisRoute => 'Choose this route';

  @override
  String get booking_routeOverviewLabel => 'ROUTE OVERVIEW';

  @override
  String get booking_finalStop => 'Final stop';

  @override
  String get booking_findYourBestCommute => 'Find your best commute';

  @override
  String get booking_searchRoutesWhenAvailable =>
      'Search active routes when they become available.';

  @override
  String booking_routesMatchSearch(int visible, int total) {
    return '$visible of $total routes match your search';
  }

  @override
  String get booking_searchDepartureDestinationHint =>
      'Search departure, destination, or route name';

  @override
  String get booking_clearSearch => 'Clear search';

  @override
  String get booking_full => 'Full';

  @override
  String get booking_occupancy => 'Occupancy';

  @override
  String booking_percentFull(int percent) {
    return '$percent% full';
  }

  @override
  String booking_availableBookedSeats(int available, int booked) {
    return '$available available · $booked booked';
  }

  @override
  String get booking_selectTripAndVehicle => 'Select trip and vehicle';

  @override
  String booking_seatsCapacity(int count) {
    return '$count seats capacity';
  }

  @override
  String get booking_stepStops => 'Stops';

  @override
  String booking_stepXOfY(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get communication_chatHubTitle => 'Chat Hub';

  @override
  String get communication_refresh => 'Refresh';

  @override
  String get communication_searchHint => 'Search chats, contacts, messages...';

  @override
  String get communication_filterAll => 'All';

  @override
  String get communication_filterDrivers => 'Drivers';

  @override
  String get communication_filterSupport => 'Support';

  @override
  String get communication_filterGroups => 'Groups';

  @override
  String get communication_emptyTitle => 'No conversations found';

  @override
  String get communication_emptySubtitle =>
      'Filter or search in your active shuttle runs.';

  @override
  String get communication_categoryDriver => 'Driver';

  @override
  String get communication_categorySupport => 'Support';

  @override
  String get communication_categoryGroup => 'Group';

  @override
  String get communication_statusOpenFallback => 'Open';

  @override
  String get communication_messageInputHint => 'Type your message...';

  @override
  String get communication_justNow => 'Just now';

  @override
  String get booking_pickYourSeat => 'Pick your seat';

  @override
  String get booking_frontSeatsNote => 'Front seats are nearest to the driver.';

  @override
  String booking_freeCount(int count) {
    return '$count free';
  }

  @override
  String get booking_yourSelectedSeat => 'Your selected seat';

  @override
  String get booking_continueToPackages => 'Continue to packages';

  @override
  String get booking_additionalVehicleSeats => 'Additional vehicle seats';

  @override
  String get booking_couldNotLoadSeats => 'Could not load seats';

  @override
  String get communication_messagesUnavailable => 'Messages unavailable';

  @override
  String get communication_imagePreviewUnavailable =>
      'Preview not available yet';

  @override
  String get booking_whereGetOnOff => 'Where will you get on and off?';

  @override
  String get booking_choosePickupThenStop =>
      'Choose your pickup first, then a stop further along the route.';

  @override
  String booking_stopsCountLabel(int count) {
    return '$count stops';
  }

  @override
  String get booking_selectYourPickupStop => '1  Select your pickup stop';

  @override
  String get booking_selectYourDropoffStop =>
      '2  Now select your drop-off stop';

  @override
  String get booking_routeSegmentReady => 'Route segment ready';

  @override
  String get booking_routeBeginsHere => 'Route begins here';

  @override
  String get booking_finalDestination => 'Final destination';

  @override
  String get booking_pickupDropoffPoint => 'Pickup and drop-off point';

  @override
  String get booking_findAvailableTrips => 'Find available trips';

  @override
  String get booking_reviewYourBooking => 'Review your booking';

  @override
  String get booking_nothingChargedUntilPay =>
      'Nothing is charged until you pay on the next step.';

  @override
  String get booking_proceedToPayment => 'Proceed to payment';

  @override
  String get booking_seatHeldWhilePaying =>
      'Your seat is locked in the moment you confirm and pay.';

  @override
  String get booking_chooseYourDeparture => 'Choose your departure';

  @override
  String booking_pickupToDropoff(String pickup, String dropoff) {
    return '$pickup to $dropoff';
  }

  @override
  String get booking_chooseASeat => 'Choose a seat';

  @override
  String booking_departsAtTime(String time) {
    return 'Departs $time';
  }

  @override
  String booking_departsOnDayAtTime(String day, String time) {
    return 'Departs $day · $time';
  }

  @override
  String get booking_perRide => 'per ride';

  @override
  String get booking_noTripsAvailable => 'No trips available';

  @override
  String booking_noTripsFoundForRoute(String route) {
    return 'No trips found for $route today.';
  }

  @override
  String get offices_directoryTitle => 'Transport offices';

  @override
  String get offices_directoryEmpty =>
      'No offices are open for booking right now.';

  @override
  String get offices_searchHint => 'Search by company or city';

  @override
  String offices_noSearchResults(String query) {
    return 'No office matches \"$query\"';
  }

  @override
  String get offices_clearSearch => 'Clear search';

  @override
  String get offices_routesHeader => 'Routes this office runs';

  @override
  String get offices_noRoutes =>
      'This office has no bookable routes right now.';

  @override
  String get offices_departuresHeader => 'Departures on sale';

  @override
  String get offices_noDepartures =>
      'This office has no departures on sale right now.';

  @override
  String get offices_noRatingsYet => 'No ratings yet';

  @override
  String offices_ratingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get routes_officesCardTitle => 'Transport offices';

  @override
  String get routes_officesCardSubtitle =>
      'Browse operators, compare ratings, and see the routes each one runs.';

  @override
  String get routes_heroSubtitle => 'Search, compare, and book your commute';

  @override
  String get routes_searchDescription =>
      'Enter pickup, destination, date and time to see available trips.';

  @override
  String get routes_step1Title => 'Search';

  @override
  String get routes_step1Subtitle => 'Pickup, destination, date & time';

  @override
  String get routes_step2Title => 'Compare';

  @override
  String get routes_step2Subtitle => 'Routes and vehicles';

  @override
  String get routes_step3Title => 'Select seat';

  @override
  String get routes_step3Subtitle => 'Choose your place on board';

  @override
  String get routes_step4Title => 'Pay';

  @override
  String get routes_step4Subtitle => 'Secure checkout';

  @override
  String get routes_howItWorks => 'How it works';

  @override
  String get routes_browsePopularRoutes => 'Browse popular routes';

  @override
  String get routes_tagFastDiscovery => 'Fast discovery';

  @override
  String get routes_tagLiveAvailability => 'Live availability';

  @override
  String get routes_tagPremiumRoutes => 'Premium routes';

  @override
  String get routes_searchTripsButton => 'Search trips';

  @override
  String get booking_routeTypeDirect => 'Direct';

  @override
  String get booking_routeTypeMultiStop => 'Multi-stop';

  @override
  String get booking_chooseBestDeparture =>
      'Choose the departure that works best for you.';

  @override
  String get booking_noExactMatchCoversTrip =>
      'No exact match for your search. These routes cover most of your trip.';

  @override
  String get booking_noRouteMatchClosest =>
      'No route matches this exact trip yet. Here are the closest options we run.';

  @override
  String get booking_bestResultsForYou => 'Best results for you';

  @override
  String get booking_otherMatchingRoutes => 'Other matching routes';

  @override
  String get booking_noBookableTripsNow => 'No bookable trips right now';

  @override
  String get booking_noScheduledTripsYet => 'No scheduled trips yet';

  @override
  String get booking_routeHasPricingNoTrip =>
      'This route has pricing, but no upcoming trip is open for booking.';

  @override
  String get booking_tripsFromDashboardAppear =>
      'Trips created from the dashboard will appear here.';

  @override
  String get booking_noTripsMatchFilters => 'No trips match your filters';

  @override
  String get booking_tryWideningFilterRange =>
      'Try widening the price, seats, or time-of-day range.';

  @override
  String get booking_continueWithThisRoute => 'Continue with this route';

  @override
  String get booking_dragToExpandDetails => 'Drag to expand route details';

  @override
  String get booking_isThisRouteSuitable => 'Is this route suitable?';

  @override
  String get booking_closestRoutesForSearch => 'Closest routes for your search';

  @override
  String get booking_editStops => 'Edit stops';

  @override
  String get booking_noBookableRouteFound => 'No bookable route found';

  @override
  String get booking_tryDifferentDepartureDest =>
      'Try a different departure, destination, or travel time.';

  @override
  String get booking_distance => 'Distance';

  @override
  String get booking_startingPrice => 'Starting price';

  @override
  String get booking_priceRange => 'Price range';

  @override
  String get booking_stopsNotPublishedYet => 'Stops are not published yet';

  @override
  String get booking_routeStationsWillAppear =>
      'Route stations will appear here once available.';

  @override
  String get booking_routeTimeline => 'Route timeline';

  @override
  String get booking_whereGetOnOffShort => 'Where you can get on and off';

  @override
  String get booking_oneStop => '1 stop';

  @override
  String get booking_stopCapabilityBoardAlight => 'Pickup & drop-off';

  @override
  String get booking_stopCapabilityBoardOnly => 'Pickup only';

  @override
  String get booking_stopCapabilityAlightOnly => 'Drop-off only';

  @override
  String get booking_stopCapabilityPassThrough => 'Pass-through';

  @override
  String get booking_stopStart => 'Start';

  @override
  String get booking_stopEnd => 'End';

  @override
  String get booking_filterTrips => 'Filter trips';

  @override
  String get booking_filterVehicleType => 'Vehicle type';

  @override
  String get booking_filterTimeOfDay => 'Time of day';

  @override
  String get booking_filterAny => 'Any';

  @override
  String get booking_filterSortBy => 'Sort by';

  @override
  String get booking_dayPartMorning => 'Morning';

  @override
  String get booking_dayPartAfternoon => 'Afternoon';

  @override
  String get booking_dayPartEvening => 'Evening';

  @override
  String get booking_tripSortEarliestDeparture => 'Earliest departure';

  @override
  String get booking_needAChange => 'Need a change?';

  @override
  String get booking_fare => 'Fare';

  @override
  String get booking_fareBreakdown => 'Fare breakdown';

  @override
  String booking_ridesStartsOn(String rides, String date) {
    return '$rides · starts $date';
  }

  @override
  String get booking_worksOutTo => 'Works out to';

  @override
  String get booking_youSave => 'You save';

  @override
  String booking_vsSingleTickets(int count) {
    return 'vs. $count single tickets';
  }

  @override
  String get booking_totalDue => 'Total due';

  @override
  String get booking_yourTicket => 'Your ticket';

  @override
  String get booking_ridesLabel => 'Rides';

  @override
  String get booking_oneRide => '1 ride';

  @override
  String get booking_receiptTooLarge => 'Receipts must be 8 MB or smaller.';

  @override
  String get booking_receiptUnreadable =>
      'That file could not be read. Try another one.';

  @override
  String get booking_someDetailsAreMissing =>
      'Some booking details are missing.';

  @override
  String get booking_choosePaymentMethodToContinue =>
      'Choose a payment method to continue.';

  @override
  String get booking_receiptStillUploading =>
      'Your receipt is still uploading.';

  @override
  String get booking_attachReceiptToContinue =>
      'Attach your transfer receipt to continue.';

  @override
  String get booking_submitReceipt => 'Submit receipt';

  @override
  String get booking_couldNotLoadPaymentMethods =>
      'We could not load the ways to pay. Your seat is still yours — try again.';

  @override
  String get booking_proofOfTransfer => 'Proof of transfer';

  @override
  String get booking_receiptAttachedNote =>
      'Attached. Our team will check it against your transfer.';

  @override
  String get booking_receiptHintUpTo8mb =>
      'A screenshot or PDF of the transfer — up to 8 MB.';

  @override
  String get booking_uploadingEllipsis => 'Uploading…';

  @override
  String get booking_replaceReceipt => 'Replace receipt';

  @override
  String get booking_attachReceipt => 'Attach receipt';

  @override
  String booking_sendMethodTo(String method) {
    return 'Send $method to';
  }

  @override
  String get booking_contactSupportForTransfer =>
      'Contact support for the transfer details.';

  @override
  String get booking_copyAccount => 'Copy account';

  @override
  String get booking_accountNumberCopied => 'Account number copied.';

  @override
  String get booking_transferReferenceOptional =>
      'Transfer reference (optional)';

  @override
  String get booking_paidFromPhoneOptional =>
      'Phone number you paid from (optional)';

  @override
  String booking_distanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String booking_distanceKm(String km) {
    return '$km km';
  }

  @override
  String booking_ridersCount(int count) {
    return '$count riders';
  }

  @override
  String get booking_tracingRoad => 'Tracing road…';

  @override
  String get booking_sortShortestDuration => 'Shortest duration';

  @override
  String get booking_sortMostTrips => 'Most trips';

  @override
  String get booking_filterRoutes => 'Filter routes';

  @override
  String get booking_seatsAvailableShort => 'Seats available';

  @override
  String get booking_checkLater => 'Check later';

  @override
  String get booking_noActiveRoutesYet => 'No active routes yet';

  @override
  String get booking_routesFromDashboardAppear =>
      'Routes published from the dashboard will appear here when they are ready for booking.';

  @override
  String get booking_refreshRoutes => 'Refresh routes';

  @override
  String get booking_noRoutesMatchSearch => 'No routes match your search';

  @override
  String get booking_tryDifferentSearchTerm =>
      'Try a different search term or adjust your filters.';

  @override
  String get booking_resetFilters => 'Reset filters';

  @override
  String booking_pricesAreForRoute(String pickup, String dropoff) {
    return 'Prices are for $pickup → $dropoff.';
  }

  @override
  String get booking_yourPickupFallback => 'your pickup';

  @override
  String get booking_yourStopFallback => 'your stop';

  @override
  String booking_optionsCount(int count) {
    return '$count options';
  }

  @override
  String get booking_chooseYourFare => 'Choose your fare';

  @override
  String get booking_reviewBooking => 'Review booking';

  @override
  String get seatSelection_defaultVehicleName => 'Standard Coach';

  @override
  String get seatSelection_defaultRoute => 'Route not selected';

  @override
  String communication_hoursAgo(int hours) {
    return '$hours hr ago';
  }

  @override
  String referral_inviteMessage(String code, String link) {
    return 'Join me on EasyWay and book your daily commute! Use my referral code $code to get a welcome reward.\n$link';
  }

  @override
  String get mySubscription_title => 'My Subscription';

  @override
  String get mySubscription_statusActive => 'Active';

  @override
  String get mySubscription_statusExpired => 'Expired';

  @override
  String get mySubscription_statusPending => 'Pending';

  @override
  String get mySubscription_started => 'Started';

  @override
  String get mySubscription_expires => 'Expires';

  @override
  String mySubscription_tripsUsedOfTotal(int used, int total) {
    return '$used of $total trips used';
  }

  @override
  String mySubscription_tripsRemaining(int count) {
    return '$count trips remaining';
  }

  @override
  String mySubscription_daysUsedOfTotal(int used, int total) {
    return '$used of $total days used';
  }

  @override
  String get mySubscription_statDaysLeft => 'Days left';

  @override
  String get mySubscription_statRidesLeft => 'Rides left';

  @override
  String get mySubscription_unlimitedTrips => 'Unlimited trips';

  @override
  String get mySubscription_emptyTitle => 'No active subscription';

  @override
  String get mySubscription_emptyBody =>
      'Packages are offered while you book a trip, priced for the route you pick.';

  @override
  String get mySubscription_findTrip => 'Find a trip';

  @override
  String get trips_attentionAwaitingReviewTitle =>
      'Waiting for the office to check your payment';

  @override
  String trips_attentionAwaitingReviewBody(String office) {
    return 'Your seat is held while $office reviews the receipt. We\'ll notify you as soon as it\'s approved.';
  }

  @override
  String get trips_attentionAwaitingReviewBodyNoOffice =>
      'Your seat is held while the office reviews the receipt. We\'ll notify you as soon as it\'s approved.';

  @override
  String get trips_attentionPaymentIncompleteTitle => 'Payment not completed';

  @override
  String get trips_attentionPaymentIncompleteBody =>
      'Your seat is only held until payment is settled. Finish paying or cancel to free it.';

  @override
  String get trips_attentionPaymentRejectedTitle => 'Payment was not accepted';

  @override
  String get trips_attentionPaymentRejectedBody =>
      'The office could not verify this payment. Contact support or book again.';

  @override
  String get trips_attentionRefundDueTitle =>
      'This trip was cancelled after you paid';

  @override
  String get trips_attentionRefundDueBody =>
      'You are owed a refund for this booking. Open support to follow it up.';

  @override
  String get trips_attentionNeedsSupportTitle => 'This booking needs checking';

  @override
  String trips_attentionNeedsSupportBody(String reference) {
    return 'Its booking and payment records disagree, so we won\'t guess. Please contact support with reference $reference.';
  }

  @override
  String get trips_attentionOpenSupport => 'Contact support';

  @override
  String get trips_seatHeldNotYours => 'Seat held — not confirmed yet';

  @override
  String get trips_bookingStateReserved => 'Awaiting approval';

  @override
  String get trips_bookingStateConfirmed => 'Confirmed';

  @override
  String get trips_bookingStateCompleted => 'Travelled';

  @override
  String get trips_bookingStateCancelled => 'Cancelled';

  @override
  String get offices_nothingListedTitle =>
      'This office has nothing listed right now';

  @override
  String get offices_nothingListedBody =>
      'No departures and no routes are published yet. Try another office, or search every route on the platform.';

  @override
  String get offices_browseOtherOffices => 'Browse other offices';

  @override
  String get offices_searchAllRoutes => 'Search all routes';

  @override
  String get offices_new => 'New';

  @override
  String get offices_statDepartures => 'Departures';

  @override
  String get offices_statRoutes => 'Routes';

  @override
  String get offices_statPackages => 'Packages';

  @override
  String get packages_priceAtBooking => 'Price shown when you pick a trip';

  @override
  String get packages_priceDependsTitle => 'Priced on the route you pick';

  @override
  String get packages_priceDependsBody =>
      'Every route has its own fare, so this package is priced once you choose a trip.';

  @override
  String get packages_howItWorks => 'How it works';

  @override
  String get packages_step1Title => 'Pick your route';

  @override
  String get packages_step1Body =>
      'Choose the trip you commute on — the package binds to that route.';

  @override
  String get packages_step2Title => 'See your price';

  @override
  String get packages_step2Body =>
      'The package is priced for that exact route, then you pay once.';

  @override
  String get packages_step3Title => 'Ride your seats';

  @override
  String get packages_step3Body =>
      'Book any departure on the route until your rides or days run out.';

  @override
  String get offices_directoryLead =>
      'Every operator selling seats on EWT, best rated first.';

  @override
  String offices_countLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operators',
      one: '1 operator',
    );
    return '$_temp0';
  }

  @override
  String offices_matchesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String offices_moreAreasCount(int count) {
    return '+$count';
  }

  @override
  String get offices_openProfile => 'Departures & routes';

  @override
  String get offices_serves => 'Serves';

  @override
  String get offices_statRating => 'Rating';

  @override
  String get offices_unrated => 'Unrated';

  @override
  String get booking_routePackagesTitle => 'Commute packages';

  @override
  String get booking_routePackagesSubtitle =>
      'Ride this route often? A plan costs less per seat.';

  @override
  String booking_routePackagesBy(String office) {
    return 'Sold by $office';
  }

  @override
  String get booking_routePackageFrom => 'From';

  @override
  String get booking_routePackageChoose => 'Book with this plan';

  @override
  String get booking_routePackagesNote =>
      'The exact price is confirmed once you pick your stops and departure.';

  @override
  String get wallet_title => 'My wallet';

  @override
  String get wallet_subtitle => 'Your balance at each office and its history';

  @override
  String get wallet_totalLabel => 'Total balance';

  @override
  String get wallet_totalOneOffice =>
      'Usable only at the office that granted it.';

  @override
  String wallet_totalManyOffices(int count) {
    return 'Split across $count offices — each balance is usable only at the office holding it.';
  }

  @override
  String get wallet_emptyTitle => 'No balance in your wallet';

  @override
  String get wallet_emptyBody =>
      'Anything an office refunds you, or grants you as a reward, appears here.';

  @override
  String get wallet_frozenNotice =>
      'This office has paused your balance. Contact them to find out why.';

  @override
  String wallet_entryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String wallet_entriesTruncated(int count) {
    return 'Showing the $count most recent entries only.';
  }

  @override
  String wallet_balanceAfter(String amount) {
    return 'Balance $amount';
  }

  @override
  String get wallet_kindRefund => 'Refund';

  @override
  String get wallet_kindCashback => 'Cashback';

  @override
  String get wallet_kindManualCredit => 'Credit added';

  @override
  String get wallet_kindManualDebit => 'Deduction';

  @override
  String get wallet_kindWalletSpend => 'Paid from wallet';

  @override
  String get wallet_kindWalletTopup => 'Top-up';

  @override
  String get wallet_kindReversal => 'Correction';

  @override
  String get auth_comingSoon => 'Soon';

  @override
  String get auth_continueWithGoogle => 'Continue with Google';

  @override
  String get auth_continueWithApple => 'Continue with Apple';

  @override
  String get auth_continueWithPhone => 'Continue with phone number';

  @override
  String get auth_phoneShort => 'Phone';

  @override
  String get auth_alternativeMethodsPendingNote =>
      'These sign-in methods are being set up. Use your email for now.';

  @override
  String get auth_methodUnavailable =>
      'This sign-in method isn\'t available yet. Use your email and password.';

  @override
  String get auth_phoneLoginTitle => 'Phone sign-in';

  @override
  String get auth_phoneLoginSubtitle =>
      'Enter your phone number and we\'ll send you a verification code.';

  @override
  String get auth_phoneOtpHelper =>
      'We\'ll text a verification code to this number.';

  @override
  String get auth_sendOtpCode => 'Send verification code';

  @override
  String get auth_phoneOtpSecurityNote =>
      'Standard SMS rates from your carrier may apply.';

  @override
  String get auth_otpTitle => 'Enter verification code';

  @override
  String auth_otpIntro(int count) {
    return 'We sent a $count-digit code to';
  }

  @override
  String get auth_verifyCode => 'Verify code';

  @override
  String auth_resendCodeIn(String timer) {
    return 'You can resend in $timer';
  }

  @override
  String get auth_changePhoneNumber => 'Change phone number';

  @override
  String get auth_otpInvalidCode =>
      'That code isn\'t right. Check the digits and try again.';

  @override
  String get auth_otpExpiredCode => 'That code has expired. Request a new one.';

  @override
  String get auth_otpRateLimited =>
      'Too many attempts. Wait a moment before requesting a new code.';
}
