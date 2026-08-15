# «المنصة» — the Platform Console

The business of EWT itself: what the platform sells, who it sells to, what each customer is
allowed to do, what they were charged, and who decided it.

This is the **only** part of the dashboard that is not about running a transport office. Every
other module — الرحلات, الحجوزات, إدارة الأسطول, المدفوعات — belongs to a *tenant*. المنصة
belongs to EWT, and it is where a transport office is created, priced, licensed, invoiced,
suspended and audited.

> **Access.** Four sidebar rows, visible only when the signed-in operator's session carries
> `is_platform_admin` **and** the `platformOffices` / `platformLicensing` permissions. The flag is
> a hint for the shell only: every RPC behind these screens re-checks it server-side, so a forged
> session lands on the screen and then fails on contact.

> **Rebuilt 2026-08-14.** Seven sidebar rows became four, and the reasoning is in
> [Part 6](#part-6--the-2026-08-14-consolidation). The subsystem's rules did not change; the
> enforcement design, the migrations and the regression suite are documented separately in
> [../architecture/PLATFORM_LICENSING.md](../architecture/PLATFORM_LICENSING.md), which remains the
> authority on *how* entitlement is enforced. This document is the authority on **what the business
> is and how the console expresses it**.

---

## Part 1 — The business in one page

EWT is a **multi-tenant SaaS**. It does not run buses. It sells three transport-office
applications — the operations dashboard, the captain app, and a place in the client marketplace —
to transport offices, on a subscription.

The commercial model has exactly four nouns, and no synonyms are permitted:

| Noun | Arabic | What it is |
|---|---|---|
| **Feature** | ميزة | One capability the platform can sell, and its type. `max_drivers` is a feature. `wallet` is a feature. |
| **Plan** | باقة | A named, priced bundle of feature *values*. A template. It has no behaviour of its own. |
| **License** | ترخيص | One office's subscription to one plan, with a status, a billing cycle and a period. |
| **Override** | استثناء | One feature value for one office, above or below what their plan says. |

> **The naming law.** `plan` and `license` — never `package` or `subscription`. Those two words
> already mean *passenger fare bundles* in four tables and in the الاشتراكات nav item, which is a
> completely different product sold by an office to a passenger. Mixing them has broken this
> codebase before. See the note on the two subscription worlds in
> [../architecture/PLATFORM_LICENSING.md](../architecture/PLATFORM_LICENSING.md).

### What an office is allowed to do

Three independent predicates, ANDed, never merged:

```
may = role  ∧  entitlement  ∧  quota
      │        │               └── "you have 5 of 5 drivers"      (office_can_consume)
      │        └────────────────── "your plan includes the wallet" (office_has)
      └─────────────────────────── "you are an owner, not support" (office_can)
```

They stay separate so a refusal can always name **which one** said no. "غير مسموح" that could mean
any of three things is a support ticket; "باقتك لا تشمل المحفظة" is an upgrade.

### The resolution ladder

Every feature value an office resolves comes from exactly one rung, and the console always shows
which one. This single field is the difference between a two-minute support conversation and a
twenty-minute one.

| Rung | Beats everything below | Shown as |
|---|---|---|
| 1. **Platform kill switch** | A feature marked `disabled` in the catalog returns to its default for *everyone*, whatever any plan or override says. | «مفتاح إيقاف المنصة» |
| 2. **License hold** | A suspended or expired licence withdraws creation rights and marketplace listing. | «حالة الترخيص» |
| 3. **Override** | This office's negotiated exception. | «استثناء» |
| 4. **Plan** | The value the office's plan carries. | «الباقة» |
| 5. **Catalog default** | No one decided; the catalog's default applies. | «الافتراضي» |

**A feature absent from a plan is not a feature set to false.** It means "fall through to the
catalog default", which may well be `true`. `platform_save_plan` replaces a plan's feature map
*wholesale*, so an omitted key is a deleted key — the plan editor therefore always sends the
complete map, and the difference between "unset" and "false" is drawn on every row.

### The kill switch

One row, no deploy:

```sql
update public.platform_settings set enforcement_mode = 'off';
```

`off` restores pre-licensing behaviour instantly and completely — every gate is mode-aware, and a
trigger reprojects `licensing_hold` for every office when the mode moves. `shadow` records
violations without blocking anything; **a row appearing in shadow means a limit is misconfigured,
not that an office is cheating.** `enforcing` is production.

The switch is on the التراخيص page header, as a three-segment control with the consequence written
underneath it. It is not buried in settings, because the moment it is needed is a moment when
nobody wants to go looking.

### Limits do not delete

An office that downgrades from 50 drivers to 10 **keeps all 50**. Limits block *creation*, they
never remove what exists. "تجاوز حدًّا" is therefore a real, expected state — a fact about a
customer, not an error — and the console says so out loud on the signals strip rather than styling
it as a fault.

Two kinds of meter, and they behave differently:

- **stock** — how many exist right now. Counted at read time, so deleting a driver returns the
  seat and the number can never drift.
- **flow** — how many happened this period. Deleting the trip does **not** return the quota, or an
  office on a 100-trip plan would run 1,000 by deleting each one as it finished.

The usage tab labels which is which, because "why did my number not go down" is the first question
this data produces.

### Billing is a record, not a gateway

There is no card capture, no payment provider and no automatic collection in this version. An
invoice is a **record** that a gateway can later plug into; payment is recorded by hand when it
arrives. The screen says so in its subtitle, so that a «مسدَّد» chip is never mistaken for money
that moved by itself.

### The audit trail cannot be edited

Written by database triggers, not by application code — an audit log a caller can forget to write
is not an audit log. It is append-only: the API roles cannot UPDATE or DELETE it, and a trigger
refuses both even for the table owner. Removing evidence requires a schema change, which is itself
visible.

---

## Part 2 — The four destinations

```
المنصة
├── مكاتب المنصة        create the customer, and decide if the marketplace shows them
├── الباقات والميزات     decide what there is to sell, and what it costs
├── التراخيص             decide what this customer gets, and what they are using
└── الفوترة والسجل       what was charged, and what was decided
```

Every destination follows one shape:

> **Browse in a grid → open one thing full width → work.**
> The only exception is كتالوج الميزات, which is read rather than edited and so keeps a
> master/detail split: you skim many rows and read one.

---

### 2.1 مكاتب المنصة — the customer roster

**The job:** bring a transport office onto the platform, and control whether the client marketplace
shows it.

**Onboarding is one transaction that creates two things** — an office row and a login account —
and the form keeps them visually separate for one reason: the office's public contact email is not
the administrator's login. The login is a **name**; the address behind it is synthetic and never
typed by anyone.

The password is shown **once**, on a full-width panel, and cannot be read back from anywhere. That
panel is a distinct state rather than a flag, precisely so a rebuild cannot lose the only copy.

**Listing is separate from existence.** A newly created office is live but invisible: it does not
appear to clients until it is published to the marketplace, and publishing requires a description
and service areas. Withdrawing an office hides it from clients without touching its operations.

**What this screen does not do:** it does not price anything. An office created here has no licence
until one is assigned on التراخيص. The «مكاتب بلا ترخيص» signal there is the handoff.

---

### 2.2 الباقات والميزات — the product

Two sections, one destination, because they are two halves of one question: a plan is a set of
feature values, and a feature is meaningless until a plan carries it. Nobody prices one without
reading the other.

#### الباقات — the gallery

Plans are read the way a pricing page is read: a grid of cards carrying the price, the trial, the
reach and their own actions. Opening one replaces the gallery with a **full-width workspace**.

The workspace has three tabs:

| Tab | Answers |
|---|---|
| **الميزات** | What this plan includes — the whole catalog, grouped by category, each row a typed control. |
| **المكاتب** | Who is on it right now, and therefore who a save will affect. |
| **السجل** | Every previous version, diffed against the current one. |

**A plan can be edited while it is live**, and the change applies to every subscribed office
immediately. That is not a hazard to be warned about repeatedly — it is what a plan *is*, a
template with no behaviour of its own. The save bar states the blast radius (`يسري فورًا على N
مكتب مشترك`) and the previous state is snapshotted into the revision history either way.

**Saving is not a negotiation.** `platform_save_plan` requires no reason and writes the revision
snapshot regardless, so the save bar carries an **optional inline note**, not a modal demanding
eight characters. Publishing and archiving still confirm — but they confirm with the *consequence*,
not with a text field:

> أرشفة «الباقة الاحترافية» — المكاتب الـ٣ المشتركة تكمل عليها بلا أي تغيير، ولا يمكن تعيينها
> لمكتب جديد بعد الأرشفة.

**Archiving is not deletion.** Subscribed offices continue untouched; the plan simply stops being
assignable to new ones.

#### الميزات — the catalog

47 features, and the catalog answers six things about each: its type, its default, where the code
enforces it, what it depends on, who has it now, and whether it is switched on.

The number that matters here is **enforced vs declared**:

- **مطبَّقة بكود** — there is code that enforces this. Selling it changes behaviour.
- **معلنة فقط** — it is in the catalog and nothing enforces it yet. Selling it changes *nothing*.

The distinction is drawn on every row and counted in the header, because shipping flags that
silently do nothing is how a licensing system loses credibility internally. The «مُباعة بلا كود»
signal on التراخيص is the same fact from the other end: a plan that promises something no code
delivers.

**Dependencies subtract, they never add.** A feature whose requirement is off does not work, even
if an override grants it — and the detail panel says what falls with it before you switch anything
off.

**Feature status** is the fifth control on this screen and the most dangerous:

| Status | Meaning |
|---|---|
| `active` | Normal. Listable in plans. |
| `hidden` | Not offered in new plans; keeps working for everyone who already has it. |
| `deprecated` | Marked for removal; works, but should not go into new plans. |
| `disabled` | **The platform kill switch.** Overrides every plan and every exception; the feature returns to its default for every office instantly. |

`disabled` is the only one that confirms, and it confirms with the count of plans and overrides it
is about to overrule.

---

### 2.3 التراخيص — the customer

**The job:** what does this office get, what are they using, what did we agree, and why do they
have it.

The directory is a grid of office cards carrying the commercial facts — plan, status, price, period
end, exception count, over-limit count, marketplace block — so most questions are answered without
opening anything. Above it sits the **signals strip**.

#### The signals strip

Six possible signals, and **only the ones with rows are drawn**. An empty signal is good news and
takes no space; a platform with nothing to chase shows one green sentence instead of six cards
saying «لا يوجد». Each signal is a count that expands into *every* office it means — never "and 8
others", because the long one is precisely the one the screen was opened for.

| Signal | Why it matters |
|---|---|
| متأخرة أو موقوفة | Money, or a deliberate hold. |
| تجاوزت حدًّا | A real state, not a fault — see Part 1. |
| مكاتب بلا ترخيص | Created but never priced. The handoff from مكاتب المنصة. |
| تجارب تنتهي قريبًا | The sales queue. |
| استثناءات تنتهي قريبًا | A negotiated exception about to lapse. |
| مُباعة بلا كود | A plan promising a feature nothing enforces. |

#### The office workspace

Opening an office gives the full page. Identity, licence status, plan, hold state, **and every
action** stay pinned at the top — assign/change plan, extend trial, suspend/resume, issue invoice.
None of them hides behind a `⋯`.

Four tabs beneath:

| Tab | Answers |
|---|---|
| **الميزات والحدود** | The whole catalog for this office: a switch per feature, an editable number per limit, and the rung that produced each current value. This is the tab an office opens on. |
| **الاستخدام** | Every metered limit, consumption against it, stock vs flow. |
| **الاستثناءات** | The record of this office's negotiated exceptions — direction, reason, expiry, including lapsed ones. |
| **الفوترة والنشاط** | This office's invoices, and its slice of the audit trail. |

#### The feature board

> **افتح المكتب، شغّل الميزة، اضبط الحد، اكتب السبب مرة واحدة.**

Changing one thing for one office used to be: التراخيص → find the office → open it →
«الاستثناءات» → «استثناء» → find the feature in a dropdown of forty-seven → set a value → type a
reason → save. Twice, for two things. Nothing on that path ever showed *what this office currently
has*, which is the question the screen is opened with.

The board answers that first and makes the change a control:

- **A switch per boolean, a number field with its own unit per limit, a dropdown per level.** Live
  consumption sits beside each limit («مستخدَم ٥٢ من ٤٠ — تجاوز ١٢»), so a ceiling is raised against
  the number that made someone ask.
- **Every row names its rung** — الباقة / استثناء / الافتراضي / حالة الترخيص / مفتاح إيقاف المنصة —
  and «إرجاع لقيمة الباقة» removes an exception from the row it applies to.
- **It is a draft.** Controls write to an edit buffer; nothing reaches the server until «تطبيق».
  The save bar counts *decisions*, not gestures — a switch flipped and flipped back is not a change
  — states each one in words («عدد السائقين: من ٤٠ إلى ٦٠»), and takes **one reason for the whole
  batch**. Leaving the office with a dirty buffer asks first.
- **It refuses rather than pretends.** A feature disabled platform-wide, or one held down by the
  licence's own status, renders disabled and says which rung is holding it — a switch that silently
  snaps back is worse than one that will not move. A `declared` feature carries «غير مفعّلة بعد»,
  so nobody sells a switch that does nothing yet.

Each row is still one audited `platform_set_override` / `platform_clear_override` call: the
batching is in the console, never in the record.

Reached from «مكاتب المنصة» too — an office card and its details panel both carry
«الميزات والحدود», which switches module and opens that office on this tab.

#### Exceptions, not bespoke plans

> **لا تُنشأ باقة جديدة لكل تفاوض — يُنشأ صف.**

Every commercial concession is an override row on the office, not a new plan. A plan per customer
is how a catalog becomes unmaintainable. An override carries a mandatory reason (the server
requires it), an optional expiry, and its direction — ▲ upgrade or ▼ restriction — read from the
plan value rather than assumed.

#### Suspension degrades, it does not black out

A suspended office becomes **read-only**, and specifically:

| Stops | Continues |
|---|---|
| Creating trips, drivers, routes, operators | Tickets already sold |
| Editing configuration | Trips already running |
| Appearing in the client marketplace | Captains signing in and driving |

The in-flight exemption is computed server-side, not trusted from the client. `max_live_trips`
stays unlimited on the `restricted` plan **on purpose** — a suspension must never strand a bus
mid-route with passengers on it.

#### Reasons: only where the server demands one

A modal asking for an eight-character reason before every action was the single biggest source of
friction in the first version of this console. The server is the authority on which actions need
one, and only those still ask:

| Action | Reason required |
|---|---|
| `platform_set_license_status` (suspend / cancel) | ✅ |
| `platform_extend_trial` | ✅ |
| `platform_set_override` / `platform_clear_override` | ✅ |
| `platform_save_plan` | ❌ — optional inline note |
| Plan status change | ❌ — confirms with the consequence |
| Assign plan, issue invoice | ❌ |

Where a reason *is* required, one-tap suggestion chips carry the three or four true answers. The
reason still has to be true; retyping the true one every time buys nothing.

---

### 2.4 الفوترة والسجل — the record

Two sections, one destination, because both are append-only records of what already happened,
consulted when a question comes up rather than worked in daily. They also answer each other: *"why
was this office invoiced at this figure"* is a billing question whose answer — the plan assignment,
the override, the cycle change — is an audit row.

#### الفواتير

Four figures on a line: **MRR** (from active licences only), paid, issued-and-unpaid, overdue. Then
upcoming renewals, then the invoice ledger.

Two actions per invoice:

- **تسجيل سداد** — records payment as it actually arrived (transfer, cash, wallet, cheque) and
  lifts any restriction the lateness caused.
- **إبطال** — takes the invoice out of the accounts and leaves a trace. **A paid invoice is never
  voided**: reversing collected money is a refund, not an edit.

**تشغيل دورة التجديد** issues renewal invoices on demand rather than waiting for the schedule —
far more useful than waiting a night while investigating one customer.

#### سجل التغييرات

A **day-grouped trail**, not a grid. The grid it replaced spent five of its seven columns on
machine references (`max_captains`, `true`, a bare uuid) and dashes, printed a date but never a
time, and never showed the one thing an audit row exists for — the value before and after.

Every row now reads as a sentence — *who did what to whom, when, and why* — with the evidence
opening in place. Filters (entity family, period) are **server-side**, which is also how the
operator reaches past the 100-row read cap; the footer says so out loud rather than implying that
100 rows is all there ever was.

---

## Part 3 — The lifecycle of a customer

```
1.  إنشاء المكتب              مكاتب المنصة → «مكتب جديد»
       office row + first admin account, one transaction
       password revealed once
       ↓
2.  تعيين باقة                التراخيص → open the office → «تعيين باقة»
       trial starts if the plan carries trial days
       ↓
3.  النشر في السوق            مكاتب المنصة → publish
       requires a description and service areas
       ↓
4.  التشغيل                   the office runs itself; the platform meters it
       stock limits self-heal; flow limits accumulate monthly
       ↓
5a. تفاوض                     التراخيص → open the office → «الميزات والحدود»
       flip the switches, set the numbers, one reason for the batch —
       one override row per change, never a bespoke plan
       ↓
5b. الفوترة                   الفوترة → «تشغيل دورة التجديد», then «تسجيل سداد»
       ↓
6.  التأخر                    signals strip → «متأخرة أو موقوفة»
       ↓
7a. إيقاف مؤقت                read-only; sold tickets and running trips continue
7b. استئناف                   both require a reason; both land in the trail
```

**تشغيل دورة الحياة** on the التراخيص header runs the nightly job on demand: it suspends what is
due for suspension, downgrades what is due for downgrade, and warns what is due a warning, then
reports exactly how many of each.

---

## Part 4 — What the console will not do

Stated so nobody goes looking:

| Not here | Where instead |
|---|---|
| Collect money | Nowhere. There is no gateway; payment is recorded by hand. |
| Delete an office | Nowhere. Suspend or withdraw from the marketplace. |
| Delete a plan | Archive it. Subscribed offices keep it. |
| Refund a platform invoice | Nowhere. Voiding a paid invoice is refused by design. |
| Change an office's own operational data | The office's own dashboard, under its own login. |
| Read back an admin password | Nowhere. It is revealed once, at creation. |
| Edit or remove an audit row | Nowhere. Append-only, enforced by trigger. |

---

## Part 5 — Reading the vocabulary

The console uses a small, fixed set of visual statements. They mean the same thing everywhere.

| Element | Statement |
|---|---|
| **Stat strip** (numbers on a line) | Context for the section you are in. Never a control. |
| **Fact** (bordered pill) | Data — «٣ مكاتب», «تجربة ١٤ يوم». Not clickable, deliberately not a chip. |
| **Chip** | A control. If it looks like a chip, it filters or selects. |
| **Signal tile** | A count that has something to say. Press it to see exactly who. |
| **Notice** (tinted sentence) | The one thing on this panel you must not skim past. |
| **Source chip** | Which rung of the ladder produced this value. |
| **Save bar** (floating) | You have unsaved changes, and here is who they will reach. |
| **Coloured card stripe** | Status at a glance: active / draft / archived, or licence state. |

And three rules the layout keeps:

1. **A number belongs on a line, not in a tile.** Four bordered boxes for four figures nobody
   drills into is a header that eats a third of the console.
2. **A control names itself.** No filter is a bare chip whose axis you must infer from whichever
   value happens to be selected.
3. **An action is visible.** Nothing important hides behind `⋯`. «تعيين باقة» is the most common
   operation on التراخيص and it used to be two clicks deep in an overflow menu.

---

## Part 6 — The 2026-08-14 consolidation

The console shipped as **seven sidebar rows**. Each was a section of a job rather than a job, so
answering one question meant touring several of them. The rebuild before this one had already cut
the chrome *inside* each screen; what remained was structural.

| Before (7) | After (4) | Why |
|---|---|---|
| مكاتب المنصة | **مكاتب المنصة** | Unchanged destination. Onboarding moved into a dialog behind «مكتب جديد» — it was standing chrome for an action taken a handful of times a year. |
| الخطط والباقات<br>كتالوج الميزات | **الباقات والميزات** | A plan is a set of feature values. Pricing one without reading the other is not a thing anyone does. |
| التراخيص<br>الاستخدام | **التراخيص** | الاستخدام drew the same meters the licence detail already drew, one office per panel. It is now a tab of the office it describes; "who is over a limit" is answered better by the signal that names them. |
| الفوترة<br>سجل التغييرات | **الفوترة والسجل** | Both append-only records of what already happened; neither a daily destination. |

**Three further changes inside the screens:**

- **التراخيص moved from master/detail to directory → full-width workspace.** The office used to
  open into a pane worth three fifths of the window holding six stacked, individually-folding
  panels; reaching the invoices meant scrolling past everything above them in a column too narrow
  for any of it. It is now four tabs across the full page. This is the same shape الباقات uses, and
  the console now has one rule: **browse in a grid, work full width; split panes are for reading,
  not editing.**
- **The section switch lives in the page header**, in the same place on every section of a
  destination — so moving between الباقات and الميزات is one press where the eye already is. It
  disappears while a plan workspace is open: a page-level tab strip above a workspace with its own
  tabs is two navigations competing for one glance.
- **Six `platform.licenses.*` collapsible sections were deleted.** A tab that also folds is a
  control that hides a control.

**What did not change:** no RPC, no migration, no entitlement rule, no permission. This was a
presentation-layer consolidation; the data layer, the cubit and the domain were untouched.

---

## Part 7 — Where the code is

```
lib/apps/dashboard/features/
├── platform_admin/                      مكاتب المنصة
│   └── presentation/
│       ├── screens/platform_offices_screen.dart
│       └── widgets/office_onboarding_dialog.dart      creation, in a dialog
└── platform_licensing/                  the other three destinations
    ├── domain/                          entities, repos, 26 use cases
    ├── data/                            one Supabase datasource over the platform_* RPCs
    └── presentation/
        ├── cubit/                       ONE cubit drives all three — the sections read
        │                                each other constantly, and seven cubits would mean
        │                                seven copies of the catalog per navigation
        ├── screens/
        │   ├── platform_catalog_screen.dart      الباقات + الميزات
        │   ├── platform_licenses_screen.dart     التراخيص  (directory + office workspace)
        │   └── platform_billing_screen.dart      الفوترة + السجل
        ├── sections/
        │   ├── plans_section.dart                gallery → plan workspace
        │   ├── features_section.dart             catalog master/detail
        │   ├── usage_section.dart                one office's meters
        │   ├── invoices_section.dart             the ledger
        │   └── audit_section.dart                the day-grouped trail
        └── widgets/
            ├── licensing_layout.dart             the shared layout vocabulary
            ├── office_feature_board.dart         «الميزات والحدود» — the per-office
            │                                     switchboard, its edit buffer's reduction
            │                                     to real changes, and its save bar
            └── licensing_scaffold.dart           an action error never replaces the screen
```

**One frame rule, enforced by `LicensingScreenFrame`:** a failed *load* shows the error view; a
failed *action* shows a snackbar over whatever the operator was editing, so the form they mistyped
is still there.

**Tests:** `test/apps/dashboard/features/platform_licensing/` and
`test/apps/dashboard/features/platform_admin/`. The four-window size matrix on each screen is the
real assertion — an overflowing `Row`/`Column` throws during paint in debug, so a null exception is
a genuine pass.

---

### See also

- [../architecture/PLATFORM_LICENSING.md](../architecture/PLATFORM_LICENSING.md) — the enforcement
  design: gates, triggers, refusal codes, the regression suite. The authority on *how*.
- [DASHBOARD_FEATURES.md](DASHBOARD_FEATURES.md) — the tenant-facing modules.
- [DASHBOARD_USER_FLOWS.md](DASHBOARD_USER_FLOWS.md) — operator journeys for those modules.
