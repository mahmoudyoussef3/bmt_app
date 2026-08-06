-- ═══════════════════════════════════════════════════════════════════════════════════
-- EWT Entitlement Platform — Phase 1/6 (b): the catalog and plan seed
--
-- Design: docs/architecture/PLATFORM_LICENSING.md Part 6, §15.2 step 2.
--
-- 47 features in 7 categories, and 5 plans.
--
-- ── Why no gate rows are seeded here ────────────────────────────────────────────────
--
-- platform_features.enforcement_status is DERIVED from platform_feature_gates, and a
-- gate row means "this feature is gated by this named piece of code". At Phase 1 no
-- code gates anything, so every feature is honestly `declared`. Phase 4 inserts a gate
-- row alongside each trigger and RPC guard it creates, and Phase 6 inserts the
-- marketplace one — which is what flips the console badge to `enforced`. Seeding gates
-- for code that does not exist yet would make the badge a lie on day one, and the
-- badge existing at all is decision 7.
--
-- ── is_public ───────────────────────────────────────────────────────────────────────
--
-- true for the 34 features Part 6 marks `E` (there is, or will be by Phase 6, code
-- behind them), false for the 13 marked `D`. It decides hidden-vs-locked in the nav
-- (§7.4): a feature the code cannot deliver must not be shown to an office as an
-- upgrade prompt.
--
-- ── The numbers ────────────────────────────────────────────────────────────────────
--
-- Every price and every limit below is a PLACEHOLDER (§18 question 5). They are seed
-- data, editable live from the console, and are not a commercial recommendation.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. Categories
-- ═══════════════════════════════════════════════════════════════════════════════════

insert into public.platform_feature_categories (key, name_ar, icon_key, sort_order) values
  ('operations',  'التشغيل',            'route',          10),
  ('fleet',       'الأسطول',            'bus',            20),
  ('sales',       'المبيعات والعملاء',  'ticket',         30),
  ('finance',     'المالية',            'wallet',         40),
  ('insight',     'التقارير والتحليل',  'chart',          50),
  ('engagement',  'التواصل والدعم',     'bell',           60),
  ('platform',    'المنصة والتوسع',     'settings',       70)
on conflict (key) do update
  set name_ar = excluded.name_ar,
      icon_key = excluded.icon_key,
      sort_order = excluded.sort_order;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. The catalog — 47 features
-- ═══════════════════════════════════════════════════════════════════════════════════

insert into public.platform_features
  (key, name_ar, name_en, description_ar, category_key, value_type, value_schema,
   default_value, is_public, meter_kind, meter_period, unit_ar, sort_order)
values
  -- ── Operations ────────────────────────────────────────────────────────────────
  ('trips', 'الرحلات', 'Trips',
   'إنشاء وإدارة الرحلات وجدولتها.',
   'operations', 'boolean', '{}', 'true', true, null, null, '', 10),

  ('routes', 'خطوط السير', 'Routes',
   'بناء خطوط السير ومحطاتها والتسعير بينها.',
   'operations', 'boolean', '{}', 'true', true, null, null, '', 20),

  ('max_routes', 'حد خطوط السير', 'Max routes',
   'أقصى عدد لخطوط السير القائمة. تخفيض الحد لا يحذف أي خط قائم.',
   'operations', 'limit', '{"min": 0, "max": 100000}', '"unlimited"', true,
   'stock', 'lifetime', 'خط', 30),

  ('max_trips_per_month', 'حد الرحلات شهريًا', 'Max trips / month',
   'عدد الرحلات التي يمكن إنشاؤها خلال الشهر. حذف رحلة لا يعيد الحصة.',
   'operations', 'limit', '{"min": 0, "max": 1000000}', '"unlimited"', true,
   'flow', 'month', 'رحلة', 40),

  ('max_live_trips', 'حد الرحلات الجارية', 'Max live trips',
   'أقصى عدد للرحلات الجارية في وقت واحد.',
   'operations', 'limit', '{"min": 0, "max": 100000}', '"unlimited"', true,
   'stock', 'lifetime', 'رحلة', 50),

  ('live_tracking', 'التتبع المباشر', 'Live tracking',
   'بث موقع المركبة أثناء الرحلة وعرضه للعميل ولمركز التشغيل.',
   'operations', 'boolean', '{}', 'true', true, null, null, '', 60),

  ('live_ops_center', 'مركز التشغيل المباشر', 'Live ops center',
   'شاشة متابعة الرحلات النشطة وسلامة التتبع وبلاغات الكباتن.',
   'operations', 'boolean', '{}', 'true', true, null, null, '', 70),

  -- ── Fleet ─────────────────────────────────────────────────────────────────────
  ('drivers', 'السائقون والمركبات', 'Fleet',
   'إدارة السائقين والمركبات وربطهم بالرحلات.',
   'fleet', 'boolean', '{}', 'true', true, null, null, '', 10),

  ('max_drivers', 'حد السائقين', 'Max drivers',
   'أقصى عدد للسائقين النشطين. تخفيض الحد لا يعطّل أي سائق قائم.',
   'fleet', 'limit', '{"min": 0, "max": 100000}', '"unlimited"', true,
   'stock', 'lifetime', 'سائق', 20),

  ('max_vehicles', 'حد المركبات', 'Max vehicles',
   'أقصى عدد للمركبات المسجلة.',
   'fleet', 'limit', '{"min": 0, "max": 100000}', '"unlimited"', true,
   'stock', 'lifetime', 'مركبة', 30),

  ('max_captains', 'حد حسابات الكباتن', 'Max captains',
   'أقصى عدد للسائقين الذين لديهم حساب على تطبيق الكابتن.',
   'fleet', 'limit', '{"min": 0, "max": 100000}', '"unlimited"', true,
   'stock', 'lifetime', 'كابتن', 40),

  ('driver_app', 'تطبيق الكابتن', 'Captain app',
   'دخول السائقين على تطبيق الكابتن وتشغيل الرحلات منه.',
   'fleet', 'boolean', '{}', 'true', true, null, null, '', 50),

  ('bulk_import', 'الاستيراد الجماعي', 'Bulk import',
   'رفع السائقين والمركبات دفعة واحدة من ملف.',
   'fleet', 'boolean', '{}', 'false', false, null, null, '', 60),

  -- ── Sales & customers ─────────────────────────────────────────────────────────
  ('bookings', 'الحجوزات', 'Bookings',
   'استقبال الحجوزات ومراجعتها واعتمادها.',
   'sales', 'boolean', '{}', 'true', true, null, null, '', 10),

  ('client_app', 'الظهور في تطبيق العملاء', 'Client marketplace',
   'ظهور المكتب ورحلاته للعملاء في التطبيق.',
   'sales', 'boolean', '{}', 'true', true, null, null, '', 20),

  ('passenger_packages', 'باقات الركاب', 'Passenger packages',
   'بيع باقات الركوب للعملاء وإدارة اشتراكاتهم.',
   'sales', 'boolean', '{}', 'true', true, null, null, '', 30),

  ('qr_tickets', 'تذاكر QR', 'QR tickets',
   'إصدار تذاكر بكود QR ومسحها عند الصعود.',
   'sales', 'boolean', '{}', 'false', false, null, null, '', 40),

  -- ── Money ─────────────────────────────────────────────────────────────────────
  ('finance', 'المالية', 'Finance',
   'تقارير الإيرادات والتحصيل والمستحقات.',
   'finance', 'boolean', '{}', 'true', true, null, null, '', 10),

  ('wallet', 'محفظة العملاء', 'Customer wallet',
   'رصيد محفوظ للعميل لدى المكتب، مع دفتر حركة كامل.',
   'finance', 'boolean', '{}', 'false', true, null, null, '', 20),

  ('refunds', 'المرتجعات', 'Refunds',
   'طلبات الاسترداد واعتمادها.',
   'finance', 'boolean', '{}', 'false', true, null, null, '', 30),

  ('cashback', 'الكاش باك', 'Cashback',
   'إضافة رصيد ترويجي لمحفظة العميل. يتطلب تفعيل المحفظة.',
   'finance', 'boolean', '{}', 'false', true, null, null, '', 40),

  ('promotions', 'أكواد الخصم', 'Promotions',
   'إنشاء أكواد خصم وحملات ترويجية.',
   'finance', 'boolean', '{}', 'false', true, null, null, '', 50),

  ('loyalty', 'الولاء والنقاط', 'Loyalty',
   'نقاط ومكافآت للعملاء المتكررين.',
   'finance', 'boolean', '{}', 'false', true, null, null, '', 60),

  ('referrals', 'الإحالات', 'Referrals',
   'دعوة العملاء لبعضهم ومكافأة الطرفين.',
   'finance', 'boolean', '{}', 'true', true, null, null, '', 70),

  -- ── Insight ───────────────────────────────────────────────────────────────────
  ('reports', 'التقارير', 'Reports',
   'تقارير التشغيل والمبيعات والأسطول.',
   'insight', 'boolean', '{}', 'true', true, null, null, '', 10),

  ('report_level', 'مستوى التقارير', 'Report level',
   'اتساع التقارير المتاحة: أساسي، احترافي، أو مؤسسي.',
   'insight', 'enum', '{"allowed": ["basic","professional","enterprise"]}',
   '"basic"', true, null, null, '', 20),

  ('analytics_level', 'مستوى التحليلات', 'Analytics level',
   'عمق لوحة التحليلات: أساسي، متقدم، أو مدعوم بالذكاء الاصطناعي.',
   'insight', 'enum', '{"allowed": ["basic","advanced","ai"]}',
   '"basic"', true, null, null, '', 30),

  ('export_pdf', 'تصدير PDF', 'Export PDF',
   'تصدير التقارير بصيغة PDF.',
   'insight', 'boolean', '{}', 'false', true, null, null, '', 40),

  ('export_excel', 'تصدير Excel', 'Export Excel',
   'تصدير التقارير بصيغة Excel أو CSV.',
   'insight', 'boolean', '{}', 'false', true, null, null, '', 50),

  ('max_exports_per_month', 'حد التصدير شهريًا', 'Max exports / month',
   'عدد مرات التصدير خلال الشهر. لا تُستعاد الحصة بحذف الملف.',
   'insight', 'limit', '{"min": 0, "max": 1000000}', '"unlimited"', true,
   'flow', 'month', 'تصدير', 60),

  -- ── Engagement ────────────────────────────────────────────────────────────────
  ('notifications', 'التنبيهات', 'Notifications',
   'تنبيهات التشغيل داخل لوحة التحكم.',
   'engagement', 'boolean', '{}', 'true', true, null, null, '', 10),

  ('push_notifications', 'الإشعارات الفورية', 'Push notifications',
   'إرسال إشعارات فورية لأجهزة العملاء والكباتن.',
   'engagement', 'boolean', '{}', 'false', true, null, null, '', 20),

  ('support_tickets', 'شكاوى العملاء', 'Support tickets',
   'استقبال شكاوى العملاء والرد عليها.',
   'engagement', 'boolean', '{}', 'true', true, null, null, '', 30),

  ('support_sla', 'مستوى دعم المنصة', 'Support SLA',
   'أولوية دعم المنصة للمكتب. تعريفي في الإصدار الحالي.',
   'engagement', 'enum', '{"allowed": ["standard","priority","dedicated"]}',
   '"standard"', false, null, null, '', 40),

  ('marketing', 'أدوات التسويق', 'Marketing tools',
   'حملات تسويقية ورسائل موجهة للعملاء.',
   'engagement', 'boolean', '{}', 'false', false, null, null, '', 50),

  -- ── Platform & scale ──────────────────────────────────────────────────────────
  ('max_admin_users', 'حد مستخدمي اللوحة', 'Max admin users',
   'أقصى عدد لحسابات موظفي المكتب على اللوحة. تخفيض الحد لا يوقف أي حساب قائم.',
   'platform', 'limit', '{"min": 0, "max": 10000}', '"unlimited"', true,
   'stock', 'lifetime', 'مستخدم', 10),

  ('custom_roles', 'أدوار مخصصة', 'Custom roles',
   'تعريف أدوار وصلاحيات إضافية داخل المكتب.',
   'platform', 'boolean', '{}', 'false', false, null, null, '', 20),

  ('multi_branch', 'تعدد الفروع', 'Multi-branch',
   'تقسيم المكتب إلى فروع مستقلة التشغيل.',
   'platform', 'boolean', '{}', 'false', false, null, null, '', 30),

  ('max_branches', 'حد الفروع', 'Max branches',
   'أقصى عدد للفروع.',
   'platform', 'limit', '{"min": 1, "max": 1000}', '1', false,
   'stock', 'lifetime', 'فرع', 40),

  ('api_access', 'واجهة برمجية', 'API access',
   'وصول برمجي لبيانات المكتب من أنظمته الخاصة.',
   'platform', 'boolean', '{}', 'false', false, null, null, '', 50),

  ('max_api_calls_per_month', 'حد نداءات الواجهة شهريًا', 'Max API calls / month',
   'عدد النداءات البرمجية المسموحة خلال الشهر.',
   'platform', 'limit', '{"min": 0, "max": 100000000}', '0', false,
   'flow', 'month', 'نداء', 60),

  ('webhook_url', 'عنوان Webhook', 'Webhook URL',
   'عنوان يستقبل أحداث المكتب لحظيًا.',
   'platform', 'config', '{"kind": "url"}', '""', false, null, null, '', 70),

  ('white_label', 'العلامة البيضاء', 'White label',
   'إخفاء هوية المنصة وعرض هوية المكتب. يتطلب نطاقًا مخصصًا.',
   'platform', 'boolean', '{}', 'false', false, null, null, '', 80),

  ('custom_domain', 'نطاق مخصص', 'Custom domain',
   'نطاق خاص بالمكتب بدلًا من نطاق المنصة.',
   'platform', 'config', '{"kind": "text"}', '""', false, null, null, '', 90),

  ('max_storage_mb', 'حد المساحة', 'Max storage',
   'أقصى مساحة تخزين لملفات المكتب وشعاراته.',
   'platform', 'limit', '{"min": 0, "max": 1000000}', '500', true,
   'stock', 'lifetime', 'ميجابايت', 100),

  ('logo_max_kb', 'أقصى حجم للشعار', 'Logo max size',
   'أقصى حجم لملف شعار المكتب بالكيلوبايت.',
   'platform', 'config', '{"kind": "int"}', '512', true, null, null, '', 110),

  ('booking_retention_days', 'مدة حفظ الحجوزات', 'Booking retention',
   'المدة التي تبقى فيها تفاصيل الحجوزات متاحة.',
   'platform', 'config', '{"kind": "int"}', '"unlimited"', false, null, null, '', 120)

on conflict (key) do update
  set name_ar        = excluded.name_ar,
      name_en        = excluded.name_en,
      description_ar = excluded.description_ar,
      category_key   = excluded.category_key,
      value_type     = excluded.value_type,
      value_schema   = excluded.value_schema,
      default_value  = excluded.default_value,
      is_public      = excluded.is_public,
      meter_kind     = excluded.meter_kind,
      meter_period   = excluded.meter_period,
      unit_ar        = excluded.unit_ar,
      sort_order     = excluded.sort_order;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. Dependencies (§4.1 gate 5 — these can only ever SUBTRACT)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- If a prerequisite resolves falsey, the dependent collapses: a boolean to false, a
-- limit to 0, an enum to its lowest allowed value. Never raises — an override that
-- grants cashback while wallet is off is honoured at rung 2 and defeated here, and
-- the resolver reports BOTH facts so the console can say exactly that.

insert into public.platform_feature_dependencies (feature_key, requires_key) values
  ('cashback',                'wallet'),
  ('white_label',             'custom_domain'),
  ('max_routes',              'routes'),
  ('max_trips_per_month',     'trips'),
  ('max_live_trips',          'trips'),
  ('max_drivers',             'drivers'),
  ('max_captains',            'driver_app'),
  ('live_ops_center',         'live_tracking'),
  ('passenger_packages',      'bookings'),
  ('qr_tickets',              'bookings'),
  ('export_pdf',              'reports'),
  ('export_excel',            'reports'),
  ('max_exports_per_month',   'reports'),
  ('report_level',            'reports'),
  ('push_notifications',      'notifications'),
  ('max_api_calls_per_month', 'api_access'),
  ('webhook_url',             'api_access'),
  ('max_branches',            'multi_branch')
on conflict (feature_key, requires_key) do nothing;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. Plans
-- ═══════════════════════════════════════════════════════════════════════════════════

insert into public.platform_plans
  (key, name_ar, name_en, tagline_ar, status, is_public,
   price_monthly, price_yearly, trial_days, sort_order, notes)
values
  ('founder', 'المؤسِّسة', 'Founder',
   'الباقة الموروثة للمكاتب التي سبقت نظام التراخيص.',
   'active', false, null, null, 0, 5,
   'كل شيء بلا حدود. لا تُعرض للبيع ولا يمكن اختيارها؛ هي ضمان بعدم فقدان أي مكتب قائم لأي قدرة.'),

  ('starter', 'الأساسية', 'Starter',
   'مكتب صغير يبدأ التشغيل.',
   'active', true, 1500, 16500, 0, 10, 'الأرقام مبدئية.'),

  ('professional', 'الاحترافية', 'Professional',
   'مكتب قائم يحتاج المحفظة والتقارير الموسعة.',
   'active', true, 4500, 49500, 14, 20, 'الأرقام مبدئية.'),

  ('enterprise', 'المؤسسية', 'Enterprise',
   'عقد مفصّل بلا حدود تشغيلية.',
   'active', false, null, null, 0, 30,
   'السعر تفاوضي ويُسجَّل على ترخيص المكتب لا على الباقة.'),

  ('restricted', 'المقيّدة', 'Restricted',
   'ما يبقى للمكتب أثناء الإيقاف: قراءة فقط.',
   'active', false, null, null, 0, 90,
   'ليست باقة تُباع. يقرأ منها المُحلِّل قيم المكتب الموقوف (§4.3).')

on conflict (key) do update
  set name_ar    = excluded.name_ar,
      name_en    = excluded.name_en,
      tagline_ar = excluded.tagline_ar,
      status     = excluded.status,
      is_public  = excluded.is_public,
      sort_order = excluded.sort_order;


-- The downgrade chain. Set after insert because it self-references.
update public.platform_plans set downgrade_to_plan_id =
  (select id from public.platform_plans where key = 'starter')
 where key = 'professional';

update public.platform_plans set downgrade_to_plan_id =
  (select id from public.platform_plans where key = 'professional')
 where key = 'enterprise';


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. Plan values
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Only the 34 enforced features get explicit rows. The 13 declared ones fall through
-- to their catalog defaults, so no plan promises a capability the code does not have —
-- turning one on is then a deliberate act, which §9.5's health screen flags.

insert into public.platform_plan_features (plan_id, feature_key, value)
select p.id, v.feature_key, v.value
from (values
  -- ── founder: everything, unlimited. The incumbent offices land here (§15.2 step 3)
  ('founder', 'trips', 'true'::jsonb),
  ('founder', 'routes', 'true'),
  ('founder', 'max_routes', '"unlimited"'),
  ('founder', 'max_trips_per_month', '"unlimited"'),
  ('founder', 'max_live_trips', '"unlimited"'),
  ('founder', 'live_tracking', 'true'),
  ('founder', 'live_ops_center', 'true'),
  ('founder', 'drivers', 'true'),
  ('founder', 'max_drivers', '"unlimited"'),
  ('founder', 'max_vehicles', '"unlimited"'),
  ('founder', 'max_captains', '"unlimited"'),
  ('founder', 'driver_app', 'true'),
  ('founder', 'bookings', 'true'),
  ('founder', 'client_app', 'true'),
  ('founder', 'passenger_packages', 'true'),
  ('founder', 'finance', 'true'),
  ('founder', 'wallet', 'true'),
  ('founder', 'refunds', 'true'),
  ('founder', 'cashback', 'true'),
  ('founder', 'promotions', 'true'),
  ('founder', 'loyalty', 'true'),
  ('founder', 'referrals', 'true'),
  ('founder', 'reports', 'true'),
  ('founder', 'report_level', '"enterprise"'),
  ('founder', 'analytics_level', '"ai"'),
  ('founder', 'export_pdf', 'true'),
  ('founder', 'export_excel', 'true'),
  ('founder', 'max_exports_per_month', '"unlimited"'),
  ('founder', 'notifications', 'true'),
  ('founder', 'push_notifications', 'true'),
  ('founder', 'support_tickets', 'true'),
  ('founder', 'max_admin_users', '"unlimited"'),
  ('founder', 'max_storage_mb', '"unlimited"'),
  ('founder', 'logo_max_kb', '2048'),

  -- ── starter
  ('starter', 'trips', 'true'),
  ('starter', 'routes', 'true'),
  ('starter', 'max_routes', '5'),
  ('starter', 'max_trips_per_month', '100'),
  ('starter', 'max_live_trips', '3'),
  ('starter', 'live_tracking', 'true'),
  ('starter', 'live_ops_center', 'false'),
  ('starter', 'drivers', 'true'),
  ('starter', 'max_drivers', '5'),
  ('starter', 'max_vehicles', '3'),
  ('starter', 'max_captains', '5'),
  ('starter', 'driver_app', 'true'),
  ('starter', 'bookings', 'true'),
  ('starter', 'client_app', 'true'),
  ('starter', 'passenger_packages', 'false'),
  ('starter', 'finance', 'true'),
  ('starter', 'wallet', 'false'),
  ('starter', 'refunds', 'false'),
  ('starter', 'cashback', 'false'),
  ('starter', 'promotions', 'false'),
  ('starter', 'loyalty', 'false'),
  ('starter', 'referrals', 'true'),
  ('starter', 'reports', 'true'),
  ('starter', 'report_level', '"basic"'),
  ('starter', 'analytics_level', '"basic"'),
  ('starter', 'export_pdf', 'false'),
  ('starter', 'export_excel', 'false'),
  ('starter', 'max_exports_per_month', '0'),
  ('starter', 'notifications', 'true'),
  ('starter', 'push_notifications', 'false'),
  ('starter', 'support_tickets', 'true'),
  ('starter', 'max_admin_users', '2'),
  ('starter', 'max_storage_mb', '500'),
  ('starter', 'logo_max_kb', '512'),

  -- ── professional
  ('professional', 'trips', 'true'),
  ('professional', 'routes', 'true'),
  ('professional', 'max_routes', '20'),
  ('professional', 'max_trips_per_month', '1000'),
  ('professional', 'max_live_trips', '15'),
  ('professional', 'live_tracking', 'true'),
  ('professional', 'live_ops_center', 'true'),
  ('professional', 'drivers', 'true'),
  ('professional', 'max_drivers', '25'),
  ('professional', 'max_vehicles', '15'),
  ('professional', 'max_captains', '25'),
  ('professional', 'driver_app', 'true'),
  ('professional', 'bookings', 'true'),
  ('professional', 'client_app', 'true'),
  ('professional', 'passenger_packages', 'true'),
  ('professional', 'finance', 'true'),
  ('professional', 'wallet', 'true'),
  ('professional', 'refunds', 'true'),
  ('professional', 'cashback', 'true'),
  ('professional', 'promotions', 'true'),
  ('professional', 'loyalty', 'true'),
  ('professional', 'referrals', 'true'),
  ('professional', 'reports', 'true'),
  ('professional', 'report_level', '"professional"'),
  ('professional', 'analytics_level', '"advanced"'),
  ('professional', 'export_pdf', 'true'),
  ('professional', 'export_excel', 'true'),
  ('professional', 'max_exports_per_month', '100'),
  ('professional', 'notifications', 'true'),
  ('professional', 'push_notifications', 'true'),
  ('professional', 'support_tickets', 'true'),
  ('professional', 'max_admin_users', '8'),
  ('professional', 'max_storage_mb', '2000'),
  ('professional', 'logo_max_kb', '1024'),

  -- ── enterprise
  ('enterprise', 'trips', 'true'),
  ('enterprise', 'routes', 'true'),
  ('enterprise', 'max_routes', '"unlimited"'),
  ('enterprise', 'max_trips_per_month', '"unlimited"'),
  ('enterprise', 'max_live_trips', '"unlimited"'),
  ('enterprise', 'live_tracking', 'true'),
  ('enterprise', 'live_ops_center', 'true'),
  ('enterprise', 'drivers', 'true'),
  ('enterprise', 'max_drivers', '"unlimited"'),
  ('enterprise', 'max_vehicles', '"unlimited"'),
  ('enterprise', 'max_captains', '"unlimited"'),
  ('enterprise', 'driver_app', 'true'),
  ('enterprise', 'bookings', 'true'),
  ('enterprise', 'client_app', 'true'),
  ('enterprise', 'passenger_packages', 'true'),
  ('enterprise', 'finance', 'true'),
  ('enterprise', 'wallet', 'true'),
  ('enterprise', 'refunds', 'true'),
  ('enterprise', 'cashback', 'true'),
  ('enterprise', 'promotions', 'true'),
  ('enterprise', 'loyalty', 'true'),
  ('enterprise', 'referrals', 'true'),
  ('enterprise', 'reports', 'true'),
  ('enterprise', 'report_level', '"enterprise"'),
  ('enterprise', 'analytics_level', '"ai"'),
  ('enterprise', 'export_pdf', 'true'),
  ('enterprise', 'export_excel', 'true'),
  ('enterprise', 'max_exports_per_month', '"unlimited"'),
  ('enterprise', 'notifications', 'true'),
  ('enterprise', 'push_notifications', 'true'),
  ('enterprise', 'support_tickets', 'true'),
  -- Informational in V1 and documented as such, so this is not a promise the code
  -- fails to keep — it is a routing hint the platform's own staff read.
  ('enterprise', 'support_sla', '"dedicated"'),
  ('enterprise', 'max_admin_users', '"unlimited"'),
  ('enterprise', 'max_storage_mb', '"unlimited"'),
  ('enterprise', 'logo_max_kb', '2048'),

  -- ── restricted: what a SUSPENDED office keeps (§4.3)
  --
  -- Not "everything off". The module booleans stay TRUE so the office can still read
  -- its own operational and financial history — limits gate CREATION, never existence
  -- (§5.4). What goes to zero is new sellable inventory.
  ('restricted', 'trips', 'true'),
  ('restricted', 'routes', 'true'),
  ('restricted', 'max_routes', '0'),
  ('restricted', 'max_trips_per_month', '0'),
  -- Deliberately unlimited. A trip whose tickets are already sold must be able to
  -- depart and complete; blocking it strands passengers, and no billing outcome is
  -- worth that (decision 4).
  ('restricted', 'max_live_trips', '"unlimited"'),
  ('restricted', 'live_tracking', 'true'),
  ('restricted', 'live_ops_center', 'true'),
  ('restricted', 'drivers', 'true'),
  ('restricted', 'max_drivers', '0'),
  ('restricted', 'max_vehicles', '0'),
  ('restricted', 'max_captains', '0'),
  -- Captains keep signing in and completing what they started (§18 question 4).
  ('restricted', 'driver_app', 'true'),
  ('restricted', 'bookings', 'true'),
  ('restricted', 'client_app', 'false'),
  ('restricted', 'passenger_packages', 'false'),
  ('restricted', 'finance', 'true'),
  -- Money OUT is blocked while money IN is disputed. Refund REQUESTS stay open: a
  -- passenger's claim must not be blocked by the office's billing dispute — and the
  -- settlement is blocked anyway, because settling posts to the wallet.
  ('restricted', 'wallet', 'false'),
  ('restricted', 'refunds', 'true'),
  ('restricted', 'cashback', 'false'),
  ('restricted', 'promotions', 'false'),
  ('restricted', 'loyalty', 'false'),
  ('restricted', 'referrals', 'false'),
  ('restricted', 'reports', 'true'),
  ('restricted', 'report_level', '"basic"'),
  ('restricted', 'analytics_level', '"basic"'),
  ('restricted', 'export_pdf', 'false'),
  ('restricted', 'export_excel', 'false'),
  ('restricted', 'max_exports_per_month', '0'),
  ('restricted', 'notifications', 'true'),
  ('restricted', 'push_notifications', 'false'),
  ('restricted', 'support_tickets', 'true'),
  ('restricted', 'max_admin_users', '0'),
  ('restricted', 'max_storage_mb', '500'),
  ('restricted', 'logo_max_kb', '512')
) as v(plan_key, feature_key, value)
join public.platform_plans p on p.key = v.plan_key
on conflict (plan_id, feature_key) do update set value = excluded.value;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Point the platform at its fallback and signup plans
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- default_signup_plan_id follows the proposal in §18 question 2 — 14 days on
-- `professional`, downgrading to `starter`. Both this and grace_days are single-row
-- UPDATEs, so answering those questions differently later is a console edit, not a
-- migration.

update public.platform_settings
   set restricted_plan_id     = (select id from public.platform_plans where key = 'restricted'),
       default_signup_plan_id = (select id from public.platform_plans where key = 'professional')
 where id;
