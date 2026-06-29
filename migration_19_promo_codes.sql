-- =============================================================================
-- Migration 19: Promo Codes
-- =============================================================================
-- Adds a promo_codes table so the client app can validate codes against real
-- data instead of relying on hardcoded values.
-- Column names match the SupabasePaymentDatasource.validatePromoCode query.
-- =============================================================================

create table if not exists public.promo_codes (
  id              uuid primary key default gen_random_uuid(),
  code            text not null unique,
  discount_amount int not null default 0 check (discount_amount >= 0),
  discount_type   text not null default 'fixed' check (discount_type in ('fixed', 'percentage')),
  max_uses        int,                 -- null = unlimited
  use_count       int not null default 0,
  expires_at      timestamptz,         -- null = never expires
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);

-- RLS: authenticated clients can read active, non-expired codes.
alter table public.promo_codes enable row level security;

create policy "clients can read active promo codes"
  on public.promo_codes for select
  to authenticated
  using (is_active = true and (expires_at is null or expires_at > now()));

-- Index for fast code lookup.
create index if not exists idx_promo_codes_code on public.promo_codes(code);
