import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get common_view;

  /// No description provided for @common_dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get common_dismiss;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get common_error;

  /// No description provided for @home_goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String home_goodMorning(String name);

  /// No description provided for @home_readyForCommute.
  ///
  /// In en, this message translates to:
  /// **'Ready for your commute today?'**
  String get home_readyForCommute;

  /// No description provided for @home_tripStarted.
  ///
  /// In en, this message translates to:
  /// **'Your trip has started'**
  String get home_tripStarted;

  /// No description provided for @home_upcomingTrip.
  ///
  /// In en, this message translates to:
  /// **'Your upcoming trip'**
  String get home_upcomingTrip;

  /// No description provided for @home_trackBus.
  ///
  /// In en, this message translates to:
  /// **'Track the bus and current stop'**
  String get home_trackBus;

  /// No description provided for @home_reviewTrip.
  ///
  /// In en, this message translates to:
  /// **'Review trip details before departure'**
  String get home_reviewTrip;

  /// No description provided for @home_tripRoute.
  ///
  /// In en, this message translates to:
  /// **'Trip Route'**
  String get home_tripRoute;

  /// No description provided for @home_liveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live tracking'**
  String get home_liveTracking;

  /// No description provided for @home_stationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stations'**
  String home_stationsCount(int count);

  /// No description provided for @home_moreStations.
  ///
  /// In en, this message translates to:
  /// **'There are {count} more stations in trip details'**
  String home_moreStations(int count);

  /// No description provided for @home_pointPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get home_pointPassed;

  /// No description provided for @home_pointCurrent.
  ///
  /// In en, this message translates to:
  /// **'Bus is here'**
  String get home_pointCurrent;

  /// No description provided for @home_pointStart.
  ///
  /// In en, this message translates to:
  /// **'Start Point'**
  String get home_pointStart;

  /// No description provided for @home_pointEnd.
  ///
  /// In en, this message translates to:
  /// **'End Point'**
  String get home_pointEnd;

  /// No description provided for @home_pointStation.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get home_pointStation;

  /// No description provided for @home_trackTrip.
  ///
  /// In en, this message translates to:
  /// **'Track Trip'**
  String get home_trackTrip;

  /// No description provided for @home_tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get home_tripDetails;

  /// No description provided for @home_whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get home_whereTo;

  /// No description provided for @home_searchDestination.
  ///
  /// In en, this message translates to:
  /// **'Search destination...'**
  String get home_searchDestination;

  /// No description provided for @home_quickDestinations.
  ///
  /// In en, this message translates to:
  /// **'Quick destinations'**
  String get home_quickDestinations;

  /// No description provided for @home_packagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get home_packagesTitle;

  /// No description provided for @home_packagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Built for daily commuters'**
  String get home_packagesSubtitle;

  /// No description provided for @home_seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get home_seeAll;

  /// No description provided for @home_popularRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular routes'**
  String get home_popularRoutesTitle;

  /// No description provided for @home_popularRoutesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frequent commutes from your area'**
  String get home_popularRoutesSubtitle;

  /// No description provided for @home_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get home_viewAll;

  /// No description provided for @home_contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Need help? Contact support'**
  String get home_contactSupport;

  /// No description provided for @auth_welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to EasyWay'**
  String get auth_welcomeTitle;

  /// No description provided for @auth_welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your premium daily commute and transportation manager.'**
  String get auth_welcomeSubtitle;

  /// No description provided for @auth_login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get auth_login;

  /// No description provided for @auth_createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an Account'**
  String get auth_createAccount;

  /// No description provided for @auth_termsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get auth_termsPrefix;

  /// No description provided for @auth_termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get auth_termsOfService;

  /// No description provided for @auth_termsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get auth_termsAnd;

  /// No description provided for @auth_privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get auth_privacyPolicy;

  /// No description provided for @auth_signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed.'**
  String get auth_signInFailed;

  /// No description provided for @auth_rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get auth_rememberMe;

  /// No description provided for @auth_welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get auth_welcomeBack;

  /// No description provided for @auth_signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to book your next trip'**
  String get auth_signInSubtitle;

  /// No description provided for @auth_email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get auth_email;

  /// No description provided for @auth_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get auth_required;

  /// No description provided for @auth_invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get auth_invalidEmail;

  /// No description provided for @auth_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_password;

  /// No description provided for @auth_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get auth_forgotPassword;

  /// No description provided for @auth_signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get auth_signIn;

  /// No description provided for @auth_noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get auth_noAccount;

  /// No description provided for @auth_signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get auth_signUp;

  /// No description provided for @auth_registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed.'**
  String get auth_registrationFailed;

  /// No description provided for @auth_createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get auth_createAccountTitle;

  /// No description provided for @auth_signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join EasyWay to book and track your trips'**
  String get auth_signUpSubtitle;

  /// No description provided for @auth_fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get auth_fullName;

  /// No description provided for @auth_invalidFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get auth_invalidFullName;

  /// No description provided for @auth_phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get auth_phoneNumber;

  /// No description provided for @auth_invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get auth_invalidPhone;

  /// No description provided for @auth_invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get auth_invalidPassword;

  /// No description provided for @auth_forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get auth_forgotPasswordTitle;

  /// No description provided for @auth_forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No worries. Enter your email and we’ll send you a secure link to reset your password.'**
  String get auth_forgotPasswordSubtitle;

  /// No description provided for @auth_sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get auth_sendResetLink;

  /// No description provided for @auth_backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get auth_backToLogin;

  /// No description provided for @auth_checkEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get auth_checkEmailTitle;

  /// No description provided for @auth_checkEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'We sent a secure reset link to {email}. Open it to create a new password.'**
  String auth_checkEmailMessage(String email);

  /// No description provided for @auth_resendLink.
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get auth_resendLink;

  /// No description provided for @auth_resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend link in {seconds}s'**
  String auth_resendIn(int seconds);

  /// No description provided for @auth_rateLimited.
  ///
  /// In en, this message translates to:
  /// **'Please wait before requesting another reset link.'**
  String get auth_rateLimited;

  /// No description provided for @auth_unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again later.'**
  String get auth_unknownError;

  /// No description provided for @auth_alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get auth_alreadyHaveAccount;

  /// No description provided for @booking_title.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get booking_title;

  /// No description provided for @booking_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to book your commute'**
  String get booking_subtitle;

  /// No description provided for @booking_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get booking_today;

  /// No description provided for @booking_month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get booking_month;

  /// No description provided for @booking_dailyBooking.
  ///
  /// In en, this message translates to:
  /// **'Daily Booking'**
  String get booking_dailyBooking;

  /// No description provided for @booking_dailyBookingDesc.
  ///
  /// In en, this message translates to:
  /// **'Book a trip step by step for today'**
  String get booking_dailyBookingDesc;

  /// No description provided for @booking_monthlySubscription.
  ///
  /// In en, this message translates to:
  /// **'Monthly Subscription'**
  String get booking_monthlySubscription;

  /// No description provided for @booking_monthlySubscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'Reserve your permanent route and seat'**
  String get booking_monthlySubscriptionDesc;

  /// No description provided for @booking_summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get booking_summary;

  /// No description provided for @booking_activeTrips.
  ///
  /// In en, this message translates to:
  /// **'Active trips'**
  String get booking_activeTrips;

  /// No description provided for @booking_upcomingBookings.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bookings'**
  String get booking_upcomingBookings;

  /// No description provided for @booking_reservedSeats.
  ///
  /// In en, this message translates to:
  /// **'Reserved seats'**
  String get booking_reservedSeats;

  /// No description provided for @booking_selectPickupDestination.
  ///
  /// In en, this message translates to:
  /// **'Select pickup and destination to continue'**
  String get booking_selectPickupDestination;

  /// No description provided for @booking_searchTrip.
  ///
  /// In en, this message translates to:
  /// **'Search Trip'**
  String get booking_searchTrip;

  /// No description provided for @booking_pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get booking_pickupLocation;

  /// No description provided for @booking_destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get booking_destination;

  /// No description provided for @booking_selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get booking_selectDate;

  /// No description provided for @booking_selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get booking_selectTime;

  /// No description provided for @booking_otherWaysToSearch.
  ///
  /// In en, this message translates to:
  /// **'Other ways to search'**
  String get booking_otherWaysToSearch;

  /// No description provided for @booking_browseOrPickMap.
  ///
  /// In en, this message translates to:
  /// **'Browse or pick on map'**
  String get booking_browseOrPickMap;

  /// No description provided for @booking_popularRoutes.
  ///
  /// In en, this message translates to:
  /// **'Popular Routes'**
  String get booking_popularRoutes;

  /// No description provided for @booking_popularRoutesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Most used commutes in your network'**
  String get booking_popularRoutesSubtitle;

  /// No description provided for @booking_selectOnMap.
  ///
  /// In en, this message translates to:
  /// **'Route Map'**
  String get booking_selectOnMap;

  /// No description provided for @booking_selectOnMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Zoom in or out to view trip routes'**
  String get booking_selectOnMapSubtitle;

  /// No description provided for @booking_selectPickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Select Pickup Point'**
  String get booking_selectPickupPoint;

  /// No description provided for @booking_selectDestination.
  ///
  /// In en, this message translates to:
  /// **'Select Destination'**
  String get booking_selectDestination;

  /// No description provided for @booking_availableVehicles.
  ///
  /// In en, this message translates to:
  /// **'Available Vehicles'**
  String get booking_availableVehicles;

  /// No description provided for @booking_pickBestShuttle.
  ///
  /// In en, this message translates to:
  /// **'Pick the best shuttle for your trip'**
  String get booking_pickBestShuttle;

  /// No description provided for @booking_bookYourRide.
  ///
  /// In en, this message translates to:
  /// **'Book Your Ride'**
  String get booking_bookYourRide;

  /// No description provided for @booking_stepOf4.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 4'**
  String booking_stepOf4(int step);

  /// No description provided for @booking_selectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle'**
  String get booking_selectVehicle;

  /// No description provided for @booking_availableOptions.
  ///
  /// In en, this message translates to:
  /// **'{count} options available now'**
  String booking_availableOptions(int count);

  /// No description provided for @booking_sortRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get booking_sortRecommended;

  /// No description provided for @booking_sortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price Low'**
  String get booking_sortPriceLow;

  /// No description provided for @booking_sortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get booking_sortRating;

  /// No description provided for @booking_searchingBestOptions.
  ///
  /// In en, this message translates to:
  /// **'Searching for best options...'**
  String get booking_searchingBestOptions;

  /// No description provided for @booking_errorLoadingVehicles.
  ///
  /// In en, this message translates to:
  /// **'Could not load vehicles'**
  String get booking_errorLoadingVehicles;

  /// No description provided for @common_tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get common_tryAgain;

  /// No description provided for @booking_noVehiclesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No vehicles available'**
  String get booking_noVehiclesAvailable;

  /// No description provided for @booking_noVehiclesDesc.
  ///
  /// In en, this message translates to:
  /// **'No vehicles available for this time. Try a different arrival time or search again.'**
  String get booking_noVehiclesDesc;

  /// No description provided for @booking_searchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search Again'**
  String get booking_searchAgain;

  /// No description provided for @booking_selectRoute.
  ///
  /// In en, this message translates to:
  /// **'Select Route'**
  String get booking_selectRoute;

  /// No description provided for @booking_compareVehicles.
  ///
  /// In en, this message translates to:
  /// **'Compare Vehicles'**
  String get booking_compareVehicles;

  /// No description provided for @booking_availableRoutes.
  ///
  /// In en, this message translates to:
  /// **'Available routes'**
  String get booking_availableRoutes;

  /// No description provided for @booking_optionsForSearch.
  ///
  /// In en, this message translates to:
  /// **'{count} options for your search'**
  String booking_optionsForSearch(int count);

  /// No description provided for @booking_map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get booking_map;

  /// No description provided for @booking_vehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details'**
  String get booking_vehicleDetails;

  /// No description provided for @booking_recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get booking_recommendedForYou;

  /// No description provided for @booking_comfortAndAmenities.
  ///
  /// In en, this message translates to:
  /// **'Comfort & Amenities'**
  String get booking_comfortAndAmenities;

  /// No description provided for @booking_comfortDesc.
  ///
  /// In en, this message translates to:
  /// **'Check comfort level before selecting your seat'**
  String get booking_comfortDesc;

  /// No description provided for @booking_driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get booking_driver;

  /// No description provided for @booking_driverDesc.
  ///
  /// In en, this message translates to:
  /// **'Captain details and rating'**
  String get booking_driverDesc;

  /// No description provided for @booking_priceAndAvailability.
  ///
  /// In en, this message translates to:
  /// **'Price & Availability'**
  String get booking_priceAndAvailability;

  /// No description provided for @booking_priceDesc.
  ///
  /// In en, this message translates to:
  /// **'Cost and number of available seats'**
  String get booking_priceDesc;

  /// No description provided for @booking_ac.
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get booking_ac;

  /// No description provided for @booking_available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get booking_available;

  /// No description provided for @booking_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get booking_unavailable;

  /// No description provided for @booking_seatType.
  ///
  /// In en, this message translates to:
  /// **'Seat Type'**
  String get booking_seatType;

  /// No description provided for @booking_recliningSeats.
  ///
  /// In en, this message translates to:
  /// **'Reclining Seats'**
  String get booking_recliningSeats;

  /// No description provided for @common_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @booking_vehicleCondition.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Condition'**
  String get booking_vehicleCondition;

  /// No description provided for @booking_legRoom.
  ///
  /// In en, this message translates to:
  /// **'Leg Room'**
  String get booking_legRoom;

  /// No description provided for @booking_ratingExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get booking_ratingExcellent;

  /// No description provided for @booking_ratingVeryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get booking_ratingVeryGood;

  /// No description provided for @booking_ratingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get booking_ratingGood;

  /// No description provided for @booking_ratingNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get booking_ratingNormal;

  /// No description provided for @booking_certified.
  ///
  /// In en, this message translates to:
  /// **'Certified'**
  String get booking_certified;

  /// No description provided for @booking_completedTrips.
  ///
  /// In en, this message translates to:
  /// **'completed trips'**
  String get booking_completedTrips;

  /// No description provided for @booking_yearsExperience.
  ///
  /// In en, this message translates to:
  /// **'years exp'**
  String get booking_yearsExperience;

  /// No description provided for @booking_tripPrice.
  ///
  /// In en, this message translates to:
  /// **'Trip Price'**
  String get booking_tripPrice;

  /// No description provided for @booking_remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get booking_remaining;

  /// No description provided for @booking_selectPickupDestMap.
  ///
  /// In en, this message translates to:
  /// **'Pickup and destination are set by the selected trip'**
  String get booking_selectPickupDestMap;

  /// No description provided for @booking_popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get booking_popular;

  /// No description provided for @booking_pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get booking_pickup;

  /// No description provided for @booking_tapMapPickup.
  ///
  /// In en, this message translates to:
  /// **'Zoom in or out to view pickup points'**
  String get booking_tapMapPickup;

  /// No description provided for @booking_tapMapDest.
  ///
  /// In en, this message translates to:
  /// **'Zoom in or out to view destination points'**
  String get booking_tapMapDest;

  /// No description provided for @booking_pickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Pickup Point'**
  String get booking_pickupPoint;

  /// No description provided for @booking_notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get booking_notSet;

  /// No description provided for @booking_destinationPoint.
  ///
  /// In en, this message translates to:
  /// **'Destination Point'**
  String get booking_destinationPoint;

  /// No description provided for @booking_confirmRoute.
  ///
  /// In en, this message translates to:
  /// **'Confirm Route'**
  String get booking_confirmRoute;

  /// No description provided for @booking_availableSeats.
  ///
  /// In en, this message translates to:
  /// **'Available Seats'**
  String get booking_availableSeats;

  /// No description provided for @packages_commutePackages.
  ///
  /// In en, this message translates to:
  /// **'Commute Packages'**
  String get packages_commutePackages;

  /// No description provided for @packages_packageDetails.
  ///
  /// In en, this message translates to:
  /// **'Package Details'**
  String get packages_packageDetails;

  /// No description provided for @packages_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get packages_all;

  /// No description provided for @packages_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get packages_weekly;

  /// No description provided for @packages_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get packages_monthly;

  /// No description provided for @packages_quarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get packages_quarterly;

  /// No description provided for @packages_perRide.
  ///
  /// In en, this message translates to:
  /// **'Per ride'**
  String get packages_perRide;

  /// No description provided for @packages_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No packages in this range'**
  String get packages_emptyTitle;

  /// No description provided for @packages_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try another duration, or pull to refresh to load the latest plans.'**
  String get packages_emptyBody;

  /// No description provided for @packages_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get packages_duration;

  /// No description provided for @packages_totalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total Trips'**
  String get packages_totalTrips;

  /// No description provided for @packages_ridesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Rides'**
  String packages_ridesCount(int count);

  /// No description provided for @packages_egpAmount.
  ///
  /// In en, this message translates to:
  /// **'EGP {amount}'**
  String packages_egpAmount(String amount);

  /// No description provided for @packages_startingPrice.
  ///
  /// In en, this message translates to:
  /// **'starting'**
  String get packages_startingPrice;

  /// No description provided for @packages_whatIsIncluded.
  ///
  /// In en, this message translates to:
  /// **'What is Included'**
  String get packages_whatIsIncluded;

  /// No description provided for @packages_reservedSeatGuaranteed.
  ///
  /// In en, this message translates to:
  /// **'Reserved Seat Guaranteed'**
  String get packages_reservedSeatGuaranteed;

  /// No description provided for @packages_reservedSeatDesc.
  ///
  /// In en, this message translates to:
  /// **'Your preferred seat is locked for every daily shuttle ride.'**
  String get packages_reservedSeatDesc;

  /// No description provided for @packages_flexibleTiming.
  ///
  /// In en, this message translates to:
  /// **'Flexible Ride Timing'**
  String get packages_flexibleTiming;

  /// No description provided for @packages_flexibleTimingDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust your ride booking times anytime without cancellation fees.'**
  String get packages_flexibleTimingDesc;

  /// No description provided for @packages_routeLimits.
  ///
  /// In en, this message translates to:
  /// **'Route & Booking Limits'**
  String get packages_routeLimits;

  /// No description provided for @packages_routeScope.
  ///
  /// In en, this message translates to:
  /// **'Route Scope'**
  String get packages_routeScope;

  /// No description provided for @packages_routeScopeDesc.
  ///
  /// In en, this message translates to:
  /// **'Fixed designated route selected upon checkout.'**
  String get packages_routeScopeDesc;

  /// No description provided for @packages_includedRides.
  ///
  /// In en, this message translates to:
  /// **'Included Rides'**
  String get packages_includedRides;

  /// No description provided for @packages_singleTripsDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} single shuttle trips.'**
  String packages_singleTripsDesc(int count);

  /// No description provided for @packages_validityPeriod.
  ///
  /// In en, this message translates to:
  /// **'Validity Period'**
  String get packages_validityPeriod;

  /// No description provided for @packages_consecutiveDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'{days} consecutive calendar days.'**
  String packages_consecutiveDaysDesc(int days);

  /// No description provided for @packages_termsCancellation.
  ///
  /// In en, this message translates to:
  /// **'Terms & Cancellation'**
  String get packages_termsCancellation;

  /// No description provided for @packages_termsText1.
  ///
  /// In en, this message translates to:
  /// **'Packages cannot be refunded once activated.'**
  String get packages_termsText1;

  /// No description provided for @packages_termsText2.
  ///
  /// In en, this message translates to:
  /// **'Seats must be confirmed at least 2 hours before trip.'**
  String get packages_termsText2;

  /// No description provided for @packages_termsText3.
  ///
  /// In en, this message translates to:
  /// **'Package holds up to {count} reservations for the selected route.'**
  String packages_termsText3(int count);

  /// No description provided for @packages_subscriptionCost.
  ///
  /// In en, this message translates to:
  /// **'Subscription Cost'**
  String get packages_subscriptionCost;

  /// No description provided for @packages_route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get packages_route;

  /// No description provided for @packages_marketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover packages from transport offices'**
  String get packages_marketplaceSubtitle;

  /// No description provided for @packages_allOffices.
  ///
  /// In en, this message translates to:
  /// **'All offices'**
  String get packages_allOffices;

  /// No description provided for @packages_filterByOffice.
  ///
  /// In en, this message translates to:
  /// **'Choose office'**
  String get packages_filterByOffice;

  /// No description provided for @packages_officeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by office name'**
  String get packages_officeSearchHint;

  /// No description provided for @packages_noOfficeMatch.
  ///
  /// In en, this message translates to:
  /// **'No office matches \"{query}\"'**
  String packages_noOfficeMatch(String query);

  /// No description provided for @packages_fromOffice.
  ///
  /// In en, this message translates to:
  /// **'{office} packages'**
  String packages_fromOffice(String office);

  /// No description provided for @packages_showAllOffices.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get packages_showAllOffices;

  /// No description provided for @packages_officePackagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 package} other{{count} packages}}'**
  String packages_officePackagesCount(int count);

  /// No description provided for @packages_emptyMarketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'No packages available yet'**
  String get packages_emptyMarketplaceTitle;

  /// No description provided for @packages_emptyMarketplaceBody.
  ///
  /// In en, this message translates to:
  /// **'No office has listed packages for booking yet. Explore the available trips instead.'**
  String get packages_emptyMarketplaceBody;

  /// No description provided for @packages_exploreTrips.
  ///
  /// In en, this message translates to:
  /// **'Explore available trips'**
  String get packages_exploreTrips;

  /// No description provided for @packages_emptyOfficeTitle.
  ///
  /// In en, this message translates to:
  /// **'No packages from this office yet'**
  String get packages_emptyOfficeTitle;

  /// No description provided for @packages_emptyOfficeBody.
  ///
  /// In en, this message translates to:
  /// **'Try another office, or browse every package in the marketplace.'**
  String get packages_emptyOfficeBody;

  /// No description provided for @packages_viewAllOffices.
  ///
  /// In en, this message translates to:
  /// **'View all offices'**
  String get packages_viewAllOffices;

  /// No description provided for @packages_providedBy.
  ///
  /// In en, this message translates to:
  /// **'Provided by'**
  String get packages_providedBy;

  /// No description provided for @packages_viewOffice.
  ///
  /// In en, this message translates to:
  /// **'View office'**
  String get packages_viewOffice;

  /// No description provided for @packages_chooseTripToSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Choose a trip to subscribe'**
  String get packages_chooseTripToSubscribe;

  /// No description provided for @error_timeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please try again.'**
  String get error_timeout;

  /// No description provided for @error_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Request was cancelled.'**
  String get error_cancelled;

  /// No description provided for @error_noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get error_noInternet;

  /// No description provided for @error_badRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request.'**
  String get error_badRequest;

  /// No description provided for @error_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized access.'**
  String get error_unauthorized;

  /// No description provided for @error_forbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this resource.'**
  String get error_forbidden;

  /// No description provided for @error_notFound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found.'**
  String get error_notFound;

  /// No description provided for @error_validation.
  ///
  /// In en, this message translates to:
  /// **'Invalid data provided.'**
  String get error_validation;

  /// No description provided for @error_server.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get error_server;

  /// No description provided for @error_unknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get error_unknown;

  /// No description provided for @dashboard_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get dashboard_home;

  /// No description provided for @dashboard_bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get dashboard_bookings;

  /// No description provided for @dashboard_trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get dashboard_trips;

  /// No description provided for @dashboard_fleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet Management'**
  String get dashboard_fleet;

  /// No description provided for @dashboard_routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get dashboard_routes;

  /// No description provided for @dashboard_subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get dashboard_subscriptions;

  /// No description provided for @dashboard_payments.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get dashboard_payments;

  /// No description provided for @dashboard_tickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get dashboard_tickets;

  /// No description provided for @dashboard_reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get dashboard_reports;

  /// No description provided for @dashboard_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get dashboard_settings;

  /// No description provided for @dashboard_permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get dashboard_permissions;

  /// No description provided for @dashboard_panel.
  ///
  /// In en, this message translates to:
  /// **'Operation Panel'**
  String get dashboard_panel;

  /// No description provided for @dashboard_system.
  ///
  /// In en, this message translates to:
  /// **'Transportation Ops System'**
  String get dashboard_system;

  /// No description provided for @dashboard_menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get dashboard_menu;

  /// No description provided for @dashboard_lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get dashboard_lightMode;

  /// No description provided for @dashboard_darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dashboard_darkMode;

  /// No description provided for @dashboard_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'This page is not available for the current role'**
  String get dashboard_unauthorized;

  /// No description provided for @onboarding_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboarding_skip;

  /// No description provided for @onboarding_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboarding_next;

  /// No description provided for @onboarding_getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboarding_getStarted;

  /// No description provided for @onboarding_page1Title.
  ///
  /// In en, this message translates to:
  /// **'Travel With Confidence'**
  String get onboarding_page1Title;

  /// No description provided for @onboarding_page1Body.
  ///
  /// In en, this message translates to:
  /// **'Book your trip in seconds, choose your seat, and track your vehicle live until you reach your destination safely.'**
  String get onboarding_page1Body;

  /// No description provided for @onboarding_page1FeatureA.
  ///
  /// In en, this message translates to:
  /// **'Trip booking'**
  String get onboarding_page1FeatureA;

  /// No description provided for @onboarding_page1FeatureB.
  ///
  /// In en, this message translates to:
  /// **'Route discovery'**
  String get onboarding_page1FeatureB;

  /// No description provided for @onboarding_page2Title.
  ///
  /// In en, this message translates to:
  /// **'Comfort In Every Ride'**
  String get onboarding_page2Title;

  /// No description provided for @onboarding_page2Body.
  ///
  /// In en, this message translates to:
  /// **'Modern vehicles, comfortable seating, and a seamless booking experience designed for your daily commute.'**
  String get onboarding_page2Body;

  /// No description provided for @onboarding_page2FeatureA.
  ///
  /// In en, this message translates to:
  /// **'Live tracking'**
  String get onboarding_page2FeatureA;

  /// No description provided for @onboarding_page2FeatureB.
  ///
  /// In en, this message translates to:
  /// **'Arrival ETA'**
  String get onboarding_page2FeatureB;

  /// No description provided for @onboarding_page3Title.
  ///
  /// In en, this message translates to:
  /// **'Every Journey Starts With Trust'**
  String get onboarding_page3Title;

  /// No description provided for @onboarding_page3Body.
  ///
  /// In en, this message translates to:
  /// **'Professional drivers, live tracking, and real-time updates keep you informed from departure to arrival.'**
  String get onboarding_page3Body;

  /// No description provided for @onboarding_page3FeatureA.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get onboarding_page3FeatureA;

  /// No description provided for @onboarding_page3FeatureB.
  ///
  /// In en, this message translates to:
  /// **'Discounted packages'**
  String get onboarding_page3FeatureB;

  /// No description provided for @onboarding_page4Title.
  ///
  /// In en, this message translates to:
  /// **'Pay securely, get help anytime'**
  String get onboarding_page4Title;

  /// No description provided for @onboarding_page4Body.
  ///
  /// In en, this message translates to:
  /// **'Pay safely with trusted methods and reach our support team whenever you need.'**
  String get onboarding_page4Body;

  /// No description provided for @onboarding_page4FeatureA.
  ///
  /// In en, this message translates to:
  /// **'Secure payments'**
  String get onboarding_page4FeatureA;

  /// No description provided for @onboarding_page4FeatureB.
  ///
  /// In en, this message translates to:
  /// **'24/7 support'**
  String get onboarding_page4FeatureB;

  /// No description provided for @welcome_trustSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure payments'**
  String get welcome_trustSecure;

  /// No description provided for @welcome_trustLive.
  ///
  /// In en, this message translates to:
  /// **'Real-time tracking'**
  String get welcome_trustLive;

  /// No description provided for @welcome_trustDaily.
  ///
  /// In en, this message translates to:
  /// **'Trusted daily commute'**
  String get welcome_trustDaily;

  /// No description provided for @authSuccess_createdTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get authSuccess_createdTitle;

  /// No description provided for @authSuccess_createdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. Let\'s get you moving.'**
  String get authSuccess_createdSubtitle;

  /// No description provided for @authSuccess_verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get authSuccess_verifyTitle;

  /// No description provided for @authSuccess_verifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to {email}. Confirm it to activate your account, then sign in.'**
  String authSuccess_verifySubtitle(String email);

  /// No description provided for @authSuccess_getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get authSuccess_getStarted;

  /// No description provided for @authSuccess_backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authSuccess_backToSignIn;

  /// No description provided for @authSuccess_perkBooking.
  ///
  /// In en, this message translates to:
  /// **'Book trips instantly'**
  String get authSuccess_perkBooking;

  /// No description provided for @authSuccess_perkTracking.
  ///
  /// In en, this message translates to:
  /// **'Track rides live'**
  String get authSuccess_perkTracking;

  /// No description provided for @authSuccess_perkPasses.
  ///
  /// In en, this message translates to:
  /// **'Save with passes'**
  String get authSuccess_perkPasses;

  /// No description provided for @auth_passwordStrengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get auth_passwordStrengthLabel;

  /// No description provided for @auth_passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get auth_passwordWeak;

  /// No description provided for @auth_passwordFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get auth_passwordFair;

  /// No description provided for @auth_passwordGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get auth_passwordGood;

  /// No description provided for @auth_passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get auth_passwordStrong;

  /// No description provided for @auth_passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Use 8+ characters with letters, numbers and a symbol.'**
  String get auth_passwordHint;

  /// No description provided for @auth_policyComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{title} will open when published.'**
  String auth_policyComingSoon(String title);

  /// No description provided for @auth_referralCodeSection.
  ///
  /// In en, this message translates to:
  /// **'Referral code (optional)'**
  String get auth_referralCodeSection;

  /// No description provided for @auth_referralCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter a referral code'**
  String get auth_referralCodeLabel;

  /// No description provided for @auth_referralCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Have a code from a friend? Add it to earn a welcome reward.'**
  String get auth_referralCodeHint;

  /// No description provided for @referral_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get referral_pending;

  /// No description provided for @referral_leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Top referrers'**
  String get referral_leaderboardTitle;

  /// No description provided for @referral_leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Be the first to climb the leaderboard.'**
  String get referral_leaderboardEmpty;

  /// No description provided for @referral_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get referral_you;

  /// No description provided for @tracking_title.
  ///
  /// In en, this message translates to:
  /// **'Track your trip'**
  String get tracking_title;

  /// No description provided for @tracking_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading your trip…'**
  String get tracking_loading;

  /// No description provided for @tracking_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get tracking_refresh;

  /// No description provided for @tracking_errorTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your tracking'**
  String get tracking_errorTitle;

  /// No description provided for @tracking_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No trip to track'**
  String get tracking_emptyTitle;

  /// No description provided for @tracking_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Live tracking appears here once a booking of yours is confirmed.'**
  String get tracking_emptyBody;

  /// No description provided for @tracking_emptyAction.
  ///
  /// In en, this message translates to:
  /// **'Browse trips'**
  String get tracking_emptyAction;

  /// No description provided for @tracking_stateNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Your trip hasn\'t started yet'**
  String get tracking_stateNotStarted;

  /// No description provided for @tracking_stateDriverOnWay.
  ///
  /// In en, this message translates to:
  /// **'The captain is on the way'**
  String get tracking_stateDriverOnWay;

  /// No description provided for @tracking_stateBoarding.
  ///
  /// In en, this message translates to:
  /// **'Boarding now'**
  String get tracking_stateBoarding;

  /// No description provided for @tracking_stateInProgress.
  ///
  /// In en, this message translates to:
  /// **'On the road'**
  String get tracking_stateInProgress;

  /// No description provided for @tracking_stateCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get tracking_stateCompleted;

  /// No description provided for @tracking_signalLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get tracking_signalLive;

  /// No description provided for @tracking_signalStale.
  ///
  /// In en, this message translates to:
  /// **'Signal delayed'**
  String get tracking_signalStale;

  /// No description provided for @tracking_signalNone.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the captain\'s signal'**
  String get tracking_signalNone;

  /// No description provided for @tracking_signalOffRoute.
  ///
  /// In en, this message translates to:
  /// **'Off route'**
  String get tracking_signalOffRoute;

  /// No description provided for @tracking_updatedJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get tracking_updatedJustNow;

  /// No description provided for @tracking_updatedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String tracking_updatedMinutesAgo(int minutes);

  /// No description provided for @tracking_etaToYourStop.
  ///
  /// In en, this message translates to:
  /// **'Arrives at your stop'**
  String get tracking_etaToYourStop;

  /// No description provided for @tracking_etaToDestination.
  ///
  /// In en, this message translates to:
  /// **'You arrive at'**
  String get tracking_etaToDestination;

  /// No description provided for @tracking_etaNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get tracking_etaNow;

  /// No description provided for @tracking_etaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get tracking_etaUnavailable;

  /// No description provided for @tracking_etaMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String tracking_etaMinutes(int minutes);

  /// No description provided for @tracking_etaHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String tracking_etaHoursMinutes(int hours, int minutes);

  /// No description provided for @tracking_sourceLive.
  ///
  /// In en, this message translates to:
  /// **'From live GPS'**
  String get tracking_sourceLive;

  /// No description provided for @tracking_sourceEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get tracking_sourceEstimated;

  /// No description provided for @tracking_sourceScheduled.
  ///
  /// In en, this message translates to:
  /// **'From the schedule'**
  String get tracking_sourceScheduled;

  /// No description provided for @tracking_departsAt.
  ///
  /// In en, this message translates to:
  /// **'Departs at {time}'**
  String tracking_departsAt(String time);

  /// No description provided for @tracking_stopsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No stops left} =1{1 stop left} other{{count} stops left}}'**
  String tracking_stopsRemaining(int count);

  /// No description provided for @tracking_yourBooking.
  ///
  /// In en, this message translates to:
  /// **'Your booking'**
  String get tracking_yourBooking;

  /// No description provided for @tracking_seat.
  ///
  /// In en, this message translates to:
  /// **'Seat {label}'**
  String tracking_seat(String label);

  /// No description provided for @tracking_boarded.
  ///
  /// In en, this message translates to:
  /// **'You\'re on board'**
  String get tracking_boarded;

  /// No description provided for @tracking_notBoarded.
  ///
  /// In en, this message translates to:
  /// **'Not boarded yet'**
  String get tracking_notBoarded;

  /// No description provided for @tracking_boardAt.
  ///
  /// In en, this message translates to:
  /// **'Board at'**
  String get tracking_boardAt;

  /// No description provided for @tracking_alightAt.
  ///
  /// In en, this message translates to:
  /// **'Get off at'**
  String get tracking_alightAt;

  /// No description provided for @tracking_stopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip stops'**
  String get tracking_stopsTitle;

  /// No description provided for @tracking_yourStopBadge.
  ///
  /// In en, this message translates to:
  /// **'Your stop'**
  String get tracking_yourStopBadge;

  /// No description provided for @tracking_yourDropoffBadge.
  ///
  /// In en, this message translates to:
  /// **'Your drop-off'**
  String get tracking_yourDropoffBadge;

  /// No description provided for @tracking_stopDeparted.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get tracking_stopDeparted;

  /// No description provided for @tracking_stopArrived.
  ///
  /// In en, this message translates to:
  /// **'At the stop'**
  String get tracking_stopArrived;

  /// No description provided for @tracking_stopNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tracking_stopNext;

  /// No description provided for @tracking_captain.
  ///
  /// In en, this message translates to:
  /// **'Captain'**
  String get tracking_captain;

  /// No description provided for @tracking_vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get tracking_vehicle;

  /// No description provided for @tracking_call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get tracking_call;

  /// No description provided for @tracking_noRating.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get tracking_noRating;

  /// No description provided for @tracking_ratingWithCount.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count})'**
  String tracking_ratingWithCount(String rating, int count);

  /// No description provided for @tracking_noPhone.
  ///
  /// In en, this message translates to:
  /// **'The captain\'s number isn\'t available'**
  String get tracking_noPhone;

  /// No description provided for @tracking_completedTitle.
  ///
  /// In en, this message translates to:
  /// **'You arrived safely'**
  String get tracking_completedTitle;

  /// No description provided for @tracking_completedBody.
  ///
  /// In en, this message translates to:
  /// **'We hope the ride was comfortable.'**
  String get tracking_completedBody;

  /// No description provided for @tracking_rateTrip.
  ///
  /// In en, this message translates to:
  /// **'Rate this trip'**
  String get tracking_rateTrip;

  /// No description provided for @tracking_alreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'Thanks — you\'ve already rated this trip.'**
  String get tracking_alreadyReviewed;

  /// No description provided for @tracking_bookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book another trip'**
  String get tracking_bookAgain;

  /// No description provided for @tracking_mapUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Map data unavailable'**
  String get tracking_mapUnavailableTitle;

  /// No description provided for @tracking_mapUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'No route coordinates were found for this trip.'**
  String get tracking_mapUnavailableBody;

  /// No description provided for @tracking_recenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get tracking_recenter;

  /// No description provided for @tracking_followVehicle.
  ///
  /// In en, this message translates to:
  /// **'Follow the vehicle'**
  String get tracking_followVehicle;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// No description provided for @profile_memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String profile_memberSince(String date);

  /// No description provided for @profile_guestName.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get profile_guestName;

  /// No description provided for @profile_noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email added'**
  String get profile_noEmail;

  /// No description provided for @profile_completeTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish setting up your account'**
  String get profile_completeTitle;

  /// No description provided for @profile_completeBody.
  ///
  /// In en, this message translates to:
  /// **'Add your missing details so your captain and support can reach you.'**
  String get profile_completeBody;

  /// No description provided for @profile_completeAction.
  ///
  /// In en, this message translates to:
  /// **'Complete now'**
  String get profile_completeAction;

  /// No description provided for @profile_statTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips taken'**
  String get profile_statTrips;

  /// No description provided for @profile_statUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get profile_statUpcoming;

  /// No description provided for @profile_statPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get profile_statPackage;

  /// No description provided for @profile_packageNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get profile_packageNone;

  /// No description provided for @profile_packageActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profile_packageActive;

  /// No description provided for @profile_packageExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Your {name} package on {route} ends in {days} days.'**
  String profile_packageExpiringSoon(String name, String route, int days);

  /// No description provided for @profile_packageRenew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get profile_packageRenew;

  /// No description provided for @profile_sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profile_sectionAccount;

  /// No description provided for @profile_sectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profile_sectionPreferences;

  /// No description provided for @profile_sectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get profile_sectionSupport;

  /// No description provided for @profile_sectionLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get profile_sectionLegal;

  /// No description provided for @profile_editProfile.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get profile_editProfile;

  /// No description provided for @profile_editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, phone and email'**
  String get profile_editProfileSubtitle;

  /// No description provided for @profile_subscription.
  ///
  /// In en, this message translates to:
  /// **'My package'**
  String get profile_subscription;

  /// No description provided for @profile_subscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plans, renewals and billing'**
  String get profile_subscriptionSubtitle;

  /// No description provided for @profile_myTrips.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get profile_myTrips;

  /// No description provided for @profile_myTripsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming, active and past trips'**
  String get profile_myTripsSubtitle;

  /// No description provided for @profile_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profile_language;

  /// No description provided for @profile_languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profile_languageEnglish;

  /// No description provided for @profile_languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get profile_languageArabic;

  /// No description provided for @profile_selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose a language'**
  String get profile_selectLanguage;

  /// No description provided for @profile_selectLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'The app switches immediately, including the layout direction.'**
  String get profile_selectLanguageBody;

  /// No description provided for @profile_theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profile_theme;

  /// No description provided for @profile_themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get profile_themeSystem;

  /// No description provided for @profile_themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profile_themeLight;

  /// No description provided for @profile_themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profile_themeDark;

  /// No description provided for @profile_selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose an appearance'**
  String get profile_selectTheme;

  /// No description provided for @profile_selectThemeBody.
  ///
  /// In en, this message translates to:
  /// **'System follows your device setting.'**
  String get profile_selectThemeBody;

  /// No description provided for @profile_themeLightBody.
  ///
  /// In en, this message translates to:
  /// **'Best in daylight'**
  String get profile_themeLightBody;

  /// No description provided for @profile_themeDarkBody.
  ///
  /// In en, this message translates to:
  /// **'Easier on the eyes at night'**
  String get profile_themeDarkBody;

  /// No description provided for @profile_helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help centre'**
  String get profile_helpCenter;

  /// No description provided for @profile_helpCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs, tickets and refunds'**
  String get profile_helpCenterSubtitle;

  /// No description provided for @profile_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms & conditions'**
  String get profile_terms;

  /// No description provided for @profile_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get profile_privacy;

  /// No description provided for @profile_lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {date}'**
  String profile_lastUpdated(String date);

  /// No description provided for @profile_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get profile_editTitle;

  /// No description provided for @profile_editBody.
  ///
  /// In en, this message translates to:
  /// **'Your captain uses these details to reach you about a trip.'**
  String get profile_editBody;

  /// No description provided for @profile_fieldName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profile_fieldName;

  /// No description provided for @profile_fieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get profile_fieldPhone;

  /// No description provided for @profile_fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get profile_fieldEmail;

  /// No description provided for @profile_errorRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get profile_errorRequired;

  /// No description provided for @profile_errorNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get profile_errorNameTooShort;

  /// No description provided for @profile_errorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Egyptian mobile number'**
  String get profile_errorInvalidPhone;

  /// No description provided for @profile_errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get profile_errorInvalidEmail;

  /// No description provided for @profile_saved.
  ///
  /// In en, this message translates to:
  /// **'Your details were saved'**
  String get profile_saved;

  /// No description provided for @profile_logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profile_logout;

  /// No description provided for @profile_logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profile_logoutTitle;

  /// No description provided for @profile_logoutBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to book or track a trip.'**
  String get profile_logoutBody;

  /// No description provided for @profile_logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t log you out. Please try again.'**
  String get profile_logoutFailed;

  /// No description provided for @profile_refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t refresh your profile.'**
  String get profile_refreshFailed;

  /// No description provided for @profile_signInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your profile'**
  String get profile_signInRequiredTitle;

  /// No description provided for @profile_signInRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re browsing as a guest. Sign in to see your trips, packages and account details.'**
  String get profile_signInRequiredBody;

  /// No description provided for @profile_signInCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get profile_signInCta;

  /// No description provided for @welcome_continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get welcome_continueWithEmail;

  /// No description provided for @welcome_createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get welcome_createAccount;

  /// No description provided for @welcome_continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get welcome_continueAsGuest;

  /// No description provided for @welcome_heroTagline.
  ///
  /// In en, this message translates to:
  /// **'Smart, comfortable transport.\nBook, track, and ride — all in one place.'**
  String get welcome_heroTagline;

  /// No description provided for @welcome_valueSeats.
  ///
  /// In en, this message translates to:
  /// **'Reserve seats'**
  String get welcome_valueSeats;

  /// No description provided for @welcome_valueTracking.
  ///
  /// In en, this message translates to:
  /// **'Live bus tracking'**
  String get welcome_valueTracking;

  /// No description provided for @welcome_valuePasses.
  ///
  /// In en, this message translates to:
  /// **'Manage passes'**
  String get welcome_valuePasses;

  /// No description provided for @auth_termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get auth_termsAndConditions;

  /// No description provided for @welcome_languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get welcome_languageName;

  /// No description provided for @auth_signInHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to track your trips, manage subscriptions, and follow buses in real time.'**
  String get auth_signInHeroSubtitle;

  /// No description provided for @auth_signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get auth_signingIn;

  /// No description provided for @auth_signInInfoCard.
  ///
  /// In en, this message translates to:
  /// **'All your trips and bookings in one place — log in and follow your day easily.'**
  String get auth_signInInfoCard;

  /// No description provided for @auth_signInSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'Make sure to use the email associated with your account to access your bookings and subscriptions.'**
  String get auth_signInSecurityNote;

  /// No description provided for @auth_signUpHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register your details once and enjoy booking trips, tracking buses, and managing subscriptions easily.'**
  String get auth_signUpHeroSubtitle;

  /// No description provided for @auth_accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get auth_accountDetails;

  /// No description provided for @auth_loginDetails.
  ///
  /// In en, this message translates to:
  /// **'Login Details'**
  String get auth_loginDetails;

  /// No description provided for @auth_creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating Account...'**
  String get auth_creatingAccount;

  /// No description provided for @auth_signUpTrustBanner.
  ///
  /// In en, this message translates to:
  /// **'Your data is secure and used only to manage your trips and bookings.'**
  String get auth_signUpTrustBanner;

  /// No description provided for @auth_signUpSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'By clicking Create Account, a confirmation will be sent to your email.'**
  String get auth_signUpSecurityNote;

  /// No description provided for @auth_sendingLink.
  ///
  /// In en, this message translates to:
  /// **'Sending link...'**
  String get auth_sendingLink;

  /// No description provided for @auth_recoveryLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send recovery link'**
  String get auth_recoveryLinkFailed;

  /// No description provided for @auth_resetInfoCard.
  ///
  /// In en, this message translates to:
  /// **'We will send a temporary link to your email. Open it soon to set a new password.'**
  String get auth_resetInfoCard;

  /// No description provided for @auth_recoveryLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Recovery link sent'**
  String get auth_recoveryLinkSent;

  /// No description provided for @auth_openEmailToReset.
  ///
  /// In en, this message translates to:
  /// **'Open the email and tap the link to reset your password.'**
  String get auth_openEmailToReset;

  /// No description provided for @auth_emailHelp.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t find the email? Check your spam folder or wait a bit before resending.'**
  String get auth_emailHelp;

  /// No description provided for @auth_forgotSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'For your security, the system may prevent sending multiple links in a short period.'**
  String get auth_forgotSecurityNote;

  /// No description provided for @auth_help.
  ///
  /// In en, this message translates to:
  /// **'Help?'**
  String get auth_help;

  /// No description provided for @auth_resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get auth_resetPasswordTitle;

  /// No description provided for @auth_resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get auth_resetPasswordSubtitle;

  /// No description provided for @auth_newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get auth_newPassword;

  /// No description provided for @auth_confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get auth_confirmPassword;

  /// No description provided for @auth_passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get auth_passwordsDoNotMatch;

  /// No description provided for @auth_updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get auth_updatePassword;

  /// No description provided for @auth_updatingPassword.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get auth_updatingPassword;

  /// No description provided for @auth_passwordUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated. Please sign in.'**
  String get auth_passwordUpdatedSnack;

  /// No description provided for @auth_resetPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password'**
  String get auth_resetPasswordFailed;

  /// No description provided for @auth_resetLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'This reset link is invalid or has expired. Please request a new one.'**
  String get auth_resetLinkInvalid;

  /// No description provided for @auth_verifyingResetLink.
  ///
  /// In en, this message translates to:
  /// **'Verifying your reset link...'**
  String get auth_verifyingResetLink;

  /// No description provided for @auth_enterPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get auth_enterPhoneTitle;

  /// No description provided for @auth_enterPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code to the number you enter.'**
  String get auth_enterPhoneSubtitle;

  /// No description provided for @auth_or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get auth_or;

  /// No description provided for @auth_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get auth_continue;

  /// No description provided for @auth_verifyNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify number'**
  String get auth_verifyNumberTitle;

  /// No description provided for @auth_enterOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get auth_enterOtpTitle;

  /// No description provided for @auth_otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'The code was sent by SMS to:\n{phone}'**
  String auth_otpSentTo(String phone);

  /// No description provided for @auth_verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get auth_verify;

  /// No description provided for @auth_didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get auth_didntReceiveCode;

  /// No description provided for @auth_resendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend ({seconds})'**
  String auth_resendCountdown(int seconds);

  /// No description provided for @auth_resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get auth_resendCode;

  /// No description provided for @auth_mustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Terms & Conditions.'**
  String get auth_mustAcceptTerms;

  /// No description provided for @auth_completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get auth_completeProfileTitle;

  /// No description provided for @auth_welcomeToApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BMT'**
  String get auth_welcomeToApp;

  /// No description provided for @auth_completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We need a few details to give you the best service.'**
  String get auth_completeProfileSubtitle;

  /// No description provided for @auth_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Ahmed Hassan'**
  String get auth_nameHint;

  /// No description provided for @auth_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get auth_nameRequired;

  /// No description provided for @auth_emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get auth_emailOptional;

  /// No description provided for @auth_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get auth_gender;

  /// No description provided for @auth_genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get auth_genderMale;

  /// No description provided for @auth_genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get auth_genderFemale;

  /// No description provided for @auth_acceptTermsCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy.'**
  String get auth_acceptTermsCheckbox;

  /// No description provided for @auth_createAccountAndStart.
  ///
  /// In en, this message translates to:
  /// **'Create account and get started'**
  String get auth_createAccountAndStart;

  /// No description provided for @auth_invalidPhoneShort.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get auth_invalidPhoneShort;

  /// No description provided for @splash_tagline.
  ///
  /// In en, this message translates to:
  /// **'Your journey, simplified.'**
  String get splash_tagline;

  /// No description provided for @common_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get common_today;

  /// No description provided for @common_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get common_date;

  /// No description provided for @common_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get common_time;

  /// No description provided for @common_seats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get common_seats;

  /// No description provided for @common_soldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get common_soldOut;

  /// No description provided for @common_notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get common_notSet;

  /// No description provided for @common_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get common_notifications;

  /// No description provided for @common_support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get common_support;

  /// No description provided for @common_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get common_manage;

  /// No description provided for @common_pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get common_pickup;

  /// No description provided for @common_destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get common_destination;

  /// No description provided for @common_dropOff.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get common_dropOff;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get nav_routes;

  /// No description provided for @nav_trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get nav_trips;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @home_myTrips.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get home_myTrips;

  /// No description provided for @home_greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get home_greetingMorning;

  /// No description provided for @home_greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get home_greetingAfternoon;

  /// No description provided for @home_greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get home_greetingEvening;

  /// No description provided for @home_welcomeAboard.
  ///
  /// In en, this message translates to:
  /// **'Welcome aboard'**
  String get home_welcomeAboard;

  /// No description provided for @home_popularDestinations.
  ///
  /// In en, this message translates to:
  /// **'POPULAR DESTINATIONS'**
  String get home_popularDestinations;

  /// No description provided for @home_searchRoutesTimesSeats.
  ///
  /// In en, this message translates to:
  /// **'Search routes, times and seats'**
  String get home_searchRoutesTimesSeats;

  /// No description provided for @home_expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get home_expiresToday;

  /// No description provided for @home_trackYourBus.
  ///
  /// In en, this message translates to:
  /// **'Track your bus'**
  String get home_trackYourBus;

  /// No description provided for @home_yourBooking.
  ///
  /// In en, this message translates to:
  /// **'Your booking'**
  String get home_yourBooking;

  /// No description provided for @home_yourBookings.
  ///
  /// In en, this message translates to:
  /// **'Your bookings'**
  String get home_yourBookings;

  /// No description provided for @home_yourJourney.
  ///
  /// In en, this message translates to:
  /// **'Your journey'**
  String get home_yourJourney;

  /// No description provided for @home_seatsYouHold.
  ///
  /// In en, this message translates to:
  /// **'Seats you hold, and where each one stands.'**
  String get home_seatsYouHold;

  /// No description provided for @home_bookASeat.
  ///
  /// In en, this message translates to:
  /// **'Book a seat'**
  String get home_bookASeat;

  /// No description provided for @home_nextDepartures.
  ///
  /// In en, this message translates to:
  /// **'Next departures'**
  String get home_nextDepartures;

  /// No description provided for @home_tripsOpenSoonest.
  ///
  /// In en, this message translates to:
  /// **'Trips open for booking, soonest first.'**
  String get home_tripsOpenSoonest;

  /// No description provided for @home_allRoutes.
  ///
  /// In en, this message translates to:
  /// **'All routes'**
  String get home_allRoutes;

  /// No description provided for @home_yourPackage.
  ///
  /// In en, this message translates to:
  /// **'Your package'**
  String get home_yourPackage;

  /// No description provided for @home_activeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Active subscription'**
  String get home_activeSubscription;

  /// No description provided for @home_bookAnotherSeat.
  ///
  /// In en, this message translates to:
  /// **'Book another seat'**
  String get home_bookAnotherSeat;

  /// No description provided for @home_bookSeat.
  ///
  /// In en, this message translates to:
  /// **'Book seat'**
  String get home_bookSeat;

  /// No description provided for @home_fareNotPublished.
  ///
  /// In en, this message translates to:
  /// **'Fare not published yet'**
  String get home_fareNotPublished;

  /// No description provided for @home_fareFrom.
  ///
  /// In en, this message translates to:
  /// **'FARE FROM'**
  String get home_fareFrom;

  /// No description provided for @home_departureToBeSet.
  ///
  /// In en, this message translates to:
  /// **'Departure time to be set'**
  String get home_departureToBeSet;

  /// No description provided for @home_boarding.
  ///
  /// In en, this message translates to:
  /// **'Boarding'**
  String get home_boarding;

  /// No description provided for @home_rideTime.
  ///
  /// In en, this message translates to:
  /// **'Ride time'**
  String get home_rideTime;

  /// No description provided for @home_youBookedSeats.
  ///
  /// In en, this message translates to:
  /// **'You booked {seats} seats'**
  String home_youBookedSeats(int seats);

  /// No description provided for @home_youBookedThis.
  ///
  /// In en, this message translates to:
  /// **'You booked this'**
  String get home_youBookedThis;

  /// No description provided for @home_pickupShort.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get home_pickupShort;

  /// No description provided for @home_stopNotSet.
  ///
  /// In en, this message translates to:
  /// **'Stop not set'**
  String get home_stopNotSet;

  /// No description provided for @home_noDepartures.
  ///
  /// In en, this message translates to:
  /// **'No departures scheduled'**
  String get home_noDepartures;

  /// No description provided for @home_noDeparturesBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is open for booking right now. Browse the routes to see what runs and when.'**
  String get home_noDeparturesBody;

  /// No description provided for @home_browseRoutes.
  ///
  /// In en, this message translates to:
  /// **'Browse routes'**
  String get home_browseRoutes;

  /// No description provided for @home_travelWith.
  ///
  /// In en, this message translates to:
  /// **'Travel with'**
  String get home_travelWith;

  /// No description provided for @home_companies.
  ///
  /// In en, this message translates to:
  /// **'Transport companies'**
  String get home_companies;

  /// No description provided for @home_companiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick an operator to see everything it runs.'**
  String get home_companiesSubtitle;

  /// No description provided for @home_departuresOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trip open for booking} other{{count} trips open for booking}}'**
  String home_departuresOpenCount(int count);

  /// No description provided for @home_searchTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Trip'**
  String get home_searchTripTitle;

  /// No description provided for @home_searchTripSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find your next commute in seconds'**
  String get home_searchTripSubtitle;

  /// No description provided for @home_pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get home_pickupLocation;

  /// No description provided for @home_selectPickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Select pickup point'**
  String get home_selectPickupPoint;

  /// No description provided for @home_whereAreYouGoing.
  ///
  /// In en, this message translates to:
  /// **'Where are you going?'**
  String get home_whereAreYouGoing;

  /// No description provided for @home_selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get home_selectTime;

  /// No description provided for @home_searchTrips.
  ///
  /// In en, this message translates to:
  /// **'Search Trips'**
  String get home_searchTrips;

  /// No description provided for @home_seatsOnlyLeft.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left'**
  String home_seatsOnlyLeft(int count);

  /// No description provided for @home_seatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String home_seatsAvailable(int count);

  /// No description provided for @home_statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get home_statusUnderReview;

  /// No description provided for @home_statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get home_statusConfirmed;

  /// No description provided for @home_statusOnBoard.
  ///
  /// In en, this message translates to:
  /// **'On board'**
  String get home_statusOnBoard;

  /// No description provided for @home_statusUnderReviewExplanation.
  ///
  /// In en, this message translates to:
  /// **'We are checking your payment. You will be notified as soon as your seat is confirmed.'**
  String get home_statusUnderReviewExplanation;

  /// No description provided for @home_statusConfirmedExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your seat is held. Be at the pickup point 10 minutes before departure.'**
  String get home_statusConfirmedExplanation;

  /// No description provided for @home_statusOnBoardExplanation.
  ///
  /// In en, this message translates to:
  /// **'You are on board. Have a good trip.'**
  String get home_statusOnBoardExplanation;

  /// No description provided for @home_yourBookingFallback.
  ///
  /// In en, this message translates to:
  /// **'Your booking'**
  String get home_yourBookingFallback;

  /// No description provided for @home_seatLabel.
  ///
  /// In en, this message translates to:
  /// **'Seat {label}'**
  String home_seatLabel(String label);

  /// No description provided for @home_daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String home_daysLeft(int days);

  /// No description provided for @home_dayLeft.
  ///
  /// In en, this message translates to:
  /// **'1 day left'**
  String get home_dayLeft;

  /// No description provided for @booking_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search {title}'**
  String booking_searchHint(String title);

  /// No description provided for @booking_noPickupPointsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No pickup points available yet. Please check back soon.'**
  String get booking_noPickupPointsAvailable;

  /// No description provided for @booking_noDestinationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No destinations available yet.'**
  String get booking_noDestinationsAvailable;

  /// No description provided for @booking_noDepartureTimesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No departure times available for this route yet.'**
  String get booking_noDepartureTimesAvailable;

  /// No description provided for @map_livePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Live route preview'**
  String get map_livePreviewTitle;

  /// No description provided for @map_livePreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time vehicle position and route flow'**
  String get map_livePreviewSubtitle;

  /// No description provided for @notifications_markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifications_markAllRead;

  /// No description provided for @notifications_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifications_emptyTitle;

  /// No description provided for @notifications_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Trip updates, booking confirmations and reminders will appear here when they arrive.'**
  String get notifications_emptyBody;

  /// No description provided for @notifications_categoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this category'**
  String get notifications_categoryEmptyTitle;

  /// No description provided for @notifications_categoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick another category to see the rest of your notifications.'**
  String get notifications_categoryEmptyBody;

  /// No description provided for @notifications_newBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get notifications_newBadge;

  /// No description provided for @notifications_categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notifications_categoryAll;

  /// No description provided for @notifications_categoryBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get notifications_categoryBooking;

  /// No description provided for @notifications_categoryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get notifications_categoryPayment;

  /// No description provided for @notifications_categoryTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get notifications_categoryTrip;

  /// No description provided for @notifications_categoryNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get notifications_categoryNews;

  /// No description provided for @notifications_categoryOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get notifications_categoryOffers;

  /// No description provided for @notifications_categoryAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get notifications_categoryAlerts;

  /// No description provided for @trips_headerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming, active, and past commutes'**
  String get trips_headerSubtitle;

  /// No description provided for @trips_bookNewTripTooltip.
  ///
  /// In en, this message translates to:
  /// **'Book new trip'**
  String get trips_bookNewTripTooltip;

  /// No description provided for @trips_filterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get trips_filterUpcoming;

  /// No description provided for @trips_filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get trips_filterActive;

  /// No description provided for @trips_filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get trips_filterCompleted;

  /// No description provided for @trips_filterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get trips_filterCancelled;

  /// No description provided for @trips_sectionUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming trips'**
  String get trips_sectionUpcoming;

  /// No description provided for @trips_sectionActive.
  ///
  /// In en, this message translates to:
  /// **'In progress trips'**
  String get trips_sectionActive;

  /// No description provided for @trips_sectionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed trips'**
  String get trips_sectionCompleted;

  /// No description provided for @trips_sectionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled trips'**
  String get trips_sectionCancelled;

  /// No description provided for @trips_emptyUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming trips scheduled'**
  String get trips_emptyUpcomingTitle;

  /// No description provided for @trips_emptyUpcomingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book a trip and it will show up here.'**
  String get trips_emptyUpcomingSubtitle;

  /// No description provided for @trips_emptyActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips in progress right now'**
  String get trips_emptyActiveTitle;

  /// No description provided for @trips_emptyActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trips currently on the road will appear here.'**
  String get trips_emptyActiveSubtitle;

  /// No description provided for @trips_emptyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet'**
  String get trips_emptyCompletedTitle;

  /// No description provided for @trips_emptyCompletedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trips you finish will show up here.'**
  String get trips_emptyCompletedSubtitle;

  /// No description provided for @trips_emptyCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'No cancelled trips'**
  String get trips_emptyCancelledTitle;

  /// No description provided for @trips_emptyCancelledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trips you cancel will show up here.'**
  String get trips_emptyCancelledSubtitle;

  /// No description provided for @payments_checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get payments_checkoutTitle;

  /// No description provided for @payments_encrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get payments_encrypted;

  /// No description provided for @payments_fareSummary.
  ///
  /// In en, this message translates to:
  /// **'Fare summary'**
  String get payments_fareSummary;

  /// No description provided for @payments_ticketFare.
  ///
  /// In en, this message translates to:
  /// **'Ticket fare'**
  String get payments_ticketFare;

  /// No description provided for @payments_serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get payments_serviceFee;

  /// No description provided for @payments_tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get payments_tax;

  /// No description provided for @payments_promoDiscount.
  ///
  /// In en, this message translates to:
  /// **'Promo discount'**
  String get payments_promoDiscount;

  /// No description provided for @payments_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get payments_total;

  /// No description provided for @payments_assuranceCardDetails.
  ///
  /// In en, this message translates to:
  /// **'Card details are entered on the bank\'s page, never stored by BMT.'**
  String get payments_assuranceCardDetails;

  /// No description provided for @payments_assuranceSeatHeld.
  ///
  /// In en, this message translates to:
  /// **'Your seat is held for you now and released only if the payment fails.'**
  String get payments_assuranceSeatHeld;

  /// No description provided for @payments_assuranceTransferChecked.
  ///
  /// In en, this message translates to:
  /// **'Transfers are checked by our team, and you will be notified once confirmed.'**
  String get payments_assuranceTransferChecked;

  /// No description provided for @payments_assuranceSupportReference.
  ///
  /// In en, this message translates to:
  /// **'Something looks wrong? Support can see this booking by its reference.'**
  String get payments_assuranceSupportReference;

  /// No description provided for @payments_bookingMissingItems.
  ///
  /// In en, this message translates to:
  /// **'This booking is missing {items}'**
  String payments_bookingMissingItems(String items);

  /// No description provided for @payments_completeBeforePaying.
  ///
  /// In en, this message translates to:
  /// **'Go back and complete it before paying.'**
  String get payments_completeBeforePaying;

  /// No description provided for @payments_goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get payments_goBack;

  /// No description provided for @payments_howToPay.
  ///
  /// In en, this message translates to:
  /// **'How would you like to pay?'**
  String get payments_howToPay;

  /// No description provided for @payments_balanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String payments_balanceAmount(String amount);

  /// No description provided for @payments_shortByAmount.
  ///
  /// In en, this message translates to:
  /// **'Short by {amount} — top up or pick another method.'**
  String payments_shortByAmount(String amount);

  /// No description provided for @payments_noMethodsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No payment method is switched on right now. Your seat is still held — contact support and we will take it from there.'**
  String get payments_noMethodsAvailable;

  /// No description provided for @payments_nextStepCard.
  ///
  /// In en, this message translates to:
  /// **'You will finish on Paymob\'s encrypted card page.'**
  String get payments_nextStepCard;

  /// No description provided for @payments_nextStepInstapay.
  ///
  /// In en, this message translates to:
  /// **'Transfer, then attach the receipt on the next step.'**
  String get payments_nextStepInstapay;

  /// No description provided for @payments_nextStepBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank details come next — attach the receipt after you transfer.'**
  String get payments_nextStepBankTransfer;

  /// No description provided for @payments_nextStepVodafoneCash.
  ///
  /// In en, this message translates to:
  /// **'Send from your wallet, then attach the receipt on the next step.'**
  String get payments_nextStepVodafoneCash;

  /// No description provided for @payments_nextStepWallet.
  ///
  /// In en, this message translates to:
  /// **'Deducted from your balance the moment you confirm.'**
  String get payments_nextStepWallet;

  /// No description provided for @payments_fastestBadge.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get payments_fastestBadge;

  /// No description provided for @payments_seatHeldWhilePaying.
  ///
  /// In en, this message translates to:
  /// **'Your seat is held while you pay.'**
  String get payments_seatHeldWhilePaying;

  /// No description provided for @payments_stepSeat.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get payments_stepSeat;

  /// No description provided for @payments_stepPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payments_stepPayment;

  /// No description provided for @payments_stepTicket.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get payments_stepTicket;

  /// No description provided for @payments_havePromoCode.
  ///
  /// In en, this message translates to:
  /// **'Have a promo code?'**
  String get payments_havePromoCode;

  /// No description provided for @payments_enterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get payments_enterCodeHint;

  /// No description provided for @payments_promoCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not valid'**
  String get payments_promoCodeInvalid;

  /// No description provided for @payments_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get payments_apply;

  /// No description provided for @payments_promoApplied.
  ///
  /// In en, this message translates to:
  /// **'{code} applied — you save {amount}'**
  String payments_promoApplied(String code, String amount);

  /// No description provided for @payments_removePromoCode.
  ///
  /// In en, this message translates to:
  /// **'Remove promo code'**
  String get payments_removePromoCode;

  /// No description provided for @payments_yourSeat.
  ///
  /// In en, this message translates to:
  /// **'Your seat'**
  String get payments_yourSeat;

  /// No description provided for @payments_seatNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Seat not selected'**
  String get payments_seatNotSelected;

  /// No description provided for @payments_seatNumber.
  ///
  /// In en, this message translates to:
  /// **'Seat {seat}'**
  String payments_seatNumber(String seat);

  /// No description provided for @payments_vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get payments_vehicle;

  /// No description provided for @payments_driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get payments_driver;

  /// No description provided for @payments_directTrip.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get payments_directTrip;

  /// No description provided for @booking_bookYourSeat.
  ///
  /// In en, this message translates to:
  /// **'Book your seat'**
  String get booking_bookYourSeat;

  /// No description provided for @booking_bookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Booking Failed'**
  String get booking_bookingFailed;

  /// No description provided for @booking_seatJustTaken.
  ///
  /// In en, this message translates to:
  /// **'This seat was just taken. Please go back and choose another seat.'**
  String get booking_seatJustTaken;

  /// No description provided for @booking_seatHoldExpired.
  ///
  /// In en, this message translates to:
  /// **'Your seat hold expired. Please select your seat again.'**
  String get booking_seatHoldExpired;

  /// No description provided for @booking_duplicateActiveBooking.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending booking for this trip. Please continue payment from your existing booking.'**
  String get booking_duplicateActiveBooking;

  /// No description provided for @booking_openMyBookings.
  ///
  /// In en, this message translates to:
  /// **'Open My Bookings'**
  String get booking_openMyBookings;

  /// No description provided for @booking_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get booking_ok;

  /// No description provided for @booking_referenceNotCreated.
  ///
  /// In en, this message translates to:
  /// **'The booking reference was not created.'**
  String get booking_referenceNotCreated;

  /// No description provided for @booking_cardPaymentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Card payment is not available right now.'**
  String get booking_cardPaymentUnavailable;

  /// No description provided for @booking_cardPaymentNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Card payment was not completed. Your booking remains pending.'**
  String get booking_cardPaymentNotCompleted;

  /// No description provided for @booking_cardPaymentDeclined.
  ///
  /// In en, this message translates to:
  /// **'Your card was declined and you have not been charged. Your seat is still held — try another card or payment method.'**
  String get booking_cardPaymentDeclined;

  /// No description provided for @booking_viewVehicleAndPhotos.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & photos'**
  String get booking_viewVehicleAndPhotos;

  /// No description provided for @booking_vehiclePhotosUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No photos of this vehicle yet'**
  String get booking_vehiclePhotosUnavailable;

  /// No description provided for @booking_noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'Not rated yet'**
  String get booking_noRatingsYet;

  /// No description provided for @booking_ratingWithCount.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count})'**
  String booking_ratingWithCount(String rating, int count);

  /// No description provided for @booking_vehicleCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get booking_vehicleCapacityLabel;

  /// No description provided for @booking_vehicleSeatsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} seats'**
  String booking_vehicleSeatsCount(int count);

  /// No description provided for @booking_vehiclePlate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get booking_vehiclePlate;

  /// No description provided for @booking_vehicleYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get booking_vehicleYear;

  /// No description provided for @booking_vehicleColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get booking_vehicleColor;

  /// No description provided for @trips_statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get trips_statusInProgress;

  /// No description provided for @trips_paymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get trips_paymentPaid;

  /// No description provided for @trips_paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get trips_paymentPending;

  /// No description provided for @trips_paymentUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get trips_paymentUnderReview;

  /// No description provided for @trips_paymentRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get trips_paymentRefunded;

  /// No description provided for @trips_paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get trips_paymentFailed;

  /// No description provided for @trips_driverBadgeAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get trips_driverBadgeAssigned;

  /// No description provided for @trips_driverBadgeEnRoute.
  ///
  /// In en, this message translates to:
  /// **'En route'**
  String get trips_driverBadgeEnRoute;

  /// No description provided for @trips_driverBadgeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip complete'**
  String get trips_driverBadgeCompleted;

  /// No description provided for @trips_driverBadgeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled'**
  String get trips_driverBadgeCancelled;

  /// No description provided for @trips_liveLoadingPosition.
  ///
  /// In en, this message translates to:
  /// **'Loading live position…'**
  String get trips_liveLoadingPosition;

  /// No description provided for @trips_livePositionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live position unavailable right now.'**
  String get trips_livePositionUnavailable;

  /// No description provided for @trips_liveWaitingForVehicle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the vehicle\'s live position…'**
  String get trips_liveWaitingForVehicle;

  /// No description provided for @trips_liveRouteCoveredPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the route covered'**
  String trips_liveRouteCoveredPercent(int percent);

  /// No description provided for @trips_liveTripInProgress.
  ///
  /// In en, this message translates to:
  /// **'Your trip is in progress'**
  String get trips_liveTripInProgress;

  /// No description provided for @trips_liveTrackButton.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get trips_liveTrackButton;

  /// No description provided for @payments_continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get payments_continueLabel;

  /// No description provided for @payments_payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payments_payNow;

  /// No description provided for @payments_missingBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Some booking details are missing.'**
  String get payments_missingBookingDetails;

  /// No description provided for @payments_choosePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose a payment method to continue.'**
  String get payments_choosePaymentMethod;

  /// No description provided for @payments_walletShortByAmount.
  ///
  /// In en, this message translates to:
  /// **'Your wallet is {amount} short of this fare.'**
  String payments_walletShortByAmount(String amount);

  /// No description provided for @support_minLengthHint.
  ///
  /// In en, this message translates to:
  /// **'Please add a bit more detail'**
  String get support_minLengthHint;

  /// No description provided for @support_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get support_refresh;

  /// No description provided for @support_centerTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Center'**
  String get support_centerTitle;

  /// No description provided for @support_categoryBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking Issue'**
  String get support_categoryBooking;

  /// No description provided for @support_categoryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment Issue'**
  String get support_categoryPayment;

  /// No description provided for @support_categoryTripDelay.
  ///
  /// In en, this message translates to:
  /// **'Trip Delay'**
  String get support_categoryTripDelay;

  /// No description provided for @support_categoryDriverVehicle.
  ///
  /// In en, this message translates to:
  /// **'Driver or Vehicle Issue'**
  String get support_categoryDriverVehicle;

  /// No description provided for @support_categorySubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription Issue'**
  String get support_categorySubscription;

  /// No description provided for @support_categoryLostItem.
  ///
  /// In en, this message translates to:
  /// **'Lost Item'**
  String get support_categoryLostItem;

  /// No description provided for @support_categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get support_categoryOther;

  /// No description provided for @support_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get support_emptyTitle;

  /// No description provided for @support_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'When you open a ticket it will appear here, along with its status and every reply from our team.'**
  String get support_emptyBody;

  /// No description provided for @support_uploadPrompt.
  ///
  /// In en, this message translates to:
  /// **'Upload image or document'**
  String get support_uploadPrompt;

  /// No description provided for @support_uploadHint.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG, or PDF up to 5MB'**
  String get support_uploadHint;

  /// No description provided for @support_removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get support_removeAttachment;

  /// No description provided for @support_myTickets.
  ///
  /// In en, this message translates to:
  /// **'My tickets'**
  String get support_myTickets;

  /// No description provided for @support_statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get support_statusSubmitted;

  /// No description provided for @support_statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get support_statusUnderReview;

  /// No description provided for @support_statusContacted.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get support_statusContacted;

  /// No description provided for @support_statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get support_statusResolved;

  /// No description provided for @support_statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get support_statusClosed;

  /// No description provided for @support_statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get support_statusRejected;

  /// No description provided for @support_timelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No timeline events available.'**
  String get support_timelineEmpty;

  /// No description provided for @support_heroTitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get support_heroTitle;

  /// No description provided for @support_heroBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong and our team will follow up on your ticket. We usually reply within a few hours.'**
  String get support_heroBody;

  /// No description provided for @support_createTicket.
  ///
  /// In en, this message translates to:
  /// **'Create a ticket'**
  String get support_createTicket;

  /// No description provided for @support_topicLabel.
  ///
  /// In en, this message translates to:
  /// **'What is this about?'**
  String get support_topicLabel;

  /// No description provided for @support_topicHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the topic closest to your issue.'**
  String get support_topicHint;

  /// No description provided for @support_officeLabel.
  ///
  /// In en, this message translates to:
  /// **'Which office is this about?'**
  String get support_officeLabel;

  /// No description provided for @support_officeHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the office your complaint concerns so it reaches their team.'**
  String get support_officeHint;

  /// No description provided for @support_officePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select an office'**
  String get support_officePlaceholder;

  /// No description provided for @support_officeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please choose an office'**
  String get support_officeRequired;

  /// No description provided for @support_officeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load offices.'**
  String get support_officeLoadError;

  /// No description provided for @support_attachmentOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open attachment.'**
  String get support_attachmentOpenFailed;

  /// No description provided for @support_subjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get support_subjectLabel;

  /// No description provided for @support_subjectHint.
  ///
  /// In en, this message translates to:
  /// **'A short summary of the problem.'**
  String get support_subjectHint;

  /// No description provided for @support_subjectPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Charged twice for one booking'**
  String get support_subjectPlaceholder;

  /// No description provided for @support_subjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Subject is required'**
  String get support_subjectRequired;

  /// No description provided for @support_detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get support_detailsLabel;

  /// No description provided for @support_detailsHint.
  ///
  /// In en, this message translates to:
  /// **'What happened, and when? Add your trip or booking reference if you have it.'**
  String get support_detailsHint;

  /// No description provided for @support_detailsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue…'**
  String get support_detailsPlaceholder;

  /// No description provided for @support_detailsRequired.
  ///
  /// In en, this message translates to:
  /// **'Details are required'**
  String get support_detailsRequired;

  /// No description provided for @support_relatedBookingLabel.
  ///
  /// In en, this message translates to:
  /// **'Related booking'**
  String get support_relatedBookingLabel;

  /// No description provided for @support_relatedBookingHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — pick the booking this is about so it reaches the right office.'**
  String get support_relatedBookingHint;

  /// No description provided for @support_relatedBookingNone.
  ///
  /// In en, this message translates to:
  /// **'Not about a specific booking'**
  String get support_relatedBookingNone;

  /// No description provided for @support_attachmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get support_attachmentLabel;

  /// No description provided for @support_attachmentHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — a screenshot or receipt helps us a lot.'**
  String get support_attachmentHint;

  /// No description provided for @support_submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get support_submitting;

  /// No description provided for @support_submitTicket.
  ///
  /// In en, this message translates to:
  /// **'Submit ticket'**
  String get support_submitTicket;

  /// No description provided for @support_newTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get support_newTicketTitle;

  /// No description provided for @support_ticketCreatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Ticket created. Our team will get back to you shortly.'**
  String get support_ticketCreatedSnack;

  /// No description provided for @support_ticketCreatedAttachmentFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Ticket submitted, but the attachment failed to upload.'**
  String get support_ticketCreatedAttachmentFailedSnack;

  /// No description provided for @support_ticketNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket {number}'**
  String support_ticketNumberTitle(String number);

  /// No description provided for @support_ticketDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket details'**
  String get support_ticketDetailsTitle;

  /// No description provided for @support_failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ticket details'**
  String get support_failedToLoad;

  /// No description provided for @support_reviewingNotice.
  ///
  /// In en, this message translates to:
  /// **'Our customer service team is reviewing your ticket and may contact you shortly.'**
  String get support_reviewingNotice;

  /// No description provided for @support_currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get support_currentStatus;

  /// No description provided for @support_assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get support_assignedTo;

  /// No description provided for @support_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get support_description;

  /// No description provided for @support_customerServiceNote.
  ///
  /// In en, this message translates to:
  /// **'Customer Service Note'**
  String get support_customerServiceNote;

  /// No description provided for @support_attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get support_attachments;

  /// No description provided for @booking_tapToChoosePickupStation.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a pickup station'**
  String get booking_tapToChoosePickupStation;

  /// No description provided for @booking_noMappedPickupStations.
  ///
  /// In en, this message translates to:
  /// **'No mapped pickup stations are available'**
  String get booking_noMappedPickupStations;

  /// No description provided for @booking_tapToChooseDestination.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a destination'**
  String get booking_tapToChooseDestination;

  /// No description provided for @booking_noMappedDestinations.
  ///
  /// In en, this message translates to:
  /// **'No mapped destinations are available'**
  String get booking_noMappedDestinations;

  /// No description provided for @booking_mapCouldNotBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Map could not be loaded'**
  String get booking_mapCouldNotBeLoaded;

  /// No description provided for @common_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get common_tomorrow;

  /// No description provided for @common_durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String common_durationMinutes(int minutes);

  /// No description provided for @common_durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String common_durationHours(int hours);

  /// No description provided for @common_durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String common_durationHoursMinutes(int hours, int minutes);

  /// No description provided for @seatSelection_selectYourSeat.
  ///
  /// In en, this message translates to:
  /// **'Select Your Seat'**
  String get seatSelection_selectYourSeat;

  /// No description provided for @seatSelection_seatsFreeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} free'**
  String seatSelection_seatsFreeCount(int count);

  /// No description provided for @seatSelection_chooseASeat.
  ///
  /// In en, this message translates to:
  /// **'Choose a seat'**
  String get seatSelection_chooseASeat;

  /// No description provided for @seatSelection_tapSeatToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap an available seat to continue'**
  String get seatSelection_tapSeatToContinue;

  /// No description provided for @seatSelection_seatsOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String seatSelection_seatsOpenCount(int count);

  /// No description provided for @seatSelection_microbusCapacity.
  ///
  /// In en, this message translates to:
  /// **'15-seat microbus'**
  String get seatSelection_microbusCapacity;

  /// No description provided for @seatSelection_frontOfVehicle.
  ///
  /// In en, this message translates to:
  /// **'FRONT OF VEHICLE'**
  String get seatSelection_frontOfVehicle;

  /// No description provided for @seatSelection_cabinLayout.
  ///
  /// In en, this message translates to:
  /// **'Cabin layout'**
  String get seatSelection_cabinLayout;

  /// No description provided for @seatSelection_cabinDoor.
  ///
  /// In en, this message translates to:
  /// **'Door'**
  String get seatSelection_cabinDoor;

  /// No description provided for @seatSelection_cabinRear.
  ///
  /// In en, this message translates to:
  /// **'REAR'**
  String get seatSelection_cabinRear;

  /// No description provided for @seatSelection_driverCabinNote.
  ///
  /// In en, this message translates to:
  /// **'Seats 1 and 2 are reserved for the driver cabin'**
  String get seatSelection_driverCabinNote;

  /// No description provided for @seatSelection_driverCabinLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver Cabin'**
  String get seatSelection_driverCabinLabel;

  /// No description provided for @seatSelection_selectSeatToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select one seat to continue'**
  String get seatSelection_selectSeatToContinue;

  /// No description provided for @seatSelection_tapAvailableSeatHint.
  ///
  /// In en, this message translates to:
  /// **'Tap one available seat on the layout above.'**
  String get seatSelection_tapAvailableSeatHint;

  /// No description provided for @seatSelection_seatSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat {seatNum} selected'**
  String seatSelection_seatSelectedTitle(String seatNum);

  /// No description provided for @seatSelection_seatSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'1 seat · EGP {price} each · Total EGP {total}'**
  String seatSelection_seatSummaryLine(String price, String total);

  /// No description provided for @seatSelection_hintCardBody.
  ///
  /// In en, this message translates to:
  /// **'Middle rows use a pair on the left and a single seat on the right for a more realistic shuttle layout.'**
  String get seatSelection_hintCardBody;

  /// No description provided for @seatSelection_departsAt.
  ///
  /// In en, this message translates to:
  /// **'Departs {time}'**
  String seatSelection_departsAt(String time);

  /// No description provided for @seatSelection_selectedSeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected seat'**
  String get seatSelection_selectedSeatLabel;

  /// No description provided for @seatSelection_seatNumbersLabel.
  ///
  /// In en, this message translates to:
  /// **'Seat numbers'**
  String get seatSelection_seatNumbersLabel;

  /// No description provided for @seatSelection_perSeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Per seat'**
  String get seatSelection_perSeatLabel;

  /// No description provided for @seatSelection_reservingSeat.
  ///
  /// In en, this message translates to:
  /// **'Reserving seat...'**
  String get seatSelection_reservingSeat;

  /// No description provided for @seatSelection_continueBooking.
  ///
  /// In en, this message translates to:
  /// **'Continue Booking'**
  String get seatSelection_continueBooking;

  /// No description provided for @seatSelection_selectASeat.
  ///
  /// In en, this message translates to:
  /// **'Select a Seat'**
  String get seatSelection_selectASeat;

  /// No description provided for @seatSelection_seatCountSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} seat selected'**
  String seatSelection_seatCountSelected(int count);

  /// No description provided for @seatSelection_passengerInformation.
  ///
  /// In en, this message translates to:
  /// **'Passenger information'**
  String get seatSelection_passengerInformation;

  /// No description provided for @seatSelection_contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get seatSelection_contactDetails;

  /// No description provided for @seatSelection_passengerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Passenger name'**
  String get seatSelection_passengerNameLabel;

  /// No description provided for @seatSelection_fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name as on ID'**
  String get seatSelection_fullNameHint;

  /// No description provided for @seatSelection_passengerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Passenger phone number'**
  String get seatSelection_passengerPhoneLabel;

  /// No description provided for @seatSelection_phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+20 10 1234 5678'**
  String get seatSelection_phoneHint;

  /// No description provided for @seatSelection_phoneUsageNote.
  ///
  /// In en, this message translates to:
  /// **'We will use this number for trip updates.'**
  String get seatSelection_phoneUsageNote;

  /// No description provided for @seatSelection_saveDetails.
  ///
  /// In en, this message translates to:
  /// **'Save details'**
  String get seatSelection_saveDetails;

  /// No description provided for @seatSelection_bookingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking summary'**
  String get seatSelection_bookingSummaryTitle;

  /// No description provided for @seatSelection_pricePerSeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per seat'**
  String get seatSelection_pricePerSeatLabel;

  /// No description provided for @seatSelection_totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get seatSelection_totalAmountLabel;

  /// No description provided for @seatSelection_seatLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat legend'**
  String get seatSelection_seatLegendTitle;

  /// No description provided for @seatSelection_seatStatusSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get seatSelection_seatStatusSelected;

  /// No description provided for @seatSelection_seatStatusReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get seatSelection_seatStatusReserved;

  /// No description provided for @seatSelection_passengersTitle.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get seatSelection_passengersTitle;

  /// No description provided for @seatSelection_oneSeatBadge.
  ///
  /// In en, this message translates to:
  /// **'1 seat'**
  String get seatSelection_oneSeatBadge;

  /// No description provided for @seatSelection_addPassengerHint.
  ///
  /// In en, this message translates to:
  /// **'Select another seat to add a passenger (UI preview)'**
  String get seatSelection_addPassengerHint;

  /// No description provided for @seatSelection_awaitingSeatSelection.
  ///
  /// In en, this message translates to:
  /// **'Awaiting seat selection'**
  String get seatSelection_awaitingSeatSelection;

  /// No description provided for @seatSelection_passengerIndexLabel.
  ///
  /// In en, this message translates to:
  /// **'Passenger {index}'**
  String seatSelection_passengerIndexLabel(int index);

  /// No description provided for @seatSelection_seatsLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'seats left'**
  String get seatSelection_seatsLeftLabel;

  /// No description provided for @seatSelection_acStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'A/C · {status}'**
  String seatSelection_acStatusLabel(String status);

  /// No description provided for @seatSelection_lockErrorSeatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Seat is no longer available. Please choose another seat.'**
  String get seatSelection_lockErrorSeatUnavailable;

  /// No description provided for @payments_stepFintechConnection.
  ///
  /// In en, this message translates to:
  /// **'Establishing secure fintech connection...'**
  String get payments_stepFintechConnection;

  /// No description provided for @payments_stepVerifyingAccount.
  ///
  /// In en, this message translates to:
  /// **'Verifying account status and limit...'**
  String get payments_stepVerifyingAccount;

  /// No description provided for @payments_stepReservingSeat.
  ///
  /// In en, this message translates to:
  /// **'Reserving seat and finalising ticket metadata...'**
  String get payments_stepReservingSeat;

  /// No description provided for @payments_pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get payments_pendingLabel;

  /// No description provided for @payments_methodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method:'**
  String get payments_methodLabel;

  /// No description provided for @payments_transactionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID:'**
  String get payments_transactionIdLabel;

  /// No description provided for @payments_driverSeatSummary.
  ///
  /// In en, this message translates to:
  /// **'Driver: {driver} • Seat: {seat}'**
  String payments_driverSeatSummary(String driver, String seat);

  /// No description provided for @payments_processingPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing Payment'**
  String get payments_processingPaymentTitle;

  /// No description provided for @payments_doNotCloseScreen.
  ///
  /// In en, this message translates to:
  /// **'Please do not close this screen or press back button.'**
  String get payments_doNotCloseScreen;

  /// No description provided for @payments_secureCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Checkout'**
  String get payments_secureCheckoutTitle;

  /// No description provided for @payments_paymobCheckoutOpened.
  ///
  /// In en, this message translates to:
  /// **'Paymob Checkout Opened'**
  String get payments_paymobCheckoutOpened;

  /// No description provided for @payments_paymentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Payment Submitted'**
  String get payments_paymentSubmitted;

  /// No description provided for @payments_completeCardPaymentPaymob.
  ///
  /// In en, this message translates to:
  /// **'Complete card payment in the secure Paymob page.'**
  String get payments_completeCardPaymentPaymob;

  /// No description provided for @payments_receiptSentForReview.
  ///
  /// In en, this message translates to:
  /// **'Your receipt was sent for operations review.'**
  String get payments_receiptSentForReview;

  /// No description provided for @payments_bookingRefLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking Ref:'**
  String get payments_bookingRefLabel;

  /// No description provided for @payments_paidAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount:'**
  String get payments_paidAmountLabel;

  /// No description provided for @payments_paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method:'**
  String get payments_paymentMethodLabel;

  /// No description provided for @payments_viewTicket.
  ///
  /// In en, this message translates to:
  /// **'View Ticket'**
  String get payments_viewTicket;

  /// No description provided for @payments_backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get payments_backToHome;

  /// No description provided for @payments_paymentFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get payments_paymentFailedTitle;

  /// No description provided for @payments_transactionNotProcessed.
  ///
  /// In en, this message translates to:
  /// **'Your transaction could not be processed.'**
  String get payments_transactionNotProcessed;

  /// No description provided for @payments_reasonForFailure.
  ///
  /// In en, this message translates to:
  /// **'Reason for Failure'**
  String get payments_reasonForFailure;

  /// No description provided for @payments_paymentNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment could not be completed.'**
  String get payments_paymentNotCompleted;

  /// No description provided for @payments_retryPayment.
  ///
  /// In en, this message translates to:
  /// **'Retry Payment'**
  String get payments_retryPayment;

  /// No description provided for @payments_contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get payments_contactSupport;

  /// No description provided for @payments_contactCustomerSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Customer Support'**
  String get payments_contactCustomerSupportTitle;

  /// No description provided for @payments_supportDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Our customer support agents are ready to assist you. Reference ticket number: {ticketNumber}'**
  String payments_supportDialogBody(String ticketNumber);

  /// No description provided for @payments_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get payments_close;

  /// No description provided for @trips_newCaptain.
  ///
  /// In en, this message translates to:
  /// **'New captain'**
  String get trips_newCaptain;

  /// No description provided for @trips_ratingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rating} other{{count} ratings}}'**
  String trips_ratingsCount(int count);

  /// No description provided for @trips_verifiedCaptain.
  ///
  /// In en, this message translates to:
  /// **'Verified captain'**
  String get trips_verifiedCaptain;

  /// No description provided for @trips_factDeparts.
  ///
  /// In en, this message translates to:
  /// **'Departs'**
  String get trips_factDeparts;

  /// No description provided for @trips_factSeat.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get trips_factSeat;

  /// No description provided for @trips_seatNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get trips_seatNotAssigned;

  /// No description provided for @trips_completedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String trips_completedAt(String date);

  /// No description provided for @trips_boardingPassTitle.
  ///
  /// In en, this message translates to:
  /// **'Boarding pass'**
  String get trips_boardingPassTitle;

  /// No description provided for @trips_boardingOnBoard.
  ///
  /// In en, this message translates to:
  /// **'On board'**
  String get trips_boardingOnBoard;

  /// No description provided for @trips_boardingReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get trips_boardingReady;

  /// No description provided for @trips_bookingRefLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking ref'**
  String get trips_bookingRefLabel;

  /// No description provided for @trips_boardingOnBoardNote.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your ride — the captain has your seat on the manifest.'**
  String get trips_boardingOnBoardNote;

  /// No description provided for @trips_boardingReadyNote.
  ///
  /// In en, this message translates to:
  /// **'Show this reference to the captain when you board.'**
  String get trips_boardingReadyNote;

  /// No description provided for @trips_detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get trips_detailsTitle;

  /// No description provided for @trips_cancellationReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reason'**
  String get trips_cancellationReasonTitle;

  /// No description provided for @trips_completedRatedNote.
  ///
  /// In en, this message translates to:
  /// **'You rated this trip. Tap to see the review you left.'**
  String get trips_completedRatedNote;

  /// No description provided for @trips_completedRateInvite.
  ///
  /// In en, this message translates to:
  /// **'Help us improve by rating your trip with {driverName}.'**
  String trips_completedRateInvite(String driverName);

  /// No description provided for @trips_actionChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get trips_actionChat;

  /// No description provided for @trips_driverPhoneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Driver phone number is not available.'**
  String get trips_driverPhoneUnavailable;

  /// No description provided for @trips_callFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start a call to {phone}.'**
  String trips_callFailed(String phone);

  /// No description provided for @trips_seatLegendYours.
  ///
  /// In en, this message translates to:
  /// **'Your seat'**
  String get trips_seatLegendYours;

  /// No description provided for @trips_seatLegendAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get trips_seatLegendAvailable;

  /// No description provided for @trips_seatLegendTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get trips_seatLegendTaken;

  /// No description provided for @trips_seatMapDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get trips_seatMapDriverLabel;

  /// No description provided for @trips_yourSeatsPlural.
  ///
  /// In en, this message translates to:
  /// **'Your seats'**
  String get trips_yourSeatsPlural;

  /// No description provided for @trips_seatPending.
  ///
  /// In en, this message translates to:
  /// **'Seat pending'**
  String get trips_seatPending;

  /// No description provided for @trips_driverPending.
  ///
  /// In en, this message translates to:
  /// **'Driver Pending'**
  String get trips_driverPending;

  /// No description provided for @trips_vehiclePending.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Pending'**
  String get trips_vehiclePending;

  /// No description provided for @trips_routePointUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get trips_routePointUnknown;

  /// No description provided for @trips_awaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get trips_awaitingConfirmation;

  /// No description provided for @trips_seatsAvailableOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{available} of {total}'**
  String trips_seatsAvailableOfTotal(int available, int total);

  /// No description provided for @trips_seatsFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'seats free'**
  String get trips_seatsFreeLabel;

  /// No description provided for @trips_viewFullSeatMap.
  ///
  /// In en, this message translates to:
  /// **'View full seat map'**
  String get trips_viewFullSeatMap;

  /// No description provided for @trips_seatPendingAssignment.
  ///
  /// In en, this message translates to:
  /// **'A seat will be assigned once your booking is confirmed.'**
  String get trips_seatPendingAssignment;

  /// No description provided for @trips_vehicleCode.
  ///
  /// In en, this message translates to:
  /// **'Vehicle code: {code}'**
  String trips_vehicleCode(String code);

  /// No description provided for @trips_trackVehicleButton.
  ///
  /// In en, this message translates to:
  /// **'Track Vehicle'**
  String get trips_trackVehicleButton;

  /// No description provided for @trips_cancellingInFlight.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get trips_cancellingInFlight;

  /// No description provided for @trips_cancelTripButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Trip'**
  String get trips_cancelTripButton;

  /// No description provided for @trips_captainSubtitleFinished.
  ///
  /// In en, this message translates to:
  /// **'Who drove you'**
  String get trips_captainSubtitleFinished;

  /// No description provided for @trips_captainSubtitleActive.
  ///
  /// In en, this message translates to:
  /// **'Who is driving you'**
  String get trips_captainSubtitleActive;

  /// No description provided for @trips_vehicleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The bus on this trip'**
  String get trips_vehicleSubtitle;

  /// No description provided for @trips_seatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your seats on the cabin map'**
  String get trips_seatsSubtitle;

  /// No description provided for @trips_paymentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Status and fare breakdown'**
  String get trips_paymentSubtitle;

  /// No description provided for @trips_paymentNotePaid.
  ///
  /// In en, this message translates to:
  /// **'Your payment is confirmed.'**
  String get trips_paymentNotePaid;

  /// No description provided for @trips_paymentNotePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your payment.'**
  String get trips_paymentNotePending;

  /// No description provided for @trips_paymentNoteUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Our team is reviewing your payment.'**
  String get trips_paymentNoteUnderReview;

  /// No description provided for @trips_paymentNoteRefunded.
  ///
  /// In en, this message translates to:
  /// **'This fare was refunded to you.'**
  String get trips_paymentNoteRefunded;

  /// No description provided for @trips_paymentNoteFailed.
  ///
  /// In en, this message translates to:
  /// **'The payment did not go through.'**
  String get trips_paymentNoteFailed;

  /// No description provided for @trips_paymentNoteCancelled.
  ///
  /// In en, this message translates to:
  /// **'This booking was cancelled.'**
  String get trips_paymentNoteCancelled;

  /// No description provided for @trips_discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get trips_discountLabel;

  /// No description provided for @trips_seatMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat map'**
  String get trips_seatMapTitle;

  /// No description provided for @trips_seatMapTitleWithVehicle.
  ///
  /// In en, this message translates to:
  /// **'Seat map · {vehicle}'**
  String trips_seatMapTitleWithVehicle(String vehicle);

  /// No description provided for @trips_cancelSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Trip {reference} was cancelled and your seat is available again.'**
  String trips_cancelSuccessMessage(String reference);

  /// No description provided for @seatRelease_hubTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat Release Hub'**
  String get seatRelease_hubTitle;

  /// No description provided for @seatRelease_formTitle.
  ///
  /// In en, this message translates to:
  /// **'Release Reserved Seat'**
  String get seatRelease_formTitle;

  /// No description provided for @seatRelease_successTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat Released Successfully'**
  String get seatRelease_successTitle;

  /// No description provided for @seatRelease_detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Release Record Details'**
  String get seatRelease_detailsTitle;

  /// No description provided for @seatRelease_compensationTitle.
  ///
  /// In en, this message translates to:
  /// **'Compensation Tracking'**
  String get seatRelease_compensationTitle;

  /// No description provided for @seatRelease_historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat Release Logs'**
  String get seatRelease_historyTitle;

  /// No description provided for @seatRelease_notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts Notifications'**
  String get seatRelease_notificationsTitle;

  /// No description provided for @seatRelease_achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones & Achievements'**
  String get seatRelease_achievementsTitle;

  /// No description provided for @seatRelease_portalTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat Release Portal'**
  String get seatRelease_portalTitle;

  /// No description provided for @seatRelease_notifCompensationAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Compensation Added'**
  String get seatRelease_notifCompensationAddedTitle;

  /// No description provided for @seatRelease_notifCompensationAddedBody.
  ///
  /// In en, this message translates to:
  /// **'Your released seat on Jun 2 was rebooked. EGP 50 cashback credited to your wallet!'**
  String get seatRelease_notifCompensationAddedBody;

  /// No description provided for @seatRelease_timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get seatRelease_timeYesterday;

  /// No description provided for @seatRelease_notifRebookedTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat Rebooked Successfully'**
  String get seatRelease_notifRebookedTitle;

  /// No description provided for @seatRelease_notifRebookedBody.
  ///
  /// In en, this message translates to:
  /// **'A passenger has booked your released seat for the trip on Jun 2.'**
  String get seatRelease_notifRebookedBody;

  /// No description provided for @seatRelease_timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String seatRelease_timeDaysAgo(int count);

  /// No description provided for @seatRelease_notifReleasedTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat Released Successfully'**
  String get seatRelease_notifReleasedTitle;

  /// No description provided for @seatRelease_notifReleasedBody.
  ///
  /// In en, this message translates to:
  /// **'You successfully released your seat (Seat {seat}) for the {date} trip.'**
  String seatRelease_notifReleasedBody(String seat, String date);

  /// No description provided for @seatRelease_tripDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip Date'**
  String get seatRelease_tripDateLabel;

  /// No description provided for @seatRelease_seatNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Seat Number'**
  String get seatRelease_seatNumberLabel;

  /// No description provided for @seatRelease_actionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Seat release isn\'t available yet'**
  String get seatRelease_actionUnavailable;

  /// No description provided for @seatRelease_statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get seatRelease_statusWaiting;

  /// No description provided for @seatRelease_statusRebooked.
  ///
  /// In en, this message translates to:
  /// **'Rebooked'**
  String get seatRelease_statusRebooked;

  /// No description provided for @seatRelease_statusRewarded.
  ///
  /// In en, this message translates to:
  /// **'Rewarded'**
  String get seatRelease_statusRewarded;

  /// No description provided for @seatRelease_statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get seatRelease_statusClosed;

  /// No description provided for @seatRelease_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get seatRelease_filterAll;

  /// No description provided for @seatRelease_timelineStepReleased.
  ///
  /// In en, this message translates to:
  /// **'Seat Released'**
  String get seatRelease_timelineStepReleased;

  /// No description provided for @seatRelease_timelineStepWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting For Rebooking'**
  String get seatRelease_timelineStepWaiting;

  /// No description provided for @seatRelease_timelineStepRebooked.
  ///
  /// In en, this message translates to:
  /// **'Rebooked Successfully'**
  String get seatRelease_timelineStepRebooked;

  /// No description provided for @seatRelease_timelineReleasedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your seat has been released for commute pools.'**
  String get seatRelease_timelineReleasedDesc;

  /// No description provided for @seatRelease_timelineWaitingDesc.
  ///
  /// In en, this message translates to:
  /// **'Seat is currently listed. Waiting for other daily passenger bookings.'**
  String get seatRelease_timelineWaitingDesc;

  /// No description provided for @seatRelease_timelineRebookedDesc.
  ///
  /// In en, this message translates to:
  /// **'Seat was successfully rebooked by another commuter.'**
  String get seatRelease_timelineRebookedDesc;

  /// No description provided for @seatRelease_timelineRewardedDesc.
  ///
  /// In en, this message translates to:
  /// **'Compensation reward credited directly to your wallet account.'**
  String get seatRelease_timelineRewardedDesc;

  /// No description provided for @seatRelease_upcomingReservedSeatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Reserved Seats'**
  String get seatRelease_upcomingReservedSeatsTitle;

  /// No description provided for @seatRelease_noUpcomingTripsMessage.
  ///
  /// In en, this message translates to:
  /// **'No upcoming package trips\nAll upcoming seats are active, or no remaining days remain.'**
  String get seatRelease_noUpcomingTripsMessage;

  /// No description provided for @seatRelease_validityRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'VALIDITY RANGE'**
  String get seatRelease_validityRangeLabel;

  /// No description provided for @seatRelease_seatNoLabel.
  ///
  /// In en, this message translates to:
  /// **'SEAT NO.'**
  String get seatRelease_seatNoLabel;

  /// No description provided for @seatRelease_statRemainingDays.
  ///
  /// In en, this message translates to:
  /// **'Remaining Days'**
  String get seatRelease_statRemainingDays;

  /// No description provided for @seatRelease_statReleasedSeats.
  ///
  /// In en, this message translates to:
  /// **'Released Seats'**
  String get seatRelease_statReleasedSeats;

  /// No description provided for @seatRelease_statRebookedSeats.
  ///
  /// In en, this message translates to:
  /// **'Rebooked Seats'**
  String get seatRelease_statRebookedSeats;

  /// No description provided for @seatRelease_statEarnedReward.
  ///
  /// In en, this message translates to:
  /// **'Earned Reward'**
  String get seatRelease_statEarnedReward;

  /// No description provided for @seatRelease_daysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} Days'**
  String seatRelease_daysCount(int days);

  /// No description provided for @seatRelease_egpAmount.
  ///
  /// In en, this message translates to:
  /// **'EGP {amount}'**
  String seatRelease_egpAmount(String amount);

  /// No description provided for @seatRelease_quickLinkReleaseLogs.
  ///
  /// In en, this message translates to:
  /// **'Release Logs'**
  String get seatRelease_quickLinkReleaseLogs;

  /// No description provided for @seatRelease_quickLinkRewardsStats.
  ///
  /// In en, this message translates to:
  /// **'Rewards & Stats'**
  String get seatRelease_quickLinkRewardsStats;

  /// No description provided for @seatRelease_viewLogsButton.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get seatRelease_viewLogsButton;

  /// No description provided for @seatRelease_releaseSeatButton.
  ///
  /// In en, this message translates to:
  /// **'Release Seat'**
  String get seatRelease_releaseSeatButton;

  /// No description provided for @seatRelease_noPastRecordSnackbar.
  ///
  /// In en, this message translates to:
  /// **'No past release record exists for this date.'**
  String get seatRelease_noPastRecordSnackbar;

  /// No description provided for @seatRelease_reasonSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reason for Releasing Seat'**
  String get seatRelease_reasonSectionTitle;

  /// No description provided for @seatRelease_optionalNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional Notes'**
  String get seatRelease_optionalNotesTitle;

  /// No description provided for @seatRelease_notesHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., Working from home on Thursday...'**
  String get seatRelease_notesHint;

  /// No description provided for @seatRelease_whyReleaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Why release your seat?'**
  String get seatRelease_whyReleaseTitle;

  /// No description provided for @seatRelease_releasingTemporaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Releasing is Temporary'**
  String get seatRelease_releasingTemporaryTitle;

  /// No description provided for @seatRelease_releasingTemporaryBody.
  ///
  /// In en, this message translates to:
  /// **'You are releasing your reserved seat for this trip date only. Your package subscription remains active and future trip bookings return automatically.'**
  String get seatRelease_releasingTemporaryBody;

  /// No description provided for @seatRelease_thresholdTitle.
  ///
  /// In en, this message translates to:
  /// **'12-Hour Threshold Requirement'**
  String get seatRelease_thresholdTitle;

  /// No description provided for @seatRelease_thresholdBody.
  ///
  /// In en, this message translates to:
  /// **'Seat release is only available if submitted at least 12 hours before trip departure. Late requests will not be accepted.'**
  String get seatRelease_thresholdBody;

  /// No description provided for @seatRelease_reasonPersonalPlans.
  ///
  /// In en, this message translates to:
  /// **'Personal plans'**
  String get seatRelease_reasonPersonalPlans;

  /// No description provided for @seatRelease_reasonWorkFromHome.
  ///
  /// In en, this message translates to:
  /// **'Working from home'**
  String get seatRelease_reasonWorkFromHome;

  /// No description provided for @seatRelease_reasonVacation.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get seatRelease_reasonVacation;

  /// No description provided for @seatRelease_reasonAlternativeTransport.
  ///
  /// In en, this message translates to:
  /// **'Alternative transport'**
  String get seatRelease_reasonAlternativeTransport;

  /// No description provided for @seatRelease_reasonMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical reason'**
  String get seatRelease_reasonMedical;

  /// No description provided for @seatRelease_reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get seatRelease_reasonOther;

  /// No description provided for @seatRelease_benefitCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Help the Community'**
  String get seatRelease_benefitCommunityTitle;

  /// No description provided for @seatRelease_benefitCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'Released seats become available for other passengers needing daily rides.'**
  String get seatRelease_benefitCommunityBody;

  /// No description provided for @seatRelease_benefitCompensationTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn Compensation'**
  String get seatRelease_benefitCompensationTitle;

  /// No description provided for @seatRelease_benefitCompensationBody.
  ///
  /// In en, this message translates to:
  /// **'Receive wallet cashback or loyalty rewards if another commuter books your seat.'**
  String get seatRelease_benefitCompensationBody;

  /// No description provided for @seatRelease_benefitOptimizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Optimize Route Utilization'**
  String get seatRelease_benefitOptimizeTitle;

  /// No description provided for @seatRelease_benefitOptimizeBody.
  ///
  /// In en, this message translates to:
  /// **'Helps BMT optimize fleet load and reduce carbon emissions.'**
  String get seatRelease_benefitOptimizeBody;

  /// No description provided for @seatRelease_successHeadline.
  ///
  /// In en, this message translates to:
  /// **'Seat Released Successfully!'**
  String get seatRelease_successHeadline;

  /// No description provided for @seatRelease_referenceCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference Code: {code}'**
  String seatRelease_referenceCodeLabel(String code);

  /// No description provided for @seatRelease_releasedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Released Date'**
  String get seatRelease_releasedDateLabel;

  /// No description provided for @seatRelease_commuteSegmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Commute Segment'**
  String get seatRelease_commuteSegmentLabel;

  /// No description provided for @seatRelease_packageSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Package Source'**
  String get seatRelease_packageSourceLabel;

  /// No description provided for @seatRelease_autoNotifyBody.
  ///
  /// In en, this message translates to:
  /// **'We will automatically notify you and credit rewards to your wallet once your seat gets rebooked by other commuters.'**
  String get seatRelease_autoNotifyBody;

  /// No description provided for @seatRelease_viewReleaseDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'View Release Details'**
  String get seatRelease_viewReleaseDetailsButton;

  /// No description provided for @seatRelease_returnToDashboardButton.
  ///
  /// In en, this message translates to:
  /// **'Return to Dashboard'**
  String get seatRelease_returnToDashboardButton;

  /// No description provided for @seatRelease_idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String seatRelease_idLabel(String id);

  /// No description provided for @seatRelease_releasedSeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Released Seat'**
  String get seatRelease_releasedSeatLabel;

  /// No description provided for @seatRelease_reasonChosenLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason Chosen'**
  String get seatRelease_reasonChosenLabel;

  /// No description provided for @seatRelease_submitDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Submit Date'**
  String get seatRelease_submitDateLabel;

  /// No description provided for @seatRelease_notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get seatRelease_notesLabel;

  /// No description provided for @seatRelease_statusTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Release Status Timeline'**
  String get seatRelease_statusTimelineTitle;

  /// No description provided for @seatRelease_backToDashboardButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get seatRelease_backToDashboardButton;

  /// No description provided for @seatRelease_referenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference: {code}'**
  String seatRelease_referenceLabel(String code);

  /// No description provided for @seatRelease_compensationStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Compensation status'**
  String get seatRelease_compensationStatusLabel;

  /// No description provided for @seatRelease_compWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Your seat is listed for daily commuters. If another passenger books this seat prior to departure, you will unlock your reward instantly.'**
  String get seatRelease_compWaitingBody;

  /// No description provided for @seatRelease_compRebookedBody.
  ///
  /// In en, this message translates to:
  /// **'Your seat was successfully purchased. We are currently processing your compensation points clearance.'**
  String get seatRelease_compRebookedBody;

  /// No description provided for @seatRelease_compensationCreditedLabel.
  ///
  /// In en, this message translates to:
  /// **'COMPENSATION CREDITED'**
  String get seatRelease_compensationCreditedLabel;

  /// No description provided for @seatRelease_creditedToWalletLabel.
  ///
  /// In en, this message translates to:
  /// **'Credited to Account Wallet'**
  String get seatRelease_creditedToWalletLabel;

  /// No description provided for @seatRelease_clearingDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Clearing date: {date}'**
  String seatRelease_clearingDateLabel(String date);

  /// No description provided for @seatRelease_transactionClearedLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction Cleared Successfully'**
  String get seatRelease_transactionClearedLabel;

  /// No description provided for @seatRelease_historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search release logs by date, route...'**
  String get seatRelease_historySearchHint;

  /// No description provided for @seatRelease_noHistoryRecordsMessage.
  ///
  /// In en, this message translates to:
  /// **'No release records found\nTry adjusting your filters or search query.'**
  String get seatRelease_noHistoryRecordsMessage;

  /// No description provided for @seatRelease_alertHistoryLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert History Log'**
  String get seatRelease_alertHistoryLogTitle;

  /// No description provided for @seatRelease_clearAllButton.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get seatRelease_clearAllButton;

  /// No description provided for @seatRelease_noNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'No new notifications\nYou are completely caught up.'**
  String get seatRelease_noNotificationsMessage;

  /// No description provided for @seatRelease_achievementsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat Release Achievements'**
  String get seatRelease_achievementsHeaderTitle;

  /// No description provided for @seatRelease_tileSeatsReleased.
  ///
  /// In en, this message translates to:
  /// **'Seats Released'**
  String get seatRelease_tileSeatsReleased;

  /// No description provided for @seatRelease_tileRebookedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Rebooked Successfully'**
  String get seatRelease_tileRebookedSuccessfully;

  /// No description provided for @seatRelease_tileRewardsEarned.
  ///
  /// In en, this message translates to:
  /// **'Rewards Earned'**
  String get seatRelease_tileRewardsEarned;

  /// No description provided for @seatRelease_unlockableBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlockable Badges'**
  String get seatRelease_unlockableBadgesTitle;

  /// No description provided for @seatRelease_badgeEcoTitle.
  ///
  /// In en, this message translates to:
  /// **'Eco Commuter Tier I'**
  String get seatRelease_badgeEcoTitle;

  /// No description provided for @seatRelease_badgeEcoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Release 5 seats to reduce shuttle overhead fuel.'**
  String get seatRelease_badgeEcoSubtitle;

  /// No description provided for @seatRelease_badgeProgressReleased.
  ///
  /// In en, this message translates to:
  /// **'{count}/5 Released'**
  String seatRelease_badgeProgressReleased(int count);

  /// No description provided for @seatRelease_badgeCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Helper Gold'**
  String get seatRelease_badgeCommunityTitle;

  /// No description provided for @seatRelease_badgeCommunitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help 3 other commuters find seats.'**
  String get seatRelease_badgeCommunitySubtitle;

  /// No description provided for @seatRelease_badgeProgressRebooked.
  ///
  /// In en, this message translates to:
  /// **'{count}/3 Rebooked'**
  String seatRelease_badgeProgressRebooked(int count);

  /// No description provided for @seatRelease_badgeRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Reward Collector Level 2'**
  String get seatRelease_badgeRewardTitle;

  /// No description provided for @seatRelease_badgeRewardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accumulate EGP 200 in released rewards.'**
  String get seatRelease_badgeRewardSubtitle;

  /// No description provided for @seatRelease_badgeProgressReward.
  ///
  /// In en, this message translates to:
  /// **'EGP {amount}/EGP 200'**
  String seatRelease_badgeProgressReward(String amount);

  /// No description provided for @seatRelease_packageStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get seatRelease_packageStatusActive;

  /// No description provided for @seatRelease_packageStatusNone.
  ///
  /// In en, this message translates to:
  /// **'No subscription'**
  String get seatRelease_packageStatusNone;

  /// No description provided for @seatRelease_packageTypeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription package'**
  String get seatRelease_packageTypeSubscription;

  /// No description provided for @booking_routeDetails.
  ///
  /// In en, this message translates to:
  /// **'Route details'**
  String get booking_routeDetails;

  /// No description provided for @booking_allStopsCount.
  ///
  /// In en, this message translates to:
  /// **'All Stops ({count})'**
  String booking_allStopsCount(int count);

  /// No description provided for @booking_departure.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get booking_departure;

  /// No description provided for @booking_routeSummary.
  ///
  /// In en, this message translates to:
  /// **'Route Summary'**
  String get booking_routeSummary;

  /// No description provided for @booking_seatsAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count} seats available'**
  String booking_seatsAvailableCount(int count);

  /// No description provided for @booking_selectSeat.
  ///
  /// In en, this message translates to:
  /// **'Select Seat'**
  String get booking_selectSeat;

  /// No description provided for @booking_unableToLoadVehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Unable to load vehicle details'**
  String get booking_unableToLoadVehicleDetails;

  /// No description provided for @booking_vehicleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Vehicle not found'**
  String get booking_vehicleNotFound;

  /// No description provided for @payments_attachReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach Receipt'**
  String get payments_attachReceiptTitle;

  /// No description provided for @payments_uploadReceiptError.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload receipt: {error}'**
  String payments_uploadReceiptError(String error);

  /// No description provided for @payments_transferInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Instructions'**
  String get payments_transferInstructionsTitle;

  /// No description provided for @payments_transferInstructionsBody.
  ///
  /// In en, this message translates to:
  /// **'Transfer the exact booking amount to the address below and upload the transaction screenshot.'**
  String get payments_transferInstructionsBody;

  /// No description provided for @payments_amountToSendLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to send:'**
  String get payments_amountToSendLabel;

  /// No description provided for @payments_instapayIpaLabel.
  ///
  /// In en, this message translates to:
  /// **'InstaPay IPA:'**
  String get payments_instapayIpaLabel;

  /// No description provided for @payments_notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get payments_notConfigured;

  /// No description provided for @payments_accountHolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Holder:'**
  String get payments_accountHolderLabel;

  /// No description provided for @payments_mobileWalletNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Wallet No:'**
  String get payments_mobileWalletNoLabel;

  /// No description provided for @payments_walletTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet Type:'**
  String get payments_walletTypeLabel;

  /// No description provided for @payments_defaultWalletChannels.
  ///
  /// In en, this message translates to:
  /// **'Vodafone / Orange / Etisalat / WE'**
  String get payments_defaultWalletChannels;

  /// No description provided for @payments_copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{value} copied to clipboard'**
  String payments_copiedToClipboard(String value);

  /// No description provided for @payments_uploadReceiptScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Upload Receipt Screenshot'**
  String get payments_uploadReceiptScreenshot;

  /// No description provided for @payments_tapToSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a file (PNG, JPG)'**
  String get payments_tapToSelectFile;

  /// No description provided for @payments_receiptAttachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt Attached'**
  String get payments_receiptAttachedTitle;

  /// No description provided for @payments_receiptAttachedBody.
  ///
  /// In en, this message translates to:
  /// **'Submit payment to reserve your selected seat and send the receipt for verification.'**
  String get payments_receiptAttachedBody;

  /// No description provided for @payments_uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get payments_uploading;

  /// No description provided for @payments_submitPayment.
  ///
  /// In en, this message translates to:
  /// **'Submit Payment'**
  String get payments_submitPayment;

  /// No description provided for @booking_chooseTripAndVehicle.
  ///
  /// In en, this message translates to:
  /// **'Choose trip and vehicle'**
  String get booking_chooseTripAndVehicle;

  /// No description provided for @booking_availableTripsLabel.
  ///
  /// In en, this message translates to:
  /// **'Available trips'**
  String get booking_availableTripsLabel;

  /// No description provided for @booking_tripOptionsWithVehicles.
  ///
  /// In en, this message translates to:
  /// **'{count} trip options with assigned vehicles'**
  String booking_tripOptionsWithVehicles(int count);

  /// No description provided for @booking_sortEarliest.
  ///
  /// In en, this message translates to:
  /// **'Earliest'**
  String get booking_sortEarliest;

  /// No description provided for @booking_sortLowestPrice.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get booking_sortLowestPrice;

  /// No description provided for @booking_sortMostSeats.
  ///
  /// In en, this message translates to:
  /// **'Most seats'**
  String get booking_sortMostSeats;

  /// No description provided for @payments_closeCheckoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close checkout'**
  String get payments_closeCheckoutTooltip;

  /// No description provided for @payments_paymobCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Paymob Checkout'**
  String get payments_paymobCheckoutTitle;

  /// No description provided for @payments_reloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get payments_reloadTooltip;

  /// No description provided for @payments_unableToLoadCheckout.
  ///
  /// In en, this message translates to:
  /// **'Unable to load checkout'**
  String get payments_unableToLoadCheckout;

  /// No description provided for @payments_bookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get payments_bookingTitle;

  /// No description provided for @payments_processingBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing your booking...'**
  String get payments_processingBookingTitle;

  /// No description provided for @payments_processingBookingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This should only take a moment'**
  String get payments_processingBookingSubtitle;

  /// No description provided for @payments_bookingConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get payments_bookingConfirmedTitle;

  /// No description provided for @payments_bookingConfirmedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your seat is reserved — confirmation below'**
  String get payments_bookingConfirmedSubtitle;

  /// No description provided for @payments_bookingReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking Reference'**
  String get payments_bookingReferenceLabel;

  /// No description provided for @payments_bookingReferencePending.
  ///
  /// In en, this message translates to:
  /// **'Reference pending'**
  String get payments_bookingReferencePending;

  /// No description provided for @payments_departsLabel.
  ///
  /// In en, this message translates to:
  /// **'Departs'**
  String get payments_departsLabel;

  /// No description provided for @payments_vehicleNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle {vehicle}'**
  String payments_vehicleNumberLabel(String vehicle);

  /// No description provided for @payments_notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get payments_notesLabel;

  /// No description provided for @payments_bookingNotesBody.
  ///
  /// In en, this message translates to:
  /// **'Please arrive 10 minutes before departure. Cancellation allowed up to 1 hour before departure.'**
  String get payments_bookingNotesBody;

  /// No description provided for @payments_trackVehicle.
  ///
  /// In en, this message translates to:
  /// **'Track Vehicle'**
  String get payments_trackVehicle;

  /// No description provided for @trips_notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get trips_notFoundTitle;

  /// No description provided for @trips_notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This trip may have been removed or the link is no longer valid. Browse routes to plan your next ride.'**
  String get trips_notFoundBody;

  /// No description provided for @trips_starRatingSemantic.
  ///
  /// In en, this message translates to:
  /// **'{star} of 5 for {title}'**
  String trips_starRatingSemantic(int star, String title);

  /// No description provided for @payments_viewFullTripStatus.
  ///
  /// In en, this message translates to:
  /// **'View Full Trip & Payment Status'**
  String get payments_viewFullTripStatus;

  /// No description provided for @payments_rejectedHelpText.
  ///
  /// In en, this message translates to:
  /// **'You can contact support for help or try booking another trip.'**
  String get payments_rejectedHelpText;

  /// No description provided for @payments_pendingApprovalNotice.
  ///
  /// In en, this message translates to:
  /// **'You will receive a notification once your payment has been approved.'**
  String get payments_pendingApprovalNotice;

  /// No description provided for @payments_bookingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking Status'**
  String get payments_bookingStatusLabel;

  /// No description provided for @payments_reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get payments_reasonLabel;

  /// No description provided for @payments_estimatedReviewTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Review Time'**
  String get payments_estimatedReviewTimeLabel;

  /// No description provided for @payments_estimatedReviewTimeValue.
  ///
  /// In en, this message translates to:
  /// **'5–15 Minutes'**
  String get payments_estimatedReviewTimeValue;

  /// No description provided for @payments_paymentApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Approved'**
  String get payments_paymentApprovedTitle;

  /// No description provided for @payments_paymentApprovedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your payment was verified. Your seat is confirmed and ready to track.'**
  String get payments_paymentApprovedSubtitle;

  /// No description provided for @payments_statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get payments_statusApproved;

  /// No description provided for @payments_paymentRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Rejected'**
  String get payments_paymentRejectedTitle;

  /// No description provided for @payments_paymentRejectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t verify this payment. Contact support or try booking again.'**
  String get payments_paymentRejectedSubtitle;

  /// No description provided for @payments_statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get payments_statusRejected;

  /// No description provided for @payments_paymentReceiptSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Receipt Submitted'**
  String get payments_paymentReceiptSubmittedTitle;

  /// No description provided for @payments_paymentReceiptSubmittedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your booking request has been received. Our finance team is reviewing your payment.'**
  String get payments_paymentReceiptSubmittedSubtitle;

  /// No description provided for @payments_statusPendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get payments_statusPendingVerification;

  /// No description provided for @booking_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get booking_from;

  /// No description provided for @booking_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get booking_to;

  /// No description provided for @booking_seatsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} seats'**
  String booking_seatsCountLabel(int count);

  /// No description provided for @booking_routeStopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} route stops'**
  String booking_routeStopsCount(int count);

  /// No description provided for @booking_directTripNoStops.
  ///
  /// In en, this message translates to:
  /// **'Direct trip with no intermediate stops'**
  String get booking_directTripNoStops;

  /// No description provided for @booking_intermediateStopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} intermediate stops'**
  String booking_intermediateStopsCount(int count);

  /// No description provided for @booking_moreStopsCount.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more stops'**
  String booking_moreStopsCount(int count);

  /// No description provided for @loyalty_titlePortal.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Portal'**
  String get loyalty_titlePortal;

  /// No description provided for @loyalty_titleLedger.
  ///
  /// In en, this message translates to:
  /// **'Points Ledger Logs'**
  String get loyalty_titleLedger;

  /// No description provided for @loyalty_titleCatalog.
  ///
  /// In en, this message translates to:
  /// **'Redeem Points Catalog'**
  String get loyalty_titleCatalog;

  /// No description provided for @loyalty_titleHub.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Hub'**
  String get loyalty_titleHub;

  /// No description provided for @loyalty_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get loyalty_refresh;

  /// No description provided for @loyalty_confirmRedemptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Redemption'**
  String get loyalty_confirmRedemptionTitle;

  /// No description provided for @loyalty_confirmRedemptionBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to redeem this reward?'**
  String get loyalty_confirmRedemptionBody;

  /// No description provided for @loyalty_costPoints.
  ///
  /// In en, this message translates to:
  /// **'Cost: {points} points'**
  String loyalty_costPoints(int points);

  /// No description provided for @loyalty_currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance:'**
  String get loyalty_currentBalance;

  /// No description provided for @loyalty_balanceAfterRedemption.
  ///
  /// In en, this message translates to:
  /// **'Balance After Redemption:'**
  String get loyalty_balanceAfterRedemption;

  /// No description provided for @loyalty_redeemNow.
  ///
  /// In en, this message translates to:
  /// **'Redeem Now'**
  String get loyalty_redeemNow;

  /// No description provided for @loyalty_voucherUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Voucher Unlocked! 🎫'**
  String get loyalty_voucherUnlocked;

  /// No description provided for @loyalty_couponGeneratedBody.
  ///
  /// In en, this message translates to:
  /// **'Coupon code generated successfully. You can use it during payment checkout.'**
  String get loyalty_couponGeneratedBody;

  /// No description provided for @loyalty_copyAndClose.
  ///
  /// In en, this message translates to:
  /// **'Copy & Close'**
  String get loyalty_copyAndClose;

  /// No description provided for @loyalty_voucherCopiedSnack.
  ///
  /// In en, this message translates to:
  /// **'Voucher code copied to clipboard!'**
  String get loyalty_voucherCopiedSnack;

  /// No description provided for @loyalty_navRedeemTitle.
  ///
  /// In en, this message translates to:
  /// **'Redeem Points'**
  String get loyalty_navRedeemTitle;

  /// No description provided for @loyalty_navRedeemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse Catalog'**
  String get loyalty_navRedeemSubtitle;

  /// No description provided for @loyalty_navHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Points History'**
  String get loyalty_navHistoryTitle;

  /// No description provided for @loyalty_navHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ledger Logs'**
  String get loyalty_navHistorySubtitle;

  /// No description provided for @loyalty_activeTierPerks.
  ///
  /// In en, this message translates to:
  /// **'Active {tier} Perks'**
  String loyalty_activeTierPerks(String tier);

  /// No description provided for @loyalty_exploreMembership.
  ///
  /// In en, this message translates to:
  /// **'Explore Membership Levels'**
  String get loyalty_exploreMembership;

  /// No description provided for @loyalty_tierMemberBadge.
  ///
  /// In en, this message translates to:
  /// **'{tier} member'**
  String loyalty_tierMemberBadge(String tier);

  /// No description provided for @loyalty_megaLoyaltyBadge.
  ///
  /// In en, this message translates to:
  /// **'MEGA LOYALTY'**
  String get loyalty_megaLoyaltyBadge;

  /// No description provided for @loyalty_pointsBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'COMMUTE POINTS BALANCE'**
  String get loyalty_pointsBalanceLabel;

  /// No description provided for @loyalty_ptsUnit.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get loyalty_ptsUnit;

  /// No description provided for @loyalty_nextGoalPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Next Goal: Platinum Tier'**
  String get loyalty_nextGoalPlatinum;

  /// No description provided for @loyalty_ptsToGo.
  ///
  /// In en, this message translates to:
  /// **'{points} pts to go'**
  String loyalty_ptsToGo(int points);

  /// No description provided for @loyalty_platinumFootnote.
  ///
  /// In en, this message translates to:
  /// **'* Platinum tier rewards earn double points on all travels.'**
  String get loyalty_platinumFootnote;

  /// No description provided for @loyalty_currentTier.
  ///
  /// In en, this message translates to:
  /// **'Current Tier'**
  String get loyalty_currentTier;

  /// No description provided for @loyalty_needsPoints.
  ///
  /// In en, this message translates to:
  /// **'Needs {points}'**
  String loyalty_needsPoints(String points);

  /// No description provided for @loyalty_transactionLedger.
  ///
  /// In en, this message translates to:
  /// **'Points Transaction Ledger'**
  String get loyalty_transactionLedger;

  /// No description provided for @loyalty_activeLogs.
  ///
  /// In en, this message translates to:
  /// **'Active logs'**
  String get loyalty_activeLogs;

  /// No description provided for @loyalty_redeemableBalance.
  ///
  /// In en, this message translates to:
  /// **'Redeemable points balance'**
  String get loyalty_redeemableBalance;

  /// No description provided for @loyalty_tierLevelMember.
  ///
  /// In en, this message translates to:
  /// **'{tier} Level Member'**
  String loyalty_tierLevelMember(String tier);

  /// No description provided for @loyalty_catalogRewards.
  ///
  /// In en, this message translates to:
  /// **'Catalog Rewards'**
  String get loyalty_catalogRewards;

  /// No description provided for @loyalty_tiersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Membership levels aren\'t available right now.'**
  String get loyalty_tiersUnavailable;

  /// No description provided for @loyalty_historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No points activity yet'**
  String get loyalty_historyEmptyTitle;

  /// No description provided for @loyalty_historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Book a trip to start earning points.'**
  String get loyalty_historyEmptyBody;

  /// No description provided for @loyalty_rewardsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No rewards available'**
  String get loyalty_rewardsEmptyTitle;

  /// No description provided for @loyalty_rewardsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for new ways to spend your points.'**
  String get loyalty_rewardsEmptyBody;

  /// No description provided for @loyalty_transactionFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Points activity'**
  String get loyalty_transactionFallbackTitle;

  /// No description provided for @loyalty_redeemFailed.
  ///
  /// In en, this message translates to:
  /// **'Redemption failed. {reason}'**
  String loyalty_redeemFailed(String reason);

  /// No description provided for @loyalty_categoryDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get loyalty_categoryDiscount;

  /// No description provided for @loyalty_categoryFreeRide.
  ///
  /// In en, this message translates to:
  /// **'FreeRide'**
  String get loyalty_categoryFreeRide;

  /// No description provided for @loyalty_categoryCashback.
  ///
  /// In en, this message translates to:
  /// **'Cashback'**
  String get loyalty_categoryCashback;

  /// No description provided for @loyalty_categoryPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get loyalty_categoryPackage;

  /// No description provided for @loyalty_tierBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get loyalty_tierBronze;

  /// No description provided for @loyalty_tierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get loyalty_tierSilver;

  /// No description provided for @loyalty_tierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get loyalty_tierGold;

  /// No description provided for @loyalty_tierPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get loyalty_tierPlatinum;

  /// No description provided for @trips_cancelReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get trips_cancelReasonTitle;

  /// No description provided for @trips_cancelReasonTripRef.
  ///
  /// In en, this message translates to:
  /// **'Trip {reference}'**
  String trips_cancelReasonTripRef(String reference);

  /// No description provided for @trips_reasonScheduleChange.
  ///
  /// In en, this message translates to:
  /// **'Schedule change'**
  String get trips_reasonScheduleChange;

  /// No description provided for @trips_reasonAlternativeTransport.
  ///
  /// In en, this message translates to:
  /// **'Found alternative transport'**
  String get trips_reasonAlternativeTransport;

  /// No description provided for @trips_reasonDriverDelay.
  ///
  /// In en, this message translates to:
  /// **'Driver delay concern'**
  String get trips_reasonDriverDelay;

  /// No description provided for @trips_reasonPersonalEmergency.
  ///
  /// In en, this message translates to:
  /// **'Personal emergency'**
  String get trips_reasonPersonalEmergency;

  /// No description provided for @trips_reasonDuplicateBooking.
  ///
  /// In en, this message translates to:
  /// **'Duplicate booking'**
  String get trips_reasonDuplicateBooking;

  /// No description provided for @trips_cancelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this trip?'**
  String get trips_cancelDialogTitle;

  /// No description provided for @trips_cancelDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking will be cancelled, your seat released back to the trip, and your payment will no longer be reviewed. This cannot be undone — you would have to book again.'**
  String get trips_cancelDialogBody;

  /// No description provided for @trips_cancelReasonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String trips_cancelReasonPrefix(String reason);

  /// No description provided for @trips_keepTrip.
  ///
  /// In en, this message translates to:
  /// **'Keep trip'**
  String get trips_keepTrip;

  /// No description provided for @trips_confirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get trips_confirmCancellation;

  /// No description provided for @booking_resetAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset all'**
  String get booking_resetAllFilters;

  /// No description provided for @booking_licensedCaptain.
  ///
  /// In en, this message translates to:
  /// **'Licensed captain'**
  String get booking_licensedCaptain;

  /// No description provided for @booking_eta.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get booking_eta;

  /// No description provided for @booking_bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get booking_bookNow;

  /// No description provided for @booking_seatsLeftShort.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String booking_seatsLeftShort(int count);

  /// No description provided for @seatRelease_mockTripDateJun2.
  ///
  /// In en, this message translates to:
  /// **'Jun 2'**
  String get seatRelease_mockTripDateJun2;

  /// No description provided for @packages_refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get packages_refreshTooltip;

  /// No description provided for @packages_continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to Payment'**
  String get packages_continueToPayment;

  /// No description provided for @packages_daysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} Days'**
  String packages_daysCount(int days);

  /// No description provided for @trips_reviewFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate your trip'**
  String get trips_reviewFormTitle;

  /// No description provided for @trips_ratingOffice.
  ///
  /// In en, this message translates to:
  /// **'Office rating'**
  String get trips_ratingOffice;

  /// No description provided for @trips_ratingDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver rating'**
  String get trips_ratingDriver;

  /// No description provided for @trips_ratingVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle rating'**
  String get trips_ratingVehicle;

  /// No description provided for @trips_ratingRoute.
  ///
  /// In en, this message translates to:
  /// **'Route rating'**
  String get trips_ratingRoute;

  /// No description provided for @trips_reviewCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Share feedback (optional)'**
  String get trips_reviewCommentHint;

  /// No description provided for @trips_reviewSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get trips_reviewSubmitting;

  /// No description provided for @trips_submitReviewButton.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get trips_submitReviewButton;

  /// No description provided for @trips_reviewIncompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Give the driver, vehicle, and route a star rating to continue.'**
  String get trips_reviewIncompleteHint;

  /// No description provided for @trips_reviewThankYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your review'**
  String get trips_reviewThankYouTitle;

  /// No description provided for @trips_reviewThankYouBody.
  ///
  /// In en, this message translates to:
  /// **'Your feedback on {reference} went straight to our operations team. Only they can see it.'**
  String trips_reviewThankYouBody(String reference);

  /// No description provided for @trips_reviewYourFeedbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Your feedback'**
  String get trips_reviewYourFeedbackLabel;

  /// No description provided for @trips_reviewOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening your review…'**
  String get trips_reviewOpening;

  /// No description provided for @trips_reviewOpenError.
  ///
  /// In en, this message translates to:
  /// **'We could not open your review'**
  String get trips_reviewOpenError;

  /// No description provided for @trips_reviewErrorSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to review your trip.'**
  String get trips_reviewErrorSignIn;

  /// No description provided for @trips_reviewErrorBookingMissing.
  ///
  /// In en, this message translates to:
  /// **'This booking no longer exists.'**
  String get trips_reviewErrorBookingMissing;

  /// No description provided for @trips_reviewErrorNotYourTrip.
  ///
  /// In en, this message translates to:
  /// **'You can only review your own trips.'**
  String get trips_reviewErrorNotYourTrip;

  /// No description provided for @trips_reviewErrorCancelled.
  ///
  /// In en, this message translates to:
  /// **'This booking was cancelled, so there is nothing to review.'**
  String get trips_reviewErrorCancelled;

  /// No description provided for @trips_reviewErrorNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'You can only review a trip once it has been completed.'**
  String get trips_reviewErrorNotCompleted;

  /// No description provided for @trips_reviewErrorInvalidRating.
  ///
  /// In en, this message translates to:
  /// **'Please give the driver, vehicle, and route 1–5 stars.'**
  String get trips_reviewErrorInvalidRating;

  /// No description provided for @trips_reviewErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your review. Please try again.'**
  String get trips_reviewErrorUnknown;

  /// No description provided for @booking_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get booking_price;

  /// No description provided for @booking_mapCoordinatesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map coordinates unavailable'**
  String get booking_mapCoordinatesUnavailable;

  /// No description provided for @booking_saveDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String booking_saveDiscountPercent(int percent);

  /// No description provided for @booking_bestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get booking_bestValue;

  /// No description provided for @booking_ridesValidForDays.
  ///
  /// In en, this message translates to:
  /// **'{rides} · valid {days}'**
  String booking_ridesValidForDays(String rides, String days);

  /// No description provided for @booking_pricePerRide.
  ///
  /// In en, this message translates to:
  /// **'EGP {amount} per ride'**
  String booking_pricePerRide(String amount);

  /// No description provided for @booking_yourSelectedTrip.
  ///
  /// In en, this message translates to:
  /// **'Your selected trip'**
  String get booking_yourSelectedTrip;

  /// No description provided for @booking_startsWithYourTrip.
  ///
  /// In en, this message translates to:
  /// **'Starts with your trip'**
  String get booking_startsWithYourTrip;

  /// No description provided for @booking_couldNotLoadFares.
  ///
  /// In en, this message translates to:
  /// **'Could not load fares'**
  String get booking_couldNotLoadFares;

  /// No description provided for @booking_chooseTripTimeAndVehicle.
  ///
  /// In en, this message translates to:
  /// **'Choose trip time and vehicle'**
  String get booking_chooseTripTimeAndVehicle;

  /// No description provided for @booking_viewRouteDetails.
  ///
  /// In en, this message translates to:
  /// **'View route details'**
  String get booking_viewRouteDetails;

  /// No description provided for @booking_tripsCountToday.
  ///
  /// In en, this message translates to:
  /// **'{count} trips today'**
  String booking_tripsCountToday(int count);

  /// No description provided for @booking_noTripsToday.
  ///
  /// In en, this message translates to:
  /// **'No trips today'**
  String get booking_noTripsToday;

  /// No description provided for @referral_titleMain.
  ///
  /// In en, this message translates to:
  /// **'Referrals & Rewards'**
  String get referral_titleMain;

  /// No description provided for @referral_titleInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get referral_titleInvite;

  /// No description provided for @referral_titleHistory.
  ///
  /// In en, this message translates to:
  /// **'Referral History'**
  String get referral_titleHistory;

  /// No description provided for @referral_titleWallet.
  ///
  /// In en, this message translates to:
  /// **'Rewards Wallet'**
  String get referral_titleWallet;

  /// No description provided for @referral_titleHub.
  ///
  /// In en, this message translates to:
  /// **'Referral Hub'**
  String get referral_titleHub;

  /// No description provided for @referral_codeCopiedSnack.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied to clipboard!'**
  String get referral_codeCopiedSnack;

  /// No description provided for @referral_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get referral_refresh;

  /// No description provided for @referral_redemptionSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Redemption Successful! 🎉'**
  String get referral_redemptionSuccessTitle;

  /// No description provided for @referral_redemptionSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Rewards have been converted and transferred directly to your Main Wallet Balance!'**
  String get referral_redemptionSuccessBody;

  /// No description provided for @referral_successfullyTransferred.
  ///
  /// In en, this message translates to:
  /// **'Successfully Transferred'**
  String get referral_successfullyTransferred;

  /// No description provided for @referral_awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome'**
  String get referral_awesome;

  /// No description provided for @referral_scratchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scratch card to reveal your promotional reward code!'**
  String get referral_scratchSubtitle;

  /// No description provided for @referral_claimReward.
  ///
  /// In en, this message translates to:
  /// **'Claim Reward'**
  String get referral_claimReward;

  /// No description provided for @referral_scratchToReveal.
  ///
  /// In en, this message translates to:
  /// **'Scratch card to reveal'**
  String get referral_scratchToReveal;

  /// No description provided for @referral_scratchWithFinger.
  ///
  /// In en, this message translates to:
  /// **'Scratch with finger!'**
  String get referral_scratchWithFinger;

  /// No description provided for @referral_rewardsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Rewards unavailable'**
  String get referral_rewardsUnavailable;

  /// No description provided for @referral_referralsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} referrals'**
  String referral_referralsCount(int count);

  /// No description provided for @referral_milestoneFirst.
  ///
  /// In en, this message translates to:
  /// **'First Referral Milestone'**
  String get referral_milestoneFirst;

  /// No description provided for @referral_milestoneReached.
  ///
  /// In en, this message translates to:
  /// **'Milestone Reached!'**
  String get referral_milestoneReached;

  /// No description provided for @referral_milestoneNext.
  ///
  /// In en, this message translates to:
  /// **'Next Referral Milestone'**
  String get referral_milestoneNext;

  /// No description provided for @referral_milestoneDescFirst.
  ///
  /// In en, this message translates to:
  /// **'Invite {target} friends to unlock your first referral bonus.'**
  String referral_milestoneDescFirst(int target);

  /// No description provided for @referral_milestoneDescReached.
  ///
  /// In en, this message translates to:
  /// **'Great work! You have reached the current milestone.'**
  String get referral_milestoneDescReached;

  /// No description provided for @referral_milestoneDescNext.
  ///
  /// In en, this message translates to:
  /// **'Invite {remaining, plural, =1{1 more friend} other{{remaining} more friends}} to unlock your next reward.'**
  String referral_milestoneDescNext(int remaining);

  /// No description provided for @referral_progressCount.
  ///
  /// In en, this message translates to:
  /// **'Progress: {current} / {target} referrals'**
  String referral_progressCount(int current, int target);

  /// No description provided for @referral_statTotalInvites.
  ///
  /// In en, this message translates to:
  /// **'Total Invites'**
  String get referral_statTotalInvites;

  /// No description provided for @referral_statSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get referral_statSuccessful;

  /// No description provided for @referral_statTotalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get referral_statTotalEarned;

  /// No description provided for @referral_yourCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get referral_yourCodeLabel;

  /// No description provided for @referral_inviteFriendsNow.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends Now'**
  String get referral_inviteFriendsNow;

  /// No description provided for @referral_walletSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scratch vouchers & redeem balances'**
  String get referral_walletSubtitle;

  /// No description provided for @referral_claimableBadge.
  ///
  /// In en, this message translates to:
  /// **'EGP {amount} Claimable'**
  String referral_claimableBadge(int amount);

  /// No description provided for @referral_logsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Referral Logs & History'**
  String get referral_logsHistoryTitle;

  /// No description provided for @referral_logsHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track status of invites and code claims'**
  String get referral_logsHistorySubtitle;

  /// No description provided for @referral_scanToJoin.
  ///
  /// In en, this message translates to:
  /// **'Scan to Join BMT'**
  String get referral_scanToJoin;

  /// No description provided for @referral_qrHint.
  ///
  /// In en, this message translates to:
  /// **'Let friends scan this QR to automatically register with your code!'**
  String get referral_qrHint;

  /// No description provided for @referral_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get referral_close;

  /// No description provided for @referral_howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get referral_howItWorks;

  /// No description provided for @referral_step1Title.
  ///
  /// In en, this message translates to:
  /// **'Share your code'**
  String get referral_step1Title;

  /// No description provided for @referral_step1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Send your unique code to friends via any channel.'**
  String get referral_step1Subtitle;

  /// No description provided for @referral_step2Title.
  ///
  /// In en, this message translates to:
  /// **'Friend registers'**
  String get referral_step2Title;

  /// No description provided for @referral_step2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'They sign up and complete their first trip using your code.'**
  String get referral_step2Subtitle;

  /// No description provided for @referral_step3Title.
  ///
  /// In en, this message translates to:
  /// **'You both earn'**
  String get referral_step3Title;

  /// No description provided for @referral_step3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'You receive a referral reward credited to your wallet.'**
  String get referral_step3Subtitle;

  /// No description provided for @referral_directShareOptions.
  ///
  /// In en, this message translates to:
  /// **'Direct Share Options'**
  String get referral_directShareOptions;

  /// No description provided for @referral_shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get referral_shareLink;

  /// No description provided for @referral_showQr.
  ///
  /// In en, this message translates to:
  /// **'Show QR'**
  String get referral_showQr;

  /// No description provided for @referral_copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get referral_copyCode;

  /// No description provided for @referral_referralsLog.
  ///
  /// In en, this message translates to:
  /// **'Referrals Log'**
  String get referral_referralsLog;

  /// No description provided for @referral_totalReferralsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} total referrals'**
  String referral_totalReferralsCount(int count);

  /// No description provided for @referral_invitedOn.
  ///
  /// In en, this message translates to:
  /// **'Invited: {date}'**
  String referral_invitedOn(String date);

  /// No description provided for @referral_statusRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get referral_statusRegistered;

  /// No description provided for @referral_statusFirstOrderCompleted.
  ///
  /// In en, this message translates to:
  /// **'First Order Completed'**
  String get referral_statusFirstOrderCompleted;

  /// No description provided for @referral_statusRewardGranted.
  ///
  /// In en, this message translates to:
  /// **'Reward Granted'**
  String get referral_statusRewardGranted;

  /// No description provided for @referral_statusPendingRegistration.
  ///
  /// In en, this message translates to:
  /// **'Pending Registration'**
  String get referral_statusPendingRegistration;

  /// No description provided for @referral_egpTotal.
  ///
  /// In en, this message translates to:
  /// **'EGP {amount}'**
  String referral_egpTotal(int amount);

  /// No description provided for @referral_egpEarned.
  ///
  /// In en, this message translates to:
  /// **'+ EGP {amount}'**
  String referral_egpEarned(int amount);

  /// No description provided for @referral_egpZero.
  ///
  /// In en, this message translates to:
  /// **'EGP 0'**
  String get referral_egpZero;

  /// No description provided for @referral_claimVouchersTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim Reward Vouchers'**
  String get referral_claimVouchersTitle;

  /// No description provided for @referral_walletLabel.
  ///
  /// In en, this message translates to:
  /// **'Referral Wallet'**
  String get referral_walletLabel;

  /// No description provided for @referral_walletAvailable.
  ///
  /// In en, this message translates to:
  /// **'EGP {amount} available'**
  String referral_walletAvailable(int amount);

  /// No description provided for @referral_noBalanceYet.
  ///
  /// In en, this message translates to:
  /// **'No balance yet'**
  String get referral_noBalanceYet;

  /// No description provided for @referral_transferHint.
  ///
  /// In en, this message translates to:
  /// **'You can transfer this balance to your main wallet.'**
  String get referral_transferHint;

  /// No description provided for @referral_earnBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Earn balance by inviting friends with your referral code.'**
  String get referral_earnBalanceHint;

  /// No description provided for @referral_openWallet.
  ///
  /// In en, this message translates to:
  /// **'Open my wallet'**
  String get referral_openWallet;

  /// No description provided for @referral_walletCreditHint.
  ///
  /// In en, this message translates to:
  /// **'Referral rewards are paid straight into your wallet at the office that granted them.'**
  String get referral_walletCreditHint;

  /// No description provided for @referral_redeemToWallet.
  ///
  /// In en, this message translates to:
  /// **'Redeem to Wallet'**
  String get referral_redeemToWallet;

  /// No description provided for @referral_noBalanceToRedeem.
  ///
  /// In en, this message translates to:
  /// **'No balance to redeem'**
  String get referral_noBalanceToRedeem;

  /// No description provided for @referral_redeemFailed.
  ///
  /// In en, this message translates to:
  /// **'Redemption failed. Please try again.'**
  String get referral_redeemFailed;

  /// No description provided for @referral_revealedCode.
  ///
  /// In en, this message translates to:
  /// **'Revealed Code: {code}'**
  String referral_revealedCode(String code);

  /// No description provided for @referral_lockedScratchToReveal.
  ///
  /// In en, this message translates to:
  /// **'Locked - Scratch to reveal'**
  String get referral_lockedScratchToReveal;

  /// No description provided for @referral_inviteCopiedSnack.
  ///
  /// In en, this message translates to:
  /// **'Invite copied to clipboard'**
  String get referral_inviteCopiedSnack;

  /// No description provided for @referral_shareYourInvite.
  ///
  /// In en, this message translates to:
  /// **'Share your invite'**
  String get referral_shareYourInvite;

  /// No description provided for @referral_shareSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friends with code {code} and earn rewards.'**
  String referral_shareSheetSubtitle(String code);

  /// No description provided for @referral_channelWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get referral_channelWhatsapp;

  /// No description provided for @referral_channelFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get referral_channelFacebook;

  /// No description provided for @referral_channelMessenger.
  ///
  /// In en, this message translates to:
  /// **'Messenger'**
  String get referral_channelMessenger;

  /// No description provided for @referral_channelInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get referral_channelInstagram;

  /// No description provided for @referral_copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get referral_copyLink;

  /// No description provided for @referral_more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get referral_more;

  /// No description provided for @booking_filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get booking_filters;

  /// No description provided for @booking_filtersCount.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count})'**
  String booking_filtersCount(int count);

  /// No description provided for @booking_filtersActiveSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label} active'**
  String booking_filtersActiveSemantics(String label);

  /// No description provided for @booking_faresFrom.
  ///
  /// In en, this message translates to:
  /// **'Fares from'**
  String get booking_faresFrom;

  /// No description provided for @booking_chooseThisRoute.
  ///
  /// In en, this message translates to:
  /// **'Choose this route'**
  String get booking_chooseThisRoute;

  /// No description provided for @booking_routeOverviewLabel.
  ///
  /// In en, this message translates to:
  /// **'ROUTE OVERVIEW'**
  String get booking_routeOverviewLabel;

  /// No description provided for @booking_finalStop.
  ///
  /// In en, this message translates to:
  /// **'Final stop'**
  String get booking_finalStop;

  /// No description provided for @booking_findYourBestCommute.
  ///
  /// In en, this message translates to:
  /// **'Find your best commute'**
  String get booking_findYourBestCommute;

  /// No description provided for @booking_searchRoutesWhenAvailable.
  ///
  /// In en, this message translates to:
  /// **'Search active routes when they become available.'**
  String get booking_searchRoutesWhenAvailable;

  /// No description provided for @booking_routesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'{visible} of {total} routes match your search'**
  String booking_routesMatchSearch(int visible, int total);

  /// No description provided for @booking_searchDepartureDestinationHint.
  ///
  /// In en, this message translates to:
  /// **'Search departure, destination, or route name'**
  String get booking_searchDepartureDestinationHint;

  /// No description provided for @booking_clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get booking_clearSearch;

  /// No description provided for @booking_full.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get booking_full;

  /// No description provided for @booking_occupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get booking_occupancy;

  /// No description provided for @booking_percentFull.
  ///
  /// In en, this message translates to:
  /// **'{percent}% full'**
  String booking_percentFull(int percent);

  /// No description provided for @booking_availableBookedSeats.
  ///
  /// In en, this message translates to:
  /// **'{available} available · {booked} booked'**
  String booking_availableBookedSeats(int available, int booked);

  /// No description provided for @booking_selectTripAndVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select trip and vehicle'**
  String get booking_selectTripAndVehicle;

  /// No description provided for @booking_seatsCapacity.
  ///
  /// In en, this message translates to:
  /// **'{count} seats capacity'**
  String booking_seatsCapacity(int count);

  /// No description provided for @booking_stepStops.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get booking_stepStops;

  /// No description provided for @booking_stepXOfY.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String booking_stepXOfY(int step, int total);

  /// No description provided for @communication_chatHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Hub'**
  String get communication_chatHubTitle;

  /// No description provided for @communication_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get communication_refresh;

  /// No description provided for @communication_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search chats, contacts, messages...'**
  String get communication_searchHint;

  /// No description provided for @communication_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get communication_filterAll;

  /// No description provided for @communication_filterDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get communication_filterDrivers;

  /// No description provided for @communication_filterSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get communication_filterSupport;

  /// No description provided for @communication_filterGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get communication_filterGroups;

  /// No description provided for @communication_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations found'**
  String get communication_emptyTitle;

  /// No description provided for @communication_emptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Filter or search in your active shuttle runs.'**
  String get communication_emptySubtitle;

  /// No description provided for @communication_categoryDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get communication_categoryDriver;

  /// No description provided for @communication_categorySupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get communication_categorySupport;

  /// No description provided for @communication_categoryGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get communication_categoryGroup;

  /// No description provided for @communication_statusOpenFallback.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get communication_statusOpenFallback;

  /// No description provided for @communication_messageInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get communication_messageInputHint;

  /// No description provided for @communication_justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get communication_justNow;

  /// No description provided for @booking_pickYourSeat.
  ///
  /// In en, this message translates to:
  /// **'Pick your seat'**
  String get booking_pickYourSeat;

  /// No description provided for @booking_frontSeatsNote.
  ///
  /// In en, this message translates to:
  /// **'Front seats are nearest to the driver.'**
  String get booking_frontSeatsNote;

  /// No description provided for @booking_freeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} free'**
  String booking_freeCount(int count);

  /// No description provided for @booking_yourSelectedSeat.
  ///
  /// In en, this message translates to:
  /// **'Your selected seat'**
  String get booking_yourSelectedSeat;

  /// No description provided for @booking_continueToPackages.
  ///
  /// In en, this message translates to:
  /// **'Continue to packages'**
  String get booking_continueToPackages;

  /// No description provided for @booking_additionalVehicleSeats.
  ///
  /// In en, this message translates to:
  /// **'Additional vehicle seats'**
  String get booking_additionalVehicleSeats;

  /// No description provided for @booking_couldNotLoadSeats.
  ///
  /// In en, this message translates to:
  /// **'Could not load seats'**
  String get booking_couldNotLoadSeats;

  /// No description provided for @communication_messagesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Messages unavailable'**
  String get communication_messagesUnavailable;

  /// No description provided for @communication_imagePreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview not available yet'**
  String get communication_imagePreviewUnavailable;

  /// No description provided for @booking_whereGetOnOff.
  ///
  /// In en, this message translates to:
  /// **'Where will you get on and off?'**
  String get booking_whereGetOnOff;

  /// No description provided for @booking_choosePickupThenStop.
  ///
  /// In en, this message translates to:
  /// **'Choose your pickup first, then a stop further along the route.'**
  String get booking_choosePickupThenStop;

  /// No description provided for @booking_stopsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String booking_stopsCountLabel(int count);

  /// No description provided for @booking_selectYourPickupStop.
  ///
  /// In en, this message translates to:
  /// **'1  Select your pickup stop'**
  String get booking_selectYourPickupStop;

  /// No description provided for @booking_selectYourDropoffStop.
  ///
  /// In en, this message translates to:
  /// **'2  Now select your drop-off stop'**
  String get booking_selectYourDropoffStop;

  /// No description provided for @booking_routeSegmentReady.
  ///
  /// In en, this message translates to:
  /// **'Route segment ready'**
  String get booking_routeSegmentReady;

  /// No description provided for @booking_routeBeginsHere.
  ///
  /// In en, this message translates to:
  /// **'Route begins here'**
  String get booking_routeBeginsHere;

  /// No description provided for @booking_finalDestination.
  ///
  /// In en, this message translates to:
  /// **'Final destination'**
  String get booking_finalDestination;

  /// No description provided for @booking_pickupDropoffPoint.
  ///
  /// In en, this message translates to:
  /// **'Pickup and drop-off point'**
  String get booking_pickupDropoffPoint;

  /// No description provided for @booking_findAvailableTrips.
  ///
  /// In en, this message translates to:
  /// **'Find available trips'**
  String get booking_findAvailableTrips;

  /// No description provided for @booking_reviewYourBooking.
  ///
  /// In en, this message translates to:
  /// **'Review your booking'**
  String get booking_reviewYourBooking;

  /// No description provided for @booking_nothingChargedUntilPay.
  ///
  /// In en, this message translates to:
  /// **'Nothing is charged until you pay on the next step.'**
  String get booking_nothingChargedUntilPay;

  /// No description provided for @booking_proceedToPayment.
  ///
  /// In en, this message translates to:
  /// **'Proceed to payment'**
  String get booking_proceedToPayment;

  /// No description provided for @booking_seatHeldWhilePaying.
  ///
  /// In en, this message translates to:
  /// **'Your seat is locked in the moment you confirm and pay.'**
  String get booking_seatHeldWhilePaying;

  /// No description provided for @booking_chooseYourDeparture.
  ///
  /// In en, this message translates to:
  /// **'Choose your departure'**
  String get booking_chooseYourDeparture;

  /// No description provided for @booking_pickupToDropoff.
  ///
  /// In en, this message translates to:
  /// **'{pickup} to {dropoff}'**
  String booking_pickupToDropoff(String pickup, String dropoff);

  /// No description provided for @booking_chooseASeat.
  ///
  /// In en, this message translates to:
  /// **'Choose a seat'**
  String get booking_chooseASeat;

  /// No description provided for @booking_departsAtTime.
  ///
  /// In en, this message translates to:
  /// **'Departs {time}'**
  String booking_departsAtTime(String time);

  /// No description provided for @booking_departsOnDayAtTime.
  ///
  /// In en, this message translates to:
  /// **'Departs {day} · {time}'**
  String booking_departsOnDayAtTime(String day, String time);

  /// No description provided for @booking_perRide.
  ///
  /// In en, this message translates to:
  /// **'per ride'**
  String get booking_perRide;

  /// No description provided for @booking_noTripsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No trips available'**
  String get booking_noTripsAvailable;

  /// No description provided for @booking_noTripsFoundForRoute.
  ///
  /// In en, this message translates to:
  /// **'No trips found for {route} today.'**
  String booking_noTripsFoundForRoute(String route);

  /// No description provided for @offices_directoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Transport offices'**
  String get offices_directoryTitle;

  /// No description provided for @offices_directoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No offices are open for booking right now.'**
  String get offices_directoryEmpty;

  /// No description provided for @offices_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by company or city'**
  String get offices_searchHint;

  /// No description provided for @offices_noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No office matches \"{query}\"'**
  String offices_noSearchResults(String query);

  /// No description provided for @offices_clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get offices_clearSearch;

  /// No description provided for @offices_routesHeader.
  ///
  /// In en, this message translates to:
  /// **'Routes this office runs'**
  String get offices_routesHeader;

  /// No description provided for @offices_noRoutes.
  ///
  /// In en, this message translates to:
  /// **'This office has no bookable routes right now.'**
  String get offices_noRoutes;

  /// No description provided for @offices_departuresHeader.
  ///
  /// In en, this message translates to:
  /// **'Departures on sale'**
  String get offices_departuresHeader;

  /// No description provided for @offices_noDepartures.
  ///
  /// In en, this message translates to:
  /// **'This office has no departures on sale right now.'**
  String get offices_noDepartures;

  /// No description provided for @offices_noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get offices_noRatingsYet;

  /// No description provided for @offices_ratingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String offices_ratingsCount(int count);

  /// No description provided for @routes_officesCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Transport offices'**
  String get routes_officesCardTitle;

  /// No description provided for @routes_officesCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse operators, compare ratings, and see the routes each one runs.'**
  String get routes_officesCardSubtitle;

  /// No description provided for @routes_heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search, compare, and book your commute'**
  String get routes_heroSubtitle;

  /// No description provided for @routes_searchDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter pickup, destination, date and time to see available trips.'**
  String get routes_searchDescription;

  /// No description provided for @routes_step1Title.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get routes_step1Title;

  /// No description provided for @routes_step1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup, destination, date & time'**
  String get routes_step1Subtitle;

  /// No description provided for @routes_step2Title.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get routes_step2Title;

  /// No description provided for @routes_step2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Routes and vehicles'**
  String get routes_step2Subtitle;

  /// No description provided for @routes_step3Title.
  ///
  /// In en, this message translates to:
  /// **'Select seat'**
  String get routes_step3Title;

  /// No description provided for @routes_step3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your place on board'**
  String get routes_step3Subtitle;

  /// No description provided for @routes_step4Title.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get routes_step4Title;

  /// No description provided for @routes_step4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure checkout'**
  String get routes_step4Subtitle;

  /// No description provided for @routes_howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get routes_howItWorks;

  /// No description provided for @routes_browsePopularRoutes.
  ///
  /// In en, this message translates to:
  /// **'Browse popular routes'**
  String get routes_browsePopularRoutes;

  /// No description provided for @routes_tagFastDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Fast discovery'**
  String get routes_tagFastDiscovery;

  /// No description provided for @routes_tagLiveAvailability.
  ///
  /// In en, this message translates to:
  /// **'Live availability'**
  String get routes_tagLiveAvailability;

  /// No description provided for @routes_tagPremiumRoutes.
  ///
  /// In en, this message translates to:
  /// **'Premium routes'**
  String get routes_tagPremiumRoutes;

  /// No description provided for @routes_searchTripsButton.
  ///
  /// In en, this message translates to:
  /// **'Search trips'**
  String get routes_searchTripsButton;

  /// No description provided for @booking_routeTypeDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get booking_routeTypeDirect;

  /// No description provided for @booking_routeTypeMultiStop.
  ///
  /// In en, this message translates to:
  /// **'Multi-stop'**
  String get booking_routeTypeMultiStop;

  /// No description provided for @booking_chooseBestDeparture.
  ///
  /// In en, this message translates to:
  /// **'Choose the departure that works best for you.'**
  String get booking_chooseBestDeparture;

  /// No description provided for @booking_noExactMatchCoversTrip.
  ///
  /// In en, this message translates to:
  /// **'No exact match for your search. These routes cover most of your trip.'**
  String get booking_noExactMatchCoversTrip;

  /// No description provided for @booking_noRouteMatchClosest.
  ///
  /// In en, this message translates to:
  /// **'No route matches this exact trip yet. Here are the closest options we run.'**
  String get booking_noRouteMatchClosest;

  /// No description provided for @booking_bestResultsForYou.
  ///
  /// In en, this message translates to:
  /// **'Best results for you'**
  String get booking_bestResultsForYou;

  /// No description provided for @booking_otherMatchingRoutes.
  ///
  /// In en, this message translates to:
  /// **'Other matching routes'**
  String get booking_otherMatchingRoutes;

  /// No description provided for @booking_noBookableTripsNow.
  ///
  /// In en, this message translates to:
  /// **'No bookable trips right now'**
  String get booking_noBookableTripsNow;

  /// No description provided for @booking_noScheduledTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No scheduled trips yet'**
  String get booking_noScheduledTripsYet;

  /// No description provided for @booking_routeHasPricingNoTrip.
  ///
  /// In en, this message translates to:
  /// **'This route has pricing, but no upcoming trip is open for booking.'**
  String get booking_routeHasPricingNoTrip;

  /// No description provided for @booking_tripsFromDashboardAppear.
  ///
  /// In en, this message translates to:
  /// **'Trips created from the dashboard will appear here.'**
  String get booking_tripsFromDashboardAppear;

  /// No description provided for @booking_noTripsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No trips match your filters'**
  String get booking_noTripsMatchFilters;

  /// No description provided for @booking_tryWideningFilterRange.
  ///
  /// In en, this message translates to:
  /// **'Try widening the price, seats, or time-of-day range.'**
  String get booking_tryWideningFilterRange;

  /// No description provided for @booking_continueWithThisRoute.
  ///
  /// In en, this message translates to:
  /// **'Continue with this route'**
  String get booking_continueWithThisRoute;

  /// No description provided for @booking_dragToExpandDetails.
  ///
  /// In en, this message translates to:
  /// **'Drag to expand route details'**
  String get booking_dragToExpandDetails;

  /// No description provided for @booking_isThisRouteSuitable.
  ///
  /// In en, this message translates to:
  /// **'Is this route suitable?'**
  String get booking_isThisRouteSuitable;

  /// No description provided for @booking_closestRoutesForSearch.
  ///
  /// In en, this message translates to:
  /// **'Closest routes for your search'**
  String get booking_closestRoutesForSearch;

  /// No description provided for @booking_editStops.
  ///
  /// In en, this message translates to:
  /// **'Edit stops'**
  String get booking_editStops;

  /// No description provided for @booking_noBookableRouteFound.
  ///
  /// In en, this message translates to:
  /// **'No bookable route found'**
  String get booking_noBookableRouteFound;

  /// No description provided for @booking_tryDifferentDepartureDest.
  ///
  /// In en, this message translates to:
  /// **'Try a different departure, destination, or travel time.'**
  String get booking_tryDifferentDepartureDest;

  /// No description provided for @booking_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get booking_distance;

  /// No description provided for @booking_startingPrice.
  ///
  /// In en, this message translates to:
  /// **'Starting price'**
  String get booking_startingPrice;

  /// No description provided for @booking_priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get booking_priceRange;

  /// No description provided for @booking_stopsNotPublishedYet.
  ///
  /// In en, this message translates to:
  /// **'Stops are not published yet'**
  String get booking_stopsNotPublishedYet;

  /// No description provided for @booking_routeStationsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Route stations will appear here once available.'**
  String get booking_routeStationsWillAppear;

  /// No description provided for @booking_routeTimeline.
  ///
  /// In en, this message translates to:
  /// **'Route timeline'**
  String get booking_routeTimeline;

  /// No description provided for @booking_whereGetOnOffShort.
  ///
  /// In en, this message translates to:
  /// **'Where you can get on and off'**
  String get booking_whereGetOnOffShort;

  /// No description provided for @booking_oneStop.
  ///
  /// In en, this message translates to:
  /// **'1 stop'**
  String get booking_oneStop;

  /// No description provided for @booking_stopCapabilityBoardAlight.
  ///
  /// In en, this message translates to:
  /// **'Pickup & drop-off'**
  String get booking_stopCapabilityBoardAlight;

  /// No description provided for @booking_stopCapabilityBoardOnly.
  ///
  /// In en, this message translates to:
  /// **'Pickup only'**
  String get booking_stopCapabilityBoardOnly;

  /// No description provided for @booking_stopCapabilityAlightOnly.
  ///
  /// In en, this message translates to:
  /// **'Drop-off only'**
  String get booking_stopCapabilityAlightOnly;

  /// No description provided for @booking_stopCapabilityPassThrough.
  ///
  /// In en, this message translates to:
  /// **'Pass-through'**
  String get booking_stopCapabilityPassThrough;

  /// No description provided for @booking_stopStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get booking_stopStart;

  /// No description provided for @booking_stopEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get booking_stopEnd;

  /// No description provided for @booking_filterTrips.
  ///
  /// In en, this message translates to:
  /// **'Filter trips'**
  String get booking_filterTrips;

  /// No description provided for @booking_filterVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get booking_filterVehicleType;

  /// No description provided for @booking_filterTimeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get booking_filterTimeOfDay;

  /// No description provided for @booking_filterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get booking_filterAny;

  /// No description provided for @booking_filterSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get booking_filterSortBy;

  /// No description provided for @booking_dayPartMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get booking_dayPartMorning;

  /// No description provided for @booking_dayPartAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get booking_dayPartAfternoon;

  /// No description provided for @booking_dayPartEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get booking_dayPartEvening;

  /// No description provided for @booking_tripSortEarliestDeparture.
  ///
  /// In en, this message translates to:
  /// **'Earliest departure'**
  String get booking_tripSortEarliestDeparture;

  /// No description provided for @booking_needAChange.
  ///
  /// In en, this message translates to:
  /// **'Need a change?'**
  String get booking_needAChange;

  /// No description provided for @booking_fare.
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get booking_fare;

  /// No description provided for @booking_fareBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Fare breakdown'**
  String get booking_fareBreakdown;

  /// No description provided for @booking_ridesStartsOn.
  ///
  /// In en, this message translates to:
  /// **'{rides} · starts {date}'**
  String booking_ridesStartsOn(String rides, String date);

  /// No description provided for @booking_worksOutTo.
  ///
  /// In en, this message translates to:
  /// **'Works out to'**
  String get booking_worksOutTo;

  /// No description provided for @booking_youSave.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get booking_youSave;

  /// No description provided for @booking_vsSingleTickets.
  ///
  /// In en, this message translates to:
  /// **'vs. {count} single tickets'**
  String booking_vsSingleTickets(int count);

  /// No description provided for @booking_totalDue.
  ///
  /// In en, this message translates to:
  /// **'Total due'**
  String get booking_totalDue;

  /// No description provided for @booking_yourTicket.
  ///
  /// In en, this message translates to:
  /// **'Your ticket'**
  String get booking_yourTicket;

  /// No description provided for @booking_ridesLabel.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get booking_ridesLabel;

  /// No description provided for @booking_oneRide.
  ///
  /// In en, this message translates to:
  /// **'1 ride'**
  String get booking_oneRide;

  /// No description provided for @booking_receiptTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Receipts must be 8 MB or smaller.'**
  String get booking_receiptTooLarge;

  /// No description provided for @booking_receiptUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That file could not be read. Try another one.'**
  String get booking_receiptUnreadable;

  /// No description provided for @booking_someDetailsAreMissing.
  ///
  /// In en, this message translates to:
  /// **'Some booking details are missing.'**
  String get booking_someDetailsAreMissing;

  /// No description provided for @booking_choosePaymentMethodToContinue.
  ///
  /// In en, this message translates to:
  /// **'Choose a payment method to continue.'**
  String get booking_choosePaymentMethodToContinue;

  /// No description provided for @booking_receiptStillUploading.
  ///
  /// In en, this message translates to:
  /// **'Your receipt is still uploading.'**
  String get booking_receiptStillUploading;

  /// No description provided for @booking_attachReceiptToContinue.
  ///
  /// In en, this message translates to:
  /// **'Attach your transfer receipt to continue.'**
  String get booking_attachReceiptToContinue;

  /// No description provided for @booking_submitReceipt.
  ///
  /// In en, this message translates to:
  /// **'Submit receipt'**
  String get booking_submitReceipt;

  /// No description provided for @booking_couldNotLoadPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'We could not load the ways to pay. Your seat is still yours — try again.'**
  String get booking_couldNotLoadPaymentMethods;

  /// No description provided for @booking_proofOfTransfer.
  ///
  /// In en, this message translates to:
  /// **'Proof of transfer'**
  String get booking_proofOfTransfer;

  /// No description provided for @booking_receiptAttachedNote.
  ///
  /// In en, this message translates to:
  /// **'Attached. Our team will check it against your transfer.'**
  String get booking_receiptAttachedNote;

  /// No description provided for @booking_receiptHintUpTo8mb.
  ///
  /// In en, this message translates to:
  /// **'A screenshot or PDF of the transfer — up to 8 MB.'**
  String get booking_receiptHintUpTo8mb;

  /// No description provided for @booking_uploadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get booking_uploadingEllipsis;

  /// No description provided for @booking_replaceReceipt.
  ///
  /// In en, this message translates to:
  /// **'Replace receipt'**
  String get booking_replaceReceipt;

  /// No description provided for @booking_attachReceipt.
  ///
  /// In en, this message translates to:
  /// **'Attach receipt'**
  String get booking_attachReceipt;

  /// No description provided for @booking_sendMethodTo.
  ///
  /// In en, this message translates to:
  /// **'Send {method} to'**
  String booking_sendMethodTo(String method);

  /// No description provided for @booking_contactSupportForTransfer.
  ///
  /// In en, this message translates to:
  /// **'Contact support for the transfer details.'**
  String get booking_contactSupportForTransfer;

  /// No description provided for @booking_copyAccount.
  ///
  /// In en, this message translates to:
  /// **'Copy account'**
  String get booking_copyAccount;

  /// No description provided for @booking_accountNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Account number copied.'**
  String get booking_accountNumberCopied;

  /// No description provided for @booking_transferReferenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Transfer reference (optional)'**
  String get booking_transferReferenceOptional;

  /// No description provided for @booking_paidFromPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone number you paid from (optional)'**
  String get booking_paidFromPhoneOptional;

  /// No description provided for @booking_distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String booking_distanceMeters(int meters);

  /// No description provided for @booking_distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String booking_distanceKm(String km);

  /// No description provided for @booking_ridersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} riders'**
  String booking_ridersCount(int count);

  /// No description provided for @booking_tracingRoad.
  ///
  /// In en, this message translates to:
  /// **'Tracing road…'**
  String get booking_tracingRoad;

  /// No description provided for @booking_sortShortestDuration.
  ///
  /// In en, this message translates to:
  /// **'Shortest duration'**
  String get booking_sortShortestDuration;

  /// No description provided for @booking_sortMostTrips.
  ///
  /// In en, this message translates to:
  /// **'Most trips'**
  String get booking_sortMostTrips;

  /// No description provided for @booking_filterRoutes.
  ///
  /// In en, this message translates to:
  /// **'Filter routes'**
  String get booking_filterRoutes;

  /// No description provided for @booking_seatsAvailableShort.
  ///
  /// In en, this message translates to:
  /// **'Seats available'**
  String get booking_seatsAvailableShort;

  /// No description provided for @booking_checkLater.
  ///
  /// In en, this message translates to:
  /// **'Check later'**
  String get booking_checkLater;

  /// No description provided for @booking_noActiveRoutesYet.
  ///
  /// In en, this message translates to:
  /// **'No active routes yet'**
  String get booking_noActiveRoutesYet;

  /// No description provided for @booking_routesFromDashboardAppear.
  ///
  /// In en, this message translates to:
  /// **'Routes published from the dashboard will appear here when they are ready for booking.'**
  String get booking_routesFromDashboardAppear;

  /// No description provided for @booking_refreshRoutes.
  ///
  /// In en, this message translates to:
  /// **'Refresh routes'**
  String get booking_refreshRoutes;

  /// No description provided for @booking_noRoutesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No routes match your search'**
  String get booking_noRoutesMatchSearch;

  /// No description provided for @booking_tryDifferentSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or adjust your filters.'**
  String get booking_tryDifferentSearchTerm;

  /// No description provided for @booking_resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get booking_resetFilters;

  /// No description provided for @booking_pricesAreForRoute.
  ///
  /// In en, this message translates to:
  /// **'Prices are for {pickup} → {dropoff}.'**
  String booking_pricesAreForRoute(String pickup, String dropoff);

  /// No description provided for @booking_yourPickupFallback.
  ///
  /// In en, this message translates to:
  /// **'your pickup'**
  String get booking_yourPickupFallback;

  /// No description provided for @booking_yourStopFallback.
  ///
  /// In en, this message translates to:
  /// **'your stop'**
  String get booking_yourStopFallback;

  /// No description provided for @booking_optionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} options'**
  String booking_optionsCount(int count);

  /// No description provided for @booking_chooseYourFare.
  ///
  /// In en, this message translates to:
  /// **'Choose your fare'**
  String get booking_chooseYourFare;

  /// No description provided for @booking_reviewBooking.
  ///
  /// In en, this message translates to:
  /// **'Review booking'**
  String get booking_reviewBooking;

  /// No description provided for @seatSelection_defaultVehicleName.
  ///
  /// In en, this message translates to:
  /// **'Standard Coach'**
  String get seatSelection_defaultVehicleName;

  /// No description provided for @seatSelection_defaultRoute.
  ///
  /// In en, this message translates to:
  /// **'Route not selected'**
  String get seatSelection_defaultRoute;

  /// No description provided for @communication_hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr ago'**
  String communication_hoursAgo(int hours);

  /// No description provided for @referral_inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Join me on EasyWay and book your daily commute! Use my referral code {code} to get a welcome reward.\n{link}'**
  String referral_inviteMessage(String code, String link);

  /// No description provided for @mySubscription_title.
  ///
  /// In en, this message translates to:
  /// **'My Subscription'**
  String get mySubscription_title;

  /// No description provided for @mySubscription_statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get mySubscription_statusActive;

  /// No description provided for @mySubscription_statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get mySubscription_statusExpired;

  /// No description provided for @mySubscription_statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get mySubscription_statusPending;

  /// No description provided for @mySubscription_started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get mySubscription_started;

  /// No description provided for @mySubscription_expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get mySubscription_expires;

  /// No description provided for @mySubscription_tripsUsedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} trips used'**
  String mySubscription_tripsUsedOfTotal(int used, int total);

  /// No description provided for @mySubscription_tripsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} trips remaining'**
  String mySubscription_tripsRemaining(int count);

  /// No description provided for @mySubscription_unlimitedTrips.
  ///
  /// In en, this message translates to:
  /// **'Unlimited trips'**
  String get mySubscription_unlimitedTrips;

  /// No description provided for @mySubscription_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active subscription'**
  String get mySubscription_emptyTitle;

  /// No description provided for @mySubscription_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Packages are offered while you book a trip, priced for the route you pick.'**
  String get mySubscription_emptyBody;

  /// No description provided for @mySubscription_findTrip.
  ///
  /// In en, this message translates to:
  /// **'Find a trip'**
  String get mySubscription_findTrip;

  /// No description provided for @trips_attentionAwaitingReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the office to check your payment'**
  String get trips_attentionAwaitingReviewTitle;

  /// No description provided for @trips_attentionAwaitingReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Your seat is held while {office} reviews the receipt. We\'ll notify you as soon as it\'s approved.'**
  String trips_attentionAwaitingReviewBody(String office);

  /// No description provided for @trips_attentionAwaitingReviewBodyNoOffice.
  ///
  /// In en, this message translates to:
  /// **'Your seat is held while the office reviews the receipt. We\'ll notify you as soon as it\'s approved.'**
  String get trips_attentionAwaitingReviewBodyNoOffice;

  /// No description provided for @trips_attentionPaymentIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment not completed'**
  String get trips_attentionPaymentIncompleteTitle;

  /// No description provided for @trips_attentionPaymentIncompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your seat is only held until payment is settled. Finish paying or cancel to free it.'**
  String get trips_attentionPaymentIncompleteBody;

  /// No description provided for @trips_attentionPaymentRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment was not accepted'**
  String get trips_attentionPaymentRejectedTitle;

  /// No description provided for @trips_attentionPaymentRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'The office could not verify this payment. Contact support or book again.'**
  String get trips_attentionPaymentRejectedBody;

  /// No description provided for @trips_attentionRefundDueTitle.
  ///
  /// In en, this message translates to:
  /// **'This trip was cancelled after you paid'**
  String get trips_attentionRefundDueTitle;

  /// No description provided for @trips_attentionRefundDueBody.
  ///
  /// In en, this message translates to:
  /// **'You are owed a refund for this booking. Open support to follow it up.'**
  String get trips_attentionRefundDueBody;

  /// No description provided for @trips_attentionNeedsSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'This booking needs checking'**
  String get trips_attentionNeedsSupportTitle;

  /// No description provided for @trips_attentionNeedsSupportBody.
  ///
  /// In en, this message translates to:
  /// **'Its booking and payment records disagree, so we won\'t guess. Please contact support with reference {reference}.'**
  String trips_attentionNeedsSupportBody(String reference);

  /// No description provided for @trips_attentionOpenSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get trips_attentionOpenSupport;

  /// No description provided for @trips_seatHeldNotYours.
  ///
  /// In en, this message translates to:
  /// **'Seat held — not confirmed yet'**
  String get trips_seatHeldNotYours;

  /// No description provided for @trips_bookingStateReserved.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get trips_bookingStateReserved;

  /// No description provided for @trips_bookingStateConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get trips_bookingStateConfirmed;

  /// No description provided for @trips_bookingStateCompleted.
  ///
  /// In en, this message translates to:
  /// **'Travelled'**
  String get trips_bookingStateCompleted;

  /// No description provided for @trips_bookingStateCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get trips_bookingStateCancelled;

  /// No description provided for @offices_nothingListedTitle.
  ///
  /// In en, this message translates to:
  /// **'This office has nothing listed right now'**
  String get offices_nothingListedTitle;

  /// No description provided for @offices_nothingListedBody.
  ///
  /// In en, this message translates to:
  /// **'No departures and no routes are published yet. Try another office, or search every route on the platform.'**
  String get offices_nothingListedBody;

  /// No description provided for @offices_browseOtherOffices.
  ///
  /// In en, this message translates to:
  /// **'Browse other offices'**
  String get offices_browseOtherOffices;

  /// No description provided for @offices_searchAllRoutes.
  ///
  /// In en, this message translates to:
  /// **'Search all routes'**
  String get offices_searchAllRoutes;

  /// No description provided for @offices_new.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get offices_new;

  /// No description provided for @offices_statDepartures.
  ///
  /// In en, this message translates to:
  /// **'Departures'**
  String get offices_statDepartures;

  /// No description provided for @offices_statRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get offices_statRoutes;

  /// No description provided for @offices_statPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get offices_statPackages;

  /// No description provided for @packages_priceAtBooking.
  ///
  /// In en, this message translates to:
  /// **'Price shown when you pick a trip'**
  String get packages_priceAtBooking;

  /// No description provided for @packages_priceDependsTitle.
  ///
  /// In en, this message translates to:
  /// **'Priced on the route you pick'**
  String get packages_priceDependsTitle;

  /// No description provided for @packages_priceDependsBody.
  ///
  /// In en, this message translates to:
  /// **'Every route has its own fare, so this package is priced once you choose a trip.'**
  String get packages_priceDependsBody;

  /// No description provided for @packages_howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get packages_howItWorks;

  /// No description provided for @packages_step1Title.
  ///
  /// In en, this message translates to:
  /// **'Pick your route'**
  String get packages_step1Title;

  /// No description provided for @packages_step1Body.
  ///
  /// In en, this message translates to:
  /// **'Choose the trip you commute on — the package binds to that route.'**
  String get packages_step1Body;

  /// No description provided for @packages_step2Title.
  ///
  /// In en, this message translates to:
  /// **'See your price'**
  String get packages_step2Title;

  /// No description provided for @packages_step2Body.
  ///
  /// In en, this message translates to:
  /// **'The package is priced for that exact route, then you pay once.'**
  String get packages_step2Body;

  /// No description provided for @packages_step3Title.
  ///
  /// In en, this message translates to:
  /// **'Ride your seats'**
  String get packages_step3Title;

  /// No description provided for @packages_step3Body.
  ///
  /// In en, this message translates to:
  /// **'Book any departure on the route until your rides or days run out.'**
  String get packages_step3Body;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
