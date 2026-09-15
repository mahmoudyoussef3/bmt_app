# Dashboard · Tickets (الشكاوى — support desk)

The office's support-ticket queue: tickets routed to the office (newest 1 000) with the rider's
name/phone, status changes, an internal note, "customer contacted", close, attachments, and agent
assignment. Every write is a **direct `PATCH` on `support_tickets`** under RLS — no RPCs, no triggers.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/tickets/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.tickets` = `/tickets`) |
| Cubit | `presentation/cubit/tickets_cubit.dart` — `load()`, `updateStatus()`, `saveInternalNote()`, `markContacted()`, `closeTicket()`, `assignAgent()`, `loadAttachments()` |
| Use cases | `domain/usecases/` (`GetTicketsUseCase` — also used by Home/Business Overview, `UpdateTicketStatusUseCase`, `SaveInternalNoteUseCase`, `MarkCustomerContactedUseCase`, `CloseTicketUseCase`, `GetTicketAttachmentsUseCase`, `AssignAgentUseCase`, `GetAgentsUseCase`) |
| Repo | `data/repositories/tickets_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_tickets_datasource.dart` (`SupabaseTicketsDatasource`) |
| Model / entity | `data/models/complaint_model.dart` (`SupportTicketModel`, `SupportAttachmentModel`), `domain/entities/complaint.dart` (`SupportTicket`, `TicketStatus`, `TicketPriority`) |
| Permission | `DashboardPermission.tickets` (both roles); feature key `support_tickets` |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| K1 | List tickets (newest 1 000) + agents | `GET support_tickets?select=*,clients:client_id(id,full_name,phone)&order=created_at.desc&limit=1000` ‖ `GET user_roles?select=user_id,role&role=neq.client` | `GET /api/v1/dashboard/tickets`, `GET /api/v1/dashboard/tickets/agents` |
| K2 | Set status | `PATCH support_tickets {status}` | `PATCH /api/v1/dashboard/tickets/{id}/status` |
| K3 | Internal note | `PATCH support_tickets {internal_note}` | `PATCH /api/v1/dashboard/tickets/{id}/internal-note` |
| K4 | Customer contacted | `PATCH support_tickets {customer_contacted_at:<now>, status:'contacted'}` | `POST /api/v1/dashboard/tickets/{id}/contacted` |
| K5 | Close | `PATCH support_tickets {status:'closed', closed_at:<now>}` | `POST /api/v1/dashboard/tickets/{id}/close` |
| K6 | Attachments | `GET support_attachments?ticket_id=eq.&order=created_at.asc` | `GET /api/v1/support/tickets/{id}/attachments` (shared with client) |
| K7 | Assign agent | `PATCH support_tickets {assigned_agent_id, assigned_agent_name}` | `PATCH /api/v1/dashboard/tickets/{id}/assignee` |

Every write re-selects the row with the `clients` embed (`Prefer: return=representation`, `.single()`).
No error mapping in this datasource — Postgres errors surface raw.

`RLS` `support_tickets_office` (`20260721090200_multi_office_rls.sql:503`, `FOR ALL`):
`office_id IS NOT NULL AND office_id = current_office_id()`. Platform-level tickets (`office_id NULL`)
are invisible to every office. `support_attachments_office` (`20260730090000_client_trust_hardening.sql:80`)
resolves through the ticket. Both roles can write.

---

## K1 — List: `getTickets()` (`supabase_tickets_datasource.dart:13`)

Row → `SupportTicketModel.fromJson`: `id, ticket_number, client_id, category, title, description,
priority (low|medium|high|urgent), status, assigned_agent_id, assigned_agent_name, internal_note,
customer_contacted_at, resolved_at, closed_at, sla_due_at, sla_breached, created_at, updated_at` +
`clients.{id, full_name, phone}`. Wire `status`: `submitted | underReview | contacted | resolved | closed | rejected`
(**camelCase `underReview` on the wire** — `status.name` of the Dart enum is what is written; the client
app maps both `under_review` and `underreview`). Filtering/paging is Dart-side; `capReached` at 1 000.

Agents (`getAgents()` line 127): `GET user_roles?select=user_id,role&role=neq.client&order=created_at.desc`.
`RETIRED`-ish: `user_roles` is a legacy pre-multi-office table (not tracked in migrations; office staff
live in `office_users`), so this returns platform-era rows, not the office's staff. The assignee picker
should read `get_dashboard_users()` (see `users/`). `NEEDS BACKEND DECISION`.

**Proposed .NET:** `GET /api/v1/dashboard/tickets?status=&priority=&search=&page=` and
`GET /api/v1/dashboard/tickets/agents` = the office's active staff.

---

## K2–K5, K7 — Writes (lines 28 / 45 / 59 / 76 / 107)

```
PATCH /rest/v1/support_tickets?id=eq.<id>&select=*,clients:client_id(id,full_name,phone)
{ "status": "submitted|underReview|contacted|resolved|closed|rejected" }
{ "internal_note": "…" }
{ "customer_contacted_at": "<utc iso>", "status": "contacted" }
{ "status": "closed", "closed_at": "<utc iso>" }
{ "assigned_agent_id": "<uuid>", "assigned_agent_name": "…" }
```
No transition rules; `resolved_at` is never written by the dashboard; no notification to the rider on any
change (the client app has no ticket notification either). `sla_due_at`/`sla_breached` are read but
nothing in the repo writes them.

**Proposed .NET:** the five endpoints above; add a state machine (`submitted → under_review → contacted →
resolved → closed`, `rejected` from any open state), stamp `resolved_at`, and notify the rider on
`contacted/resolved/closed`.

## K6 — Attachments (line 93)

`GET /rest/v1/support_attachments?select=*&ticket_id=eq.<id>&order=created_at.asc` →
`SupportAttachmentModel { id, ticket_id, file_url, file_name, file_type, file_size, created_at }`.
Files live in the public bucket `support-attachments` (uploaded by the client app).

## Notes for the .NET team

1. Routing of a ticket to an office is decided by the client-side create + trigger
   `sync_support_ticket_office` (documented in `../../client_api_doc/support/`). The dashboard never
   changes `office_id`.
2. Status spelling on the wire is inconsistent across apps (`underReview` vs `under_review`); pick one.
3. The agents list reads a dead table; replace with office staff.
4. Both roles may write tickets; that matches the product (support agents work the queue).
