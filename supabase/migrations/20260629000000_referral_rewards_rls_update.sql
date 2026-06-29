-- Allow authenticated users to upsert the singleton referral_rewards config row.
-- The table previously only had a SELECT policy, which caused the dashboard to
-- receive PGRST116 (0 rows) when trying to save reward settings.

do $$ begin
  create policy referral_rewards_update on public.referral_rewards
    for update using (true) with check (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy referral_rewards_insert on public.referral_rewards
    for insert with check (id = 1);
exception when duplicate_object then null; end $$;
