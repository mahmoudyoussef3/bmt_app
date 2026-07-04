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
  String get packages_configureTravel => 'Configure Travel';

  @override
  String get packages_reviewSummary => 'Review Summary';

  @override
  String get packages_subscribed => 'Subscribed!';

  @override
  String get packages_subscribePlan => 'Subscribe Plan';

  @override
  String get packages_all => 'All';

  @override
  String get packages_weekly => 'Weekly';

  @override
  String get packages_monthly => 'Monthly';

  @override
  String get packages_quarterly => 'Quarterly';

  @override
  String packages_savePercent(int percent) {
    return 'Save $percent%';
  }

  @override
  String get packages_duration => 'Duration';

  @override
  String get packages_totalTrips => 'Total Trips';

  @override
  String packages_ridesCount(int count) {
    return '$count Rides';
  }

  @override
  String get packages_totalSavings => 'Total Savings';

  @override
  String packages_egpAmount(String amount) {
    return 'EGP $amount';
  }

  @override
  String packages_originalPrice(String price) {
    return 'Original: EGP $price';
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
  String get packages_vipBoarding => 'Priority VIP Boarding';

  @override
  String get packages_vipBoardingDesc =>
      'First access onboarding and customer concierge helpline.';

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
      '1. Packages cannot be refunded once activated.';

  @override
  String get packages_termsText2 =>
      '2. Seats must be confirmed at least 2 hours before trip.';

  @override
  String packages_termsText3(int count) {
    return '3. Package holds up to $count reservations for the selected route.';
  }

  @override
  String get packages_chooseRouteConfig => 'Choose Route & Configure';

  @override
  String get packages_basePrice => 'Base Price';

  @override
  String get packages_packageDiscount => 'Package Discount';

  @override
  String packages_percentOff(int percent) {
    return '$percent% Off';
  }

  @override
  String get packages_subscriptionCost => 'Subscription Cost';

  @override
  String get packages_selectTargetRoute => 'Select Target Route';

  @override
  String get packages_pickupPoint => 'Pickup Point';

  @override
  String get packages_destination => 'Destination';

  @override
  String get packages_selectVehicleCategory => 'Select Vehicle Category';

  @override
  String get packages_reviewActivation => 'Review & Activation';

  @override
  String get packages_selectedPackage => 'Selected Package';

  @override
  String get packages_route => 'Route';

  @override
  String get packages_vehicle => 'Vehicle';

  @override
  String get packages_billingDetails => 'Billing Details';

  @override
  String get packages_paymentMethod => 'Payment Method';

  @override
  String get packages_walletBalance => 'Wallet Balance';

  @override
  String packages_currentBalance(String balance) {
    return 'Current Balance: EGP $balance';
  }

  @override
  String get packages_sufficient => 'Sufficient';

  @override
  String get packages_payActivate => 'Pay & Activate';

  @override
  String get packages_processing => 'Processing';

  @override
  String get packages_subscriptionActive => 'Subscription Active!';

  @override
  String packages_subId(String id) {
    return 'Subscription ID: $id';
  }

  @override
  String get packages_successDesc =>
      'Your commute package is now active. You can start booking rides immediately from your dashboard.';

  @override
  String get packages_returnHome => 'Return to Home';

  @override
  String get packages_bookFirstRide => 'Book First Ride';

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
  String get dashboard_liveTrips => 'Live Trips';

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
}
