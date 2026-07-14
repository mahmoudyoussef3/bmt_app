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

  /// No description provided for @packages_configureTravel.
  ///
  /// In en, this message translates to:
  /// **'Configure Travel'**
  String get packages_configureTravel;

  /// No description provided for @packages_reviewSummary.
  ///
  /// In en, this message translates to:
  /// **'Review Summary'**
  String get packages_reviewSummary;

  /// No description provided for @packages_subscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed!'**
  String get packages_subscribed;

  /// No description provided for @packages_subscribePlan.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Plan'**
  String get packages_subscribePlan;

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

  /// No description provided for @packages_savePercent.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String packages_savePercent(int percent);

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

  /// No description provided for @packages_totalSavings.
  ///
  /// In en, this message translates to:
  /// **'Total Savings'**
  String get packages_totalSavings;

  /// No description provided for @packages_egpAmount.
  ///
  /// In en, this message translates to:
  /// **'EGP {amount}'**
  String packages_egpAmount(String amount);

  /// No description provided for @packages_originalPrice.
  ///
  /// In en, this message translates to:
  /// **'Original: EGP {price}'**
  String packages_originalPrice(String price);

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

  /// No description provided for @packages_vipBoarding.
  ///
  /// In en, this message translates to:
  /// **'Priority VIP Boarding'**
  String get packages_vipBoarding;

  /// No description provided for @packages_vipBoardingDesc.
  ///
  /// In en, this message translates to:
  /// **'First access onboarding and customer concierge helpline.'**
  String get packages_vipBoardingDesc;

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
  /// **'1. Packages cannot be refunded once activated.'**
  String get packages_termsText1;

  /// No description provided for @packages_termsText2.
  ///
  /// In en, this message translates to:
  /// **'2. Seats must be confirmed at least 2 hours before trip.'**
  String get packages_termsText2;

  /// No description provided for @packages_termsText3.
  ///
  /// In en, this message translates to:
  /// **'3. Package holds up to {count} reservations for the selected route.'**
  String packages_termsText3(int count);

  /// No description provided for @packages_chooseRouteConfig.
  ///
  /// In en, this message translates to:
  /// **'Choose Route & Configure'**
  String get packages_chooseRouteConfig;

  /// No description provided for @packages_basePrice.
  ///
  /// In en, this message translates to:
  /// **'Base Price'**
  String get packages_basePrice;

  /// No description provided for @packages_packageDiscount.
  ///
  /// In en, this message translates to:
  /// **'Package Discount'**
  String get packages_packageDiscount;

  /// No description provided for @packages_percentOff.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Off'**
  String packages_percentOff(int percent);

  /// No description provided for @packages_subscriptionCost.
  ///
  /// In en, this message translates to:
  /// **'Subscription Cost'**
  String get packages_subscriptionCost;

  /// No description provided for @packages_selectTargetRoute.
  ///
  /// In en, this message translates to:
  /// **'Select Target Route'**
  String get packages_selectTargetRoute;

  /// No description provided for @packages_pickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Pickup Point'**
  String get packages_pickupPoint;

  /// No description provided for @packages_destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get packages_destination;

  /// No description provided for @packages_selectVehicleCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle Category'**
  String get packages_selectVehicleCategory;

  /// No description provided for @packages_reviewActivation.
  ///
  /// In en, this message translates to:
  /// **'Review & Activation'**
  String get packages_reviewActivation;

  /// No description provided for @packages_selectedPackage.
  ///
  /// In en, this message translates to:
  /// **'Selected Package'**
  String get packages_selectedPackage;

  /// No description provided for @packages_route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get packages_route;

  /// No description provided for @packages_vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get packages_vehicle;

  /// No description provided for @packages_billingDetails.
  ///
  /// In en, this message translates to:
  /// **'Billing Details'**
  String get packages_billingDetails;

  /// No description provided for @packages_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get packages_paymentMethod;

  /// No description provided for @packages_walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get packages_walletBalance;

  /// No description provided for @packages_currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance: EGP {balance}'**
  String packages_currentBalance(String balance);

  /// No description provided for @packages_sufficient.
  ///
  /// In en, this message translates to:
  /// **'Sufficient'**
  String get packages_sufficient;

  /// No description provided for @packages_payActivate.
  ///
  /// In en, this message translates to:
  /// **'Pay & Activate'**
  String get packages_payActivate;

  /// No description provided for @packages_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get packages_processing;

  /// No description provided for @packages_subscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Subscription Active!'**
  String get packages_subscriptionActive;

  /// No description provided for @packages_subId.
  ///
  /// In en, this message translates to:
  /// **'Subscription ID: {id}'**
  String packages_subId(String id);

  /// No description provided for @packages_successDesc.
  ///
  /// In en, this message translates to:
  /// **'Your commute package is now active. You can start booking rides immediately from your dashboard.'**
  String get packages_successDesc;

  /// No description provided for @packages_returnHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get packages_returnHome;

  /// No description provided for @packages_bookFirstRide.
  ///
  /// In en, this message translates to:
  /// **'Book First Ride'**
  String get packages_bookFirstRide;

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
