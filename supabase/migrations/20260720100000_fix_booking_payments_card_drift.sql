-- migration_20260720100000_fix_booking_payments_card_drift.sql
--
-- Card checkout fails immediately on tapping "card": confirm_seat_booking_v2
-- inserts into booking_payments with receipt_url = null (no receipt for a
-- card leg) and method = 'credit_card'. On the live database, neither of
-- those was actually true despite the migration history claiming they were:
--
--   * receipt_url is still NOT NULL on the deployed table, so the insert
--     dies right there with "null value in column receipt_url violates
--     not-null constraint" — the exact error being reported.
--     20260704000000_production_booking_flow_hardening.sql already contains
--     `alter column receipt_url drop not null`, but the live column never
--     picked it up.
--   * booking_payments_method_check on the live database only allows
--     ('instapay', 'vodafone_cash', 'bank_transfer') — 'credit_card' was
--     never actually in the deployed constraint, even though every migration
--     that (re)defines it lists 'credit_card' first. Fixing receipt_url
--     alone would just trade one failure for this one on the very next line.
--
-- Both are re-asserted unconditionally rather than assumed, since whatever
-- caused the drift left `supabase migration list` reporting these migrations
-- as applied.

alter table public.booking_payments
  alter column receipt_url drop not null;

alter table public.booking_payments
  drop constraint if exists booking_payments_method_check;
alter table public.booking_payments
  add constraint booking_payments_method_check check (
    method in ('credit_card', 'instapay', 'vodafone_cash', 'bank_transfer')
  );
