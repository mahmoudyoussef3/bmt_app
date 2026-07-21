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
  String get auth_rememberMe => 'تذكرني';

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
  String get packages_all => 'الكل';

  @override
  String get packages_weekly => 'أسبوعية';

  @override
  String get packages_monthly => 'شهرية';

  @override
  String get packages_quarterly => 'ربع سنوية';

  @override
  String get packages_perRide => 'سعر الرحلة';

  @override
  String get packages_emptyTitle => 'لا توجد باقات بهذه المدة';

  @override
  String get packages_emptyBody =>
      'جرّب مدة أخرى، أو حدّث الصفحة لتحميل أحدث الباقات.';

  @override
  String get packages_duration => 'المدة';

  @override
  String get packages_totalTrips => 'إجمالي الرحلات';

  @override
  String packages_ridesCount(int count) {
    return '$count رحلات';
  }

  @override
  String packages_egpAmount(String amount) {
    return 'ج.م $amount';
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
  String get packages_subscriptionCost => 'تكلفة الاشتراك';

  @override
  String get packages_route => 'المسار';

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

  @override
  String get welcome_continueWithEmail => 'المتابعة بالبريد الإلكتروني';

  @override
  String get welcome_createAccount => 'إنشاء حساب';

  @override
  String get welcome_orContinueWith => 'أو تابع باستخدام';

  @override
  String get welcome_continueAsGuest => 'المتابعة كضيف';

  @override
  String get welcome_heroTagline =>
      'تنقل ذكي ومريح.\nاحجز وتتبّع واركب — كل ذلك في مكان واحد.';

  @override
  String get welcome_valueSeats => 'حجز المقاعد';

  @override
  String get welcome_valueTracking => 'تتبّع مباشر للحافلة';

  @override
  String get welcome_valuePasses => 'إدارة الاشتراكات';

  @override
  String welcome_comingSoonTitle(String provider) {
    return 'تسجيل الدخول عبر $provider قريبًا';
  }

  @override
  String get welcome_comingSoonBody =>
      'ما زلنا نضع اللمسات الأخيرة عليه. في الوقت الحالي، تابع باستخدام بريدك الإلكتروني لحجز الرحلات وتتبّع الحافلات فورًا.';

  @override
  String get welcome_maybeLater => 'ربما لاحقًا';

  @override
  String get welcome_providerPhone => 'الهاتف';

  @override
  String get auth_termsAndConditions => 'الشروط والأحكام';

  @override
  String get welcome_languageName => 'العربية';

  @override
  String get auth_signInHeroSubtitle =>
      'سجّل الدخول لتتبّع رحلاتك وإدارة اشتراكاتك ومتابعة الحافلات لحظة بلحظة.';

  @override
  String get auth_signingIn => 'جارٍ تسجيل الدخول...';

  @override
  String get auth_signInInfoCard =>
      'كل رحلاتك وحجوزاتك في مكان واحد — سجّل الدخول وتابع يومك بسهولة.';

  @override
  String get auth_signInSecurityNote =>
      'تأكد من استخدام البريد الإلكتروني المرتبط بحسابك للوصول إلى حجوزاتك واشتراكاتك.';

  @override
  String get auth_signUpHeroSubtitle =>
      'سجّل بياناتك مرة واحدة واستمتع بحجز الرحلات وتتبّع الحافلات وإدارة الاشتراكات بسهولة.';

  @override
  String get auth_accountDetails => 'بيانات الحساب';

  @override
  String get auth_loginDetails => 'بيانات الدخول';

  @override
  String get auth_creatingAccount => 'جارٍ إنشاء الحساب...';

  @override
  String get auth_signUpTrustBanner =>
      'بياناتك آمنة وتُستخدم فقط لإدارة رحلاتك وحجوزاتك.';

  @override
  String get auth_signUpSecurityNote =>
      'بالنقر على إنشاء حساب، سيتم إرسال رسالة تأكيد إلى بريدك الإلكتروني.';

  @override
  String get auth_sendingLink => 'جارٍ إرسال الرابط...';

  @override
  String get auth_recoveryLinkFailed => 'تعذر إرسال رابط الاستعادة';

  @override
  String get auth_resetInfoCard =>
      'سنرسل رابطًا مؤقتًا إلى بريدك الإلكتروني. افتحه قريبًا لتعيين كلمة مرور جديدة.';

  @override
  String get auth_recoveryLinkSent => 'تم إرسال رابط الاستعادة';

  @override
  String get auth_openEmailToReset =>
      'افتح البريد الإلكتروني واضغط على الرابط لإعادة تعيين كلمة المرور.';

  @override
  String get auth_emailHelp =>
      'لم تجد البريد؟ تحقق من مجلد الرسائل غير المرغوب فيها أو انتظر قليلًا قبل إعادة الإرسال.';

  @override
  String get auth_forgotSecurityNote =>
      'لأمانك، قد يمنع النظام إرسال عدة روابط خلال فترة قصيرة.';

  @override
  String get auth_help => 'مساعدة؟';

  @override
  String get auth_enterPhoneTitle => 'أدخل رقم هاتفك';

  @override
  String get auth_enterPhoneSubtitle => 'سنقوم بإرسال رمز تحقق للرقم المدخل.';

  @override
  String get auth_or => 'أو';

  @override
  String get auth_continue => 'متابعة';

  @override
  String get auth_verifyNumberTitle => 'التحقق من الرقم';

  @override
  String get auth_enterOtpTitle => 'أدخل الرمز المكون من 6 أرقام';

  @override
  String auth_otpSentTo(String phone) {
    return 'تم إرسال الرمز في رسالة نصية إلى:\n$phone';
  }

  @override
  String get auth_verify => 'تحقق';

  @override
  String get auth_didntReceiveCode => 'لم تستلم الرمز؟';

  @override
  String auth_resendCountdown(int seconds) {
    return 'إعادة الإرسال ($seconds)';
  }

  @override
  String get auth_resendCode => 'إعادة إرسال الرمز';

  @override
  String get auth_mustAcceptTerms => 'يجب الموافقة على الشروط والأحكام.';

  @override
  String get auth_completeProfileTitle => 'إكمال الملف الشخصي';

  @override
  String get auth_welcomeToApp => 'أهلاً بك في BMT';

  @override
  String get auth_completeProfileSubtitle =>
      'نحتاج لبعض المعلومات لنقدم لك أفضل خدمة.';

  @override
  String get auth_nameHint => 'أحمد حسن';

  @override
  String get auth_nameRequired => 'الاسم مطلوب';

  @override
  String get auth_emailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get auth_gender => 'الجنس';

  @override
  String get auth_genderMale => 'ذكر';

  @override
  String get auth_genderFemale => 'أنثى';

  @override
  String get auth_acceptTermsCheckbox =>
      'أوافق على شروط الخدمة وسياسة الخصوصية.';

  @override
  String get auth_createAccountAndStart => 'إنشاء الحساب وبدء الاستخدام';

  @override
  String get auth_invalidPhoneShort => 'رقم غير صحيح';

  @override
  String get splash_tagline => 'رحلتك، ببساطة.';

  @override
  String get common_today => 'اليوم';

  @override
  String get common_date => 'التاريخ';

  @override
  String get common_time => 'الوقت';

  @override
  String get common_seats => 'المقاعد';

  @override
  String get common_soldOut => 'نفدت المقاعد';

  @override
  String get common_notSet => 'غير محدد';

  @override
  String get common_notifications => 'الإشعارات';

  @override
  String get common_support => 'الدعم';

  @override
  String get common_manage => 'إدارة';

  @override
  String get common_pickup => 'الانطلاق';

  @override
  String get common_destination => 'الوجهة';

  @override
  String get common_dropOff => 'الوصول';

  @override
  String get nav_home => 'الرئيسية';

  @override
  String get nav_routes => 'المسارات';

  @override
  String get nav_trips => 'الرحلات';

  @override
  String get nav_profile => 'الحساب';

  @override
  String get home_myTrips => 'رحلاتي';

  @override
  String get home_greetingMorning => 'صباح الخير';

  @override
  String get home_greetingAfternoon => 'مساء الخير';

  @override
  String get home_greetingEvening => 'مساء الخير';

  @override
  String get home_welcomeAboard => 'أهلاً بك';

  @override
  String get home_popularDestinations => 'الوجهات الأكثر شيوعًا';

  @override
  String get home_searchRoutesTimesSeats =>
      'ابحث عن المسارات والمواعيد والمقاعد';

  @override
  String get home_expiresToday => 'ينتهي اليوم';

  @override
  String get home_trackYourBus => 'تتبّع حافلتك';

  @override
  String get home_yourBooking => 'حجزك';

  @override
  String get home_yourBookings => 'حجوزاتك';

  @override
  String get home_yourJourney => 'رحلتك';

  @override
  String get home_seatsYouHold => 'المقاعد التي تحجزها، وحالة كل منها.';

  @override
  String get home_bookASeat => 'احجز مقعدًا';

  @override
  String get home_nextDepartures => 'الرحلات القادمة';

  @override
  String get home_tripsOpenSoonest => 'رحلات متاحة للحجز، الأقرب أولًا.';

  @override
  String get home_allRoutes => 'كل المسارات';

  @override
  String get home_yourPackage => 'باقتك';

  @override
  String get home_activeSubscription => 'اشتراك نشط';

  @override
  String get home_bookAnotherSeat => 'احجز مقعدًا آخر';

  @override
  String get home_bookSeat => 'احجز مقعدًا';

  @override
  String get home_fareNotPublished => 'لم يُنشر السعر بعد';

  @override
  String get home_fareFrom => 'السعر يبدأ من';

  @override
  String get home_departureToBeSet => 'سيتم تحديد موعد الانطلاق';

  @override
  String get home_boarding => 'الصعود';

  @override
  String get home_rideTime => 'مدة الرحلة';

  @override
  String home_youBookedSeats(int seats) {
    return 'لقد حجزت $seats مقاعد';
  }

  @override
  String get home_youBookedThis => 'لقد حجزت هذه';

  @override
  String get home_pickupShort => 'الانطلاق';

  @override
  String get home_stopNotSet => 'المحطة غير محددة';

  @override
  String get home_noDepartures => 'لا توجد رحلات مجدولة';

  @override
  String get home_noDeparturesBody =>
      'لا يوجد ما هو متاح للحجز الآن. تصفّح المسارات لمعرفة الرحلات ومواعيدها.';

  @override
  String get home_browseRoutes => 'تصفّح المسارات';

  @override
  String get home_searchTripTitle => 'ابحث عن رحلة';

  @override
  String get home_searchTripSubtitle => 'اعثر على رحلتك القادمة في ثوانٍ';

  @override
  String get home_pickupLocation => 'نقطة الانطلاق';

  @override
  String get home_selectPickupPoint => 'اختر نقطة الانطلاق';

  @override
  String get home_whereAreYouGoing => 'إلى أين تذهب؟';

  @override
  String get home_selectTime => 'اختر الوقت';

  @override
  String get home_searchTrips => 'ابحث عن الرحلات';

  @override
  String home_seatsOnlyLeft(int count) {
    return 'بقي $count فقط';
  }

  @override
  String home_seatsAvailable(int count) {
    return '$count متاح';
  }

  @override
  String get home_statusUnderReview => 'قيد المراجعة';

  @override
  String get home_statusConfirmed => 'مؤكد';

  @override
  String get home_statusOnBoard => 'على متن الحافلة';

  @override
  String get home_statusUnderReviewExplanation =>
      'نقوم بمراجعة عملية الدفع الخاصة بك. سيتم إشعارك فور تأكيد مقعدك.';

  @override
  String get home_statusConfirmedExplanation =>
      'مقعدك محجوز. كن في نقطة الانطلاق قبل 10 دقائق من موعد الرحلة.';

  @override
  String get home_statusOnBoardExplanation =>
      'أنت على متن الحافلة. رحلة سعيدة.';

  @override
  String get home_yourBookingFallback => 'حجزك';

  @override
  String home_seatLabel(String label) {
    return 'مقعد $label';
  }

  @override
  String home_daysLeft(int days) {
    return 'متبقي $days يوم';
  }

  @override
  String get home_dayLeft => 'متبقي يوم واحد';

  @override
  String booking_searchHint(String title) {
    return 'ابحث عن $title';
  }

  @override
  String get booking_noPickupPointsAvailable =>
      'لا توجد نقاط ركوب متاحة حاليًا. برجاء المحاولة لاحقًا.';

  @override
  String get booking_noDestinationsAvailable => 'لا توجد وجهات متاحة حاليًا.';

  @override
  String get booking_noDepartureTimesAvailable =>
      'لا توجد مواعيد انطلاق متاحة لهذا الخط حاليًا.';

  @override
  String get map_livePreviewTitle => 'معاينة المسار المباشرة';

  @override
  String get map_livePreviewSubtitle =>
      'موقع المركبة الحالي ومسار الرحلة لحظة بلحظة';

  @override
  String get notifications_markAllRead => 'تحديد الكل كمقروء';

  @override
  String get notifications_emptyTitle => 'لا توجد إشعارات بعد';

  @override
  String get notifications_emptyBody =>
      'ستظهر هنا تحديثات الرحلات وتأكيدات الحجز والتذكيرات فور وصولها.';

  @override
  String get notifications_newBadge => 'جديد';

  @override
  String get notifications_categoryAll => 'الكل';

  @override
  String get notifications_categoryBooking => 'الحجز';

  @override
  String get notifications_categoryPayment => 'الدفع';

  @override
  String get notifications_categoryTrip => 'الرحلة';

  @override
  String get notifications_categoryNews => 'الأخبار';

  @override
  String get notifications_categoryOffers => 'العروض';

  @override
  String get notifications_categoryAlerts => 'التنبيهات';

  @override
  String get trips_headerSubtitle => 'الرحلات القادمة والحالية والسابقة';

  @override
  String get trips_bookNewTripTooltip => 'احجز رحلة جديدة';

  @override
  String get trips_filterUpcoming => 'قادمة';

  @override
  String get trips_filterActive => 'جارية';

  @override
  String get trips_filterCompleted => 'مكتملة';

  @override
  String get trips_filterCancelled => 'ملغاة';

  @override
  String get trips_sectionUpcoming => 'الرحلات القادمة';

  @override
  String get trips_sectionActive => 'الرحلات الجارية';

  @override
  String get trips_sectionCompleted => 'الرحلات المكتملة';

  @override
  String get trips_sectionCancelled => 'الرحلات الملغاة';

  @override
  String get trips_emptyUpcomingTitle => 'لا توجد رحلات قادمة مجدولة';

  @override
  String get trips_emptyUpcomingSubtitle => 'احجز رحلة وستظهر هنا.';

  @override
  String get trips_emptyActiveTitle => 'لا توجد رحلات جارية الآن';

  @override
  String get trips_emptyActiveSubtitle =>
      'الرحلات التي على الطريق حاليًا ستظهر هنا.';

  @override
  String get trips_emptyCompletedTitle => 'لا توجد رحلات مكتملة بعد';

  @override
  String get trips_emptyCompletedSubtitle => 'الرحلات التي تنهيها ستظهر هنا.';

  @override
  String get trips_emptyCancelledTitle => 'لا توجد رحلات ملغاة';

  @override
  String get trips_emptyCancelledSubtitle => 'الرحلات التي تلغيها ستظهر هنا.';

  @override
  String get payments_checkoutTitle => 'الدفع';

  @override
  String get payments_encrypted => 'مشفّر';

  @override
  String get payments_fareSummary => 'ملخص الأجرة';

  @override
  String get payments_ticketFare => 'أجرة التذكرة';

  @override
  String get payments_serviceFee => 'رسوم الخدمة';

  @override
  String get payments_tax => 'الضريبة';

  @override
  String get payments_promoDiscount => 'خصم كود الخصم';

  @override
  String get payments_total => 'الإجمالي';

  @override
  String get payments_assuranceCardDetails =>
      'بيانات البطاقة بتتكتب على صفحة البنك مباشرة، ومش بيتم تخزينها عندنا في BMT.';

  @override
  String get payments_assuranceSeatHeld =>
      'مقعدك محجوز لحد ما تدفع، ومش هيتفك إلا لو الدفع فشل.';

  @override
  String get payments_assuranceTransferChecked =>
      'التحويلات بتتراجع من فريقنا، وهنبعتلك إشعار بمجرد التأكيد.';

  @override
  String get payments_assuranceSupportReference =>
      'في حاجة غلط؟ الدعم يقدر يشوف الحجز ده برقم المرجع بتاعه.';

  @override
  String payments_bookingMissingItems(String items) {
    return 'الحجز ده ناقصه $items';
  }

  @override
  String get payments_completeBeforePaying =>
      'ارجع واستكمل البيانات قبل ما تدفع.';

  @override
  String get payments_goBack => 'رجوع';

  @override
  String get payments_howToPay => 'عايز تدفع إزاي؟';

  @override
  String payments_balanceAmount(String amount) {
    return 'الرصيد $amount';
  }

  @override
  String payments_shortByAmount(String amount) {
    return 'ناقصك $amount — اشحن رصيدك أو اختار طريقة تانية.';
  }

  @override
  String get payments_noMethodsAvailable =>
      'مفيش وسيلة دفع متاحة دلوقتي. مقعدك لسه محجوز — كلّم الدعم وهيكملوا معاك الباقي.';

  @override
  String get payments_nextStepCard =>
      'هتكمّل الدفع على صفحة بايموب المشفّرة الخاصة بالبطاقة.';

  @override
  String get payments_nextStepInstapay =>
      'حوّل الفلوس، وبعدين ارفق إيصال التحويل في الخطوة الجاية.';

  @override
  String get payments_nextStepBankTransfer =>
      'بيانات الحساب البنكي هتظهر بعد كده — ارفق الإيصال بعد ما تحوّل.';

  @override
  String get payments_nextStepVodafoneCash =>
      'حوّل من محفظتك، وبعدين ارفق الإيصال في الخطوة الجاية.';

  @override
  String get payments_nextStepWallet => 'هيتخصم من رصيدك فور ما تأكّد.';

  @override
  String get payments_fastestBadge => 'الأسرع';

  @override
  String get payments_seatHeldWhilePaying => 'مقعدك محجوز لحد ما تخلّص الدفع.';

  @override
  String get payments_stepSeat => 'المقعد';

  @override
  String get payments_stepPayment => 'الدفع';

  @override
  String get payments_stepTicket => 'التذكرة';

  @override
  String get payments_havePromoCode => 'عندك كود خصم؟';

  @override
  String get payments_enterCodeHint => 'اكتب الكود';

  @override
  String get payments_promoCodeInvalid => 'الكود ده مش صحيح';

  @override
  String get payments_apply => 'تطبيق';

  @override
  String payments_promoApplied(String code, String amount) {
    return 'تم تفعيل $code — هتوفر $amount';
  }

  @override
  String get payments_removePromoCode => 'إلغاء كود الخصم';

  @override
  String get payments_yourSeat => 'مقعدك';

  @override
  String get payments_seatNotSelected => 'لسه ما اخترتش مقعد';

  @override
  String payments_seatNumber(String seat) {
    return 'مقعد $seat';
  }

  @override
  String get payments_vehicle => 'المركبة';

  @override
  String get payments_driver => 'السائق';

  @override
  String get payments_directTrip => 'مباشر';

  @override
  String get booking_bookYourSeat => 'احجز مقعدك';

  @override
  String get booking_bookingFailed => 'فشل الحجز';

  @override
  String get booking_seatJustTaken =>
      'تم حجز هذا المقعد للتو. من فضلك ارجع واختر مقعدًا آخر.';

  @override
  String get booking_seatHoldExpired =>
      'انتهت مهلة حجز مقعدك. من فضلك اختر مقعدك مرة أخرى.';

  @override
  String get booking_duplicateActiveBooking =>
      'لديك بالفعل حجز معلّق لهذه الرحلة. من فضلك أكمل الدفع من حجزك الحالي.';

  @override
  String get booking_openMyBookings => 'عرض حجوزاتي';

  @override
  String get booking_ok => 'حسنًا';

  @override
  String get booking_referenceNotCreated => 'لم يتم إنشاء رقم مرجعي للحجز.';

  @override
  String get booking_cardPaymentUnavailable =>
      'الدفع بالبطاقة غير متاح حاليًا.';

  @override
  String get booking_cardPaymentNotCompleted =>
      'لم تكتمل عملية الدفع بالبطاقة. يظل حجزك معلّقًا.';

  @override
  String get booking_cardPaymentDeclined =>
      'تم رفض البطاقة ولم يتم خصم أي مبلغ. مقعدك ما زال محجوزًا — جرّب بطاقة أخرى أو وسيلة دفع مختلفة.';

  @override
  String get booking_viewVehicleAndPhotos => 'المركبة والصور';

  @override
  String get booking_vehiclePhotosUnavailable => 'لا توجد صور لهذه المركبة بعد';

  @override
  String get booking_noRatingsYet => 'لا توجد تقييمات بعد';

  @override
  String booking_ratingWithCount(String rating, int count) {
    return '$rating ($count)';
  }

  @override
  String get booking_vehicleCapacityLabel => 'السعة';

  @override
  String booking_vehicleSeatsCount(int count) {
    return '$count مقعدًا';
  }

  @override
  String get booking_vehiclePlate => 'رقم اللوحة';

  @override
  String get booking_vehicleYear => 'سنة الصنع';

  @override
  String get booking_vehicleColor => 'اللون';

  @override
  String get trips_statusInProgress => 'جارية الآن';

  @override
  String get trips_paymentPaid => 'مدفوعة';

  @override
  String get trips_paymentPending => 'قيد الانتظار';

  @override
  String get trips_paymentUnderReview => 'قيد المراجعة';

  @override
  String get trips_paymentRefunded => 'مستردة';

  @override
  String get trips_paymentFailed => 'فشلت';

  @override
  String get trips_driverBadgeAssigned => 'تم التعيين';

  @override
  String get trips_driverBadgeEnRoute => 'في الطريق';

  @override
  String get trips_driverBadgeCompleted => 'اكتملت الرحلة';

  @override
  String get trips_driverBadgeCancelled => 'أُلغيت الرحلة';

  @override
  String get trips_liveLoadingPosition => 'جارٍ تحميل الموقع المباشر…';

  @override
  String get trips_livePositionUnavailable => 'الموقع المباشر غير متاح الآن.';

  @override
  String get trips_liveWaitingForVehicle => 'في انتظار الموقع المباشر للمركبة…';

  @override
  String trips_liveRouteCoveredPercent(int percent) {
    return 'تم قطع $percent% من المسار';
  }

  @override
  String get trips_liveTripInProgress => 'رحلتك جارية الآن';

  @override
  String get trips_liveTrackButton => 'تتبع';

  @override
  String get payments_continueLabel => 'استمرار';

  @override
  String get payments_payNow => 'ادفع الآن';

  @override
  String get payments_missingBookingDetails => 'بعض بيانات الحجز ناقصة.';

  @override
  String get payments_choosePaymentMethod => 'اختار وسيلة دفع عشان تكمّل.';

  @override
  String payments_walletShortByAmount(String amount) {
    return 'محفظتك ناقصة $amount عن قيمة الأجرة دي.';
  }

  @override
  String get support_minLengthHint => 'من فضلك أضف مزيدًا من التفاصيل';

  @override
  String get support_refresh => 'تحديث';

  @override
  String get support_centerTitle => 'مركز الدعم';

  @override
  String get support_categoryBooking => 'مشكلة في الحجز';

  @override
  String get support_categoryPayment => 'مشكلة في الدفع';

  @override
  String get support_categoryTripDelay => 'تأخير الرحلة';

  @override
  String get support_categoryDriverVehicle => 'مشكلة في السائق أو المركبة';

  @override
  String get support_categorySubscription => 'مشكلة في الاشتراك';

  @override
  String get support_categoryLostItem => 'غرض مفقود';

  @override
  String get support_categoryOther => 'أخرى';

  @override
  String get support_emptyTitle => 'لا توجد تذاكر بعد';

  @override
  String get support_emptyBody =>
      'عند فتح تذكرة، ستظهر هنا مع حالتها وكل ردود فريقنا عليها.';

  @override
  String get support_uploadPrompt => 'ارفع صورة أو مستند';

  @override
  String get support_uploadHint =>
      'بصيغة JPG أو PNG أو PDF بحد أقصى 5 ميجابايت';

  @override
  String get support_removeAttachment => 'إزالة المرفق';

  @override
  String get support_myTickets => 'تذاكري';

  @override
  String get support_statusSubmitted => 'تم الإرسال';

  @override
  String get support_statusUnderReview => 'قيد المراجعة';

  @override
  String get support_statusContacted => 'تم التواصل';

  @override
  String get support_statusResolved => 'تم الحل';

  @override
  String get support_statusClosed => 'مغلقة';

  @override
  String get support_statusRejected => 'مرفوضة';

  @override
  String get support_timelineEmpty => 'لا توجد أحداث في الجدول الزمني بعد.';

  @override
  String get support_heroTitle => 'كيف يمكننا مساعدتك؟';

  @override
  String get support_heroBody =>
      'أخبرنا بما حدث وسيتابع فريقنا تذكرتك. عادةً ما نرد خلال ساعات قليلة.';

  @override
  String get support_createTicket => 'إنشاء تذكرة';

  @override
  String get support_topicLabel => 'ما هو موضوع المشكلة؟';

  @override
  String get support_topicHint => 'اختر الموضوع الأقرب لمشكلتك.';

  @override
  String get support_subjectLabel => 'الموضوع';

  @override
  String get support_subjectHint => 'ملخص قصير للمشكلة.';

  @override
  String get support_subjectPlaceholder =>
      'مثال: تم خصم المبلغ مرتين لحجز واحد';

  @override
  String get support_subjectRequired => 'الموضوع مطلوب';

  @override
  String get support_detailsLabel => 'التفاصيل';

  @override
  String get support_detailsHint =>
      'ماذا حدث، ومتى؟ أضف رقم الرحلة أو الحجز إن كان متوفرًا لديك.';

  @override
  String get support_detailsPlaceholder => 'صف المشكلة…';

  @override
  String get support_detailsRequired => 'التفاصيل مطلوبة';

  @override
  String get support_relatedBookingLabel => 'الحجز المتعلق';

  @override
  String get support_relatedBookingHint =>
      'اختياري — اختر الحجز الذي يخصه بلاغك ليصل إلى المكتب الصحيح.';

  @override
  String get support_relatedBookingNone => 'لا يخص حجزًا معينًا';

  @override
  String get support_attachmentLabel => 'المرفق';

  @override
  String get support_attachmentHint =>
      'اختياري — لقطة شاشة أو إيصال تساعدنا كثيرًا.';

  @override
  String get support_submitting => 'جارٍ الإرسال…';

  @override
  String get support_submitTicket => 'إرسال التذكرة';

  @override
  String get support_newTicketTitle => 'تذكرة جديدة';

  @override
  String get support_ticketCreatedSnack =>
      'تم إنشاء التذكرة. سيتواصل معك فريقنا قريبًا.';

  @override
  String support_ticketNumberTitle(String number) {
    return 'تذكرة $number';
  }

  @override
  String get support_failedToLoad => 'تعذر تحميل تفاصيل التذكرة';

  @override
  String get support_reviewingNotice =>
      'يقوم فريق خدمة العملاء بمراجعة تذكرتك وقد يتواصل معك قريبًا.';

  @override
  String get support_currentStatus => 'الحالة الحالية';

  @override
  String get support_assignedTo => 'مسندة إلى';

  @override
  String get support_description => 'الوصف';

  @override
  String get support_customerServiceNote => 'ملاحظة من خدمة العملاء';

  @override
  String get support_attachments => 'المرفقات';

  @override
  String get booking_tapToChoosePickupStation => 'اضغط لاختيار محطة الركوب';

  @override
  String get booking_noMappedPickupStations =>
      'لا توجد محطات ركوب متاحة على الخريطة';

  @override
  String get booking_tapToChooseDestination => 'اضغط لاختيار الوجهة';

  @override
  String get booking_noMappedDestinations => 'لا توجد وجهات متاحة على الخريطة';

  @override
  String get booking_mapCouldNotBeLoaded => 'تعذر تحميل الخريطة';

  @override
  String get common_tomorrow => 'غدًا';

  @override
  String common_durationMinutes(int minutes) {
    return '$minutes د';
  }

  @override
  String common_durationHours(int hours) {
    return '$hours س';
  }

  @override
  String common_durationHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String get seatSelection_selectYourSeat => 'اختر مقعدك';

  @override
  String seatSelection_seatsFreeCount(int count) {
    return '$count متاح';
  }

  @override
  String get seatSelection_chooseASeat => 'اختر مقعدًا';

  @override
  String get seatSelection_tapSeatToContinue => 'اضغط على مقعد متاح للمتابعة';

  @override
  String seatSelection_seatsOpenCount(int count) {
    return '$count متاح';
  }

  @override
  String get seatSelection_microbusCapacity => 'ميكروباص بسعة 15 مقعدًا';

  @override
  String get seatSelection_frontOfVehicle => 'مقدمة المركبة';

  @override
  String get seatSelection_cabinLayout => 'مخطط المقصورة';

  @override
  String get seatSelection_driverCabinNote =>
      'المقعدان 1 و2 مخصصان لمقصورة السائق';

  @override
  String get seatSelection_driverCabinLabel => 'مقصورة السائق';

  @override
  String get seatSelection_selectSeatToContinue =>
      'اختر مقعدًا واحدًا للمتابعة';

  @override
  String get seatSelection_tapAvailableSeatHint =>
      'اضغط على أي مقعد متاح في المخطط أعلاه.';

  @override
  String seatSelection_seatSelectedTitle(String seatNum) {
    return 'تم اختيار المقعد $seatNum';
  }

  @override
  String seatSelection_seatSummaryLine(String price, String total) {
    return 'مقعد واحد · $price جنيه للمقعد · الإجمالي $total جنيه';
  }

  @override
  String get seatSelection_hintCardBody =>
      'الصفوف الوسطى تحتوي على مقعدين على اليسار ومقعد واحد على اليمين لمحاكاة تخطيط الميكروباص الواقعي.';

  @override
  String seatSelection_departsAt(String time) {
    return 'الانطلاق $time';
  }

  @override
  String get seatSelection_selectedSeatLabel => 'المقعد المختار';

  @override
  String get seatSelection_seatNumbersLabel => 'أرقام المقاعد';

  @override
  String get seatSelection_perSeatLabel => 'لكل مقعد';

  @override
  String get seatSelection_reservingSeat => 'جارٍ حجز المقعد...';

  @override
  String get seatSelection_continueBooking => 'متابعة الحجز';

  @override
  String get seatSelection_selectASeat => 'اختر مقعدًا';

  @override
  String seatSelection_seatCountSelected(int count) {
    return 'تم اختيار $count مقعد';
  }

  @override
  String get seatSelection_passengerInformation => 'بيانات الراكب';

  @override
  String get seatSelection_contactDetails => 'بيانات التواصل';

  @override
  String get seatSelection_passengerNameLabel => 'اسم الراكب';

  @override
  String get seatSelection_fullNameHint => 'الاسم الكامل كما في البطاقة';

  @override
  String get seatSelection_passengerPhoneLabel => 'رقم هاتف الراكب';

  @override
  String get seatSelection_phoneHint => '+20 10 1234 5678';

  @override
  String get seatSelection_phoneUsageNote =>
      'سنستخدم هذا الرقم لإرسال تحديثات الرحلة.';

  @override
  String get seatSelection_saveDetails => 'حفظ البيانات';

  @override
  String get seatSelection_bookingSummaryTitle => 'ملخص الحجز';

  @override
  String get seatSelection_pricePerSeatLabel => 'سعر المقعد الواحد';

  @override
  String get seatSelection_totalAmountLabel => 'المبلغ الإجمالي';

  @override
  String get seatSelection_seatLegendTitle => 'دليل حالة المقاعد';

  @override
  String get seatSelection_seatStatusSelected => 'مُختار';

  @override
  String get seatSelection_seatStatusReserved => 'محجوز';

  @override
  String get seatSelection_passengersTitle => 'الركاب';

  @override
  String get seatSelection_oneSeatBadge => 'مقعد واحد';

  @override
  String get seatSelection_addPassengerHint =>
      'اختر مقعدًا آخر لإضافة راكب (معاينة الواجهة)';

  @override
  String get seatSelection_awaitingSeatSelection => 'بانتظار اختيار المقعد';

  @override
  String seatSelection_passengerIndexLabel(int index) {
    return 'الراكب $index';
  }

  @override
  String get seatSelection_seatsLeftLabel => 'مقعدًا متبقيًا';

  @override
  String seatSelection_acStatusLabel(String status) {
    return 'تكييف · $status';
  }

  @override
  String get seatSelection_lockErrorSeatUnavailable =>
      'المقعد لم يعد متاحًا. برجاء اختيار مقعد آخر.';

  @override
  String get payments_stepFintechConnection =>
      'بنجهّز اتصال آمن مع بوابة الدفع...';

  @override
  String get payments_stepVerifyingAccount =>
      'بنتأكد من حالة الحساب والحد المسموح...';

  @override
  String get payments_stepReservingSeat =>
      'بنحجز المقعد وبنجهّز بيانات التذكرة...';

  @override
  String get payments_pendingLabel => 'قيد الانتظار';

  @override
  String get payments_methodLabel => 'الطريقة:';

  @override
  String get payments_transactionIdLabel => 'رقم العملية:';

  @override
  String payments_driverSeatSummary(String driver, String seat) {
    return 'السائق: $driver • المقعد: $seat';
  }

  @override
  String get payments_processingPaymentTitle => 'جاري معالجة الدفع';

  @override
  String get payments_doNotCloseScreen =>
      'من فضلك متقفلش الشاشة دي أو تدوس رجوع.';

  @override
  String get payments_secureCheckoutTitle => 'دفع آمن';

  @override
  String get payments_paymobCheckoutOpened => 'تم فتح صفحة الدفع من بايموب';

  @override
  String get payments_paymentSubmitted => 'تم إرسال الدفع';

  @override
  String get payments_completeCardPaymentPaymob =>
      'كمّل دفع البطاقة في صفحة بايموب الآمنة.';

  @override
  String get payments_receiptSentForReview =>
      'تم إرسال الإيصال لمراجعة فريق العمليات.';

  @override
  String get payments_bookingRefLabel => 'مرجع الحجز:';

  @override
  String get payments_paidAmountLabel => 'المبلغ المدفوع:';

  @override
  String get payments_paymentMethodLabel => 'طريقة الدفع:';

  @override
  String get payments_viewTicket => 'عرض التذكرة';

  @override
  String get payments_backToHome => 'الرجوع للرئيسية';

  @override
  String get payments_paymentFailedTitle => 'فشلت عملية الدفع';

  @override
  String get payments_transactionNotProcessed => 'معالجة عمليتك مانفعتش.';

  @override
  String get payments_reasonForFailure => 'سبب الفشل';

  @override
  String get payments_paymentNotCompleted => 'الدفع مكملش.';

  @override
  String get payments_retryPayment => 'إعادة المحاولة';

  @override
  String get payments_contactSupport => 'تواصل مع الدعم';

  @override
  String get payments_contactCustomerSupportTitle => 'تواصل مع خدمة العملاء';

  @override
  String payments_supportDialogBody(String ticketNumber) {
    return 'فريق خدمة العملاء جاهز يساعدك. رقم التذكرة المرجعي: $ticketNumber';
  }

  @override
  String get payments_close => 'إغلاق';

  @override
  String get trips_newCaptain => 'كابتن جديد';

  @override
  String trips_ratingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تقييم',
      two: 'تقييمان',
      one: 'تقييم واحد',
    );
    return '$_temp0';
  }

  @override
  String get trips_verifiedCaptain => 'كابتن موثّق';

  @override
  String get trips_factDeparts => 'الانطلاق';

  @override
  String get trips_factSeat => 'مقعد';

  @override
  String get trips_seatNotAssigned => 'لم يُحدد بعد';

  @override
  String trips_completedAt(String date) {
    return 'اكتملت في $date';
  }

  @override
  String get trips_boardingPassTitle => 'بطاقة الصعود';

  @override
  String get trips_boardingOnBoard => 'على متن الرحلة';

  @override
  String get trips_boardingReady => 'جاهزة';

  @override
  String get trips_bookingRefLabel => 'رقم الحجز';

  @override
  String get trips_boardingOnBoardNote =>
      'استمتع برحلتك — مقعدك مسجّل لدى الكابتن.';

  @override
  String get trips_boardingReadyNote => 'أظهر هذا الرقم للكابتن عند الصعود.';

  @override
  String get trips_detailsTitle => 'تفاصيل الرحلة';

  @override
  String get trips_cancellationReasonTitle => 'سبب الإلغاء';

  @override
  String get trips_completedRatedNote =>
      'لقد قيّمت هذه الرحلة. اضغط لعرض تقييمك.';

  @override
  String trips_completedRateInvite(String driverName) {
    return 'ساعدنا على التحسين بتقييم رحلتك مع $driverName.';
  }

  @override
  String get trips_actionChat => 'دردشة';

  @override
  String get trips_driverPhoneUnavailable => 'رقم هاتف السائق غير متاح.';

  @override
  String trips_callFailed(String phone) {
    return 'تعذّر بدء الاتصال بالرقم $phone.';
  }

  @override
  String get trips_seatLegendYours => 'مقعدك';

  @override
  String get trips_seatLegendAvailable => 'متاح';

  @override
  String get trips_seatLegendTaken => 'محجوز';

  @override
  String get trips_seatMapDriverLabel => 'السائق';

  @override
  String get trips_yourSeatsPlural => 'مقاعدك';

  @override
  String get trips_seatPending => 'المقعد قيد التحديد';

  @override
  String get trips_awaitingConfirmation => 'بانتظار التأكيد';

  @override
  String trips_seatsAvailableOfTotal(int available, int total) {
    return '$available من $total';
  }

  @override
  String get trips_seatsFreeLabel => 'مقعدًا شاغرًا';

  @override
  String get trips_viewFullSeatMap => 'عرض خريطة المقاعد كاملة';

  @override
  String get trips_seatPendingAssignment => 'سيُحدد مقعدك بمجرد تأكيد حجزك.';

  @override
  String trips_vehicleCode(String code) {
    return 'كود المركبة: $code';
  }

  @override
  String get trips_trackVehicleButton => 'تتبّع المركبة';

  @override
  String get trips_cancellingInFlight => 'جارٍ الإلغاء…';

  @override
  String get trips_cancelTripButton => 'إلغاء الرحلة';

  @override
  String get trips_captainSubtitleFinished => 'من قاد رحلتك';

  @override
  String get trips_captainSubtitleActive => 'من يقود رحلتك';

  @override
  String get trips_vehicleSubtitle => 'الحافلة المخصصة لهذه الرحلة';

  @override
  String get trips_seatsSubtitle => 'مقاعدك على خريطة المقصورة';

  @override
  String get trips_paymentSubtitle => 'الحالة وتفاصيل الأجرة';

  @override
  String get trips_paymentNotePaid => 'تم تأكيد دفعتك.';

  @override
  String get trips_paymentNotePending => 'بانتظار دفعتك.';

  @override
  String get trips_paymentNoteUnderReview => 'فريقنا يراجع دفعتك حاليًا.';

  @override
  String get trips_paymentNoteRefunded => 'تم استرداد قيمة هذه الأجرة لك.';

  @override
  String get trips_paymentNoteFailed => 'لم تكتمل عملية الدفع.';

  @override
  String get trips_paymentNoteCancelled => 'تم إلغاء هذا الحجز.';

  @override
  String get trips_discountLabel => 'الخصم';

  @override
  String get trips_seatMapTitle => 'خريطة المقاعد';

  @override
  String trips_seatMapTitleWithVehicle(String vehicle) {
    return 'خريطة المقاعد · $vehicle';
  }

  @override
  String trips_cancelSuccessMessage(String reference) {
    return 'تم إلغاء الرحلة $reference وأصبح مقعدك متاحًا مجددًا.';
  }

  @override
  String get seatRelease_hubTitle => 'مركز إخلاء المقاعد';

  @override
  String get seatRelease_formTitle => 'إخلاء مقعد محجوز';

  @override
  String get seatRelease_successTitle => 'تم إخلاء المقعد بنجاح';

  @override
  String get seatRelease_detailsTitle => 'تفاصيل سجل الإخلاء';

  @override
  String get seatRelease_compensationTitle => 'متابعة التعويض';

  @override
  String get seatRelease_historyTitle => 'سجل عمليات الإخلاء';

  @override
  String get seatRelease_notificationsTitle => 'إشعارات التنبيهات';

  @override
  String get seatRelease_achievementsTitle => 'الإنجازات والمراحل';

  @override
  String get seatRelease_portalTitle => 'بوابة إخلاء المقاعد';

  @override
  String get seatRelease_notifCompensationAddedTitle => 'تمت إضافة التعويض';

  @override
  String get seatRelease_notifCompensationAddedBody =>
      'تم إعادة حجز المقعد الذي أخليته بتاريخ 2 يونيو. تم إضافة 50 جنيهًا كاسترداد نقدي إلى محفظتك!';

  @override
  String get seatRelease_timeYesterday => 'أمس';

  @override
  String get seatRelease_notifRebookedTitle => 'تم إعادة حجز المقعد بنجاح';

  @override
  String get seatRelease_notifRebookedBody =>
      'قام أحد الركاب بحجز مقعدك الذي أخليته لرحلة 2 يونيو.';

  @override
  String seatRelease_timeDaysAgo(int count) {
    return 'منذ $count أيام';
  }

  @override
  String get seatRelease_notifReleasedTitle => 'تم إخلاء المقعد بنجاح';

  @override
  String seatRelease_notifReleasedBody(String seat, String date) {
    return 'لقد قمت بإخلاء مقعدك (المقعد $seat) بنجاح لرحلة $date.';
  }

  @override
  String get seatRelease_timeJustNow => 'الآن';

  @override
  String get seatRelease_confirmSheetTitle => 'تأكيد إخلاء المقعد';

  @override
  String get seatRelease_confirmSheetBody =>
      'برجاء تأكيد رغبتك في إخلاء مقعدك لهذه الرحلة بالتحديد. لا يمكن استرجاع المقعد بعد أن يحجزه راكب آخر.';

  @override
  String get seatRelease_tripDateLabel => 'تاريخ الرحلة';

  @override
  String get seatRelease_routeSegmentLabel => 'قطاع المسار';

  @override
  String get seatRelease_seatNumberLabel => 'رقم المقعد';

  @override
  String get seatRelease_packageOriginLabel => 'مصدر الباقة';

  @override
  String get seatRelease_confirmSheetWarning =>
      'هذا الإجراء يؤثر فقط على تاريخ الرحلة المحدد. مواعيد التنقل القادمة تظل دون تأثير.';

  @override
  String get seatRelease_goBack => 'رجوع';

  @override
  String get seatRelease_confirmReleaseButton => 'تأكيد الإخلاء';

  @override
  String get seatRelease_mockReleaseDateToday => 'اليوم، 3 يونيو';

  @override
  String get seatRelease_noNotesProvided => 'لا توجد ملاحظات';

  @override
  String get seatRelease_statusWaiting => 'قيد الانتظار';

  @override
  String get seatRelease_statusRebooked => 'تم الحجز مجددًا';

  @override
  String get seatRelease_statusRewarded => 'تمت المكافأة';

  @override
  String get seatRelease_statusClosed => 'مغلق';

  @override
  String get seatRelease_filterAll => 'الكل';

  @override
  String get seatRelease_timelineStepReleased => 'تم إخلاء المقعد';

  @override
  String get seatRelease_timelineStepWaiting => 'بانتظار إعادة الحجز';

  @override
  String get seatRelease_timelineStepRebooked => 'تمت إعادة الحجز بنجاح';

  @override
  String get seatRelease_timelineReleasedDesc =>
      'تم إخلاء مقعدك ليصبح متاحًا لمجمعات التنقل.';

  @override
  String get seatRelease_timelineWaitingDesc =>
      'المقعد مُدرج حاليًا. بانتظار حجوزات ركاب آخرين.';

  @override
  String get seatRelease_timelineRebookedDesc =>
      'تمت إعادة حجز المقعد بنجاح بواسطة راكب آخر.';

  @override
  String get seatRelease_timelineRewardedDesc =>
      'تم إضافة مكافأة التعويض مباشرة إلى محفظتك.';

  @override
  String get seatRelease_upcomingReservedSeatsTitle =>
      'المقاعد المحجوزة القادمة';

  @override
  String get seatRelease_noUpcomingTripsMessage =>
      'لا توجد رحلات قادمة ضمن الباقة\nكل المقاعد القادمة نشطة، أو لم يتبقَ أي أيام في الباقة.';

  @override
  String get seatRelease_validityRangeLabel => 'نطاق الصلاحية';

  @override
  String get seatRelease_seatNoLabel => 'رقم المقعد';

  @override
  String get seatRelease_statRemainingDays => 'الأيام المتبقية';

  @override
  String get seatRelease_statReleasedSeats => 'المقاعد المُخلاة';

  @override
  String get seatRelease_statRebookedSeats => 'المقاعد المُعاد حجزها';

  @override
  String get seatRelease_statEarnedReward => 'المكافأة المكتسبة';

  @override
  String seatRelease_daysCount(int days) {
    return '$days يوم';
  }

  @override
  String seatRelease_egpAmount(String amount) {
    return '$amount جنيه';
  }

  @override
  String get seatRelease_quickLinkReleaseLogs => 'سجل الإخلاء';

  @override
  String get seatRelease_quickLinkRewardsStats => 'المكافآت والإحصائيات';

  @override
  String get seatRelease_viewLogsButton => 'عرض السجل';

  @override
  String get seatRelease_releaseSeatButton => 'إخلاء المقعد';

  @override
  String get seatRelease_noPastRecordSnackbar =>
      'لا يوجد سجل إخلاء سابق لهذا التاريخ.';

  @override
  String get seatRelease_reasonSectionTitle => 'سبب إخلاء المقعد';

  @override
  String get seatRelease_optionalNotesTitle => 'ملاحظات اختيارية';

  @override
  String get seatRelease_notesHint => 'مثال: العمل من المنزل يوم الخميس...';

  @override
  String get seatRelease_whyReleaseTitle => 'لماذا تُخلي مقعدك؟';

  @override
  String get seatRelease_releasingTemporaryTitle => 'الإخلاء مؤقت';

  @override
  String get seatRelease_releasingTemporaryBody =>
      'أنت تقوم بإخلاء مقعدك المحجوز لتاريخ هذه الرحلة فقط. يظل اشتراك باقتك نشطًا وتعود حجوزات الرحلات القادمة تلقائيًا.';

  @override
  String get seatRelease_thresholdTitle => 'شرط مهلة الـ 12 ساعة';

  @override
  String get seatRelease_thresholdBody =>
      'إخلاء المقعد متاح فقط إذا تم تقديم الطلب قبل موعد انطلاق الرحلة بـ 12 ساعة على الأقل. لن يتم قبول الطلبات المتأخرة.';

  @override
  String get seatRelease_reasonPersonalPlans => 'خطط شخصية';

  @override
  String get seatRelease_reasonWorkFromHome => 'العمل من المنزل';

  @override
  String get seatRelease_reasonVacation => 'إجازة';

  @override
  String get seatRelease_reasonAlternativeTransport => 'وسيلة مواصلات بديلة';

  @override
  String get seatRelease_reasonMedical => 'سبب طبي';

  @override
  String get seatRelease_reasonOther => 'أخرى';

  @override
  String get seatRelease_benefitCommunityTitle => 'ساعد المجتمع';

  @override
  String get seatRelease_benefitCommunityBody =>
      'تصبح المقاعد المُخلاة متاحة لركاب آخرين يحتاجون رحلات يومية.';

  @override
  String get seatRelease_benefitCompensationTitle => 'احصل على تعويض';

  @override
  String get seatRelease_benefitCompensationBody =>
      'احصل على استرداد نقدي في المحفظة أو مكافآت ولاء إذا قام راكب آخر بحجز مقعدك.';

  @override
  String get seatRelease_benefitOptimizeTitle => 'تحسين استغلال المسار';

  @override
  String get seatRelease_benefitOptimizeBody =>
      'يساعد BMT على تحسين حمولة الأسطول وتقليل الانبعاثات الكربونية.';

  @override
  String get seatRelease_successHeadline => 'تم إخلاء المقعد بنجاح!';

  @override
  String seatRelease_referenceCodeLabel(String code) {
    return 'رمز المرجع: $code';
  }

  @override
  String get seatRelease_releasedDateLabel => 'تاريخ الإخلاء';

  @override
  String get seatRelease_commuteSegmentLabel => 'قطاع التنقل';

  @override
  String get seatRelease_packageSourceLabel => 'مصدر الباقة';

  @override
  String get seatRelease_autoNotifyBody =>
      'سنقوم بإشعارك تلقائيًا وإضافة المكافآت إلى محفظتك بمجرد إعادة حجز مقعدك من قِبل راكب آخر.';

  @override
  String get seatRelease_viewReleaseDetailsButton => 'عرض تفاصيل الإخلاء';

  @override
  String get seatRelease_returnToDashboardButton => 'العودة إلى لوحة التحكم';

  @override
  String seatRelease_idLabel(String id) {
    return 'المعرف: $id';
  }

  @override
  String get seatRelease_releasedSeatLabel => 'المقعد المُخلى';

  @override
  String get seatRelease_reasonChosenLabel => 'السبب المختار';

  @override
  String get seatRelease_submitDateLabel => 'تاريخ التقديم';

  @override
  String get seatRelease_notesLabel => 'ملاحظات';

  @override
  String get seatRelease_statusTimelineTitle => 'الجدول الزمني لحالة الإخلاء';

  @override
  String get seatRelease_backToDashboardButton => 'العودة إلى لوحة التحكم';

  @override
  String seatRelease_referenceLabel(String code) {
    return 'المرجع: $code';
  }

  @override
  String get seatRelease_compensationStatusLabel => 'حالة التعويض';

  @override
  String get seatRelease_compWaitingBody =>
      'مقعدك مُدرج للركاب اليوميين. إذا قام راكب آخر بحجز هذا المقعد قبل موعد الانطلاق، ستحصل على مكافأتك فورًا.';

  @override
  String get seatRelease_compRebookedBody =>
      'تم شراء مقعدك بنجاح. نقوم حاليًا بمعالجة تحصيل نقاط تعويضك.';

  @override
  String get seatRelease_compensationCreditedLabel => 'تم إضافة التعويض';

  @override
  String get seatRelease_creditedToWalletLabel =>
      'تمت الإضافة إلى محفظة الحساب';

  @override
  String seatRelease_clearingDateLabel(String date) {
    return 'تاريخ التحصيل: $date';
  }

  @override
  String get seatRelease_transactionClearedLabel => 'تمت المعاملة بنجاح';

  @override
  String get seatRelease_historySearchHint =>
      'ابحث في سجل الإخلاء بالتاريخ أو المسار...';

  @override
  String get seatRelease_noHistoryRecordsMessage =>
      'لا توجد سجلات إخلاء\nحاول تعديل الفلاتر أو عبارة البحث.';

  @override
  String get seatRelease_alertHistoryLogTitle => 'سجل التنبيهات';

  @override
  String get seatRelease_clearAllButton => 'مسح الكل';

  @override
  String get seatRelease_noNotificationsMessage =>
      'لا توجد إشعارات جديدة\nأنت على اطلاع بكل شيء.';

  @override
  String get seatRelease_achievementsHeaderTitle => 'إنجازات إخلاء المقاعد';

  @override
  String get seatRelease_tileSeatsReleased => 'المقاعد المُخلاة';

  @override
  String get seatRelease_tileRebookedSuccessfully => 'تمت إعادة الحجز بنجاح';

  @override
  String get seatRelease_tileRewardsEarned => 'المكافآت المكتسبة';

  @override
  String get seatRelease_unlockableBadgesTitle => 'الأوسمة القابلة للفتح';

  @override
  String get seatRelease_badgeEcoTitle => 'متنقل صديق للبيئة - المستوى الأول';

  @override
  String get seatRelease_badgeEcoSubtitle =>
      'أخلِ 5 مقاعد لتقليل استهلاك وقود الميكروباص.';

  @override
  String seatRelease_badgeProgressReleased(int count) {
    return '$count/5 تم إخلاؤها';
  }

  @override
  String get seatRelease_badgeCommunityTitle => 'مساعد المجتمع - ذهبي';

  @override
  String get seatRelease_badgeCommunitySubtitle =>
      'ساعد 3 ركاب آخرين في إيجاد مقاعد.';

  @override
  String seatRelease_badgeProgressRebooked(int count) {
    return '$count/3 تم إعادة حجزها';
  }

  @override
  String get seatRelease_badgeRewardTitle => 'جامع المكافآت - المستوى 2';

  @override
  String get seatRelease_badgeRewardSubtitle =>
      'اجمع 200 جنيه من مكافآت الإخلاء.';

  @override
  String seatRelease_badgeProgressReward(String amount) {
    return '$amount جنيه/200 جنيه';
  }

  @override
  String get seatRelease_packageStatusActive => 'نشط';

  @override
  String get seatRelease_packageStatusNone => 'لا يوجد اشتراك';

  @override
  String get seatRelease_packageTypeSubscription => 'باقة اشتراك';

  @override
  String get booking_routeDetails => 'تفاصيل الخط';

  @override
  String booking_allStopsCount(int count) {
    return 'كل المحطات ($count)';
  }

  @override
  String get booking_departure => 'الانطلاق';

  @override
  String get booking_routeSummary => 'ملخص الخط';

  @override
  String booking_seatsAvailableCount(int count) {
    return '$count مقعد متاح';
  }

  @override
  String get booking_selectSeat => 'اختر مقعدًا';

  @override
  String get booking_unableToLoadVehicleDetails => 'تعذر تحميل بيانات المركبة';

  @override
  String get booking_vehicleNotFound => 'المركبة غير موجودة';

  @override
  String get payments_attachReceiptTitle => 'إرفاق الإيصال';

  @override
  String payments_uploadReceiptError(String error) {
    return 'تعذّر رفع الإيصال: $error';
  }

  @override
  String get payments_transferInstructionsTitle => 'تعليمات التحويل';

  @override
  String get payments_transferInstructionsBody =>
      'حوّل قيمة الحجز بالظبط للعنوان اللي تحت وارفع صورة من عملية التحويل.';

  @override
  String get payments_amountToSendLabel => 'المبلغ المطلوب تحويله:';

  @override
  String get payments_instapayIpaLabel => 'عنوان إنستاباي:';

  @override
  String get payments_notConfigured => 'غير مُفعّل';

  @override
  String get payments_accountHolderLabel => 'اسم صاحب الحساب:';

  @override
  String get payments_mobileWalletNoLabel => 'رقم المحفظة:';

  @override
  String get payments_walletTypeLabel => 'نوع المحفظة:';

  @override
  String get payments_defaultWalletChannels => 'فودافون / اورنچ / اتصالات / We';

  @override
  String payments_copiedToClipboard(String value) {
    return 'تم نسخ $value';
  }

  @override
  String get payments_uploadReceiptScreenshot => 'ارفع صورة الإيصال';

  @override
  String get payments_tapToSelectFile => 'دوس عشان تختار ملف (PNG أو JPG)';

  @override
  String get payments_receiptAttachedTitle => 'تم إرفاق الإيصال';

  @override
  String get payments_receiptAttachedBody =>
      'أكّد الدفع عشان تحجز مقعدك وترسل الإيصال للمراجعة.';

  @override
  String get payments_uploading => 'جاري الرفع...';

  @override
  String get payments_submitPayment => 'تأكيد الدفع';

  @override
  String get booking_chooseTripAndVehicle => 'اختر الرحلة والمركبة';

  @override
  String get booking_availableTripsLabel => 'الرحلات المتاحة';

  @override
  String booking_tripOptionsWithVehicles(int count) {
    return '$count خيار رحلة بمركبات محددة';
  }

  @override
  String get booking_sortEarliest => 'الأقرب';

  @override
  String get booking_sortLowestPrice => 'الأقل سعرًا';

  @override
  String get booking_sortMostSeats => 'الأكثر مقاعد';

  @override
  String get payments_closeCheckoutTooltip => 'إغلاق الدفع';

  @override
  String get payments_paymobCheckoutTitle => 'دفع بايموب';

  @override
  String get payments_reloadTooltip => 'تحديث';

  @override
  String get payments_unableToLoadCheckout => 'تعذّر تحميل صفحة الدفع';

  @override
  String get payments_bookingTitle => 'الحجز';

  @override
  String get payments_processingBookingTitle => 'جاري معالجة حجزك...';

  @override
  String get payments_processingBookingSubtitle =>
      'الأمر مش هياخد أكتر من لحظة';

  @override
  String get payments_bookingConfirmedTitle => 'تم تأكيد الحجز';

  @override
  String get payments_bookingConfirmedSubtitle => 'مقعدك محجوز — التفاصيل تحت';

  @override
  String get payments_bookingReferenceLabel => 'مرجع الحجز';

  @override
  String get payments_departsLabel => 'موعد الانطلاق';

  @override
  String payments_vehicleNumberLabel(String vehicle) {
    return 'المركبة $vehicle';
  }

  @override
  String get payments_notesLabel => 'ملاحظات';

  @override
  String get payments_bookingNotesBody =>
      'من فضلك احضر قبل ميعاد الانطلاق بـ10 دقايق. يمكن الإلغاء لحد ساعة قبل الانطلاق.';

  @override
  String get payments_trackVehicle => 'تتبّع المركبة';

  @override
  String get trips_notFoundTitle => 'الرحلة غير موجودة';

  @override
  String get trips_notFoundBody =>
      'قد تكون هذه الرحلة قد أُزيلت أو أصبح الرابط غير صالح. تصفّح المسارات لتخطيط رحلتك التالية.';

  @override
  String trips_starRatingSemantic(int star, String title) {
    return '$star من 5 لـ $title';
  }

  @override
  String get payments_viewFullTripStatus => 'عرض حالة الرحلة والدفع بالكامل';

  @override
  String get payments_rejectedHelpText =>
      'تقدر تتواصل مع الدعم للمساعدة أو تجرب تحجز رحلة تانية.';

  @override
  String get payments_pendingApprovalNotice =>
      'هنبعتلك إشعار بمجرد ما يتم اعتماد الدفع.';

  @override
  String get payments_bookingStatusLabel => 'حالة الحجز';

  @override
  String get payments_reasonLabel => 'السبب';

  @override
  String get payments_estimatedReviewTimeLabel => 'الوقت المتوقع للمراجعة';

  @override
  String get payments_estimatedReviewTimeValue => '٥ - ١٥ دقيقة';

  @override
  String get payments_paymentApprovedTitle => 'تم اعتماد الدفع';

  @override
  String get payments_paymentApprovedSubtitle =>
      'تم التحقق من دفعتك. مقعدك مؤكد وجاهز للتتبع.';

  @override
  String get payments_statusApproved => 'معتمد';

  @override
  String get payments_paymentRejectedTitle => 'تم رفض الدفع';

  @override
  String get payments_paymentRejectedSubtitle =>
      'معرفناش نتأكد من الدفعة دي. كلّم الدعم أو جرّب تحجز تاني.';

  @override
  String get payments_statusRejected => 'مرفوض';

  @override
  String get payments_paymentReceiptSubmittedTitle => 'تم إرسال إيصال الدفع';

  @override
  String get payments_paymentReceiptSubmittedSubtitle =>
      'استلمنا طلب الحجز بتاعك. فريق الحسابات بيراجع دفعتك دلوقتي.';

  @override
  String get payments_statusPendingVerification => 'قيد المراجعة';

  @override
  String get booking_from => 'من';

  @override
  String get booking_to => 'إلى';

  @override
  String booking_seatsCountLabel(int count) {
    return '$count مقعد';
  }

  @override
  String booking_routeStopsCount(int count) {
    return '$count محطة على الخط';
  }

  @override
  String get booking_directTripNoStops => 'رحلة مباشرة بدون محطات وسيطة';

  @override
  String booking_intermediateStopsCount(int count) {
    return '$count محطة وسيطة';
  }

  @override
  String booking_moreStopsCount(int count) {
    return '+ $count محطة أخرى';
  }

  @override
  String get loyalty_titlePortal => 'بوابة الولاء';

  @override
  String get loyalty_titleLedger => 'سجل عمليات النقاط';

  @override
  String get loyalty_titleCatalog => 'كتالوج استبدال النقاط';

  @override
  String get loyalty_titleHub => 'مركز الولاء';

  @override
  String get loyalty_refresh => 'تحديث';

  @override
  String get loyalty_confirmRedemptionTitle => 'تأكيد الاستبدال';

  @override
  String get loyalty_confirmRedemptionBody =>
      'هل أنت متأكد أنك تريد استبدال هذه المكافأة؟';

  @override
  String loyalty_costPoints(int points) {
    return 'التكلفة: $points نقطة';
  }

  @override
  String get loyalty_currentBalance => 'الرصيد الحالي:';

  @override
  String get loyalty_balanceAfterRedemption => 'الرصيد بعد الاستبدال:';

  @override
  String get loyalty_redeemNow => 'استبدل الآن';

  @override
  String get loyalty_voucherUnlocked => 'تم فتح القسيمة! 🎫';

  @override
  String get loyalty_couponGeneratedBody =>
      'تم إنشاء كود الكوبون بنجاح. يمكنك استخدامه أثناء الدفع.';

  @override
  String get loyalty_copyAndClose => 'نسخ وإغلاق';

  @override
  String get loyalty_voucherCopiedSnack => 'تم نسخ كود القسيمة إلى الحافظة!';

  @override
  String get loyalty_navRedeemTitle => 'استبدال النقاط';

  @override
  String get loyalty_navRedeemSubtitle => 'تصفح الكتالوج';

  @override
  String get loyalty_navHistoryTitle => 'سجل النقاط';

  @override
  String get loyalty_navHistorySubtitle => 'سجل العمليات';

  @override
  String loyalty_activeTierPerks(String tier) {
    return 'مزايا فئة $tier الحالية';
  }

  @override
  String get loyalty_exploreMembership => 'استكشف مستويات العضوية';

  @override
  String loyalty_tierMemberBadge(String tier) {
    return 'عضو $tier';
  }

  @override
  String get loyalty_megaLoyaltyBadge => 'برنامج الولاء الكبير';

  @override
  String get loyalty_pointsBalanceLabel => 'رصيد نقاط التنقل';

  @override
  String get loyalty_ptsUnit => 'نقطة';

  @override
  String get loyalty_nextGoalPlatinum => 'الهدف التالي: الفئة البلاتينية';

  @override
  String loyalty_ptsToGo(int points) {
    return 'متبقي $points نقطة';
  }

  @override
  String get loyalty_platinumFootnote =>
      '* تمنحك الفئة البلاتينية ضعف النقاط في كل رحلاتك.';

  @override
  String get loyalty_currentTier => 'فئتك الحالية';

  @override
  String loyalty_needsPoints(String points) {
    return 'يتطلب $points';
  }

  @override
  String get loyalty_transactionLedger => 'سجل معاملات النقاط';

  @override
  String get loyalty_activeLogs => 'سجلات نشطة';

  @override
  String get loyalty_redeemableBalance => 'رصيد النقاط القابل للاستبدال';

  @override
  String loyalty_tierLevelMember(String tier) {
    return 'عضو فئة $tier';
  }

  @override
  String get loyalty_catalogRewards => 'مكافآت الكتالوج';

  @override
  String get loyalty_tiersUnavailable => 'مستويات العضوية غير متاحة حاليًا.';

  @override
  String get loyalty_historyEmptyTitle => 'لا توجد عمليات نقاط بعد';

  @override
  String get loyalty_historyEmptyBody => 'احجز رحلة لتبدأ في جمع النقاط.';

  @override
  String get loyalty_rewardsEmptyTitle => 'لا توجد مكافآت متاحة';

  @override
  String get loyalty_rewardsEmptyBody =>
      'تابعنا قريبًا لاكتشاف طرق جديدة لاستخدام نقاطك.';

  @override
  String get loyalty_transactionFallbackTitle => 'عملية نقاط';

  @override
  String loyalty_redeemFailed(String reason) {
    return 'فشل الاستبدال. $reason';
  }

  @override
  String get loyalty_categoryDiscount => 'خصم';

  @override
  String get loyalty_categoryFreeRide => 'رحلة مجانية';

  @override
  String get loyalty_categoryCashback => 'استرداد نقدي';

  @override
  String get loyalty_categoryPackage => 'باقة';

  @override
  String get loyalty_tierBronze => 'برونزية';

  @override
  String get loyalty_tierSilver => 'فضية';

  @override
  String get loyalty_tierGold => 'ذهبية';

  @override
  String get loyalty_tierPlatinum => 'بلاتينية';

  @override
  String get trips_cancelReasonTitle => 'سبب الإلغاء';

  @override
  String trips_cancelReasonTripRef(String reference) {
    return 'الرحلة $reference';
  }

  @override
  String get trips_reasonScheduleChange => 'تغيير في الموعد';

  @override
  String get trips_reasonAlternativeTransport => 'وجدت وسيلة مواصلات بديلة';

  @override
  String get trips_reasonDriverDelay => 'قلق بشأن تأخر السائق';

  @override
  String get trips_reasonPersonalEmergency => 'ظرف طارئ شخصي';

  @override
  String get trips_reasonDuplicateBooking => 'حجز مكرر';

  @override
  String get trips_cancelDialogTitle => 'هل تريد إلغاء هذه الرحلة؟';

  @override
  String get trips_cancelDialogBody =>
      'سيتم إلغاء حجزك، وسيُعاد مقعدك إلى الرحلة، ولن تتم مراجعة دفعتك بعد الآن. لا يمكن التراجع عن هذا الإجراء — ستحتاج إلى الحجز مرة أخرى.';

  @override
  String trips_cancelReasonPrefix(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get trips_keepTrip => 'الاحتفاظ بالرحلة';

  @override
  String get trips_confirmCancellation => 'تأكيد الإلغاء';

  @override
  String get booking_resetAllFilters => 'إعادة تعيين الكل';

  @override
  String get booking_licensedCaptain => 'كابتن مرخّص';

  @override
  String get booking_eta => 'الوصول المتوقع';

  @override
  String get booking_bookNow => 'احجز الآن';

  @override
  String booking_seatsLeftShort(int count) {
    return 'متبقي $count';
  }

  @override
  String get seatRelease_mockTripDateJun2 => '2 يونيو';

  @override
  String get packages_refreshTooltip => 'تحديث';

  @override
  String get packages_continueToPayment => 'متابعة للدفع';

  @override
  String packages_daysCount(int days) {
    return '$days يوم';
  }

  @override
  String get trips_reviewFormTitle => 'قيّم رحلتك';

  @override
  String get trips_ratingOffice => 'تقييم المكتب';

  @override
  String get trips_ratingDriver => 'تقييم السائق';

  @override
  String get trips_ratingVehicle => 'تقييم المركبة';

  @override
  String get trips_ratingRoute => 'تقييم المسار';

  @override
  String get trips_reviewCommentHint => 'شاركنا رأيك (اختياري)';

  @override
  String get trips_reviewSubmitting => 'جارٍ الإرسال…';

  @override
  String get trips_submitReviewButton => 'إرسال التقييم';

  @override
  String get trips_reviewIncompleteHint =>
      'قيّم السائق والمركبة والمسار بالنجوم للمتابعة.';

  @override
  String get trips_reviewThankYouTitle => 'شكرًا لتقييمك';

  @override
  String trips_reviewThankYouBody(String reference) {
    return 'وصل رأيك حول $reference مباشرة إلى فريق العمليات لدينا، ولا يطّلع عليه أحد سواهم.';
  }

  @override
  String get trips_reviewYourFeedbackLabel => 'رأيك';

  @override
  String get trips_reviewOpening => 'جارٍ فتح تقييمك…';

  @override
  String get trips_reviewOpenError => 'تعذّر فتح تقييمك';

  @override
  String get trips_reviewErrorSignIn => 'سجّل الدخول لتقييم رحلتك.';

  @override
  String get trips_reviewErrorBookingMissing => 'هذا الحجز لم يعد موجودًا.';

  @override
  String get trips_reviewErrorNotYourTrip => 'يمكنك تقييم رحلاتك أنت فقط.';

  @override
  String get trips_reviewErrorCancelled =>
      'تم إلغاء هذا الحجز، لذا لا يوجد ما يمكن تقييمه.';

  @override
  String get trips_reviewErrorNotCompleted =>
      'يمكنك تقييم الرحلة بعد اكتمالها فقط.';

  @override
  String get trips_reviewErrorInvalidRating =>
      'من فضلك قيّم السائق والمركبة والمسار من ١ إلى ٥ نجوم.';

  @override
  String get trips_reviewErrorUnknown => 'تعذّر إرسال تقييمك. حاول مرة أخرى.';

  @override
  String get booking_price => 'السعر';

  @override
  String get booking_mapCoordinatesUnavailable => 'إحداثيات الخريطة غير متاحة';

  @override
  String booking_saveDiscountPercent(int percent) {
    return 'وفّر $percent%';
  }

  @override
  String get booking_bestValue => 'أفضل قيمة';

  @override
  String booking_ridesValidForDays(String rides, String days) {
    return '$rides · صالحة $days';
  }

  @override
  String booking_pricePerRide(String amount) {
    return 'ج.م $amount لكل رحلة';
  }

  @override
  String get booking_yourSelectedTrip => 'رحلتك المختارة';

  @override
  String get booking_startsWithYourTrip => 'يبدأ مع رحلتك';

  @override
  String get booking_couldNotLoadFares => 'تعذر تحميل الأسعار';

  @override
  String get booking_chooseTripTimeAndVehicle => 'اختر وقت الرحلة والمركبة';

  @override
  String get booking_viewRouteDetails => 'عرض تفاصيل الخط';

  @override
  String booking_tripsCountToday(int count) {
    return '$count رحلة اليوم';
  }

  @override
  String get booking_noTripsToday => 'لا توجد رحلات اليوم';

  @override
  String get referral_titleMain => 'الإحالات والمكافآت';

  @override
  String get referral_titleInvite => 'دعوة الأصدقاء';

  @override
  String get referral_titleHistory => 'سجل الإحالات';

  @override
  String get referral_titleWallet => 'محفظة المكافآت';

  @override
  String get referral_titleHub => 'مركز الإحالات';

  @override
  String get referral_codeCopiedSnack => 'تم نسخ كود الإحالة إلى الحافظة!';

  @override
  String get referral_refresh => 'تحديث';

  @override
  String get referral_redemptionSuccessTitle => 'تم الاستبدال بنجاح! 🎉';

  @override
  String get referral_redemptionSuccessBody =>
      'تم تحويل المكافآت مباشرة إلى رصيد محفظتك الرئيسية!';

  @override
  String get referral_successfullyTransferred => 'تم التحويل بنجاح';

  @override
  String get referral_awesome => 'رائع';

  @override
  String get referral_scratchSubtitle =>
      'اكشط البطاقة لتكتشف كود مكافأتك الترويجي!';

  @override
  String get referral_claimReward => 'استلام المكافأة';

  @override
  String get referral_scratchToReveal => 'اكشط البطاقة للكشف';

  @override
  String get referral_scratchWithFinger => 'اكشط بإصبعك!';

  @override
  String get referral_rewardsUnavailable => 'المكافآت غير متاحة';

  @override
  String referral_referralsCount(int count) {
    return '$count إحالة';
  }

  @override
  String get referral_milestoneFirst => 'معلم الإحالة الأولى';

  @override
  String get referral_milestoneReached => 'تم بلوغ الهدف!';

  @override
  String get referral_milestoneNext => 'الهدف التالي للإحالة';

  @override
  String referral_milestoneDescFirst(int target) {
    return 'ادعُ $target أصدقاء لتحصل على أول مكافأة إحالة.';
  }

  @override
  String get referral_milestoneDescReached =>
      'عمل رائع! لقد وصلت إلى الهدف الحالي.';

  @override
  String referral_milestoneDescNext(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining أصدقاء آخرين',
      one: 'صديقًا واحدًا آخر',
    );
    return 'ادعُ $_temp0 لتحصل على مكافأتك التالية.';
  }

  @override
  String referral_progressCount(int current, int target) {
    return 'التقدم: $current / $target إحالة';
  }

  @override
  String get referral_statTotalInvites => 'إجمالي الدعوات';

  @override
  String get referral_statSuccessful => 'ناجحة';

  @override
  String get referral_statTotalEarned => 'إجمالي المكتسب';

  @override
  String get referral_yourCodeLabel => 'كود الإحالة الخاص بك';

  @override
  String get referral_inviteFriendsNow => 'ادعُ أصدقاءك الآن';

  @override
  String get referral_walletSubtitle => 'اكشط القسائم واستبدل الأرصدة';

  @override
  String referral_claimableBadge(int amount) {
    return '$amount جنيه قابل للتحصيل';
  }

  @override
  String get referral_logsHistoryTitle => 'سجلات وتاريخ الإحالات';

  @override
  String get referral_logsHistorySubtitle => 'تابع حالة الدعوات ومطالبات الكود';

  @override
  String get referral_scanToJoin => 'امسح للانضمام إلى BMT';

  @override
  String get referral_qrHint =>
      'اطلب من أصدقائك مسح هذا الرمز للتسجيل تلقائيًا بكودك!';

  @override
  String get referral_close => 'إغلاق';

  @override
  String get referral_howItWorks => 'كيف يعمل';

  @override
  String get referral_step1Title => 'شارك كودك';

  @override
  String get referral_step1Subtitle =>
      'أرسل كودك الفريد لأصدقائك عبر أي وسيلة تواصل.';

  @override
  String get referral_step2Title => 'يسجّل صديقك';

  @override
  String get referral_step2Subtitle =>
      'يسجّل صديقك ويكمل أول رحلة له باستخدام كودك.';

  @override
  String get referral_step3Title => 'تكسبان معًا';

  @override
  String get referral_step3Subtitle =>
      'تحصل على مكافأة إحالة تُضاف إلى محفظتك.';

  @override
  String get referral_directShareOptions => 'خيارات المشاركة المباشرة';

  @override
  String get referral_shareLink => 'مشاركة الرابط';

  @override
  String get referral_showQr => 'عرض رمز QR';

  @override
  String get referral_copyCode => 'نسخ الكود';

  @override
  String get referral_referralsLog => 'سجل الإحالات';

  @override
  String referral_totalReferralsCount(int count) {
    return '$count إحالة إجمالاً';
  }

  @override
  String referral_invitedOn(String date) {
    return 'تمت الدعوة: $date';
  }

  @override
  String get referral_statusRegistered => 'مسجَّل';

  @override
  String get referral_statusFirstOrderCompleted => 'تم إكمال أول طلب';

  @override
  String get referral_statusRewardGranted => 'تم منح المكافأة';

  @override
  String get referral_statusPendingRegistration => 'التسجيل قيد الانتظار';

  @override
  String referral_egpTotal(int amount) {
    return '$amount جنيه';
  }

  @override
  String referral_egpEarned(int amount) {
    return '+ $amount جنيه';
  }

  @override
  String get referral_egpZero => '0 جنيه';

  @override
  String get referral_claimVouchersTitle => 'استلام قسائم المكافآت';

  @override
  String get referral_walletLabel => 'محفظة الإحالات';

  @override
  String referral_walletAvailable(int amount) {
    return '$amount جنيه متاح';
  }

  @override
  String get referral_noBalanceYet => 'لا يوجد رصيد بعد';

  @override
  String get referral_transferHint =>
      'يمكنك تحويل هذا الرصيد إلى محفظتك الرئيسية.';

  @override
  String get referral_earnBalanceHint =>
      'اكسب رصيدًا بدعوة أصدقائك باستخدام كود الإحالة الخاص بك.';

  @override
  String get referral_redeemToWallet => 'استبدال إلى المحفظة';

  @override
  String get referral_noBalanceToRedeem => 'لا يوجد رصيد للاستبدال';

  @override
  String referral_revealedCode(String code) {
    return 'الكود المكتشف: $code';
  }

  @override
  String get referral_lockedScratchToReveal => 'مقفل - اكشط للكشف';

  @override
  String get referral_inviteCopiedSnack => 'تم نسخ الدعوة إلى الحافظة';

  @override
  String get referral_shareYourInvite => 'شارك دعوتك';

  @override
  String referral_shareSheetSubtitle(String code) {
    return 'ادعُ أصدقاءك بكود $code واكسب المكافآت.';
  }

  @override
  String get referral_channelWhatsapp => 'واتساب';

  @override
  String get referral_channelFacebook => 'فيسبوك';

  @override
  String get referral_channelMessenger => 'ماسنجر';

  @override
  String get referral_channelInstagram => 'إنستغرام';

  @override
  String get referral_copyLink => 'نسخ الرابط';

  @override
  String get referral_more => 'المزيد';

  @override
  String get booking_filters => 'الفلاتر';

  @override
  String booking_filtersCount(int count) {
    return 'الفلاتر ($count)';
  }

  @override
  String booking_filtersActiveSemantics(String label) {
    return '$label مُفعّلة';
  }

  @override
  String get booking_faresFrom => 'الأسعار تبدأ من';

  @override
  String get booking_chooseThisRoute => 'اختر هذا الخط';

  @override
  String get booking_routeOverviewLabel => 'نظرة عامة على الخط';

  @override
  String get booking_finalStop => 'المحطة الأخيرة';

  @override
  String get booking_findYourBestCommute => 'ابحث عن أفضل وسيلة تنقل لك';

  @override
  String get booking_searchRoutesWhenAvailable =>
      'ابحث عن الخطوط النشطة عند توفرها.';

  @override
  String booking_routesMatchSearch(int visible, int total) {
    return '$visible من $total خط يطابق بحثك';
  }

  @override
  String get booking_searchDepartureDestinationHint =>
      'ابحث بالانطلاق أو الوجهة أو اسم الخط';

  @override
  String get booking_clearSearch => 'مسح البحث';

  @override
  String get booking_full => 'مكتمل';

  @override
  String get booking_occupancy => 'نسبة الإشغال';

  @override
  String booking_percentFull(int percent) {
    return 'ممتلئ $percent%';
  }

  @override
  String booking_availableBookedSeats(int available, int booked) {
    return '$available متاح · $booked محجوز';
  }

  @override
  String get booking_selectTripAndVehicle => 'اختر الرحلة والمركبة';

  @override
  String booking_seatsCapacity(int count) {
    return 'سعة $count مقعد';
  }

  @override
  String get booking_stepStops => 'المحطات';

  @override
  String booking_stepXOfY(int step, int total) {
    return 'الخطوة $step من $total';
  }

  @override
  String get communication_chatHubTitle => 'مركز المحادثات';

  @override
  String get communication_refresh => 'تحديث';

  @override
  String get communication_searchHint =>
      'ابحث في المحادثات وجهات الاتصال والرسائل...';

  @override
  String get communication_filterAll => 'الكل';

  @override
  String get communication_filterDrivers => 'السائقون';

  @override
  String get communication_filterSupport => 'الدعم';

  @override
  String get communication_filterGroups => 'المجموعات';

  @override
  String get communication_emptyTitle => 'لا توجد محادثات';

  @override
  String get communication_emptySubtitle =>
      'صفِّ أو ابحث ضمن رحلات الباص النشطة لديك.';

  @override
  String get communication_categoryDriver => 'سائق';

  @override
  String get communication_categorySupport => 'الدعم';

  @override
  String get communication_categoryGroup => 'مجموعة';

  @override
  String get communication_statusOpenFallback => 'مفتوحة';

  @override
  String get communication_messageInputHint => 'اكتب رسالتك...';

  @override
  String get communication_justNow => 'الآن';

  @override
  String get booking_pickYourSeat => 'اختر مقعدك';

  @override
  String get booking_frontSeatsNote => 'المقاعد الأمامية هي الأقرب للسائق.';

  @override
  String booking_freeCount(int count) {
    return '$count متاح';
  }

  @override
  String get booking_yourSelectedSeat => 'مقعدك المختار';

  @override
  String get booking_continueToPackages => 'التالي إلى الباقات';

  @override
  String get booking_additionalVehicleSeats => 'مقاعد إضافية بالمركبة';

  @override
  String get booking_couldNotLoadSeats => 'تعذر تحميل المقاعد';

  @override
  String get communication_messagesUnavailable => 'الرسائل غير متاحة';

  @override
  String get booking_whereGetOnOff => 'أين تركب وأين تنزل؟';

  @override
  String get booking_choosePickupThenStop =>
      'اختر نقطة الركوب أولاً، ثم محطة أبعد على الخط.';

  @override
  String booking_stopsCountLabel(int count) {
    return '$count محطة';
  }

  @override
  String get booking_selectYourPickupStop => '1  اختر نقطة الركوب';

  @override
  String get booking_selectYourDropoffStop => '2  اختر الآن نقطة النزول';

  @override
  String get booking_routeSegmentReady => 'مقطع الخط جاهز';

  @override
  String get booking_routeBeginsHere => 'الخط يبدأ هنا';

  @override
  String get booking_finalDestination => 'الوجهة النهائية';

  @override
  String get booking_pickupDropoffPoint => 'نقطة ركوب ونزول';

  @override
  String get booking_findAvailableTrips => 'ابحث عن الرحلات المتاحة';

  @override
  String get booking_reviewYourBooking => 'راجع حجزك';

  @override
  String get booking_nothingChargedUntilPay =>
      'لن يتم خصم أي مبلغ حتى تدفع في الخطوة التالية.';

  @override
  String get booking_proceedToPayment => 'متابعة إلى الدفع';

  @override
  String get booking_seatHeldWhilePaying => 'مقعدك محجوز لك أثناء إتمام الدفع.';

  @override
  String get booking_chooseYourDeparture => 'اختر موعد الانطلاق';

  @override
  String booking_pickupToDropoff(String pickup, String dropoff) {
    return '$pickup إلى $dropoff';
  }

  @override
  String get booking_chooseASeat => 'اختر مقعدًا';

  @override
  String booking_departsAtTime(String time) {
    return 'الانطلاق $time';
  }

  @override
  String booking_departsOnDayAtTime(String day, String time) {
    return 'الانطلاق $day · $time';
  }

  @override
  String get booking_perRide => 'لكل رحلة';

  @override
  String get booking_noTripsAvailable => 'لا توجد رحلات متاحة';

  @override
  String booking_noTripsFoundForRoute(String route) {
    return 'لا توجد رحلات لخط $route اليوم.';
  }

  @override
  String get offices_directoryTitle => 'مكاتب النقل';

  @override
  String get offices_directoryEmpty => 'لا توجد مكاتب متاحة للحجز حاليًا.';

  @override
  String get offices_routesHeader => 'خطوط هذا المكتب';

  @override
  String get offices_noRoutes =>
      'لا توجد خطوط متاحة للحجز لدى هذا المكتب حاليًا.';

  @override
  String get offices_noRatingsYet => 'لا توجد تقييمات بعد';

  @override
  String offices_ratingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تقييمًا',
      few: '$count تقييمات',
      two: 'تقييمان',
      one: 'تقييم واحد',
    );
    return '$_temp0';
  }

  @override
  String get routes_officesCardTitle => 'مكاتب النقل';

  @override
  String get routes_officesCardSubtitle =>
      'استعرض المكاتب وقارن التقييمات واطّلع على خطوط كل مكتب.';

  @override
  String get routes_heroSubtitle => 'ابحث وقارن واحجز رحلتك اليومية';

  @override
  String get routes_searchDescription =>
      'أدخل نقطة الانطلاق والوجهة والتاريخ والوقت لرؤية الرحلات المتاحة.';

  @override
  String get routes_step1Title => 'بحث';

  @override
  String get routes_step1Subtitle => 'نقطة الانطلاق والوجهة والتاريخ والوقت';

  @override
  String get routes_step2Title => 'مقارنة';

  @override
  String get routes_step2Subtitle => 'المسارات والمركبات';

  @override
  String get routes_step3Title => 'اختيار المقعد';

  @override
  String get routes_step3Subtitle => 'اختر مكانك على متن المركبة';

  @override
  String get routes_step4Title => 'الدفع';

  @override
  String get routes_step4Subtitle => 'دفع آمن';

  @override
  String get routes_howItWorks => 'كيف يعمل';

  @override
  String get routes_browsePopularRoutes => 'تصفح المسارات الشائعة';

  @override
  String get routes_tagFastDiscovery => 'اكتشاف سريع';

  @override
  String get routes_tagLiveAvailability => 'توافر لحظي';

  @override
  String get routes_tagPremiumRoutes => 'مسارات مميزة';

  @override
  String get routes_searchTripsButton => 'ابحث عن رحلات';

  @override
  String get booking_routeTypeDirect => 'مباشر';

  @override
  String get booking_routeTypeMultiStop => 'متعدد المحطات';

  @override
  String get booking_chooseBestDeparture => 'اختر موعد الانطلاق الأنسب لك.';

  @override
  String get booking_noExactMatchCoversTrip =>
      'لا توجد نتيجة مطابقة تمامًا لبحثك. هذه الخطوط تغطي معظم رحلتك.';

  @override
  String get booking_noRouteMatchClosest =>
      'لا يوجد خط يطابق هذه الرحلة بالضبط بعد. إليك أقرب الخيارات المتاحة لدينا.';

  @override
  String get booking_bestResultsForYou => 'أفضل النتائج لك';

  @override
  String get booking_otherMatchingRoutes => 'خطوط أخرى مطابقة';

  @override
  String get booking_noBookableTripsNow => 'لا توجد رحلات قابلة للحجز حاليًا';

  @override
  String get booking_noScheduledTripsYet => 'لا توجد رحلات مجدولة بعد';

  @override
  String get booking_routeHasPricingNoTrip =>
      'لهذا الخط تسعيرة، لكن لا توجد رحلة قادمة متاحة للحجز.';

  @override
  String get booking_tripsFromDashboardAppear =>
      'الرحلات التي يتم إنشاؤها من لوحة التحكم ستظهر هنا.';

  @override
  String get booking_noTripsMatchFilters =>
      'لا توجد رحلات تطابق الفلاتر المحددة';

  @override
  String get booking_tryWideningFilterRange =>
      'جرّب توسيع نطاق السعر أو المقاعد أو وقت اليوم.';

  @override
  String get booking_continueWithThisRoute => 'المتابعة بهذا الخط';

  @override
  String get booking_dragToExpandDetails => 'اسحب لتوسيع تفاصيل الخط';

  @override
  String get booking_isThisRouteSuitable => 'هل هذا الخط مناسب؟';

  @override
  String get booking_closestRoutesForSearch => 'أقرب الخطوط لبحثك';

  @override
  String get booking_editStops => 'تعديل المحطات';

  @override
  String get booking_noBookableRouteFound => 'لا يوجد خط قابل للحجز';

  @override
  String get booking_tryDifferentDepartureDest =>
      'جرّب نقطة انطلاق أو وجهة أو وقت سفر مختلف.';

  @override
  String get booking_distance => 'المسافة';

  @override
  String get booking_startingPrice => 'يبدأ من';

  @override
  String get booking_priceRange => 'نطاق السعر';

  @override
  String get booking_stopsNotPublishedYet => 'المحطات غير منشورة بعد';

  @override
  String get booking_routeStationsWillAppear =>
      'ستظهر محطات الخط هنا عند توفرها.';

  @override
  String get booking_routeTimeline => 'خط سير الرحلة';

  @override
  String get booking_whereGetOnOffShort => 'أين يمكنك الركوب والنزول';

  @override
  String get booking_oneStop => 'محطة واحدة';

  @override
  String get booking_stopCapabilityBoardAlight => 'ركوب ونزول';

  @override
  String get booking_stopCapabilityBoardOnly => 'ركوب فقط';

  @override
  String get booking_stopCapabilityAlightOnly => 'نزول فقط';

  @override
  String get booking_stopCapabilityPassThrough => 'بدون توقف';

  @override
  String get booking_stopStart => 'البداية';

  @override
  String get booking_stopEnd => 'النهاية';

  @override
  String get booking_filterTrips => 'تصفية الرحلات';

  @override
  String get booking_filterVehicleType => 'نوع المركبة';

  @override
  String get booking_filterTimeOfDay => 'وقت اليوم';

  @override
  String get booking_filterAny => 'الكل';

  @override
  String get booking_filterSortBy => 'الترتيب حسب';

  @override
  String get booking_dayPartMorning => 'الصباح';

  @override
  String get booking_dayPartAfternoon => 'بعد الظهر';

  @override
  String get booking_dayPartEvening => 'المساء';

  @override
  String get booking_tripSortEarliestDeparture => 'أقرب موعد انطلاق';

  @override
  String get booking_needAChange => 'تريد تعديل شيء؟';

  @override
  String get booking_fare => 'الأجرة';

  @override
  String get booking_fareBreakdown => 'تفاصيل الأجرة';

  @override
  String booking_ridesStartsOn(String rides, String date) {
    return '$rides · تبدأ $date';
  }

  @override
  String get booking_worksOutTo => 'بمعدل';

  @override
  String get booking_youSave => 'توفّر';

  @override
  String booking_vsSingleTickets(int count) {
    return 'مقابل $count تذكرة منفردة';
  }

  @override
  String get booking_totalDue => 'الإجمالي المستحق';

  @override
  String get booking_yourTicket => 'تذكرتك';

  @override
  String get booking_ridesLabel => 'الرحلات';

  @override
  String get booking_oneRide => 'رحلة واحدة';

  @override
  String get booking_receiptTooLarge =>
      'يجب ألا يتجاوز حجم الإيصال 8 ميجابايت.';

  @override
  String get booking_receiptUnreadable =>
      'تعذر قراءة هذا الملف. جرّب ملفًا آخر.';

  @override
  String get booking_someDetailsAreMissing => 'بعض بيانات الحجز ناقصة.';

  @override
  String get booking_choosePaymentMethodToContinue =>
      'اختر طريقة دفع للمتابعة.';

  @override
  String get booking_receiptStillUploading => 'لا يزال إيصالك قيد الرفع.';

  @override
  String get booking_attachReceiptToContinue => 'أرفق إيصال التحويل للمتابعة.';

  @override
  String get booking_submitReceipt => 'إرسال الإيصال';

  @override
  String get booking_couldNotLoadPaymentMethods =>
      'تعذر تحميل طرق الدفع. مقعدك لا يزال محجوزًا لك — حاول مرة أخرى.';

  @override
  String get booking_proofOfTransfer => 'إثبات التحويل';

  @override
  String get booking_receiptAttachedNote =>
      'تم إرفاقه. سيتحقق فريقنا منه مقابل تحويلك.';

  @override
  String get booking_receiptHintUpTo8mb =>
      'لقطة شاشة أو ملف PDF للتحويل — حتى 8 ميجابايت.';

  @override
  String get booking_uploadingEllipsis => 'جارٍ الرفع…';

  @override
  String get booking_replaceReceipt => 'استبدال الإيصال';

  @override
  String get booking_attachReceipt => 'إرفاق الإيصال';

  @override
  String booking_sendMethodTo(String method) {
    return 'أرسل عبر $method إلى';
  }

  @override
  String get booking_contactSupportForTransfer =>
      'تواصل مع الدعم للحصول على بيانات التحويل.';

  @override
  String get booking_copyAccount => 'نسخ الحساب';

  @override
  String get booking_accountNumberCopied => 'تم نسخ رقم الحساب.';

  @override
  String get booking_transferReferenceOptional => 'رقم مرجع التحويل (اختياري)';

  @override
  String get booking_paidFromPhoneOptional =>
      'رقم الهاتف الذي حوّلت منه (اختياري)';

  @override
  String booking_distanceMeters(int meters) {
    return '$meters م';
  }

  @override
  String booking_distanceKm(String km) {
    return '$km كم';
  }

  @override
  String booking_ridersCount(int count) {
    return '$count راكب';
  }

  @override
  String get booking_tracingRoad => 'جارٍ تتبع الطريق…';

  @override
  String get booking_sortShortestDuration => 'الأقصر مدة';

  @override
  String get booking_sortMostTrips => 'الأكثر رحلات';

  @override
  String get booking_filterRoutes => 'تصفية الخطوط';

  @override
  String get booking_seatsAvailableShort => 'مقاعد متاحة';

  @override
  String get booking_checkLater => 'تحقق لاحقًا';

  @override
  String get booking_noActiveRoutesYet => 'لا توجد خطوط نشطة بعد';

  @override
  String get booking_routesFromDashboardAppear =>
      'الخطوط المنشورة من لوحة التحكم ستظهر هنا عند جاهزيتها للحجز.';

  @override
  String get booking_refreshRoutes => 'تحديث الخطوط';

  @override
  String get booking_noRoutesMatchSearch => 'لا توجد خطوط تطابق بحثك';

  @override
  String get booking_tryDifferentSearchTerm =>
      'جرّب كلمة بحث مختلفة أو عدّل الفلاتر.';

  @override
  String get booking_resetFilters => 'إعادة تعيين الفلاتر';

  @override
  String booking_pricesAreForRoute(String pickup, String dropoff) {
    return 'الأسعار من $pickup إلى $dropoff.';
  }

  @override
  String get booking_yourPickupFallback => 'نقطة ركوبك';

  @override
  String get booking_yourStopFallback => 'محطتك';

  @override
  String booking_optionsCount(int count) {
    return '$count خيار';
  }

  @override
  String get booking_chooseYourFare => 'اختر أجرتك';

  @override
  String get booking_reviewBooking => 'راجع الحجز';

  @override
  String get seatSelection_defaultVehicleName => 'حافلة قياسية';

  @override
  String get seatSelection_defaultRoute => 'لم يتم اختيار المسار';

  @override
  String communication_hoursAgo(int hours) {
    return 'منذ $hours س';
  }

  @override
  String referral_inviteMessage(String code, String link) {
    return 'انضم إليّ على EasyWay واحجز تنقلاتك اليومية! استخدم كود الإحالة الخاص بي $code للحصول على مكافأة ترحيبية.\n$link';
  }

  @override
  String get mySubscription_title => 'اشتراكي';

  @override
  String get mySubscription_statusActive => 'نشط';

  @override
  String get mySubscription_statusExpired => 'منتهي';

  @override
  String get mySubscription_statusPending => 'قيد الانتظار';

  @override
  String get mySubscription_started => 'بدأ في';

  @override
  String get mySubscription_expires => 'ينتهي في';

  @override
  String mySubscription_tripsUsedOfTotal(int used, int total) {
    return 'تم استخدام $used من $total رحلة';
  }

  @override
  String mySubscription_tripsRemaining(int count) {
    return 'متبقي $count رحلة';
  }

  @override
  String get mySubscription_unlimitedTrips => 'رحلات غير محدودة';

  @override
  String get mySubscription_emptyTitle => 'لا يوجد اشتراك نشط';

  @override
  String get mySubscription_emptyBody =>
      'تصفح الباقات لتجد ما يناسب تنقلك اليومي.';

  @override
  String get mySubscription_browsePackages => 'تصفح الباقات';
}
