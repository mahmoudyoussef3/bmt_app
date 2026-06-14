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
  /// **'Select on Map'**
  String get booking_selectOnMap;

  /// No description provided for @booking_selectOnMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Google Maps style picker'**
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
  /// **'Select pickup and destination on the map'**
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
  /// **'Tap the map to cycle pickup points'**
  String get booking_tapMapPickup;

  /// No description provided for @booking_tapMapDest.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to cycle destination points'**
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

  /// No description provided for @dashboard_liveTrips.
  ///
  /// In en, this message translates to:
  /// **'Live Trips'**
  String get dashboard_liveTrips;

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
