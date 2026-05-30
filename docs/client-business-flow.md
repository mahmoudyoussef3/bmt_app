# Client App — Business Flow & Core Business Details

**Purpose:** This document captures the customer-facing business flows, primary actors, entities, high-level rules, and key metrics for the client (rider) mobile/web app. It deliberately focuses on the business (what happens, when, and why) rather than implementation or code-level logic.

**Scope:** Home, search & discovery, booking & seat selection, payment, subscriptions, live tracking, cancellations/refunds, support, notifications, and interactions that affect revenue/KPIs.

**Actors**
- **Customer (Rider):** Purchases rides, manages bookings/subscriptions, tracks vehicles, and receives notifications.
- **Driver (Captain):** Operates vehicles; receives assignments and provides trip status (summary only; operational actor).
- **Platform / Operator:** Owns fleet, pricing rules, schedules, refunds, and reporting.
- **Payment Provider:** External service handling payments and settlements.

**Core Business Entities**
- **Trip (Service Instance):** A scheduled transit run with route, vehicle, capacity, departure time, and status (scheduled, boarding, in-transit, completed, cancelled).
- **Booking:** Reservation by a customer for a Trip (one or more seats). Includes booking status, fare paid, passenger details, and seat assignment.
- **Seat:** Assignable resource tied to a vehicle for a Trip; has states (available, held, booked, blocked).
- **Subscription / Pass:** Time-bound or usage-based product offering recurring access or discounts (monthly pass, 10-ride bundle).
- **Fare / Price:** Computed cost for a booking; may include base fare, surcharges, taxes, discounts, promo codes, and loyalty credits.
- **Payment Record:** Transaction record (success, pending, failed), payout schedule to operator/driver, refunds.
- **Notification / Alert:** Customer-facing messages (booking confirm, reminder, vehicle ETA, disruptions).

**High-level Flows**

**1. Onboarding & Account Management**
- **Trigger:** New user opens app or returns user updates profile.
- **Business outcomes:** Create/verify account, collect contact & payment methods, optionally capture preferences (e.g., language, accessibility).
- **Rules:** Phone/email verification required for bookings; stored payment methods used for quick checkout.

**2. Discovery: Search & Route Selection**
- **Trigger:** Customer enters origin/destination or selects a published route.
- **Steps:** Present available Trips (times, seats available, fare), highlight subscription-eligible options and promotions.
- **Business decisions:** Show operator-defined schedules and dynamic availability; present upsell (upgrade, add-ons) when relevant.
- **Outcome:** Customer selects a Trip instance and proceeds to booking.

**3. Booking Flow (Reserve & Pay)**
- **Trigger:** Customer selects Trip and seats.
- **Steps:** Validate seat availability, present total fare (taxes, fees, promos), show cancellation policy and ETA, capture payment.
- **States:** Quote → Hold (optional short hold) → Confirmed (payment success) → Ticket issued.
- **Rules & Constraints:**
  - Seat hold timeout (e.g., 5 minutes) before being released.
  - Partial bookings allowed only if seats remain.
  - Subscription holders may bypass payment or pay reduced fare depending on rule.
  - Cancellation/partial-refund windows depend on operator rules.
- **Outcomes:** Booking confirmation, ticket delivered (QR/code), revenue recorded.

**4. Seat Selection & Assignment**
- **Trigger:** During booking (optional step) or at check-in.
- **Business notes:** Certain seats can be blocked (maintenance, accessibility), premium seats may carry a surcharge. Seat map reflects real-time availability.

**5. Payment, Invoicing & Settlement**
- **Trigger:** At booking confirmation (or subscription billing cycle).
- **Business flow:** Collect payment → Issue receipt → Hold settlement for operator/driver according to payout schedule.
- **Failure handling:** On payment failure present retry/alternate method; do not confirm booking until payment succeeds unless operator allows pay-later workflows.
- **Refunds:** Follow cancellation rules; refunds may be full, partial, or none depending on policy.

**6. Ticketing, Check-in & Boarding**
- **Trigger:** After booking confirmation and near departure time.
- **Business elements:** Send reminders, allow customer to show ticket (QR/code), mark as boarded if scanning/check-in exists.
- **No-shows:** Operator rules determine whether no-shows are forfeited or partially refunded.

**7. Live Tracking & In-Trip Updates**
- **Trigger:** Trip transitions to boarding/in-transit.
- **Business outcomes:** Provide ETA, vehicle progress, delay alerts; enable simple support contact for critical issues.
- **Impacts:** Tracking increases perceived reliability and reduces support load; delays may trigger automatic communications and compensation rules.

**8. Cancellations, Changes & Refunds**
- **Trigger:** Customer or operator cancels, or trip disrupted.
- **Business rules:** Define cutoff windows for free cancellation, partial refunds for late cancellations, and operator-initiated cancellation policies (full refunds, rebooking options).
- **Customer-facing options:** Rebook to next available Trip, request refund, or apply credit to account.

**9. Subscriptions & Loyalty**
- **Offer types:** Time-limited passes (monthly), bundle credits (N rides), or loyalty discount tiers.
- **Business rules:** Subscription eligibility, blackout periods, transferability, stacking with promos, auto-renewal and billing cadence, expiry handling.
- **Monetization:** Subscriptions may be discounted relative to ad-hoc fares, provide predictable revenue and retention.

**10. Promotions, Discounts & Promo Codes**
- **Trigger:** Marketing campaigns, referral programs, first-ride incentives.
- **Rules:** Promo eligibility, expiration, max redemptions per user, cannot be stacked with certain subscription discounts unless specified.

**11. Support & Dispute Resolution**
- **Trigger:** Payment issues, lost items, missed trips, delays, refunds.
- **Business flow:** Capture issue → Triage (automated vs manual) → Apply business resolution (refund, credit, rebooking) → Close ticket.
- **SLAs:** Response & resolution SLAs defined by operator business policy.

**12. Reporting, KPIs & Revenue Recognition**
- **Primary KPIs:** Bookings per day, active riders, revenue (gross & net), occupancy rate, cancellations rate, on-time performance, ARPU (average revenue per user).
- **Reporting cadence:** Daily operational dashboard, weekly trends, monthly financials for settlements.

**Business Rules & Constraints (Common)**
- **Capacity Enforcement:** Do not oversell seats beyond vehicle capacity.
- **Cancellation Windows:** Different cancellation window tiers (free, partial-refund, no-refund).
- **Pricing Rules:** Base fare + operator-configured surcharges (peak, fuel), promo discounts, taxes.
- **Subscription Priority:** When enabled, subscription holders may get priority booking or pre-allocated seats per configuration.
- **Payment Guarantee:** Booking is confirmed only on successful payment unless explicitly allowed.

**Data & Events Captured (for business insights)**
- **Booking events:** create, confirm, modify, cancel, refund.
- **Trip events:** publish, depart, arrive, cancel, delay.
- **User events:** onboarding, payment method added, subscription purchased/renewed.
- **Financial events:** payment success/failure, refund issued, payout to operator.

**Edge Cases & Operator Decisions**
- **Operator-initiated cancellations:** Offer full refunds and priority rebooking.
- **Partial fill routes:** Trips below minimum occupancy may be merged or cancelled per operator policy.
- **Late departures:** Compensation rules or credits may apply.

**Quick Reference: Typical Customer Journey (summary)**
1. Open app → search route/time.
2. Select Trip → choose seats (optional) → review fare and policies.
3. Pay (or apply subscription) → receive booking confirmation and ticket.
4. Receive reminders → check-in/board → track vehicle live during trip.
5. After trip, rate/feedback and receipts available.

---

If you want, I can:
- Expand this into separate, linked docs per flow (Booking, Payments, Subscriptions).
- Add sample business rules (cancellation windows, hold durations, pricing tiers) tuned to your operator's policy.

