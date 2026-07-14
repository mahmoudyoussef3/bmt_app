// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get common_retry => 'إعادة المحاولة';

  @override
  String get common_dismiss => 'إغلاق';

  @override
  String get common_confirm => 'تأكيد';

  @override
  String get common_cancel => 'إلغاء';

  @override
  String get common_save => 'حفظ';

  @override
  String get common_delete => 'حذف';

  @override
  String get common_error => 'حدث خطأ غير متوقع';

  @override
  String home_goodMorning(String name) {
    return 'صباح الخير، $name';
  }

  @override
  String get home_readyForCommute => 'مستعد لرحلتك اليوم؟';

  @override
  String get home_tripStarted => 'رحلتك بدأت';

  @override
  String get home_upcomingTrip => 'رحلتك القادمة';

  @override
  String get home_trackBus => 'تابع مسار العربية والمحطة الحالية';

  @override
  String get home_reviewTrip => 'راجع تفاصيل الرحلة قبل موعد التحرك';

  @override
  String get home_tripRoute => 'مسار الرحلة';

  @override
  String get home_liveTracking => 'تتبع مباشر';

  @override
  String home_stationsCount(int count) {
    return '$count محطات';
  }

  @override
  String home_moreStations(int count) {
    return 'يوجد $count محطات أخرى في تفاصيل الرحلة';
  }

  @override
  String get home_pointPassed => 'تم المرور';

  @override
  String get home_pointCurrent => 'العربية هنا الآن';

  @override
  String get home_pointStart => 'نقطة البداية';

  @override
  String get home_pointEnd => 'نقطة الوصول';

  @override
  String get home_pointStation => 'محطة مرور';

  @override
  String get home_trackTrip => 'تتبع الرحلة';

  @override
  String get home_tripDetails => 'التفاصيل';

  @override
  String get home_whereTo => 'إلى أين تريد الذهاب؟';

  @override
  String get home_searchDestination => 'ابحث عن وجهتك...';

  @override
  String get home_quickDestinations => 'وجهات سريعة';

  @override
  String get home_packagesTitle => 'الباقات';

  @override
  String get home_packagesSubtitle => 'مصممة للركاب اليوميين';

  @override
  String get home_seeAll => 'عرض المزيد';

  @override
  String get home_popularRoutesTitle => 'مسارات شائعة';

  @override
  String get home_popularRoutesSubtitle => 'رحلات متكررة من منطقتك';

  @override
  String get home_viewAll => 'عرض الكل';

  @override
  String get home_contactSupport => 'تحتاج مساعدة؟ تواصل مع الدعم';

  @override
  String get auth_welcomeTitle => 'مرحباً بك في EasyWay';

  @override
  String get auth_welcomeSubtitle =>
      'رفيقك اليومي المميز لإدارة رحلاتك ومواصلاتك.';

  @override
  String get auth_login => 'تسجيل الدخول';

  @override
  String get auth_createAccount => 'إنشاء حساب';

  @override
  String get auth_termsPrefix => 'بالمتابعة، فإنك توافق على ';

  @override
  String get auth_termsOfService => 'شروط الخدمة';

  @override
  String get auth_termsAnd => ' و ';

  @override
  String get auth_privacyPolicy => 'سياسة الخصوصية';

  @override
  String get auth_signInFailed => 'فشل تسجيل الدخول.';

  @override
  String get auth_welcomeBack => 'مرحباً بعودتك';

  @override
  String get auth_signInSubtitle => 'سجل دخولك لحجز رحلتك القادمة';

  @override
  String get auth_email => 'البريد الإلكتروني';

  @override
  String get auth_required => 'مطلوب';

  @override
  String get auth_invalidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get auth_password => 'كلمة المرور';

  @override
  String get auth_forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get auth_signIn => 'تسجيل الدخول';

  @override
  String get auth_noAccount => 'ليس لديك حساب؟ ';

  @override
  String get auth_signUp => 'إنشاء حساب';

  @override
  String get auth_registrationFailed => 'فشل إنشاء الحساب.';

  @override
  String get auth_createAccountTitle => 'إنشاء حساب';

  @override
  String get auth_signUpSubtitle => 'انضم إلى EasyWay لحجز وتتبع رحلاتك';

  @override
  String get auth_fullName => 'الاسم الكامل';

  @override
  String get auth_invalidFullName => 'أدخل اسمك الكامل';

  @override
  String get auth_phoneNumber => 'رقم الهاتف';

  @override
  String get auth_invalidPhone => 'أدخل رقم هاتف صحيح';

  @override
  String get auth_invalidPassword =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get auth_forgotPasswordTitle => 'هل نسيت كلمة المرور؟';

  @override
  String get auth_forgotPasswordSubtitle =>
      'لا تقلق. أدخل بريدك الإلكتروني وسنرسل لك رابطاً آمناً لإعادة تعيين كلمة المرور الخاصة بك.';

  @override
  String get auth_sendResetLink => 'إرسال رابط التعيين';

  @override
  String get auth_backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get auth_checkEmailTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String auth_checkEmailMessage(String email) {
    return 'أرسلنا رابطاً آمناً إلى $email. افتحه لإنشاء كلمة مرور جديدة.';
  }

  @override
  String get auth_resendLink => 'إعادة إرسال الرابط';

  @override
  String auth_resendIn(int seconds) {
    return 'إعادة إرسال الرابط خلال $seconds ثانية';
  }

  @override
  String get auth_rateLimited => 'من فضلك انتظر قليلًا قبل طلب رابط جديد.';

  @override
  String get auth_unknownError => 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.';

  @override
  String get auth_alreadyHaveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get booking_title => 'الحجوزات';

  @override
  String get booking_subtitle => 'اختر كيف تريد حجز رحلتك';

  @override
  String get booking_today => 'اليوم';

  @override
  String get booking_month => 'الشهر';

  @override
  String get booking_dailyBooking => 'حجز يومي';

  @override
  String get booking_dailyBookingDesc => 'احجز رحلتك خطوة بخطوة لليوم';

  @override
  String get booking_monthlySubscription => 'اشتراك شهري';

  @override
  String get booking_monthlySubscriptionDesc => 'احجز مسارك ومقعدك الدائم';

  @override
  String get booking_summary => 'الملخص';

  @override
  String get booking_activeTrips => 'رحلات نشطة';

  @override
  String get booking_upcomingBookings => 'حجوزات قادمة';

  @override
  String get booking_reservedSeats => 'مقاعد محجوزة';

  @override
  String get booking_selectPickupDestination =>
      'اختر نقطة التحرك والوصول للمتابعة';

  @override
  String get booking_searchTrip => 'بحث عن رحلة';

  @override
  String get booking_pickupLocation => 'نقطة التحرك';

  @override
  String get booking_destination => 'نقطة الوصول';

  @override
  String get booking_selectDate => 'اختر التاريخ';

  @override
  String get booking_selectTime => 'اختر الوقت';

  @override
  String get booking_otherWaysToSearch => 'طرق أخرى للبحث';

  @override
  String get booking_browseOrPickMap => 'تصفح أو اختر من الخريطة';

  @override
  String get booking_popularRoutes => 'مسارات شائعة';

  @override
  String get booking_popularRoutesSubtitle =>
      'أكثر الرحلات استخداماً في منطقتك';

  @override
  String get booking_selectOnMap => 'خريطة المسار';

  @override
  String get booking_selectOnMapSubtitle =>
      'قرّب أو بعّد الخريطة لعرض مسارات الرحلات';

  @override
  String get booking_selectPickupPoint => 'اختر نقطة التحرك';

  @override
  String get booking_selectDestination => 'اختر نقطة الوصول';

  @override
  String get booking_availableVehicles => 'العربيات المتاحة';

  @override
  String get booking_pickBestShuttle => 'اختر أفضل باص لرحلتك';

  @override
  String get booking_bookYourRide => 'احجز رحلتك';

  @override
  String booking_stepOf4(int step) {
    return 'خطوة $step من 4';
  }

  @override
  String get booking_selectVehicle => 'اختيار العربية';

  @override
  String booking_availableOptions(int count) {
    return '$count اختيارات متاحة الآن';
  }

  @override
  String get booking_sortRecommended => 'الأفضل';

  @override
  String get booking_sortPriceLow => 'السعر';

  @override
  String get booking_sortRating => 'التقييم';

  @override
  String get booking_searchingBestOptions => 'جاري البحث عن أفضل الخيارات...';

  @override
  String get booking_errorLoadingVehicles => 'لم نتمكن من تحميل العربيات';

  @override
  String get common_tryAgain => 'حاول مرة أخرى';

  @override
  String get booking_noVehiclesAvailable => 'لا توجد عربيات متاحة';

  @override
  String get booking_noVehiclesDesc =>
      'لا توجد عربيات مناسبة لهذا الوقت. جرّب وقت وصول مختلف أو أعد البحث.';

  @override
  String get booking_searchAgain => 'إعادة البحث';

  @override
  String get booking_selectRoute => 'اختر المسار';

  @override
  String get booking_compareVehicles => 'مقارنة العربيات';

  @override
  String get booking_availableRoutes => 'المسارات المتاحة';

  @override
  String booking_optionsForSearch(int count) {
    return '$count خيارات لبحثك';
  }

  @override
  String get booking_map => 'الخريطة';

  @override
  String get booking_vehicleDetails => 'تفاصيل العربية';

  @override
  String get booking_recommendedForYou => 'موصى بها لك';

  @override
  String get booking_comfortAndAmenities => 'الراحة والتجهيزات';

  @override
  String get booking_comfortDesc => 'راجع مستوى الراحة قبل اختيار المقعد';

  @override
  String get booking_driver => 'السائق';

  @override
  String get booking_driverDesc => 'بيانات الكابتن وتقييمه';

  @override
  String get booking_priceAndAvailability => 'السعر والتوافر';

  @override
  String get booking_priceDesc => 'التكلفة وعدد المقاعد المتاحة';

  @override
  String get booking_ac => 'تكييف';

  @override
  String get booking_available => 'متاح';

  @override
  String get booking_unavailable => 'غير متاح';

  @override
  String get booking_seatType => 'نوع المقاعد';

  @override
  String get booking_recliningSeats => 'مقاعد قابلة للإمالة';

  @override
  String get common_yes => 'نعم';

  @override
  String get common_no => 'لا';

  @override
  String get booking_vehicleCondition => 'حالة العربية';

  @override
  String get booking_legRoom => 'مساحة القدم';

  @override
  String get booking_ratingExcellent => 'ممتازة';

  @override
  String get booking_ratingVeryGood => 'جيدة جدًا';

  @override
  String get booking_ratingGood => 'جيدة';

  @override
  String get booking_ratingNormal => 'عادية';

  @override
  String get booking_certified => 'معتمد';

  @override
  String get booking_completedTrips => 'رحلة مكتملة';

  @override
  String get booking_yearsExperience => 'سنوات خبرة';

  @override
  String get booking_tripPrice => 'سعر الرحلة';

  @override
  String get booking_remaining => 'متبقي';

  @override
  String get booking_selectPickupDestMap =>
      'يتم تحديد نقطة التحرك والوصول حسب الرحلة المختارة';

  @override
  String get booking_popular => 'شائع';

  @override
  String get booking_pickup => 'نقطة التحرك';

  @override
  String get booking_tapMapPickup => 'قرّب أو بعّد الخريطة لعرض نقاط التحرك';

  @override
  String get booking_tapMapDest => 'قرّب أو بعّد الخريطة لعرض نقاط الوصول';

  @override
  String get booking_pickupPoint => 'نقطة التحرك';

  @override
  String get booking_notSet => 'لم تحدد';

  @override
  String get booking_destinationPoint => 'نقطة الوصول';

  @override
  String get booking_confirmRoute => 'تأكيد المسار';

  @override
  String get booking_availableSeats => 'المقاعد المتاحة';

  @override
  String get packages_commutePackages => 'باقات التنقل';

  @override
  String get packages_packageDetails => 'تفاصيل الباقة';

  @override
  String get packages_configureTravel => 'ضبط الرحلة';

  @override
  String get packages_reviewSummary => 'مراجعة الملخص';

  @override
  String get packages_subscribed => 'تم الاشتراك!';

  @override
  String get packages_subscribePlan => 'الاشتراك في الخطة';

  @override
  String get packages_all => 'الكل';

  @override
  String get packages_weekly => 'أسبوعية';

  @override
  String get packages_monthly => 'شهرية';

  @override
  String get packages_quarterly => 'ربع سنوية';

  @override
  String packages_savePercent(int percent) {
    return 'وفر $percent%';
  }

  @override
  String get packages_duration => 'المدة';

  @override
  String get packages_totalTrips => 'إجمالي الرحلات';

  @override
  String packages_ridesCount(int count) {
    return '$count رحلات';
  }

  @override
  String get packages_totalSavings => 'إجمالي التوفير';

  @override
  String packages_egpAmount(String amount) {
    return 'ج.م $amount';
  }

  @override
  String packages_originalPrice(String price) {
    return 'السعر الأصلي: $price ج.م';
  }

  @override
  String get packages_startingPrice => 'يبدأ من';

  @override
  String get packages_whatIsIncluded => 'ماذا تشمل الباقة؟';

  @override
  String get packages_reservedSeatGuaranteed => 'مقعد محجوز ومضمون';

  @override
  String get packages_reservedSeatDesc =>
      'مقعدك المفضل محجوز لكل رحلة تنقل يومية.';

  @override
  String get packages_flexibleTiming => 'مرونة في أوقات الرحلات';

  @override
  String get packages_flexibleTimingDesc =>
      'تعديل أوقات حجز الرحلة في أي وقت بدون رسوم إلغاء.';

  @override
  String get packages_vipBoarding => 'أولوية صعود VIP';

  @override
  String get packages_vipBoardingDesc =>
      'أولوية في الصعود ورقم خدمة عملاء خاص.';

  @override
  String get packages_routeLimits => 'حدود المسار والحجز';

  @override
  String get packages_routeScope => 'نطاق المسار';

  @override
  String get packages_routeScopeDesc => 'مسار ثابت يتم اختياره عند الدفع.';

  @override
  String get packages_includedRides => 'الرحلات المشمولة';

  @override
  String packages_singleTripsDesc(int count) {
    return '$count رحلة فردية.';
  }

  @override
  String get packages_validityPeriod => 'فترة الصلاحية';

  @override
  String packages_consecutiveDaysDesc(int days) {
    return '$days يوم متتالي.';
  }

  @override
  String get packages_termsCancellation => 'الشروط والإلغاء';

  @override
  String get packages_termsText1 =>
      '1. لا يمكن استرداد قيمة الباقات بمجرد تفعيلها.';

  @override
  String get packages_termsText2 =>
      '2. يجب تأكيد المقاعد قبل ساعتين على الأقل من موعد الرحلة.';

  @override
  String packages_termsText3(int count) {
    return '3. الباقة تمنحك حتى $count حجز للمسار المختار.';
  }

  @override
  String get packages_chooseRouteConfig => 'اختيار المسار والإعدادات';

  @override
  String get packages_basePrice => 'السعر الأساسي';

  @override
  String get packages_packageDiscount => 'خصم الباقة';

  @override
  String packages_percentOff(int percent) {
    return 'خصم $percent%';
  }

  @override
  String get packages_subscriptionCost => 'تكلفة الاشتراك';

  @override
  String get packages_selectTargetRoute => 'اختيار المسار المستهدف';

  @override
  String get packages_pickupPoint => 'نقطة التحرك';

  @override
  String get packages_destination => 'نقطة الوصول';

  @override
  String get packages_selectVehicleCategory => 'اختيار فئة العربية';

  @override
  String get packages_reviewActivation => 'المراجعة والتفعيل';

  @override
  String get packages_selectedPackage => 'الباقة المختارة';

  @override
  String get packages_route => 'المسار';

  @override
  String get packages_vehicle => 'العربية';

  @override
  String get packages_billingDetails => 'تفاصيل الدفع';

  @override
  String get packages_paymentMethod => 'طريقة الدفع';

  @override
  String get packages_walletBalance => 'رصيد المحفظة';

  @override
  String packages_currentBalance(String balance) {
    return 'الرصيد الحالي: $balance ج.م';
  }

  @override
  String get packages_sufficient => 'رصيد كافِ';

  @override
  String get packages_payActivate => 'دفع وتفعيل';

  @override
  String get packages_processing => 'جاري المعالجة';

  @override
  String get packages_subscriptionActive => 'تم التفعيل!';

  @override
  String packages_subId(String id) {
    return 'رقم الاشتراك: $id';
  }

  @override
  String get packages_successDesc =>
      'باقتك الآن مفعلة. يمكنك البدء في حجز رحلاتك فوراً من لوحة التحكم الخاصة بك.';

  @override
  String get packages_returnHome => 'العودة للرئيسية';

  @override
  String get packages_bookFirstRide => 'احجز أول رحلة';

  @override
  String get error_timeout => 'انتهى وقت الاتصال، يرجى المحاولة مرة أخرى.';

  @override
  String get error_cancelled => 'تم إلغاء الطلب.';

  @override
  String get error_noInternet => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get error_badRequest => 'طلب غير صالح.';

  @override
  String get error_unauthorized =>
      'غير مصرح لك بالوصول، يرجى تسجيل الدخول مجدداً.';

  @override
  String get error_forbidden => 'ليس لديك صلاحية للوصول.';

  @override
  String get error_notFound => 'المورد غير موجود.';

  @override
  String get error_validation => 'بيانات غير صالحة.';

  @override
  String get error_server => 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.';

  @override
  String get error_unknown => 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.';

  @override
  String get dashboard_home => 'الرئيسية';

  @override
  String get dashboard_bookings => 'الحجوزات';

  @override
  String get dashboard_trips => 'الرحلات';

  @override
  String get dashboard_fleet => 'إدارة الأسطول';

  @override
  String get dashboard_routes => 'المسارات';

  @override
  String get dashboard_subscriptions => 'الاشتراكات';

  @override
  String get dashboard_payments => 'المالية';

  @override
  String get dashboard_tickets => 'الشكاوى';

  @override
  String get dashboard_reports => 'التقارير';

  @override
  String get dashboard_settings => 'الإعدادات';

  @override
  String get dashboard_permissions => 'الصلاحيات';

  @override
  String get dashboard_panel => 'لوحة التشغيل';

  @override
  String get dashboard_system => 'نظام عمليات النقل';

  @override
  String get dashboard_menu => 'القائمة';

  @override
  String get dashboard_lightMode => 'الوضع الفاتح';

  @override
  String get dashboard_darkMode => 'الوضع الداكن';

  @override
  String get dashboard_unauthorized => 'هذه الصفحة غير متاحة للدور الحالي';

  @override
  String get onboarding_skip => 'تخطّي';

  @override
  String get onboarding_next => 'التالي';

  @override
  String get onboarding_getStarted => 'ابدأ الآن';

  @override
  String get onboarding_page1Title => 'تنقّل يومك بكل ثقة';

  @override
  String get onboarding_page1Body =>
      'احجز رحلتك في ثوانٍ، واختر مقعدك، وتابع مركبتك مباشرة حتى تصل إلى وجهتك بأمان وراحة.';

  @override
  String get onboarding_page1FeatureA => 'حجز الرحلات';

  @override
  String get onboarding_page1FeatureB => 'اكتشاف المسارات';

  @override
  String get onboarding_page2Title => 'رحلة أكثر راحة... كل يوم';

  @override
  String get onboarding_page2Body =>
      'استمتع بمركبات حديثة، مقاعد مريحة، وحجوزات منظمة تمنحك تجربة تنقّل سلسة في كل رحلة.';

  @override
  String get onboarding_page2FeatureA => 'تتبّع مباشر';

  @override
  String get onboarding_page2FeatureB => 'وقت الوصول';

  @override
  String get onboarding_page3Title => 'رحلتك تبدأ باطمئنان';

  @override
  String get onboarding_page3Body =>
      'سائقون محترفون، تتبع مباشر، وإشعارات لحظية لتبقى على اطلاع بكل تفاصيل رحلتك.';

  @override
  String get onboarding_page3FeatureA => 'الاشتراكات';

  @override
  String get onboarding_page3FeatureB => 'باقات مخفّضة';

  @override
  String get onboarding_page4Title => 'ادفع بأمان واحصل على الدعم دائماً';

  @override
  String get onboarding_page4Body =>
      'ادفع بأمان عبر وسائل موثوقة وتواصل مع فريق الدعم وقت ما تحتاج.';

  @override
  String get onboarding_page4FeatureA => 'دفع آمن';

  @override
  String get onboarding_page4FeatureB => 'دعم على مدار الساعة';

  @override
  String get welcome_trustSecure => 'دفع آمن';

  @override
  String get welcome_trustLive => 'تتبّع لحظي';

  @override
  String get welcome_trustDaily => 'تنقل يومي موثوق';

  @override
  String get authSuccess_createdTitle => 'كل شيء جاهز!';

  @override
  String get authSuccess_createdSubtitle => 'تم إنشاء حسابك. لنبدأ رحلتك.';

  @override
  String get authSuccess_verifyTitle => 'فعّل بريدك الإلكتروني';

  @override
  String authSuccess_verifySubtitle(String email) {
    return 'أرسلنا رابط تأكيد إلى $email. أكّده لتفعيل حسابك ثم سجّل الدخول.';
  }

  @override
  String get authSuccess_getStarted => 'ابدأ الآن';

  @override
  String get authSuccess_backToSignIn => 'العودة لتسجيل الدخول';

  @override
  String get authSuccess_perkBooking => 'احجز رحلاتك فوراً';

  @override
  String get authSuccess_perkTracking => 'تتبّع رحلاتك مباشرة';

  @override
  String get authSuccess_perkPasses => 'وفّر مع الباقات';

  @override
  String get auth_passwordStrengthLabel => 'قوة كلمة المرور';

  @override
  String get auth_passwordWeak => 'ضعيفة';

  @override
  String get auth_passwordFair => 'متوسطة';

  @override
  String get auth_passwordGood => 'جيدة';

  @override
  String get auth_passwordStrong => 'قوية';

  @override
  String get auth_passwordHint =>
      'استخدم ٨ أحرف على الأقل تتضمن حروفاً وأرقاماً ورمزاً.';

  @override
  String auth_policyComingSoon(String title) {
    return 'سيتوفر $title عند نشره.';
  }

  @override
  String get auth_referralCodeSection => 'رمز الإحالة (اختياري)';

  @override
  String get auth_referralCodeLabel => 'أدخل رمز الإحالة';

  @override
  String get auth_referralCodeHint =>
      'لديك رمز من صديق؟ أضفه لتحصل على مكافأة ترحيبية.';

  @override
  String get referral_pending => 'قيد الانتظار';

  @override
  String get referral_leaderboardTitle => 'أفضل المُحيلين';

  @override
  String get referral_leaderboardEmpty => 'كن أول من يتصدّر القائمة.';

  @override
  String get referral_you => 'أنت';

  @override
  String get tracking_title => 'تتبع رحلتك';

  @override
  String get tracking_loading => 'جاري تحميل رحلتك…';

  @override
  String get tracking_refresh => 'تحديث';

  @override
  String get tracking_errorTitle => 'تعذّر تحميل بيانات التتبع';

  @override
  String get tracking_emptyTitle => 'لا توجد رحلة لتتبعها';

  @override
  String get tracking_emptyBody =>
      'يظهر التتبع المباشر هنا بمجرد تأكيد أحد حجوزاتك.';

  @override
  String get tracking_emptyAction => 'تصفّح الرحلات';

  @override
  String get tracking_stateNotStarted => 'لم تبدأ رحلتك بعد';

  @override
  String get tracking_stateDriverOnWay => 'الكابتن في الطريق';

  @override
  String get tracking_stateBoarding => 'جاري صعود الركاب';

  @override
  String get tracking_stateInProgress => 'الرحلة جارية';

  @override
  String get tracking_stateCompleted => 'اكتملت الرحلة';

  @override
  String get tracking_signalLive => 'مباشر';

  @override
  String get tracking_signalStale => 'الإشارة متأخرة';

  @override
  String get tracking_signalNone => 'في انتظار إشارة الكابتن';

  @override
  String get tracking_signalOffRoute => 'خارج المسار';

  @override
  String get tracking_updatedJustNow => 'الآن';

  @override
  String tracking_updatedMinutesAgo(int minutes) {
    return 'منذ $minutes دقيقة';
  }

  @override
  String get tracking_etaToYourStop => 'يصل إلى محطتك';

  @override
  String get tracking_etaToDestination => 'تصل إلى وجهتك';

  @override
  String get tracking_etaNow => 'الآن';

  @override
  String get tracking_etaUnavailable => 'غير متاح بعد';

  @override
  String tracking_etaMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String tracking_etaHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String get tracking_sourceLive => 'من الموقع المباشر';

  @override
  String get tracking_sourceEstimated => 'تقدير';

  @override
  String get tracking_sourceScheduled => 'حسب الجدول';

  @override
  String tracking_departsAt(String time) {
    return 'الانطلاق $time';
  }

  @override
  String tracking_stopsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محطات متبقية',
      two: 'محطتان متبقيتان',
      one: 'محطة واحدة متبقية',
      zero: 'لا محطات متبقية',
    );
    return '$_temp0';
  }

  @override
  String get tracking_yourBooking => 'حجزك';

  @override
  String tracking_seat(String label) {
    return 'مقعد $label';
  }

  @override
  String get tracking_boarded => 'تم صعودك';

  @override
  String get tracking_notBoarded => 'لم يتم صعودك بعد';

  @override
  String get tracking_boardAt => 'تصعد من';

  @override
  String get tracking_alightAt => 'تنزل في';

  @override
  String get tracking_stopsTitle => 'محطات الرحلة';

  @override
  String get tracking_yourStopBadge => 'محطتك';

  @override
  String get tracking_yourDropoffBadge => 'محطة نزولك';

  @override
  String get tracking_stopDeparted => 'غادرت';

  @override
  String get tracking_stopArrived => 'عند المحطة';

  @override
  String get tracking_stopNext => 'التالية';

  @override
  String get tracking_captain => 'الكابتن';

  @override
  String get tracking_vehicle => 'المركبة';

  @override
  String get tracking_call => 'اتصال';

  @override
  String get tracking_noRating => 'لا توجد تقييمات بعد';

  @override
  String tracking_ratingWithCount(String rating, int count) {
    return '$rating ($count)';
  }

  @override
  String get tracking_noPhone => 'رقم الكابتن غير متاح';

  @override
  String get tracking_completedTitle => 'وصلت بأمان';

  @override
  String get tracking_completedBody => 'نتمنى أن تكون رحلتك كانت مريحة.';

  @override
  String get tracking_rateTrip => 'قيّم هذه الرحلة';

  @override
  String get tracking_alreadyReviewed =>
      'شكراً لك — لقد قيّمت هذه الرحلة بالفعل.';

  @override
  String get tracking_bookAgain => 'احجز رحلة أخرى';

  @override
  String get tracking_mapUnavailableTitle => 'لا تتوفر بيانات الخريطة';

  @override
  String get tracking_mapUnavailableBody =>
      'لم يتم العثور على إحداثيات لمسار هذه الرحلة.';

  @override
  String get tracking_recenter => 'توسيط المسار';

  @override
  String get tracking_followVehicle => 'تتبع المركبة';

  @override
  String get profile_title => 'حسابي';

  @override
  String profile_memberSince(String date) {
    return 'عضو منذ $date';
  }

  @override
  String get profile_guestName => 'حسابك';

  @override
  String get profile_noEmail => 'لم يتم إضافة بريد إلكتروني';

  @override
  String get profile_completeTitle => 'أكمل بيانات حسابك';

  @override
  String get profile_completeBody =>
      'أضف بياناتك الناقصة حتى يتمكن الكابتن وخدمة العملاء من التواصل معك.';

  @override
  String get profile_completeAction => 'أكمل الآن';

  @override
  String get profile_statTrips => 'رحلات تمت';

  @override
  String get profile_statUpcoming => 'رحلات قادمة';

  @override
  String get profile_statPackage => 'الاشتراك';

  @override
  String get profile_packageNone => 'لا يوجد';

  @override
  String get profile_packageActive => 'نشط';

  @override
  String profile_packageExpiringSoon(String name, String route, int days) {
    return 'اشتراك $name على خط $route ينتهي خلال $days أيام.';
  }

  @override
  String get profile_packageRenew => 'تجديد';

  @override
  String get profile_sectionAccount => 'الحساب';

  @override
  String get profile_sectionPreferences => 'التفضيلات';

  @override
  String get profile_sectionSupport => 'الدعم';

  @override
  String get profile_sectionLegal => 'القانونية';

  @override
  String get profile_editProfile => 'البيانات الشخصية';

  @override
  String get profile_editProfileSubtitle =>
      'الاسم ورقم الهاتف والبريد الإلكتروني';

  @override
  String get profile_subscription => 'اشتراكي';

  @override
  String get profile_subscriptionSubtitle => 'الباقات والتجديد والفواتير';

  @override
  String get profile_myTrips => 'رحلاتي';

  @override
  String get profile_myTripsSubtitle => 'الرحلات القادمة والحالية والسابقة';

  @override
  String get profile_language => 'اللغة';

  @override
  String get profile_languageEnglish => 'English';

  @override
  String get profile_languageArabic => 'العربية';

  @override
  String get profile_selectLanguage => 'اختر اللغة';

  @override
  String get profile_selectLanguageBody =>
      'يتم تغيير لغة التطبيق واتجاه الواجهة فوراً.';

  @override
  String get profile_theme => 'المظهر';

  @override
  String get profile_themeSystem => 'حسب النظام';

  @override
  String get profile_themeLight => 'فاتح';

  @override
  String get profile_themeDark => 'داكن';

  @override
  String get profile_selectTheme => 'اختر المظهر';

  @override
  String get profile_selectThemeBody => 'خيار النظام يتبع إعدادات جهازك.';

  @override
  String get profile_themeLightBody => 'الأنسب في ضوء النهار';

  @override
  String get profile_themeDarkBody => 'أراح للعين ليلاً';

  @override
  String get profile_helpCenter => 'مركز المساعدة';

  @override
  String get profile_helpCenterSubtitle =>
      'الأسئلة الشائعة والتذاكر والاسترداد';

  @override
  String get profile_terms => 'الشروط والأحكام';

  @override
  String get profile_privacy => 'سياسة الخصوصية';

  @override
  String profile_lastUpdated(String date) {
    return 'آخر تحديث $date';
  }

  @override
  String get profile_editTitle => 'البيانات الشخصية';

  @override
  String get profile_editBody =>
      'يستخدم الكابتن هذه البيانات للتواصل معك بخصوص رحلتك.';

  @override
  String get profile_fieldName => 'الاسم بالكامل';

  @override
  String get profile_fieldPhone => 'رقم الهاتف';

  @override
  String get profile_fieldEmail => 'البريد الإلكتروني';

  @override
  String get profile_errorRequired => 'هذا الحقل مطلوب';

  @override
  String get profile_errorNameTooShort => 'أدخل اسمك بالكامل';

  @override
  String get profile_errorInvalidPhone => 'أدخل رقم موبايل مصري صحيح';

  @override
  String get profile_errorInvalidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get profile_saved => 'تم حفظ بياناتك';

  @override
  String get profile_logout => 'تسجيل الخروج';

  @override
  String get profile_logoutTitle => 'تسجيل الخروج؟';

  @override
  String get profile_logoutBody =>
      'ستحتاج إلى تسجيل الدخول مرة أخرى لحجز أو تتبع أي رحلة.';

  @override
  String get profile_logoutFailed =>
      'تعذر تسجيل الخروج. من فضلك حاول مرة أخرى.';

  @override
  String get profile_refreshFailed => 'تعذر تحديث بيانات حسابك.';
}
