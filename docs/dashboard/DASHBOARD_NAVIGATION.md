# Dashboard — Navigation

---

## 1. The shape

```
┌──────────┬────────────────────────────────────────────────┐
│          │  section · MODULE TITLE      🔔  ☀/🌙  [role]  │  top bar (72px)
│ sidebar  ├────────────────────────────────────────────────┤
│  268px   │                                                │
│   or     │  DashboardModuleHeader                         │
│  76px    │  ─────────────────────                         │
│  rail    │  module content                                │
│          │                                                │
└──────────┴────────────────────────────────────────────────┘
```

Breakpoints:

| Width | Sidebar |
|---|---|
| ≥ 1180px | full, labelled (268px) |
| 920–1180px | icon rail (76px) — a 268px sidebar on a 1000px laptop eats a quarter of the working area |
| < 920px | hidden behind a drawer |

The operator can override with the collapse toggle; `_navCollapsed == null` means "follow
the window", and it stays null until they choose. Collapsed, every icon carries its label
as a tooltip and group boundaries become short rules, or the rail is twenty
undifferentiated icons.

---

## 2. The sidebar, as shipped

```
الرئيسية                    ← operator's console
نظرة تنفيذية                ← executive read          (owner)
التقارير                    ← analytical reports

التشغيل
  العمليات المباشرة
  الرحلات                                             (owner)
  المسارات                                             (owner)
المبيعات
  الحجوزات
  الاشتراكات                                           (owner)
الأسطول
  إدارة الأسطول                                        (owner)
  طلبات الكباتن                                         (owner)
المالية
  المدفوعات                                            (owner)
  محفظة العملاء
الدعم
  الشكاوى
  التقييمات                                            (owner)
النظام
  الإشعارات
  ملف المكتب                                           (owner)
  الباقة والفوترة                                       (owner)
  المستخدمون والصلاحيات                                 (owner)
  الإعدادات                                            (owner)
المنصة                                        (platform admins only)
  مكاتب المنصة
  الباقات والميزات
  التراخيص
  الفوترة والسجل
  برنامج الإحالة
```

A support agent's sidebar is the three top-level entries minus نظرة تنفيذية, plus
العمليات المباشرة, الحجوزات, محفظة العملاء, الشكاوى and الإشعارات. Nine rows.

---

## 3. Why the top three sit outside the groups

الرئيسية, نظرة تنفيذية and التقارير are whole-business surfaces. Filing them under a
section would claim they belong to one part of the business, and they do not — نظرة
تنفيذية reads money *and* operations *and* customers, and التقارير reports across all of
them. Items with `group: null` render above every section header.

They also answer three different questions and are not interchangeable:

| Surface | Question | Audience |
|---|---|---|
| الرئيسية | *What do I have to do right now?* | whoever is on shift |
| نظرة تنفيذية | *How is the business performing?* | the owner, in thirty seconds |
| التقارير | *Show me the numbers, filtered, and give me the file* | whoever is being asked for evidence |

---

## 4. Hidden destinations

Five routes the shell renders but the sidebar does not draw (`inSidebar: false`):

| Route | Reached from | Why not a row |
|---|---|---|
| `/drivers` | Home fleet tile, نظرة تنفيذية | A tab of إدارة الأسطول, not a peer of it |
| `/vehicles` | Home fleet tile, نظرة تنفيذية | Same |
| `/assignments` | Trip planner, when the chosen driver has no bus | Same |
| `/payment-verification` | Home attention panel, نظرة تنفيذية | Redundant with الحجوزات; see the audit |
| `/users` | — | Alias of `/permissions`, kept for compatibility |

**They are still registered.** `_items` is what the role gate, the licensing gate and the
top-bar title read; a route rendered but unregistered used to fall back to the home item,
which permits everyone and is titled "الرئيسية". Being undrawn is a `inSidebar` flag, not
an omission.

---

## 5. Locked rows

A module the office could buy but has not is drawn **dimmed with a padlock**, and it is
still tappable on purpose — the tap is how the owner finds out what the module is and what
it would cost. Hiding a purchasable module makes it unsellable; showing an unpurchasable
one is noise. `EntitlementContext.isLocked` draws that line: `is_public && enforced &&
!isOn`.

Tapping a locked row opens the upgrade card, not the module.

---

## 6. Adding a destination

1. Add the constant to `DashboardRoutes`.
2. Add a `_DashboardNavItem` to `_items` with `permission`, and `feature` if it is
   licensed, and `group` if it belongs to a section, and `inSidebar: false` if it is a
   drill-in.
3. Add a `case` to `_buildContent()`, wrapping the screen in whatever `BlocProvider` it
   needs.
4. Register the cubit in `dashboard_di.dart` as a **factory**.
5. If a new permission is involved, add it to `DashboardPermission` and decide explicitly
   whether the support agent gets it.

Skipping step 2 leaves the route ungated and mistitled. `dashboard_shell_route_gate_test.dart`
fails if it happens.

---

## 7. Cross-module links

Modules do not navigate. The shell passes `onOpenModule(String route)` down to the screens
that need it, and those screens call it. Two special cases:

- **`onCreateTrip`** opens Trips *and* the creation wizard on top of it, so "create a
  trip" from Home is one click rather than navigate-then-hunt. Consumed once per mount.
- **`_openOfficeFeatures(officeId)`** switches to التراخيص *and* selects an office, because
  the licensing console is one long-lived cubit shared by three destinations: telling it
  which office to open **is** the navigation.
