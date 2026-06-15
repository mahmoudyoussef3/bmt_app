# State Machines

System entities follow strict state machines enforced by the Domain layer and Backend RPCs.

---

## 1. Driver State Machine

States: `available`, `assigned`, `on_trip`, `suspended`, `license_expired`

| Current State | Trigger Event | Next State | Conditions / Rules |
|---------------|---------------|------------|---------------------|
| `available` | Vehicle Assigned | `assigned` | Must have valid license |
| `assigned` | Trip Started | `on_trip` | Must be within Trip Time |
| `on_trip` | Trip Completed | `assigned` | Driver still has the vehicle |
| `assigned` | Assignment Ended| `available` | - |
| *Any* | License Expires | `license_expired`| Daily CRON job checks dates |
| *Any* | Admin Suspends | `suspended` | Immediate revocation of access |

---

## 2. Vehicle State Machine

States: `available`, `assigned`, `in_maintenance`, `on_trip`, `inactive`

| Current State | Trigger Event | Next State | Conditions / Rules |
|---------------|---------------|------------|---------------------|
| `available` | Driver Assigned | `assigned` | - |
| `assigned` | Trip Started | `on_trip` | - |
| `on_trip` | Trip Completed | `assigned` | - |
| `assigned` | Admin Reports Issue| `in_maintenance`| Cancels upcoming trips for vehicle |
| `in_maintenance`| Maintenance Fixed| `available` | Unassigned from driver |

---

## 3. Trip State Machine

States: `scheduled`, `boarding`, `in_progress`, `completed`, `cancelled`

| Current State | Trigger Event | Next State | Conditions / Rules |
|---------------|---------------|------------|---------------------|
| `scheduled` | Driver taps "Start Boarding"| `boarding` | Must be <30 mins from departure |
| `boarding` | Driver taps "Start Moving" | `in_progress`| Stops new bookings |
| `in_progress` | Driver taps "End Trip" | `completed` | Must be near final destination |
| `scheduled` | Admin Cancels | `cancelled` | Triggers auto-refunds |

---

## 4. Booking State Machine

States: `pending`, `confirmed`, `cancelled`, `refunded`

| Current State | Trigger Event | Next State | Conditions / Rules |
|---------------|---------------|------------|---------------------|
| `pending` | Payment Success | `confirmed` | Generates QR code |
| `pending` | Payment Timeout | `cancelled` | Frees the seat |
| `confirmed` | User Cancels (<2 hrs)| `cancelled` | No refund policy |
| `confirmed` | User Cancels (>2 hrs)| `refunded` | Wallet refunded |
| `confirmed` | Admin Cancels Trip| `refunded` | Wallet refunded |

---

## 5. Seat State Machine

States: `available`, `reserved`, `paid`, `subscription`, `blocked`

| Current State | Trigger Event | Next State | Conditions / Rules |
|---------------|---------------|------------|---------------------|
| `available` | User clicks Seat | `reserved` | Locked for 5 mins for payment |
| `reserved` | Payment Success | `paid` | Locked permanently |
| `reserved` | Payment Timeout | `available`| Lock expires |
| `available` | Sub. user books | `subscription`| Deducts 1 from package |
| `available` | Admin blocks seat | `blocked` | For broken seats / luggage |
