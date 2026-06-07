import '../models/live_trip_model.dart';
import '../../domain/entities/live_trip.dart';

abstract class LiveTripsDatasource {
  Future<List<LiveTripModel>> fetchLiveTrips();
}

class MockLiveTripsDatasource implements LiveTripsDatasource {
  @override
  Future<List<LiveTripModel>> fetchLiveTrips() async {
    return _liveTrips;
  }
}

const _timeline = [
  LiveTripTimelineItem(
    title: 'انطلاق',
    time: '٨:٣٠ صباحاً',
    status: 'تم الانطلاق من بنها',
    done: true,
  ),
  LiveTripTimelineItem(
    title: 'محطة شبرا',
    time: '٨:٥٥ صباحاً',
    status: 'تم الوصول والمغادرة',
    done: true,
  ),
  LiveTripTimelineItem(
    title: 'الدائري',
    time: '٩:١٥ صباحاً',
    status: 'في الطريق',
    done: true,
  ),
  LiveTripTimelineItem(
    title: 'الوصول',
    time: '٩:٤٥ صباحاً',
    status: 'متوقع',
    done: false,
  ),
];

const _liveTrips = [
  LiveTripModel(
    id: 'live-221',
    route: 'بنها - مدينة نصر',
    driver: 'كريم حسن',
    driverStatus: 'يقود الآن',
    vehicle: 'س د هـ ٧٨٩',
    passengersCount: 8,
    progress: 62,
    eta: '١٨ دقيقة',
    currentStation: 'الدائري',
    nextStation: 'عباس العقاد',
    timeline: _timeline,
    alerts: [
      LiveTripAlert(
        id: 'alert-1',
        type: LiveTripAlertType.delay,
        message: 'تأخير ٧ دقائق بسبب ازدحام عند الدائري.',
        time: 'منذ ٣ دقائق',
        urgent: true,
      ),
    ],
  ),
  LiveTripModel(
    id: 'live-224',
    route: 'بنها - القرية الذكية',
    driver: 'محمد أحمد',
    driverStatus: 'متصل ومستقر',
    vehicle: 'أ ب ج ٤٥٦',
    passengersCount: 10,
    progress: 78,
    eta: '١٢ دقيقة',
    currentStation: 'بوابة الشيخ زايد',
    nextStation: 'القرية الذكية',
    timeline: _timeline,
    alerts: [],
  ),
  LiveTripModel(
    id: 'live-226',
    route: 'بنها - المهندسين',
    driver: 'هاني صلاح',
    driverStatus: 'توقف مؤقت',
    vehicle: 'م ن و ٣٣١',
    passengersCount: 12,
    progress: 41,
    eta: '٣٢ دقيقة',
    currentStation: 'المؤسسة',
    nextStation: 'جامعة الدول',
    timeline: _timeline,
    alerts: [
      LiveTripAlert(
        id: 'alert-2',
        type: LiveTripAlertType.suddenStop,
        message: 'توقف مفاجئ لمدة ٤ دقائق.',
        time: 'الآن',
        urgent: true,
      ),
      LiveTripAlert(
        id: 'alert-3',
        type: LiveTripAlertType.complaint,
        message: 'شكوى من راكب عن تأخر الوصول.',
        time: 'منذ دقيقة',
        urgent: false,
      ),
    ],
  ),
  LiveTripModel(
    id: 'live-227',
    route: 'بنها - التجمع',
    driver: 'مصطفى علي',
    driverStatus: 'يحتاج متابعة',
    vehicle: 'ر ز ط ١٢٣',
    passengersCount: 6,
    progress: 35,
    eta: '٤٠ دقيقة',
    currentStation: 'شبرا',
    nextStation: 'الدائري',
    timeline: _timeline,
    alerts: [
      LiveTripAlert(
        id: 'alert-4',
        type: LiveTripAlertType.routeDeviation,
        message: 'خروج بسيط عن المسار المقترح.',
        time: 'منذ ٥ دقائق',
        urgent: true,
      ),
    ],
  ),
];
