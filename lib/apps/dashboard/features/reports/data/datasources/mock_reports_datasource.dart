import 'dart:math';
import '../../domain/entities/report_entities.dart';

class MockReportsDatasource {
  final List<TripReportRow> _trips = [];
  final List<BookingReportRow> _bookings = [];
  final List<RevenueReportRow> _revenue = [];
  final List<DriverReportRow> _drivers = [];
  final List<VehicleReportRow> _vehicles = [];
  final List<SubscriptionReportRow> _subscriptions = [];
  final List<ComplaintReportRow> _complaints = [];
  final List<String> _routes = [
    'CAI-ALX-01', 'ALX-SHM-02', 'CAI-GIZ-03', 'SHM-DAB-04', 'ASW-LUX-05',
    'CAI-SUZ-06', 'ALX-CAI-07', 'HRG-CAI-08', 'CAI-SHM-09', 'DAB-CAI-10',
    'CAI-ASW-11', 'LUX-HRG-12', 'SHM-SUZ-13', 'ALX-SUZ-14', 'CAI-DAB-15'
  ];

  MockReportsDatasource() {
    _generateMockData();
  }

  void _generateMockData() {
    final random = Random(123); // Seeded for deterministic data

    final driversNames = [
      'أحمد رأفت', 'محمود سعد', 'مصطفى كامل', 'ياسر جلال', 'سليمان عيد',
      'إبراهيم عيسى', 'علي شريف', 'محمد رمضان', 'خالد الصاوي', 'طارق لطفي',
      'كريم عبد العزيز', 'أحمد حلمي', 'ماجد الكدواني', 'عمرو يوسف', 'شريف منير',
      'أسر ياسين', 'محمد سعد', 'هاني سلامة', 'أحمد زاهر', 'فتحي عبد الوهاب',
      'سيد رجب', 'بيومي فؤاد', 'صبري فواز', 'محمد فراج', 'أحمد داود',
      'مصطفى خاطر', 'علي ربيع', 'أحمد فتحي', 'محمد ثروت', 'حمدي الميرغني',
      'محمد عبد الرحمن', 'أوس أوس', 'كريم عفيفي', 'شيكو', 'هشام ماجد',
      'أحمد مكي', 'محمد هنيدي', 'علاء ولي الدين', 'أحمد آدم', 'صلاح عبد الله'
    ];

    final plates = [
      'أ ب ج 123', 'د هـ و 456', 'ز ح ط 789', 'ي ك ل 101', 'م ن س 202',
      'ع ف ص 303', 'ق ر ش 404', 'ت ث خ 505', 'ذ ض ظ 606', 'غ أ ب 707',
      'ج د هـ 808', 'و ز ح 909', 'ط ي ك 111', 'ل م ن 222', 'س ع ف 333',
      'ص ق ر 444', 'ش ت ث 555', 'خ ذ ض 666', 'ظ غ أ 777', 'ب ج د 888',
      'هـ و ز 999', 'ح ط ي 121', 'ك ل م 232', 'ن س ع 343', 'ف ص ق 454',
      'ر ش ت 565', 'ث خ ذ 676', 'ض ظ غ 787', 'أ ب ج 898', 'د هـ و 909'
    ];

    final vehicleModels = ['كينج لونج 2024', 'تويوتا هايس 2023', 'مرسيدس بنز 2024', 'شيفورليه مايكرو 2023'];
    final subscriptionPackages = ['الباقة الأسبوعية', 'الباقة الشهرية', 'باقة 10 رحلات', 'باقة 30 رحلة', 'باقة الطلاب المميزة'];
    final complaintCategories = ['سلوك السائق', 'تأخير الرحلة', 'نظافة الحافلة', 'الأعطال الفنية', 'طريقة الدفع', 'أخرى'];

    // 1. Generate Drivers (40 rows)
    for (int i = 0; i < driversNames.length; i++) {
      _drivers.add(DriverReportRow(
        driverId: 'DRV-${2000 + i}',
        name: driversNames[i],
        completedTrips: 15 + random.nextInt(40),
        totalWorkingHours: (80 + random.nextInt(100)).toDouble(),
        rating: (4.0 + random.nextDouble()).clamp(1.0, 5.0),
        totalRevenue: (5000 + random.nextInt(15000)).toDouble(),
        status: random.nextDouble() > 0.1 ? 'نشط' : 'إجازة',
      ));
    }

    // 2. Generate Vehicles (30 rows)
    for (int i = 0; i < plates.length; i++) {
      _vehicles.add(VehicleReportRow(
        vehicleId: 'VEH-${3000 + i}',
        plateNumber: plates[i],
        model: vehicleModels[random.nextInt(vehicleModels.length)],
        completedTrips: 20 + random.nextInt(50),
        fuelConsumption: (10 + random.nextDouble() * 5), // 10 to 15 L/100km
        maintenanceStatus: random.nextDouble() > 0.15 ? 'جاهزة' : 'تحتاج صيانة',
        status: random.nextDouble() > 0.1 ? 'في الخدمة' : 'متوقفة',
      ));
    }

    // 3. Generate Trips (500 rows)
    for (int i = 1; i <= 500; i++) {
      final route = _routes[random.nextInt(_routes.length)];
      final driver = _drivers[random.nextInt(_drivers.length)];
      final vehicle = _vehicles[random.nextInt(_vehicles.length)];

      final passengers = 5 + random.nextInt(25); // 5 to 30 passengers
      final occupancy = passengers / 30.0;
      final revenue = passengers * (30.0 + random.nextInt(6) * 10.0); // 30 to 90 EGP per ticket
      final daysAgo = random.nextInt(60);
      final date = DateTime.now().subtract(Duration(days: daysAgo, hours: random.nextInt(24)));

      _trips.add(TripReportRow(
        tripId: 'TRP-${5000 + i}',
        routeCode: route,
        driverName: driver.name,
        vehiclePlate: vehicle.plateNumber,
        passengerCount: passengers,
        occupancyRate: occupancy,
        revenue: revenue,
        date: date,
        status: random.nextDouble() > 0.05 ? 'مكتملة' : 'ملغاة',
      ));
    }

    // 4. Generate Bookings (1000 rows)
    final clientNames = [
      'خالد علي', 'عمر فاروق', 'منى الشافعي', 'ريهام سعيد', 'عبد الرحمن محمد',
      'ياسر جلال', 'منى زكي', 'حسين فهمي', 'فاتن حمامة', 'أحمد رمزي',
      'سعاد حسني', 'أحمد مظهر', 'عادل إمام', 'نور الشريف', 'محمود عبد العزيز'
    ];

    for (int i = 1; i <= 1000; i++) {
      // Pick a random trip to link details
      final trip = _trips[random.nextInt(_trips.length)];
      final client = clientNames[random.nextInt(clientNames.length)];
      final amount = trip.revenue / trip.passengerCount;

      final method = ['كاش', 'محفظة إلكترونية', 'بطاقة ائتمان', 'انستا باي'][random.nextInt(4)];
      final status = random.nextDouble() > 0.08 ? 'مؤكدة' : 'ملغاة';
      // Booking date is slightly before trip date
      final date = trip.date.subtract(Duration(hours: random.nextInt(48)));

      _bookings.add(BookingReportRow(
        bookingId: 'BKG-${10000 + i}',
        clientName: client,
        tripId: trip.tripId,
        amount: amount,
        paymentMethod: method,
        status: status,
        date: date,
      ));
    }

    // 5. Generate Revenue summaries (800 rows = daily records for the last 800 days)
    for (int i = 0; i < 800; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      
      final bookingsRev = (3000 + random.nextInt(10000)).toDouble();
      final subsRev = (1000 + random.nextInt(5000)).toDouble();
      final refunds = random.nextInt(3);
      final refundsAmt = refunds * 150.0;
      final total = bookingsRev + subsRev;

      _revenue.add(RevenueReportRow(
        date: DateTime(date.year, date.month, date.day),
        totalRevenue: total,
        bookingsRevenue: bookingsRev,
        subscriptionsRevenue: subsRev,
        refundsCount: refunds,
        netRevenue: total - refundsAmt,
      ));
    }

    // 6. Generate Subscriptions (200 rows)
    for (int i = 1; i <= 200; i++) {
      final pkg = subscriptionPackages[random.nextInt(subscriptionPackages.length)];
      final active = 5 + random.nextInt(25);
      final expired = 2 + random.nextInt(15);
      final price = pkg == 'باقة 30 رحلة' ? 700.0 : (pkg == 'باقة 10 رحلات' ? 250.0 : 500.0);
      final totalRev = (active + expired) * price;
      final renewals = active - random.nextInt(5);

      _subscriptions.add(SubscriptionReportRow(
        packageName: pkg,
        activeUsers: active,
        expiredUsers: expired,
        totalRevenue: totalRev,
        renewalsCount: renewals,
      ));
    }

    // 7. Generate Complaints (120 rows)
    for (int i = 0; i < complaintCategories.length; i++) {
      final cat = complaintCategories[i];
      final total = 10 + random.nextInt(30);
      final resolved = total - random.nextInt(6);
      final avgTime = (2 + random.nextDouble() * 24); // 2 to 26 hours

      _complaints.add(ComplaintReportRow(
        category: cat,
        totalComplaints: total,
        resolvedComplaints: resolved,
        avgResolutionTime: avgTime,
        pendingComplaints: total - resolved,
      ));
    }
  }

  // -------------------------------------------------------------
  // DYNAMIC REPORT DATA COMPILER
  // -------------------------------------------------------------
  ReportData getReportData(ReportType type, ReportFilter filter) {
    // Normalise start and end times to encompass full days
    final startOfDay = DateTime(filter.startDate.year, filter.startDate.month, filter.startDate.day);
    final endOfDay = DateTime(filter.endDate.year, filter.endDate.month, filter.endDate.day, 23, 59, 59);

    final String? route = filter.routeCode;
    final String? driver = filter.driverName;
    final String? vehicle = filter.vehiclePlate;
    final String? package = filter.packageName;

    final kpis = <String, String>{};
    final List<dynamic> rows = [];
    final List<MapEntry<String, double>> trends = [];

    // Helper: list dates in filter range for trend generation
    final List<DateTime> dateRangeList = [];
    for (int i = 0; i <= filter.endDate.difference(filter.startDate).inDays; i++) {
      dateRangeList.add(startOfDay.add(Duration(days: i)));
    }

    switch (type) {
      // ---------------------------------------------------------
      // TRIPS REPORT
      // ---------------------------------------------------------
      case ReportType.trips:
        final filteredTrips = _trips.where((t) {
          final inRange = t.date.isAfter(startOfDay) && t.date.isBefore(endOfDay);
          final matchRoute = route == null || t.routeCode == route;
          final matchDriver = driver == null || t.driverName == driver;
          final matchVehicle = vehicle == null || t.vehiclePlate == vehicle;
          return inRange && matchRoute && matchDriver && matchVehicle;
        }).toList();

        // Calculate KPIs
        final totalTrips = filteredTrips.length;
        double totalOccupancy = 0.0;
        double totalRev = 0.0;
        int totalPassengers = 0;

        for (final t in filteredTrips) {
          totalOccupancy += t.occupancyRate;
          totalRev += t.revenue;
          totalPassengers += t.passengerCount;
        }

        final avgOccupancy = totalTrips == 0 ? 0.0 : (totalOccupancy / totalTrips) * 100;
        final avgPassengers = totalTrips == 0 ? 0.0 : (totalPassengers / totalTrips);

        kpis['إجمالي الرحلات'] = '$totalTrips رحلة';
        kpis['نسبة الإشغال المتوسطة'] = '${avgOccupancy.toStringAsFixed(1)}%';
        kpis['إجمالي الإيرادات'] = '${totalRev.toStringAsFixed(0)} ج.م';
        kpis['متوسط الركاب/الرحلة'] = '${avgPassengers.toStringAsFixed(1)} راكب';

        rows.addAll(filteredTrips);

        // Trend: Revenue over the days
        for (final day in dateRangeList) {
          final dateStr = day.toString().substring(0, 10);
          final dayName = _getArabicDayName(day);

          final dayRevenue = filteredTrips
              .where((t) => t.date.toString().substring(0, 10) == dateStr)
              .fold(0.0, (sum, t) => sum + t.revenue);

          trends.add(MapEntry(dayName, dayRevenue));
        }
        break;

      // ---------------------------------------------------------
      // BOOKINGS REPORT
      // ---------------------------------------------------------
      case ReportType.bookings:
        // Filter bookings linked to trips in range & filter
        final filteredBookings = _bookings.where((b) {
          final inRange = b.date.isAfter(startOfDay) && b.date.isBefore(endOfDay);
          
          // Match bookings with the trip filters
          final matchingTripIndex = _trips.indexWhere((t) => t.tripId == b.tripId);
          if (matchingTripIndex == -1) return inRange;

          final trip = _trips[matchingTripIndex];
          final matchRoute = route == null || trip.routeCode == route;
          final matchDriver = driver == null || trip.driverName == driver;
          final matchVehicle = vehicle == null || trip.vehiclePlate == vehicle;

          return inRange && matchRoute && matchDriver && matchVehicle;
        }).toList();

        final totalBkg = filteredBookings.length;
        final sumAmt = filteredBookings.fold(0.0, (sum, b) => sum + b.amount);
        final successfulBkg = filteredBookings.where((b) => b.status == 'مؤكدة').length;
        final successRate = totalBkg == 0 ? 0.0 : (successfulBkg / totalBkg) * 100;
        final avgAmt = totalBkg == 0 ? 0.0 : sumAmt / totalBkg;

        kpis['إجمالي الحجوزات'] = '$totalBkg حجز';
        kpis['قيمة مبيعات التذاكر'] = '${sumAmt.toStringAsFixed(0)} ج.م';
        kpis['معدل نجاح الحجز'] = '${successRate.toStringAsFixed(1)}%';
        kpis['متوسط قيمة التذكرة'] = '${avgAmt.toStringAsFixed(1)} ج.م';

        rows.addAll(filteredBookings);

        // Trend: Bookings count over time
        for (final day in dateRangeList) {
          final dateStr = day.toString().substring(0, 10);
          final dayName = _getArabicDayName(day);

          final count = filteredBookings
              .where((b) => b.date.toString().substring(0, 10) == dateStr)
              .length
              .toDouble();

          trends.add(MapEntry(dayName, count));
        }
        break;

      // ---------------------------------------------------------
      // REVENUE REPORT
      // ---------------------------------------------------------
      case ReportType.revenue:
        final filteredRevenue = _revenue.where((r) {
          return r.date.isAfter(startOfDay) && r.date.isBefore(endOfDay);
        }).toList();

        final totalNet = filteredRevenue.fold(0.0, (sum, r) => sum + r.netRevenue);
        final totalBkgRev = filteredRevenue.fold(0.0, (sum, r) => sum + r.bookingsRevenue);
        final totalSubRev = filteredRevenue.fold(0.0, (sum, r) => sum + r.subscriptionsRevenue);
        final totalRefundsCount = filteredRevenue.fold(0, (sum, r) => sum + r.refundsCount);

        kpis['صافي الإيرادات'] = '${totalNet.toStringAsFixed(0)} ج.م';
        kpis['إيرادات حجز الرحلات'] = '${totalBkgRev.toStringAsFixed(0)} ج.م';
        kpis['إيرادات الاشتراكات'] = '${totalSubRev.toStringAsFixed(0)} ج.م';
        kpis['عدد عمليات الاسترداد'] = '$totalRefundsCount طلب مسترد';

        rows.addAll(filteredRevenue);

        // Trend: Net revenue daily progression
        for (final r in filteredRevenue.reversed.take(10).toList().reversed) {
          trends.add(MapEntry(r.date.toString().substring(5, 10), r.netRevenue));
        }
        if (trends.isEmpty) {
          trends.add(const MapEntry('لا يوجد بيانات', 0.0));
        }
        break;

      // ---------------------------------------------------------
      // DRIVERS REPORT
      // ---------------------------------------------------------
      case ReportType.drivers:
        final filteredDrivers = _drivers.where((d) {
          return driver == null || d.name == driver;
        }).toList();

        final activeDrivers = filteredDrivers.where((d) => d.status == 'نشط').length;
        final avgRating = filteredDrivers.isEmpty
            ? 0.0
            : filteredDrivers.map((d) => d.rating).reduce((a, b) => a + b) / filteredDrivers.length;
        final sumTrips = filteredDrivers.fold(0, (sum, d) => sum + d.completedTrips);
        final sumHours = filteredDrivers.fold(0.0, (sum, d) => sum + d.totalWorkingHours);

        kpis['عدد السائقين'] = '${filteredDrivers.length} سائق';
        kpis['السائقين النشطين حالياً'] = '$activeDrivers سائق';
        kpis['متوسط تقييم الأداء'] = '${avgRating.toStringAsFixed(2)} ★';
        kpis['إجمالي الرحلات المنجزة'] = '$sumTrips رحلة';
        kpis['إجمالي ساعات العمل'] = '${sumHours.toStringAsFixed(0)} ساعة';

        rows.addAll(filteredDrivers);

        // Trend: Driver Completed Trips comparison
        for (final d in filteredDrivers.take(7)) {
          trends.add(MapEntry(d.name.split(' ').first, d.completedTrips.toDouble()));
        }
        break;

      // ---------------------------------------------------------
      // VEHICLES REPORT
      // ---------------------------------------------------------
      case ReportType.vehicles:
        final filteredVehicles = _vehicles.where((v) {
          return vehicle == null || v.plateNumber == vehicle;
        }).toList();

        final readyVehicles = filteredVehicles.where((v) => v.maintenanceStatus == 'جاهزة').length;
        final activeVehicles = filteredVehicles.where((v) => v.status == 'في الخدمة').length;
        final avgFuel = filteredVehicles.isEmpty
            ? 0.0
            : filteredVehicles.map((v) => v.fuelConsumption).reduce((a, b) => a + b) / filteredVehicles.length;

        kpis['إجمالي أسطول المركبات'] = '${filteredVehicles.length} مركبة';
        kpis['مركبات جاهزة للخدمة'] = '$readyVehicles مركبة';
        kpis['المركبات قيد التشغيل'] = '$activeVehicles مركبة';
        kpis['متوسط استهلاك الوقود'] = '${avgFuel.toStringAsFixed(1)} لتر/100كم';

        rows.addAll(filteredVehicles);

        // Trend: Vehicle efficiency
        for (final v in filteredVehicles.take(7)) {
          trends.add(MapEntry(v.plateNumber, v.completedTrips.toDouble()));
        }
        break;

      // ---------------------------------------------------------
      // SUBSCRIPTIONS REPORT
      // ---------------------------------------------------------
      case ReportType.subscriptions:
        final filteredSubs = _subscriptions.where((s) {
          return package == null || s.packageName == package;
        }).toList();

        final sumActive = filteredSubs.fold(0, (sum, s) => sum + s.activeUsers);
        final sumExpired = filteredSubs.fold(0, (sum, s) => sum + s.expiredUsers);
        final sumRevenue = filteredSubs.fold(0.0, (sum, s) => sum + s.totalRevenue);
        final sumRenewals = filteredSubs.fold(0, (sum, s) => sum + s.renewalsCount);

        kpis['المشتركين النشطين'] = '$sumActive مستخدم';
        kpis['الاشتراكات المنتهية'] = '$sumExpired مستخدم';
        kpis['إجمالي مبيعات الباقات'] = '${sumRevenue.toStringAsFixed(0)} ج.م';
        kpis['إجمالي حركات التجديد'] = '$sumRenewals تجديد';

        rows.addAll(filteredSubs);

        // Trend: Subscribers distribution
        for (final s in filteredSubs) {
          trends.add(MapEntry(s.packageName.replaceAll('الباقة ', ''), s.activeUsers.toDouble()));
        }
        break;

      // ---------------------------------------------------------
      // COMPLAINTS REPORT
      // ---------------------------------------------------------
      case ReportType.complaints:
        final totalComplaints = _complaints.fold(0, (sum, c) => sum + c.totalComplaints);
        final resolved = _complaints.fold(0, (sum, c) => sum + c.resolvedComplaints);
        final pending = _complaints.fold(0, (sum, c) => sum + c.pendingComplaints);
        final avgTime = _complaints.isEmpty
            ? 0.0
            : _complaints.map((c) => c.avgResolutionTime).reduce((a, b) => a + b) / _complaints.length;

        kpis['إجمالي الشكاوى الواردة'] = '$totalComplaints شكوى';
        kpis['الشكاوى التي تم حلها'] = '$resolved شكوى';
        kpis['شكاوى قيد المراجعة والحل'] = '$pending شكوى معلقة';
        kpis['متوسط سرعة الاستجابة والحل'] = '${avgTime.toStringAsFixed(1)} ساعة';

        rows.addAll(_complaints);

        // Trend: Complaints by category
        for (final c in _complaints) {
          trends.add(MapEntry(c.category, c.totalComplaints.toDouble()));
        }
        break;
    }

    return ReportData(kpis: kpis, rows: rows, trends: trends);
  }

  // -------------------------------------------------------------
  // REUSABLE HELPER DATA FOR SELECT DROPDOWNS
  // -------------------------------------------------------------
  List<String> getAvailableRoutes() => List.unmodifiable(_routes);

  List<String> getAvailableDrivers() => _drivers.map((d) => d.name).toList();

  List<String> getAvailableVehicles() => _vehicles.map((v) => v.plateNumber).toList();

  List<String> getAvailablePackages() => [
        'الباقة الأسبوعية',
        'الباقة الشهرية',
        'باقة 10 رحلات',
        'باقة 30 رحلة',
        'باقة الطلاب المميزة'
      ];

  // Helper date naming in Arabic
  String _getArabicDayName(DateTime date) {
    const arabicDays = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return arabicDays[date.weekday % 7];
  }
}
