-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 7 — Client Trust Hardening
--
-- Four holes found auditing every table, view and function the Client app can
-- reach. Each was measured on the live database before this migration; the
-- measurements are quoted inline so a reader can re-run them and see the change.
--
--   1. `support_attachments` has RLS DISABLED. It carries two correct, ownership-
--      scoped policies — they have simply never been enforced, because nobody ran
--      `enable row level security`. With SELECT/INSERT/UPDATE also granted to
--      `anon`, every support attachment on the platform (file_url, file_name,
--      ticket_id) is readable by anyone holding the shipped anon key, and writable
--      by any signed-in rider onto anyone's ticket.
--
--      This is not theoretical: the Client app's own
--      `SupabaseSupportDatasource.getTicketAttachments(ticketId)` filters on
--      ticket_id alone and trusts RLS for ownership. Today it will happily return
--      another rider's attachments for any ticket id.
--
--   2. `notifications` INSERT is governed by a policy named "Service role insert
--      notifications" that is granted to `public` with `with_check (true)`, while
--      INSERT is granted to `anon` and `authenticated`. Any rider can therefore
--      write a notification addressed to any other user, with any title, body and
--      `action_url`. Since both the in-app inbox and `FcmService` navigate on
--      `action_url`, that is a phishing primitive aimed at the platform's own
--      customers. `service_role` bypasses RLS outright and never needed the policy;
--      the DB's own notification writers are all SECURITY DEFINER and likewise
--      bypass it.
--
--   3. Three legacy SECURITY DEFINER booking functions are still executable by
--      `authenticated` and insert `operation_bookings.payment_amount` straight from
--      a client-supplied parameter:
--
--        book_trip_seat(...)                    -- 16 args
--        confirm_seat_booking(...)              -- 17 args
--        confirm_seat_booking_v2(... p_receipt_url)  -- 19-arg overload
--
--      `20260710090000_authoritative_booking_pricing` made the *current* booking
--      path resolve the fare server-side and stop reading `p_payment_amount`, but
--      it created a new function rather than replacing the old ones, so the
--      price-trusting versions were left callable. A rider can POST to
--      /rest/v1/rpc/confirm_seat_booking with p_payment_amount = 1 and hold a
--      legitimate-looking booking the operator will approve for 1 EGP.
--
--      The 19-arg `confirm_seat_booking_v2` overload does resolve the fare itself,
--      but it predates `20260713090000`'s stop-id namespace fix, so it prices some
--      stop pairs wrong — and having two overloads of one name is an ambiguity trap
--      for any future caller. One booking entry point, one price authority.
--
--   4. The `documents` and `vehicle-images` storage buckets grant INSERT, UPDATE
--      and DELETE to `public`. No app in this repo uploads to either — but anyone
--      holding the anon key can overwrite or erase every vehicle photo and document
--      on the platform.
--
-- Not fixed here, deliberately, and tracked in docs/client/CLIENT_SECURITY.md:
--   • `trip_seats.passenger_id` is readable through `trip_seats_marketplace_read`.
--     Closing it means either column privileges (which break the Dashboard's
--     `trip_seats(*)` reads) or moving clients onto a view (which kills the
--     realtime signal Home subscribes to). The column is fully redundant —
--     `trip_passengers.seat_id` covers every one of the 5 populated rows — so the
--     real fix is to drop it, which is a Dashboard change, not a Client one.
--   • The `support-attachments` bucket is public-read. Closing it requires signed
--     URLs in both the Client and the Dashboard. §1 removes the ability to
--     *enumerate* the URLs, which is the practical dump vector.
-- ═══════════════════════════════════════════════════════════════════════════════════

-- ── 1. support_attachments: turn the policies on ────────────────────────────────────
--
-- Before:  select relrowsecurity from pg_class where relname = 'support_attachments';
--          -- false
--
-- The two client policies already say the right thing. Enabling RLS makes them
-- mean it. An office policy is added alongside them because the Dashboard reads
-- this table too (`SupabaseTicketsDatasource.getTicketAttachments`) and would
-- otherwise go blank — it mirrors `support_tickets_office` exactly.

alter table public.support_attachments enable row level security;

drop policy if exists support_attachments_office on public.support_attachments;
create policy support_attachments_office
  on public.support_attachments
  for all
  to authenticated
  using (
    exists (
      select 1
        from public.support_tickets t
       where t.id = support_attachments.ticket_id
         and t.office_id is not null
         and t.office_id = public.current_office_id()
    )
  )
  with check (
    exists (
      select 1
        from public.support_tickets t
       where t.id = support_attachments.ticket_id
         and t.office_id is not null
         and t.office_id = public.current_office_id()
    )
  );

-- A ticket attachment is never marketplace data. `anon` has no business here at
-- all, and leaving the grant in place would keep the table one `enable`-less
-- migration away from being wide open again.
revoke all on public.support_attachments from anon;

comment on table public.support_attachments is
  'Files a rider attached to a support ticket. RLS-scoped to the ticket owner '
  '(client) and the owning office. Never readable by anon.';

-- ── 2. notifications: only the platform may address a user ──────────────────────────
--
-- Before:  select policyname, roles, with_check from pg_policies
--            where tablename = 'notifications' and cmd = 'INSERT';
--          -- "Service role insert notifications" | {public} | true
--
-- Replaced with an office-staff / platform-admin gate. That is what the Dashboard's
-- `SupabaseNotificationsDispatchDatasource.insertForUser` runs as, and it is the
-- only client-tier writer in the codebase. Riders hold no office, so they can no
-- longer forge a notification for anyone — including themselves.
--
-- Every in-database writer (confirm_seat_booking_v2, approve_payment, the trigger
-- engine, platform_broadcast_notification) is SECURITY DEFINER and runs as the
-- table owner, so none of them are affected by this policy.

drop policy if exists "Service role insert notifications" on public.notifications;

drop policy if exists notifications_staff_insert on public.notifications;
create policy notifications_staff_insert
  on public.notifications
  for insert
  to authenticated
  with check (
    public.current_office_id() is not null
    or public.is_platform_admin()
  );

-- Duplicate SELECT/UPDATE policies accumulated across migrations: one pair granted
-- to {public}, one to {authenticated}, saying the same thing. Keep the
-- authenticated pair; drop the {public} duplicates so the readable policy set
-- matches the actual access model.
drop policy if exists "Users read own notifications"   on public.notifications;
drop policy if exists "Users update own notifications" on public.notifications;

-- anon has no inbox.
revoke all on public.notifications from anon;

comment on table public.notifications is
  'Per-user inbox. Readable/updatable only by its addressee; insertable only by '
  'office staff, platform admins, and SECURITY DEFINER backend functions.';

-- ── 3. One booking entry point, one price authority ─────────────────────────────────
--
-- Before:  select proname, pg_get_function_identity_arguments(oid)
--            from pg_proc p join pg_namespace n on n.oid = p.pronamespace
--           where n.nspname = 'public'
--             and proname in ('book_trip_seat','confirm_seat_booking',
--                             'confirm_seat_booking_v2');
--          -- 4 rows: 3 legacy + the current 22-arg confirm_seat_booking_v2
--
-- After this migration exactly one survives: the 22-arg
-- confirm_seat_booking_v2(..., p_payment_reference, p_payer_phone,
-- p_subscription_id), which ignores p_payment_amount and derives the fare from
-- trip_pricing / transport_packages itself.
--
-- Dropping rather than revoking: a revoked function is one `grant` away from being
-- live again, and these have no caller left. The Client app's only booking path is
-- `PlaceSeatBookingUseCase` → the 22-arg overload.

drop function if exists public.book_trip_seat(
  uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, date, text, text,
  numeric, text, text
);

drop function if exists public.confirm_seat_booking(
  uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, date, text, text,
  numeric, text, text, text
);

drop function if exists public.confirm_seat_booking_v2(
  uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, date, text, text,
  numeric, text, text, uuid, date, text
);

-- ── 4. Storage: read-only for the public buckets ────────────────────────────────────
--
-- `documents` and `vehicle-images` are served publicly on purpose (vehicle photos
-- render in the Client app). Being *writable* by public was not on purpose: no
-- Dart code in this repo uploads to either bucket, and anon DELETE means anyone
-- can erase the fleet's photos.

drop policy if exists documents_public_upload on storage.objects;
drop policy if exists documents_public_update on storage.objects;
drop policy if exists documents_public_delete on storage.objects;

drop policy if exists vehicle_images_public_upload on storage.objects;
drop policy if exists vehicle_images_public_update on storage.objects;
drop policy if exists vehicle_images_public_delete on storage.objects;

drop policy if exists documents_staff_write on storage.objects;
create policy documents_staff_write
  on storage.objects
  for all
  to authenticated
  using (
    bucket_id = 'documents'
    and (public.current_office_id() is not null or public.is_platform_admin())
  )
  with check (
    bucket_id = 'documents'
    and (public.current_office_id() is not null or public.is_platform_admin())
  );

drop policy if exists vehicle_images_staff_write on storage.objects;
create policy vehicle_images_staff_write
  on storage.objects
  for all
  to authenticated
  using (
    bucket_id = 'vehicle-images'
    and (public.current_office_id() is not null or public.is_platform_admin())
  )
  with check (
    bucket_id = 'vehicle-images'
    and (public.current_office_id() is not null or public.is_platform_admin())
  );
