# Client · Communication (legacy chat threads)

A chat-style view over `operation_complaints` — a table the support system **deprecated**
(`migration_05_simplify_support.sql:113`: "DEPRECATED: Migrated to public.support_tickets"). The
screen is still reachable from the Trip Details driver card ("contact support" →
`CommunicationRoutes.communication`). Messages are appended to a JSONB array with a
compare-and-set on `updated_at`. Treat this as a **candidate for retirement**; if it is kept, it
should be re-modelled as messages on a support ticket.

## Overview

| Layer | Files (relative to `lib/apps/client/features/communication/`) |
|---|---|
| Screens | `presentation/screens/communication_screen.dart` (`CommunicationRoutes.communication`), `chat_thread_screen.dart` (`CommunicationRoutes.chatThread`, args `ChatThreadArguments`) |
| Cubits | `CommunicationCubit` (`load()`, `refresh()`), `ChatThreadCubit` (`load(conversationId)`, `send(text)`) |
| Repo | `data/repositories/communication_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_communication_datasource.dart` |
| Models / mapper | `data/models/conversation_model.dart` (`ConversationModel`, `ChatMessageModel`), `data/mappers/conversation_mapper.dart` |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| M1 | My conversations | `GET operation_complaints?client_id=eq.` | session | `GET /api/v1/me/conversations` |
| M2 | One conversation | `GET operation_complaints?id=eq.&client_id=eq.` | session | `GET /api/v1/me/conversations/{id}` |
| M3 | Send a message | read + `PATCH operation_complaints` (CAS) | session | `POST /api/v1/me/conversations/{id}/messages` |

All three throw `'You must be signed in to use support chat.'` without a session.

---

## M1 — `getConversations()` (`supabase_communication_datasource.dart:24`)

```
GET /rest/v1/operation_complaints
  ?select=id,category,status,priority,description,assigned_to,conversation,created_at,updated_at
  &client_id=eq.<uid>&order=updated_at.desc
```

Row → `ConversationModel { id, description, assignedTo, category, status, priority, updatedAt (?? created_at), messages[] }`
where `messages` = the `conversation` JSONB array, each entry parsed defensively (`ChatMessageModel.fromJson`):
`id`, text from `message|text|body`, `sender` from `sender|author_role|role`, `sender_name|author_name`,
`created_at|timestamp`, `type`, `attachment_name`, `attachment_size`, `duration`, `is_read` (default true).

`UNKNOWN`: no RLS policy for `operation_complaints` exists in `supabase/migrations/`; the table was
office-scoped in `20260721100100_report_views_office_scoping.sql` (added `office_id` + a sync trigger).
The client filter on `client_id` is the only guard visible in the repo.

---

## M2 — `getConversation(id)` (line 44)

```
GET /rest/v1/operation_complaints?select=<same>&id=eq.<id>&client_id=eq.<uid>     (.single())
```

---

## M3 — `appendClientMessage({conversationId, text})` (line 74-129)

Up to **3 compare-and-set attempts**:

```
GET   /rest/v1/operation_complaints?select=conversation,updated_at&id=eq.<id>&client_id=eq.<uid>   (.single())
PATCH /rest/v1/operation_complaints?id=eq.<id>&client_id=eq.<uid>&updated_at=eq.<previous updated_at>
Prefer: return=representation
{ "conversation": [ ...existing, { "id":"<µs epoch>", "sender":"client", "message":"<text>", "type":"text", "is_read":true, "created_at":"<UTC ISO>" } ],
  "updated_at": "<UTC ISO now>" }
→ 200 [ {id} ]  (empty array ⇒ someone else wrote in between ⇒ retry)
```

After 3 failed rounds: `'Your message could not be sent. Please try again.'`.

**Proposed .NET:** `POST /api/v1/me/conversations/{id}/messages { text }` → `201 Message` — an
append is trivially atomic in a proper messages table; the CAS dance disappears.

## Notes for the .NET team

1. `NEEDS BACKEND DECISION`: retire this surface and route the driver-card CTA to the Support Center, or model messages as `support_ticket_messages`. The unused `support_message_model.dart` in the support feature suggests the second was once planned.
2. No realtime here — the thread refreshes on pull.
