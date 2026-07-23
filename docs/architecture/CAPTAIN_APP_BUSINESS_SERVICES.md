# Captain Platform — Business Services

> The Captain App is currently one app for one job: help a driver run a trip. The data it
> produces — every position, transition, incident, manifest and timestamp — is the raw
> material for services EWT could **sell**, not just operate.
>
> This document takes that view deliberately. It asks what the platform is already close to
> being able to offer, and what each of those would take.
>
> **Companions.** [`CAPTAIN_APP_RECOMMENDATIONS.md`](CAPTAIN_APP_RECOMMENDATIONS.md)
> (product roadmap) · [`CAPTAIN_APP_STATUS.md`](CAPTAIN_APP_STATUS.md) (what exists).
>
> **Last revised.** 2026-07-23. Readiness is assessed against what is actually built and
> verified today, not what is planned.

---

## Readiness legend

| Mark | Meaning |
| --- | --- |
| 🟢 **Ready** | The data and the flows exist. This is packaging and a surface. |
| 🟡 **Close** | The data exists; a surface or one capability is missing. |
| 🟠 **Foundational** | Real gaps, but nothing architectural blocks it. |
| 🔴 **Distant** | Needs a new capability or a business model decision first. |

---

## The asset

Before the services, what the platform actually holds:

| Asset | Where it comes from | Fidelity today |
| --- | --- | --- |
| Vehicle position over time | `trip_live_locations`, 30 s cadence | **Foreground only** — the honest caveat on every service below |
| Trip lifecycle with timestamps | `operation_trips` + `trip_events` | Complete and server-validated |
| Stop-by-stop arrivals | `trip_events` canonical markers | Complete; shared convention across all three apps |
| Passenger manifest & boarding | `trip_passengers` | Complete |
| Incidents & SOS | `driver_trip_reports` | Captured; **nothing reads it yet** |
| Driver ↔ operations messages | `captain_messages` | Complete, office-scoped |
| Driver & vehicle ratings | `trip_reviews` | Complete |
| Multi-office isolation | Office-scoped RLS throughout | Complete and verified |

**The single constraint that limits every service here** is foreground-only location. A
service sold on continuous vehicle telemetry cannot be honestly sold until that is closed
(R3). It is called out per-service rather than repeated as a caveat.

---

# 1. Live fleet monitoring 🟡 Close

**Service.** An operations control view: every active trip on a map, with position, stage,
boarded count and delay against schedule.

**Target customer.** The office operations team; larger fleets running several vehicles at
once.

**Business value.** Turns dispatch from a phone-call activity into a screen. It is also
the surface every other operational service hangs off, so it compounds.

**Required.** Position ✅ · lifecycle ✅ · manifest ✅ · **a Dashboard map surface** ❌ ·
continuous telemetry ⚠️ (R3).

**Readiness.** The client app already consumes exactly this data for its own tracking
screen, so the hard part — delivery — is proven. What is missing is an operations-shaped
view of it.

**Next steps.** Build the fleet view against the existing live-location stream; close R3
so the map does not go dark; close R1 so fleet positions are not public.

---

# 2. Incident & safety management 🟠 Foundational

**Service.** Structured capture, triage and resolution of everything that goes wrong on a
trip — breakdowns, disputes, emergencies — with an audit trail.

**Target customer.** Operations and compliance; any corporate client who asks "what is
your incident process?"

**Business value.** This is frequently a **procurement requirement** rather than a
nice-to-have. Corporate and school contracts ask for it directly, and having no answer
loses the tender.

**Required.** Capture ✅ · RLS ✅ (closed in this audit) · **operations inbox** ❌ ·
**escalation & paging** ❌ · media attachments ❌.

**Readiness.** Capture works and is now properly scoped. The gap is that a filed report
lands in a table nobody reads (R2) — so today the service exists on the captain's side
only.

**Next steps.** R2 (inbox), then R4 (escalation). Both are modest, and together they turn
a form into a service.

---

# 3. Driver performance & SLA monitoring 🟡 Close

**Service.** Per-captain on-time performance, completion rate, incident frequency and
passenger ratings — as an operations report and as a captain-facing view.

**Target customer.** Fleet managers; corporate clients buying against an SLA.

**Business value.** Two markets at once: an internal quality signal and the basis of an
incentive scheme, and an **externally reportable SLA** that makes contracts enforceable.

**Required.** Scheduled vs actual timestamps ✅ · arrivals ✅ · ratings ✅ ·
**aggregation and reporting** ❌.

**Readiness.** The measurements are all being recorded already. This is largely a query
and a surface — one of the better value-per-effort services on this list.

**Next steps.** R6, in both directions (captain view and operations report).

---

# 4. Route analytics 🟠 Foundational

**Service.** Which routes run late and where; where dwell time concentrates; which stops
are consistently missed or empty.

**Target customer.** Operations planning; the commercial team pricing routes.

**Business value.** Better schedules from evidence rather than habit, and a factual basis
for pricing and retiring routes.

**Required.** Position history ✅ · arrival markers ✅ · **retention policy** ❌ ·
**analytics pipeline** ❌ · continuous telemetry ⚠️ (R3).

**Readiness.** The events are captured. Two things stand in the way: gaps from
foreground-only tracking would bias any dwell-time analysis, and nobody has decided how
long position history is kept.

**Next steps.** Decide retention, close R3, then build the pipeline. Retention is a
decision, not a task — make it before the table grows.

---

# 5. Corporate & contract transportation 🟠 Foundational

**Service.** Managed transport for a company, school or factory: fixed routes, a known
passenger roster, guaranteed vehicles, reporting against a contract.

**Target customer.** Employers, schools, industrial sites.

**Business value.** The highest-value segment available to the platform — recurring,
contracted revenue with predictable utilisation, rather than seat-by-seat sales.

**Required.** Multi-office ✅ · manifests ✅ · tracking ✅ · **contract/roster model** ❌ ·
**client-facing SLA reporting** ❌ · incident process ❌ (service 2) · continuous
telemetry ⚠️.

**Readiness.** The operational spine genuinely exists — this is what the Captain App
already does. What is missing is the commercial layer above it: contracts, rosters and
the reporting a corporate buyer expects.

**Next steps.** Services 2 and 3 first — they are what a corporate buyer asks for during
procurement — then the contract model.

---

# 6. Operations control centre 🔴 Distant

**Service.** A staffed real-time control room: live fleet, exception alerts, direct
captain contact, incident triage, intervention.

**Target customer.** Internal operations at scale; sold as managed operations to a fleet
owner who does not want to run their own.

**Business value.** Moves EWT from software to an operated service, which is a different
and stickier business.

**Required.** Services 1, 2 and 3 · alerting ✅ (the event engine exists) · chat ✅ ·
**staffing and process** ❌.

**Readiness.** Every component is either built or on this list, but the service is mostly
an **operational** undertaking rather than an engineering one. It is distant because it
needs people and process, not because the platform cannot support it.

---

# 7. Driver management & compliance 🟡 Close

**Service.** The captain lifecycle: onboarding, approval, document validity, activity
history, deactivation.

**Target customer.** Fleet HR and compliance.

**Business value.** Avoids the expensive failure mode — a driver at a checkpoint with
lapsed papers, which costs a cancelled trip, a stranded busload and a fine.

**Required.** Self-service onboarding ✅ · dashboard approval ✅ · office scoping ✅ ·
document storage ✅ · **expiry tracking and reminders** ❌.

**Readiness.** The lifecycle works end to end today. **The expiry dates are already on the
profile** — nothing reads them and warns. This is the cheapest item in this document.

**Next steps.** R7.

---

# 8. Passenger experience services 🟢 Ready

**Service.** What the passenger already gets from captain-produced data: live tracking,
accurate arrival information, and a channel to the vehicle.

**Target customer.** Retail passengers; a differentiator against informal operators.

**Business value.** The most visible reason to book through EWT rather than turn up at a
depot. It is also the service most damaged by the foreground-only gap — a map that stops
moving is worse than no map.

**Required.** Position ✅ · realtime delivery ✅ (verified) · broadcast messaging ✅ ·
continuous telemetry ⚠️ (R3).

**Readiness.** Live and working. R3 is what takes it from good to dependable.

---

## Summary

| # | Service | Readiness | Blocking item | Value |
| --- | --- | --- | --- | --- |
| 8 | Passenger experience | 🟢 Ready | R3 for reliability | High — visible differentiator |
| 1 | Live fleet monitoring | 🟡 Close | Dashboard surface, R3 | High — compounds |
| 3 | Driver performance / SLA | 🟡 Close | Aggregation + reporting | High — best effort ratio |
| 7 | Driver management | 🟡 Close | R7 expiry reminders | Medium — cheapest win |
| 2 | Incident & safety | 🟠 Foundational | R2, R4 | High — procurement gate |
| 4 | Route analytics | 🟠 Foundational | Retention decision, R3 | Medium |
| 5 | Corporate contracts | 🟠 Foundational | Contract model, services 2–3 | **Highest revenue** |
| 6 | Operations control centre | 🔴 Distant | Staffing and process | Strategic |

### The through-line

Three items unlock most of this list, and they are already on the roadmap for other
reasons:

1. **R3 background location** — gates services 1, 4 and 8's reliability.
2. **R2 incident inbox** — gates service 2, which gates corporate procurement (5).
3. **R6 performance aggregation** — is service 3, and is most of what a corporate SLA
   report needs.

The corporate segment (5) is the largest prize, and the honest read is that it is gated
less by engineering than by two small services — incidents and performance reporting —
that a buyer will ask about before they ask about anything else.
