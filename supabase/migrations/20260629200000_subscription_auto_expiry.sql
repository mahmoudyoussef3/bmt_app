-- ── Auto-expiry of overdue subscriptions ──────────────────────────────────────
-- Creates a function that marks active subscriptions as expired when their
-- end_date has passed. Called by the Flutter app on load (lazy expiry) and
-- can be scheduled via pg_cron if available.

create or replace function public.expire_overdue_subscriptions()
returns integer
language plpgsql
security definer
as $$
declare
  updated_count integer;
begin
  update public.subscriptions
     set status = 'expired',
         updated_at = now()
   where status = 'active'
     and end_date < now();

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

grant execute on function public.expire_overdue_subscriptions() to authenticated;

-- ── Schedule via pg_cron if the extension is available ────────────────────────
-- Runs every hour to expire overdue subscriptions without relying on the app.
-- Silently skipped if pg_cron is not enabled on this Supabase project.

do $$
begin
  if exists (
    select 1 from pg_extension where extname = 'pg_cron'
  ) then
    perform cron.schedule(
      'expire-overdue-subscriptions',
      '0 * * * *',
      'select public.expire_overdue_subscriptions()'
    );
  end if;
exception
  when others then null; -- pg_cron not available, lazy expiry in app handles it
end;
$$;
