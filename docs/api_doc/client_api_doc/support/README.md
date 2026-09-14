# Client · Support (tickets)

The Support Center: the rider's tickets, creating a ticket (optionally routed to an office and
linked to a booking/trip, with one attachment), ticket detail and its attachments.

## Overview

| Layer | Files (relative to `lib/apps/client/features/support/`) |
|---|---|
| Screens | `presentation/screens/support_center_screen.dart` (`SupportRoutes.center` = `/support`), `create_support_ticket_screen.dart` (`SupportRoutes.createTicket`), `support_ticket_details_screen.dart` (`SupportRoutes.ticketDetails` = `/ticket_details`, argument `ticketId`) |
| Cubit | `SupportCubit` (`presentation/cubit/support_cubit.dart` — `loadTickets()`, `refreshTickets()`, `loadRelatedBookingOptions()`, `loadOfficeOptions()`, `createTicket(...)`, `openTicketDetails(id)`) |
| Use cases | `domain/usecases/` (`GetMyTicketsUseCase`, `CreateSupportTicketUseCase`, `GetTicketDetailsUseCase`, …) |
| Repo | `data/repositories/support_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_support_datasource.dart` |
| Models | `data/models/support_ticket_model.dart`, `support_attachment_model.dart`, `related_booking_option_model.dart`, `support_office_option_model.dart` (`support_message_model.dart`, `support_refund_request_model.dart`, `support_timeline_event_model.dart` exist but have no datasource — unused) |
| Entities | `domain/entities/support_ticket.dart` (`TicketStatus`, `TicketPriority`), `support_category.dart`, `support_attachment.dart`, `related_booking_option.dart`, `support_office_option.dart` |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| U1 | My tickets | `GET support_tickets?client_id=eq.` | session | `GET /api/v1/me/support/tickets` |
| U2 | Create ticket | `POST support_tickets` | session | `POST /api/v1/me/support/tickets` |
| U3 | Related-booking picker | `GET operation_bookings … limit=10` | session | `GET /api/v1/me/support/booking-options` |
| U4 | Office picker | `GET public_offices?select=id,name` | anon | `GET /api/v1/support/offices` |
| U5 | Ticket detail | `GET support_tickets?id=eq.&client_id=eq.` | session | `GET /api/v1/me/support/tickets/{ticketId}` |
| U6 | Ticket attachments | `GET support_attachments?ticket_id=eq.` | session | `GET /api/v1/support/tickets/{ticketId}/attachments` |
| U7 | Upload attachment | Storage `support-attachments` + `POST support_attachments` | session | `POST /api/v1/support/tickets/{ticketId}/attachments` (multipart) |

All datasource methods throw `Exception('User not authenticated')` without a session.

---

## U1 — My tickets: `getMyTickets()` (`supabase_support_datasource.dart:20`)

```
GET /rest/v1/support_tickets?select=*&client_id=eq.<uid>&order=created_at.desc
```

Row → `SupportTicketModel.fromJson`:

| Field | Column | Notes |
|---|---|---|
| `id`, `ticketNumber`, `category`, `title`, `description` | `id, ticket_number, category, title, description` | required strings |
| `priority` | `priority` | `urgent|high|medium|low` (default low) |
| `status` | `status` | `submitted|under_review (underreview)|contacted|resolved|closed|rejected` (default submitted) |
| `assignedAgentName`, `relatedBookingId`, `relatedTripId`, `internalNote`, `customerContactedAt`, `resolvedAt`, `closedAt` | same names snake_case | nullable |
| `createdAt`, `updatedAt` | required timestamps |

`RLS` (`20260721090200_multi_office_rls.sql:493-506`): `support_tickets_client_read` / `_client_insert` (`client_id = auth.uid()`); offices see tickets routed to them; platform-level tickets (`office_id IS NULL`) are visible only to EWT support.

---

## U2 — Create ticket: `createTicket(...)` (line 35)

```
POST /rest/v1/support_tickets
Prefer: return=representation
{
  "client_id": "<uid>",
  "ticket_number": "#TK-<last 6 digits of epoch ms>",     // generated client-side
  "category": "Booking Issue | Payment Issue | Trip Delay | Driver or Vehicle Issue | Subscription Issue | Lost Item | Other",
  "title": "…", "description": "…",
  "priority": "medium",                                    // always; triage is the support team's job
  "status": "submitted",
  "office_id": "<uuid|null>", "related_booking_id": "<uuid|null>", "related_trip_id": "<uuid|null>"
}
→ 201 [ { …ticket row… } ]   (.single())
```

**`BUSINESS RULE`** — trigger `sync_support_ticket_office()` (`20260726120000_*.sql:36-65`) decides the
real `office_id`, in order: (1) the office of `related_booking_id`, else (2) the office of
`related_trip_id`, else (3) the caller's `office_id` **only if it exists in `public_offices`** (a listed,
active office), else (4) `current_office_id()` (dashboard operators) — which is NULL for a client, so a
forged/unlisted office id is discarded and the ticket becomes platform-level.

After creation the cubit uploads the optional attachment (U7); an attachment failure does not fail the ticket (`attachmentFailed` flag).

**Proposed .NET:** `POST /api/v1/me/support/tickets { category, title, description, officeId?, relatedBookingId?, relatedTripId? }` → `201 Ticket`.
Generate `ticketNumber` server-side (the client-side epoch suffix can collide). Keep the office-routing rule.

---

## U3 — Related bookings for the picker: `getRelatedBookingOptions()` (line 73)

```
GET /rest/v1/operation_bookings?select=id,trip_id,route,trip_date,seat,office_id&client_id=eq.<uid>&order=created_at.desc&limit=10
```

→ `RelatedBookingOption { bookingId=id, tripId, route, tripDate, seat, officeId }`. Picking one also pre-fills the office.

---

## U4 — Offices for the picker: `getOfficeOptions()` (line 88)

```
GET /rest/v1/public_offices?select=id,name&order=name.asc
```

Only listed, active offices — exactly the set the trigger accepts as a routing target.

---

## U5 — Ticket detail: `getTicketDetails(ticketId)` (line 97)

```
GET /rest/v1/support_tickets?select=*&id=eq.<ticketId>&client_id=eq.<uid>     (.single() — 406/error when not found)
```

---

## U6 — Attachments: `getTicketAttachments(ticketId)` (line 108)

```
GET /rest/v1/support_attachments?select=*&ticket_id=eq.<ticketId>&order=created_at.asc
```

→ `SupportAttachment { id, ticketId, messageId?, fileUrl, fileName, fileType, fileSize?, createdAt }`.
`RLS` enabled in `20260730090000_client_trust_hardening.sql:77` (ownership through the ticket).

---

## U7 — Upload attachment: `uploadAttachment({ticketId, file})` (line 120)

```
POST /storage/v1/object/support-attachments/tickets/<ticketId>/<uuidv4>_<originalName>
<file bytes>

→ public URL: <base>/storage/v1/object/public/support-attachments/tickets/<ticketId>/<name>

POST /rest/v1/support_attachments
Prefer: return=representation
{ "ticket_id": "<uuid>", "file_url": "<public url>", "file_name": "<originalName>", "file_type": "<extension>", "file_size": <bytes> }
→ 201 { …row… }
```

The bucket is **public-read** today (`20260730090000_client_trust_hardening.sql:62` notes closing it
requires signed URLs). No size/type limit is enforced client-side for support attachments.

**Proposed .NET:** `POST /api/v1/support/tickets/{ticketId}/attachments` (multipart `file`) → `201 Attachment`
with a backend-served URL; enforce a size cap and an allow-list of types; make the bucket private.

---

## Notes for the .NET team

1. `category` is a free-text English label from a fixed client list; `priority` is always `medium` from the client.
2. Status vocabulary the app renders: `submitted, under_review, contacted, resolved, closed, rejected`.
3. Ticket numbers are generated on the device — move to the server.
4. The office picker and the trigger share one truth: the set of listed offices.
