# العملاء — Overview

The console's customer module. It replaces the assembly job that
`DASHBOARD_CUSTOMERS.md` described as *"the single biggest usability gap in the
console"*.

---

## 1. The problem it removes

Before this module a passenger existed in five places and was assembled by the
operator's memory. A caller saying *"I paid twice for the trip to Alexandria last
Thursday and nobody refunded me"* cost a support agent five modules, four
searches by two different keys, and no record that the call happened.

Each of those five surfaces is a list of **events**, filtered by its own module's
concerns. None was a list of **people**.

العملاء is the list of people.

---

## 2. What it answers

The module exists to answer ten questions quickly. Each maps to something on
screen, and each is backed by a real column:

| Question | Where |
|---|---|
| Who is this customer? | Profile header — name, phone, email, short id, account status |
| Is the customer active? | ملخص العميل chip, and the النشاط filter in the directory |
| Do they have a live subscription? | Directory الاشتراك column, نظرة عامة panel, الاشتراكات tab |
| Do they have an upcoming trip? | Directory الرحلة القادمة column, chip, الرحلات → القادمة |
| What trips have they taken? | الرحلات → السابقة |
| How often do they use the service? | نظرة عامة → سلوك السفر and المسارات الأكثر استخداماً |
| What have they paid? | نظرة عامة → إجمالي المدفوعات, المدفوعات tab |
| Is there wallet activity? | المدفوعات → wallet position and حركة المحفظة |
| Do they cancel or miss trips? | سلوك السفر, and the cancellation/no-show chips |
| What is their relationship with my office? | The chips, taken together |

---

## 3. Shape

```
العملاء  (sidebar → المبيعات)
│
├── directory                        browse: KPIs · search · 4 filters · sort · paged table
│     ▼ open a customer
└── Customer 360 workspace           work: full width
      ├── header      identity · quick actions · ملخص العميل chips
      └── tabs        نظرة عامة · الرحلات · الاشتراكات · المدفوعات · النشاط
```

The split follows the console's standing rule — *browse in a grid, work full
width; split panes are for reading, not editing* (`PLATFORM_CONSOLE.md` Part 6).
A Customer 360 with five tabs crammed into three fifths of a window would need
its own horizontal scroll in every tab.

---

## 4. It is a read surface

Nothing in this module writes. The repository interface exposes no mutation and
the migration contains no `INSERT`, `UPDATE` or `DELETE`.

That is deliberate, not unfinished. Approving a payment, adjusting a wallet and
deciding a refund already have audited homes in الحجوزات and محفظة العملاء, each
with its own guards, capability checks and audit trail. A second write path into
the same rows would be a second set of preconditions to keep in step — and the
first time they drifted, the money would be wrong.

The quick actions in the header therefore jump to a tab of the same page. They
never navigate away and never change state.

---

## 5. Honesty rules this module follows

- **No invented metric.** Every figure is a count or a sum over a real column.
- **No trend without a comparable period.** None of the five KPIs has a stored
  prior period, so none carries a "+12%".
- **No score, no prediction, no churn probability.** The ملخص العميل chips are
  deterministic sentences; each names the number driving it.
- **Null is not zero.** "No wallet has been opened" and "the balance is 0" are
  different statements and render differently.
- **A share needs a denominator worth having.** A cancellation rate is withheld
  below four bookings — one of two is 50%, and printing that beside a customer
  who has travelled twice is slander dressed as a statistic.
- **A window says it is a window.** The activity feed carries a cap notice when
  it comes back full.

---

## 6. Where the code is

```
lib/apps/dashboard/features/customers/
├── customers_di.dart
├── data/         datasources (7 RPCs) · models (document→entity) · repository impl
├── domain/       entities · repository interface · 7 use cases
└── presentation/ 2 cubits · 1 screen · 13 widgets

supabase/migrations/20260820150000_office_customers_module.sql
test/apps/dashboard/features/customers/            5 files, 109 assertions
docs/dashboard/customers/                          this folder
```

See `CLIENTS_ARCHITECTURE.md` for the layering, `CLIENTS_DATA_MODEL.md` for
where every field comes from, `CLIENTS_FEATURES.md` for the surface inventory,
`CLIENTS_UX.md` for the interface decisions and `CLIENTS_KNOWN_ISSUES.md` for
what is still missing.
