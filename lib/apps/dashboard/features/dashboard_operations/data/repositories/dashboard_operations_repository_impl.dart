import '../../domain/entities/dashboard_workspace.dart';
import '../../domain/repositories/dashboard_operations_repository.dart';

// Workspace layout is static UI configuration — no Supabase query needed.
// Metrics values are placeholders; they will be replaced when the analytics
// aggregates endpoint is wired up in a future iteration.
class DashboardOperationsRepositoryImpl
    implements DashboardOperationsRepository {
  const DashboardOperationsRepositoryImpl();

  @override
  Future<DashboardWorkspace> getWorkspace(String workspaceId) async {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) {
      throw Exception('تعذر تحميل بيانات مساحة العمل: $workspaceId');
    }
    return workspace;
  }

  static const _defaultTabs = [
    DashboardWorkspaceTab(label: 'الكل', filter: 'all'),
    DashboardWorkspaceTab(label: 'يحتاج متابعة', filter: 'attention'),
    DashboardWorkspaceTab(label: 'مكتمل', filter: 'done'),
  ];

  static const Map<String, DashboardWorkspace> _workspaces = {
    'bookings': DashboardWorkspace(
      id: 'bookings',
      title: 'الحجوزات',
      subtitle: 'متابعة الحجوزات وتغيير الحالة وربط الحجز برحلة.',
      actions: [
        DashboardWorkspaceAction(label: 'حجز جديد', message: ''),
        DashboardWorkspaceAction(label: 'تعديل الحجز', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'حجوزات اليوم', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'مؤكدة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'قيد الانتظار', value: '—', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['رقم الحجز', 'العميل', 'الرحلة', 'الحالة'],
      rows: [],
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
    'trips': DashboardWorkspace(
      id: 'trips',
      title: 'الرحلات',
      subtitle: 'إنشاء الرحلات وتعديلها وإسناد السائق والمركبة.',
      actions: [
        DashboardWorkspaceAction(label: 'إنشاء رحلة', message: ''),
        DashboardWorkspaceAction(label: 'إسناد سائق', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'رحلات اليوم', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'تحتاج تدخل', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'نسبة الالتزام', value: '—', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['رقم الرحلة', 'المسار', 'السائق', 'الحالة'],
      rows: [],
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
    'liveTrips': DashboardWorkspace(
      id: 'liveTrips',
      title: 'الرحلات المباشرة',
      subtitle: 'الرحلات الجارية الآن والتواصل السريع مع السائقين.',
      actions: [
        DashboardWorkspaceAction(label: 'عرض مباشر', message: ''),
        DashboardWorkspaceAction(label: 'التواصل مع السائق', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'جارية الآن', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'متأخرة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'مكتملة اليوم', value: '—', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['رقم الرحلة', 'السائق', 'المركبة', 'الحالة'],
      rows: [],
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
    'drivers': DashboardWorkspace(
      id: 'drivers',
      title: 'السائقين',
      subtitle: 'حالة السائقين والرحلات الحالية والتقييم.',
      actions: [
        DashboardWorkspaceAction(label: 'إضافة سائق', message: ''),
        DashboardWorkspaceAction(label: 'عرض الرحلات', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'متاحون', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'في رحلة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'يحتاجون متابعة', value: '—', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['السائق', 'الهاتف', 'الحالة', 'التقييم'],
      rows: [],
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
    'vehicles': DashboardWorkspace(
      id: 'vehicles',
      title: 'المركبات',
      subtitle: 'جاهزية المركبات والسعة والسائق الحالي.',
      actions: [
        DashboardWorkspaceAction(label: 'إضافة مركبة', message: ''),
        DashboardWorkspaceAction(label: 'تعديل الحالة', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'جاهزة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'في رحلة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'صيانة', value: '—', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['اللوحة', 'النوع', 'السعة', 'الحالة'],
      rows: [],
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
    'users': DashboardWorkspace(
      id: 'users',
      title: 'المستخدمين',
      subtitle: 'بيانات العملاء وسجل الحجوزات والتذاكر.',
      actions: [
        DashboardWorkspaceAction(label: 'إضافة مستخدم', message: ''),
        DashboardWorkspaceAction(label: 'إنشاء حجز', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'نشطون', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'يحتاجون متابعة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'مشتركون', value: '—', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['الاسم', 'الهاتف', 'الحجوزات', 'الحالة'],
      rows: [],
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
    'payments': DashboardWorkspace(
      id: 'payments',
      title: 'المدفوعات',
      subtitle: 'مراجعة المدفوعات والمبالغ المستردة وطرق الدفع.',
      actions: [
        DashboardWorkspaceAction(label: 'قبول دفع', message: ''),
        DashboardWorkspaceAction(label: 'رد مبلغ', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'إيراد اليوم', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'معلقة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'مستردة', value: '—', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['رقم الدفع', 'العميل', 'المبلغ', 'الحالة'],
      rows: [],
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
    'tickets': DashboardWorkspace(
      id: 'tickets',
      title: 'الشكاوى',
      subtitle: 'كل الشكاوى المفتوحة وقيد المعالجة والمغلقة.',
      actions: [
        DashboardWorkspaceAction(label: 'تعيين مسؤول', message: ''),
        DashboardWorkspaceAction(label: 'إغلاق', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'مفتوحة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'متوسط الرد', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'مغلقة اليوم', value: '—', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['رقم التذكرة', 'العميل', 'الأولوية', 'الحالة'],
      rows: [],
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
    'reports': DashboardWorkspace(
      id: 'reports',
      title: 'التقارير',
      subtitle: 'تقارير تشغيلية ومالية قابلة للتصدير للفرق الداخلية.',
      actions: [
        DashboardWorkspaceAction(label: 'تصدير الحجوزات', message: ''),
        DashboardWorkspaceAction(label: 'تصدير المدفوعات', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'تقارير جاهزة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'آخر تحديث', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'طلبات معلقة', value: '—', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['التقرير', 'الفترة', 'آخر تحديث', 'الحالة'],
      rows: [],
      sections: [
        DashboardWorkspaceSection(
          title: 'استخدام التقارير',
          items: ['التقارير هنا تشغيلية وليست بديلاً للمحاسبة.'],
        ),
      ],
    ),
    'permissions': DashboardWorkspace(
      id: 'permissions',
      title: 'الصلاحيات',
      subtitle: 'إدارة أدوار الوصول للمسؤولين فقط.',
      actions: [
        DashboardWorkspaceAction(label: 'تعديل صلاحية', message: ''),
        DashboardWorkspaceAction(label: 'إضافة مسؤول', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'أدوار', value: '٢', note: ''),
        DashboardWorkspaceMetric(label: 'مستخدمو لوحة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'محظور عن CS', value: '٣', note: ''),
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
      sections: [],
    ),
    'routes': DashboardWorkspace(
      id: 'routes',
      title: 'المسارات',
      subtitle: 'إدارة خطوط التشغيل ونقاط التجمع.',
      actions: [
        DashboardWorkspaceAction(label: 'إضافة مسار', message: ''),
        DashboardWorkspaceAction(label: 'تعديل نقاط', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'مسارات نشطة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'نقاط تجمع', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'طلب تعديل', value: '—', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['المسار', 'البداية', 'النهاية', 'الحالة'],
      rows: [],
      sections: [
        DashboardWorkspaceSection(
          title: 'إدارة المسارات',
          items: ['راجع نقاط التجمع ذات الشكاوى المتكررة.'],
        ),
      ],
    ),
    'subscriptions': DashboardWorkspace(
      id: 'subscriptions',
      title: 'الاشتراكات',
      subtitle: 'متابعة الاشتراكات والتجديدات للركاب.',
      actions: [
        DashboardWorkspaceAction(label: 'تجديد اشتراك', message: ''),
        DashboardWorkspaceAction(label: 'إيقاف مؤقت', message: ''),
      ],
      metrics: [
        DashboardWorkspaceMetric(label: 'نشطة', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'تجديد اليوم', value: '—', note: ''),
        DashboardWorkspaceMetric(label: 'تحتاج متابعة', value: '—', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['العميل', 'الباقة', 'الرصيد', 'الحالة'],
      rows: [],
      sections: [
        DashboardWorkspaceSection(
          title: 'متابعة الاشتراكات',
          items: ['راجع الاشتراكات منخفضة الرصيد قبل ساعات الذروة.'],
        ),
      ],
    ),
    'settings': DashboardWorkspace(
      id: 'settings',
      title: 'الإعدادات',
      subtitle: 'إعدادات عامة للوحة التشغيل.',
      actions: [DashboardWorkspaceAction(label: 'حفظ الإعدادات', message: '')],
      metrics: [
        DashboardWorkspaceMetric(label: 'نمط العرض', value: '—', note: ''),
        DashboardWorkspaceMetric(
          label: 'إشعارات التشغيل',
          value: '—',
          note: '',
        ),
        DashboardWorkspaceMetric(label: 'تكاملات خارجية', value: '٠', note: ''),
      ],
      tabs: _defaultTabs,
      columns: ['الإعداد', 'القيمة', 'النطاق', 'الحالة'],
      rows: [],
      sections: [],
    ),
  };
}
