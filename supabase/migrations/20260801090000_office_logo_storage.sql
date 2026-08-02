-- ═══════════════════════════════════════════════════════════════════════════════════
-- Office logo storage
--
-- Until now the Dashboard's office profile took the logo as a *URL typed by hand*
-- (`OfficeIdentityForm._LogoField`), because there was no bucket for office
-- branding the way `documents` exists for fleet paperwork. That pushed every
-- operator onto some third-party image host, and a card in the client
-- marketplace whose logo silently dies when that host does.
--
-- This adds the missing bucket so the owner can upload a file instead.
--
-- Shape, and why:
--
--   * **Public read.** The Client app renders office logos with a plain
--     `Image.network` (`public_offices.logo_url`), with no session and no signed
--     URL — same as `vehicle-images`. A private bucket would need signed URLs on
--     the client, the captain app and the dashboard all at once.
--
--   * **Writes are owner-only and office-scoped.** Two conditions, both required:
--     the caller's `office_role()` must be `dashboard_admin` — matching
--     `offices_operator_update`, since a support agent cannot save the profile and
--     so has no business uploading its logo — and the object's first path segment
--     must be the caller's own office id. That second half is what `documents` and
--     `vehicle-images` lack: there, any office's staff may overwrite any other
--     office's objects. Here the path *is* the tenant boundary.
--
--   * **A size and MIME ceiling on the bucket itself.** The picker limits both
--     client-side, but the app is not the only thing holding the anon key.
-- ═══════════════════════════════════════════════════════════════════════════════════

-- ── 1. The bucket ───────────────────────────────────────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'office-logos',
  'office-logos',
  true,
  2 * 1024 * 1024,
  array['image/png', 'image/jpeg', 'image/webp']
)
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ── 2. Read: public, like every other marketplace-facing asset ──────────────────────

drop policy if exists office_logos_public_read on storage.objects;
create policy office_logos_public_read
  on storage.objects
  for select
  to public
  using (bucket_id = 'office-logos');

-- ── 3. Write: the office's own owner, inside the office's own folder ────────────────
--
-- `storage.foldername(name)` splits the object path; `[1]` is the leading segment,
-- which the Dashboard writes as the office id. A platform admin is allowed through
-- for support work — the same exception `documents_staff_write` makes.

drop policy if exists office_logos_owner_write on storage.objects;
create policy office_logos_owner_write
  on storage.objects
  for all
  to authenticated
  using (
    bucket_id = 'office-logos'
    and (
      public.is_platform_admin()
      or (
        public.office_role() = 'dashboard_admin'
        and public.current_office_id() is not null
        and (storage.foldername(name))[1] = public.current_office_id()::text
      )
    )
  )
  with check (
    bucket_id = 'office-logos'
    and (
      public.is_platform_admin()
      or (
        public.office_role() = 'dashboard_admin'
        and public.current_office_id() is not null
        and (storage.foldername(name))[1] = public.current_office_id()::text
      )
    )
  );
