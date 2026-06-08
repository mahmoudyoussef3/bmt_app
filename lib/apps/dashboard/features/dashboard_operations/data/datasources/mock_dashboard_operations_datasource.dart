import '../models/dashboard_workspace_model.dart';
import '../../domain/entities/dashboard_workspace.dart';

abstract class DashboardOperationsDatasource {
  Future<DashboardWorkspaceModel> fetchWorkspace(String workspaceId);
}

class MockDashboardOperationsDatasource
    implements DashboardOperationsDatasource {
  @override
  Future<DashboardWorkspaceModel> fetchWorkspace(String workspaceId) async {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) {
      throw ArgumentError('Unknown dashboard workspace: $workspaceId');
    }
    return workspace;
  }

  static const _defaultTabs = [
    DashboardWorkspaceTab(label: 'الكل', filter: 'all'),
    DashboardWorkspaceTab(label: 'يحتاج متابعة', filter: 'attention'),
    DashboardWorkspaceTab(label: 'مكتمل', filter: 'done'),
  ];

  static const Map<String, DashboardWorkspaceModel> _workspaces = {
    'bookings': DashboardWorkspaceModel(
      id: 'bookings',
      title: 'الحجوزات',
      subtitle: 'متابعة الحجوزات وتغيير الحالة وربط الحجز برحلة.',
      actions: [
        DashboardWorkspaceAction(
          label: 'حجز جديد',
          message: 'تم فتح نموذج حجز تجريبي.',
        ),
        DashboardWorkspaceAction(
          label: 'تعديل الحجز',
          message: 'اختر حجزاً من الجدول لتعديل بياناته.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'حجوزات اليوم',
          value: '١٥٦',
          note: '٢٣ تحتاج متابعة',
        ),
        DashboardWorkspaceMetric(
          label: 'مؤكدة',
          value: '١٢٨',
          note: '٨٢٪ من اليوم',
        ),
        DashboardWorkspaceMetric(
          label: 'قيد الانتظار',
          value: '١٩',
          note: 'متوسط الرد ٦ دقائق',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['رقم الحجز', 'العميل', 'الرحلة', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['٩٨٧٢', 'سارة أحمد', '٢٢٤', 'مؤكد'],
          status: 'done',
          details: 'تم تأكيد الدفع وربط المقعد ٦ بالمركبة أ ب ج ٤٥٦.',
        ),
        DashboardWorkspaceRow(
          cells: ['٩٨٧٣', 'خالد محمود', '٢٢١', 'في الانتظار'],
          status: 'attention',
          details: 'ينتظر تأكيد التحويل البنكي قبل موعد الانطلاق.',
        ),
        DashboardWorkspaceRow(
          cells: ['٩٨٧٤', 'رنا يوسف', '٢٢٣', 'جديد'],
          status: 'attention',
          details: 'طلب تعديل موعد ويحتاج تواصل من خدمة العملاء.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'أولوية التشغيل',
          items: [
            'راجع الحجوزات المعلقة قبل الرحلات القريبة.',
            'أغلق طلبات تعديل الموعد قبل نهاية الوردية.',
          ],
        ),
      ],
    ),
    'trips': DashboardWorkspaceModel(
      id: 'trips',
      title: 'الرحلات',
      subtitle: 'إنشاء الرحلات وتعديلها وإسناد السائق والمركبة.',
      actions: [
        DashboardWorkspaceAction(
          label: 'إنشاء رحلة',
          message: 'تم تجهيز نموذج رحلة تجريبي.',
        ),
        DashboardWorkspaceAction(
          label: 'إسناد سائق',
          message: 'اختر رحلة لإسناد السائق.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'رحلات اليوم',
          value: '٤٢',
          note: '١٢ جارية الآن',
        ),
        DashboardWorkspaceMetric(
          label: 'تحتاج تدخل',
          value: '٣',
          note: 'إسناد أو تأخير',
        ),
        DashboardWorkspaceMetric(
          label: 'نسبة الالتزام',
          value: '٩١٪',
          note: 'آخر ٢٤ ساعة',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['رقم الرحلة', 'المسار', 'السائق', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['٢٢٤', 'بنها - القرية الذكية', 'محمد أحمد', 'قادمة'],
          status: 'done',
          details: 'المركبة جاهزة والسائق أكد الحضور.',
        ),
        DashboardWorkspaceRow(
          cells: ['٢٢١', 'بنها - مدينة نصر', 'كريم حسن', 'جارية'],
          status: 'done',
          details: 'الرحلة في الطريق ووصول متوقع خلال ٢٨ دقيقة.',
        ),
        DashboardWorkspaceRow(
          cells: ['٢٢٣', 'بنها - المهندسين', 'مصطفى علي', 'تحتاج تدخل'],
          status: 'attention',
          details: 'تحتاج إسناد مركبة بديلة بسبب صيانة مفاجئة.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'خطة الوردية',
          items: [
            'ابدأ بإسناد المركبات للرحلات القريبة.',
            'راجع الرحلات التي تجاوزت وقت التجمع.',
          ],
        ),
      ],
    ),
    'liveTrips': DashboardWorkspaceModel(
      id: 'liveTrips',
      title: 'الرحلات المباشرة',
      subtitle: 'الرحلات الجارية الآن والتواصل السريع مع السائقين.',
      actions: [
        DashboardWorkspaceAction(
          label: 'عرض مباشر',
          message: 'تم تحديث الخريطة التجريبية.',
        ),
        DashboardWorkspaceAction(
          label: 'التواصل مع السائق',
          message: 'تم فتح قناة اتصال تجريبية.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'جارية الآن',
          value: '١٢',
          note: '٣ مسارات رئيسية',
        ),
        DashboardWorkspaceMetric(
          label: 'متأخرة',
          value: '٢',
          note: 'أكثر من ٧ دقائق',
        ),
        DashboardWorkspaceMetric(
          label: 'مكتملة اليوم',
          value: '٣٠',
          note: 'بدون حوادث',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['رقم الرحلة', 'السائق', 'المركبة', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['٢٢١', 'كريم حسن', 'أ ب ج ٤٥٦', 'في الطريق'],
          status: 'done',
          details: 'آخر تحديث موقع منذ دقيقة واحدة.',
        ),
        DashboardWorkspaceRow(
          cells: ['٢٢٦', 'هاني صلاح', 'س د هـ ٧٨٩', 'متأخرة'],
          status: 'attention',
          details: 'ازدحام عند محور شبرا ويحتاج إبلاغ الركاب.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'متابعة مباشرة',
          items: [
            'اتصل بالسائقين المتأخرين فقط.',
            'أرسل تحديثاً للركاب عند تغير وقت الوصول.',
          ],
        ),
      ],
    ),
    'drivers': DashboardWorkspaceModel(
      id: 'drivers',
      title: 'السائقين',
      subtitle: 'حالة السائقين والرحلات الحالية والتقييم.',
      actions: [
        DashboardWorkspaceAction(
          label: 'إضافة سائق',
          message: 'تم فتح ملف سائق تجريبي.',
        ),
        DashboardWorkspaceAction(
          label: 'عرض الرحلات',
          message: 'اختر سائقاً لعرض سجل الرحلات.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'متاحون',
          value: '٢٦',
          note: 'جاهزون للإسناد',
        ),
        DashboardWorkspaceMetric(
          label: 'في رحلة',
          value: '١٢',
          note: 'يتم تتبعهم',
        ),
        DashboardWorkspaceMetric(
          label: 'يحتاجون متابعة',
          value: '٢',
          note: 'تأخير أو مستندات',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['السائق', 'الهاتف', 'الحالة', 'التقييم'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['محمد أحمد', '٠١٠١٢٣٤٥٦٧٨', 'متاح', '٤.٨'],
          status: 'done',
          details: 'مستندات كاملة وآخر رحلة بدون ملاحظات.',
        ),
        DashboardWorkspaceRow(
          cells: ['كريم حسن', '٠١٢٣٤٥٦٧٨٩٠', 'في رحلة', '٤.٦'],
          status: 'done',
          details: 'ملتزم بالمسار وآخر تحديث منذ دقيقتين.',
        ),
        DashboardWorkspaceRow(
          cells: ['هاني صلاح', '٠١١١٢٢٢٣٣٣٤', 'متأخر', '٤.٥'],
          status: 'attention',
          details: 'تواصل معه مشرف الوردية بسبب تأخير التجمع.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'جاهزية السائقين',
          items: [
            'راجع المستندات المنتهية هذا الأسبوع.',
            'لا تسند رحلات جديدة لمن لديه تأخير نشط.',
          ],
        ),
      ],
    ),
    'vehicles': DashboardWorkspaceModel(
      id: 'vehicles',
      title: 'المركبات',
      subtitle: 'جاهزية المركبات والسعة والسائق الحالي.',
      actions: [
        DashboardWorkspaceAction(
          label: 'إضافة مركبة',
          message: 'تم فتح ملف مركبة تجريبي.',
        ),
        DashboardWorkspaceAction(
          label: 'تعديل الحالة',
          message: 'اختر مركبة لتحديث حالتها.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'جاهزة',
          value: '٣١',
          note: 'صالحة للإسناد',
        ),
        DashboardWorkspaceMetric(
          label: 'في رحلة',
          value: '١٢',
          note: 'تعمل الآن',
        ),
        DashboardWorkspaceMetric(label: 'صيانة', value: '٤', note: '٢ حرجة'),
      ],
      tabs: _defaultTabs,
      columns: ['اللوحة', 'النوع', 'السعة', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['أ ب ج ٤٥٦', 'ميني باص', '١٢', 'جاهزة'],
          status: 'done',
          details: 'فحص الصباح مكتمل والسعة متاحة.',
        ),
        DashboardWorkspaceRow(
          cells: ['س د هـ ٧٨٩', 'فان', '٨', 'في رحلة'],
          status: 'done',
          details: 'مرتبطة بالرحلة ٢٢٦ حالياً.',
        ),
        DashboardWorkspaceRow(
          cells: ['م ن و ٣٣١', 'ميني باص', '١٢', 'صيانة'],
          status: 'attention',
          details: 'تحتاج مراجعة فرامل قبل الإسناد.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'جاهزية الأسطول',
          items: [
            'استخدم المركبات الجاهزة فقط للرحلات الجديدة.',
            'تابع صيانة المركبات الحرجة قبل الذروة.',
          ],
        ),
      ],
    ),
    'users': DashboardWorkspaceModel(
      id: 'users',
      title: 'المستخدمين',
      subtitle: 'بيانات العملاء وسجل الحجوزات والتذاكر.',
      actions: [
        DashboardWorkspaceAction(
          label: 'إضافة مستخدم',
          message: 'تم فتح ملف مستخدم تجريبي.',
        ),
        DashboardWorkspaceAction(
          label: 'إنشاء حجز',
          message: 'اختر مستخدماً لإنشاء حجز.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'نشطون',
          value: '٤٬٨٢٠',
          note: 'آخر ٣٠ يوم',
        ),
        DashboardWorkspaceMetric(
          label: 'يحتاجون متابعة',
          value: '١٧',
          note: 'تذاكر أو دفع',
        ),
        DashboardWorkspaceMetric(
          label: 'مشتركون',
          value: '٧٣٠',
          note: 'باقات نشطة',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['الاسم', 'الهاتف', 'الحجوزات', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['سارة أحمد', '٠١٠١٢٣٤٥٦٧٨', '٤٨', 'نشط'],
          status: 'done',
          details: 'عميلة منتظمة ولا توجد تذاكر مفتوحة.',
        ),
        DashboardWorkspaceRow(
          cells: ['خالد محمود', '٠١٢٣٤٥٦٧٨٩٠', '٣٢', 'يحتاج متابعة'],
          status: 'attention',
          details: 'لديه دفعة معلقة وتذكرة مفتوحة.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'رؤية خدمة العملاء',
          items: [
            'افتح سجل المستخدم قبل الرد على أي تذكرة.',
            'راجع المدفوعات المعلقة عند ظهور حالة متابعة.',
          ],
        ),
      ],
    ),
    'payments': DashboardWorkspaceModel(
      id: 'payments',
      title: 'المدفوعات',
      subtitle: 'مراجعة المدفوعات والمبالغ المستردة وطرق الدفع.',
      actions: [
        DashboardWorkspaceAction(
          label: 'قبول دفع',
          message: 'تمت محاكاة قبول الدفع.',
        ),
        DashboardWorkspaceAction(
          label: 'رد مبلغ',
          message: 'تم فتح طلب رد تجريبي.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'إيراد اليوم',
          value: '١٨٬٤٠٠ ج.م',
          note: 'من ١٢٨ عملية',
        ),
        DashboardWorkspaceMetric(
          label: 'معلقة',
          value: '٥',
          note: 'تحتاج مراجعة',
        ),
        DashboardWorkspaceMetric(
          label: 'مستردة',
          value: '٢',
          note: 'هذا الأسبوع',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['رقم الدفع', 'العميل', 'المبلغ', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['١٠٠١', 'سارة أحمد', '١٢٠ ج.م', 'معلق'],
          status: 'attention',
          details: 'صورة التحويل غير واضحة وتحتاج مراجعة.',
        ),
        DashboardWorkspaceRow(
          cells: ['١٠٠٢', 'خالد محمود', '٢٤٠ ج.م', 'مقبول'],
          status: 'done',
          details: 'تم ربط الدفع بالحجز ٩٨٧٣.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'مراجعة مالية',
          items: [
            'ابدأ بالمدفوعات المعلقة قبل الرحلات القريبة.',
            'لا تعرض بيانات حساسة داخل سجل النشاط.',
          ],
        ),
      ],
    ),
    'tickets': DashboardWorkspaceModel(
      id: 'tickets',
      title: 'الشكاوى',
      subtitle: 'كل الشكاوى المفتوحة وقيد المعالجة والمغلقة.',
      actions: [
        DashboardWorkspaceAction(
          label: 'تعيين مسؤول',
          message: 'تم تعيين مسؤول تجريبي.',
        ),
        DashboardWorkspaceAction(
          label: 'إغلاق',
          message: 'تمت محاكاة إغلاق التذكرة.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'مفتوحة', value: '٨', note: '٢ عالية'),
        DashboardWorkspaceMetric(
          label: 'متوسط الرد',
          value: '٦ دقائق',
          note: 'ضمن الهدف',
        ),
        DashboardWorkspaceMetric(
          label: 'مغلقة اليوم',
          value: '٢٩',
          note: 'رضا ٩٤٪',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['رقم التذكرة', 'العميل', 'الأولوية', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['١٠٠١', 'خالد محمود', 'عالية', 'مفتوحة'],
          status: 'attention',
          details: 'مشكلة دفع تؤثر على رحلة قريبة.',
        ),
        DashboardWorkspaceRow(
          cells: ['١٠٠٢', 'رنا يوسف', 'متوسطة', 'قيد المعالجة'],
          status: 'attention',
          details: 'طلب تغيير موعد تم تحويله للمشرف.',
        ),
        DashboardWorkspaceRow(
          cells: ['١٠٠٣', 'سارة أحمد', 'منخفضة', 'مغلقة'],
          status: 'done',
          details: 'تم تأكيد نقطة التجمع وإغلاق الطلب.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'قواعد الدعم',
          items: [
            'ابدأ بالأولوية العالية المرتبطة برحلات قريبة.',
            'وثق نتيجة المكالمة في تفاصيل التذكرة.',
          ],
        ),
      ],
    ),
    'reports': DashboardWorkspaceModel(
      id: 'reports',
      title: 'التقارير',
      subtitle: 'تقارير تشغيلية ومالية قابلة للتصدير للفرق الداخلية.',
      actions: [
        DashboardWorkspaceAction(
          label: 'تصدير الحجوزات',
          message: 'تم تجهيز تصدير تجريبي.',
        ),
        DashboardWorkspaceAction(
          label: 'تصدير المدفوعات',
          message: 'تم تجهيز ملف مالي تجريبي.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'تقارير جاهزة',
          value: '٦',
          note: 'تحديث تلقائي',
        ),
        DashboardWorkspaceMetric(
          label: 'آخر تحديث',
          value: '٥ دقائق',
          note: 'كل البيانات وهمية',
        ),
        DashboardWorkspaceMetric(
          label: 'طلبات معلقة',
          value: '١',
          note: 'تقرير مالي شهري',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['التقرير', 'الفترة', 'آخر تحديث', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['الحجوزات', 'اليوم', 'منذ ٥ دقائق', 'جاهز'],
          status: 'done',
          details: 'يعرض الحجوزات حسب المسار والحالة.',
        ),
        DashboardWorkspaceRow(
          cells: ['المدفوعات', 'هذا الأسبوع', 'منذ ساعة', 'جاهز'],
          status: 'done',
          details: 'ملخص المقبوضات والمعلقات والمستردات.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'استخدام التقارير',
          items: [
            'التقارير هنا تشغيلية وليست بديلاً للمحاسبة.',
            'مصدر البيانات الحالي وهمي بالكامل.',
          ],
        ),
      ],
    ),
    'permissions': DashboardWorkspaceModel(
      id: 'permissions',
      title: 'الصلاحيات',
      subtitle: 'إدارة أدوار الوصول للمسؤولين فقط.',
      actions: [
        DashboardWorkspaceAction(
          label: 'تعديل صلاحية',
          message: 'تم فتح مصفوفة صلاحيات تجريبية.',
        ),
        DashboardWorkspaceAction(
          label: 'إضافة مسؤول',
          message: 'تم فتح دعوة مسؤول تجريبية.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'أدوار',
          value: '٢',
          note: 'Admin وCustomer Service',
        ),
        DashboardWorkspaceMetric(
          label: 'مستخدمو لوحة',
          value: '١٤',
          note: '٣ مسؤولين',
        ),
        DashboardWorkspaceMetric(
          label: 'محظور عن CS',
          value: '٣',
          note: 'صلاحيات وإعدادات وإدارة',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['الدور', 'الوصول', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['المسؤول', 'كل الأقسام', 'نشط'],
          status: 'done',
          details: 'وصول كامل لكل الشاشات والإعدادات.',
        ),
        DashboardWorkspaceRow(
          cells: ['خدمة العملاء', 'التشغيل والدعم والتقارير', 'نشط'],
          status: 'done',
          details: 'لا يمكنه الوصول للصلاحيات أو الإعدادات أو إدارة المسؤولين.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'محاكاة الوصول',
          items: [
            'تغيير الدور من الشريط الجانبي يغير عناصر التنقل فوراً.',
            'البيانات وهمية وجاهزة لاستبدال المصدر لاحقاً.',
          ],
        ),
      ],
    ),
    'routes': DashboardWorkspaceModel(
      id: 'routes',
      title: 'المسارات',
      subtitle: 'إدارة خطوط التشغيل ونقاط التجمع.',
      actions: [
        DashboardWorkspaceAction(
          label: 'إضافة مسار',
          message: 'تم فتح نموذج مسار تجريبي.',
        ),
        DashboardWorkspaceAction(
          label: 'تعديل نقاط',
          message: 'اختر مساراً لتعديل النقاط.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'مسارات نشطة',
          value: '١٨',
          note: 'داخل القاهرة الكبرى',
        ),
        DashboardWorkspaceMetric(
          label: 'نقاط تجمع',
          value: '١١٢',
          note: '٨ تحتاج مراجعة',
        ),
        DashboardWorkspaceMetric(
          label: 'طلب تعديل',
          value: '٤',
          note: 'هذا الأسبوع',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['المسار', 'البداية', 'النهاية', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['القرية الذكية', 'بنها', 'القرية الذكية', 'نشط'],
          status: 'done',
          details: 'وقت الرحلة المتوقع ٧٥ دقيقة.',
        ),
        DashboardWorkspaceRow(
          cells: ['مدينة نصر', 'بنها', 'مدينة نصر', 'نشط'],
          status: 'done',
          details: 'أعلى طلب في الفترة الصباحية.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'إدارة المسارات',
          items: [
            'المسارات متاحة للمسؤولين فقط في هذه المحاكاة.',
            'راجع نقاط التجمع ذات الشكاوى المتكررة.',
          ],
        ),
      ],
    ),
    'subscriptions': DashboardWorkspaceModel(
      id: 'subscriptions',
      title: 'الاشتراكات',
      subtitle: 'متابعة الاشتراكات والتجديدات للركاب.',
      actions: [
        DashboardWorkspaceAction(
          label: 'تجديد اشتراك',
          message: 'تم فتح تجديد تجريبي.',
        ),
        DashboardWorkspaceAction(
          label: 'إيقاف مؤقت',
          message: 'تم فتح طلب إيقاف تجريبي.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'نشطة',
          value: '٧٣٠',
          note: '١٨ تنتهي قريباً',
        ),
        DashboardWorkspaceMetric(
          label: 'تجديد اليوم',
          value: '٤١',
          note: 'مكتملة',
        ),
        DashboardWorkspaceMetric(
          label: 'تحتاج متابعة',
          value: '٦',
          note: 'دفع أو رصيد منخفض',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['العميل', 'الباقة', 'الرصيد', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['سارة أحمد', 'شهري', '١٨ رحلة', 'نشط'],
          status: 'done',
          details: 'تجديد تلقائي مفعل.',
        ),
        DashboardWorkspaceRow(
          cells: ['ياسمين علي', 'شهري', '٣ رحلات', 'ينتهي قريباً'],
          status: 'attention',
          details: 'أرسل تذكير تجديد قبل نهاية الأسبوع.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'متابعة الاشتراكات',
          items: [
            'هذه شاشة إدارية وليست ضمن صلاحيات خدمة العملاء.',
            'راجع الاشتراكات منخفضة الرصيد قبل ساعات الذروة.',
          ],
        ),
      ],
    ),
    'settings': DashboardWorkspaceModel(
      id: 'settings',
      title: 'الإعدادات',
      subtitle: 'إعدادات عامة للوحة التشغيل.',
      actions: [
        DashboardWorkspaceAction(
          label: 'حفظ الإعدادات',
          message: 'تم حفظ إعدادات تجريبية.',
        ),
      ],
      metrics: [
        DashboardWorkspaceMetric(
          label: 'نمط العرض',
          value: 'فعال',
          note: 'فاتح وداكن',
        ),
        DashboardWorkspaceMetric(
          label: 'إشعارات التشغيل',
          value: 'مفعلة',
          note: 'محاكاة فقط',
        ),
        DashboardWorkspaceMetric(
          label: 'تكاملات خارجية',
          value: '٠',
          note: 'لا توجد APIs',
        ),
      ],
      tabs: _defaultTabs,
      columns: ['الإعداد', 'القيمة', 'النطاق', 'الحالة'],
      rows: [
        DashboardWorkspaceRow(
          cells: ['ساعات الذروة', '٧-١٠ صباحاً', 'التشغيل', 'نشط'],
          status: 'done',
          details: 'تستخدم لترتيب تنبيهات الشاشة فقط.',
        ),
        DashboardWorkspaceRow(
          cells: ['العملة', 'جنيه مصري', 'المدفوعات', 'نشط'],
          status: 'done',
          details: 'عرض وهمي دون تكامل مالي.',
        ),
      ],
      sections: [
        DashboardWorkspaceSection(
          title: 'إعدادات النظام',
          items: [
            'الإعدادات محاكاة ولا ترسل بيانات خارجية.',
            'تبديل الثيم محفوظ عبر cubit موجود.',
          ],
        ),
      ],
    ),
  };
}
