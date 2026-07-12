-- migration_20260712100000_backfill_flat_package_tiers.sql
--
-- Root cause (Client app showed "fake" package prices): the Dashboard trip
-- planner collects ONE ticket price, and CreateTripUseCase expanded it into
-- trip_pricing by copying that single number into ALL FIVE tier columns:
--
--     one_time_price = five_days_price = ten_days_price
--                    = monthly_price   = three_months_price
--
-- So for every trip created through the planner, a monthly subscription was
-- priced identically to a single ride. The Client resolves a package to its
-- matching tier column (TripPricingResolver / confirm_seat_booking_v2), then
-- renders "regular total vs package price" — producing absurd output like
-- "2,200 EGP -> 100 EGP, save 95%", exactly the unreal pricing reported.
--
-- Verified on this database before writing: 25 of 27 trip_pricing rows were
-- flat. The 2 non-flat rows belong to the single trip an operator priced by
-- hand through the Trip Pricing tab.
--
-- The writer is fixed (CreateTripUseCase now derives tiers via
-- lib/core/pricing/package_tier_pricing.dart, and the planner exposes every
-- tier for override). This migration repairs the DATA the old writer already
-- produced, since fixing the writer does nothing for existing rows.
--
-- Pricing model — flat multiples of the ticket (NOT rides x fare). A package
-- is a subscription, deliberately much cheaper than buying each ride. These
-- multipliers reproduce the pricing the operator actually configured by hand
-- (ticket 200 -> 700 / 750 / 800 / 900) and MUST stay in lockstep with
-- PackageTierPricing in Dart:
--
--     five_days    = fare x 3.5
--     ten_days     = fare x 3.75
--     monthly      = fare x 4.0
--     three_months = fare x 4.5
--
-- Scope guard: ONLY rows that are provably flat (all five tiers equal to the
-- one-time fare) are touched. Any trip an operator genuinely priced by hand has
-- differing tiers and is left completely alone — this migration must never
-- overwrite deliberate pricing.

update public.trip_pricing
set
  five_days_price    = round(one_time_price * 3.5,  2),
  ten_days_price     = round(one_time_price * 3.75, 2),
  monthly_price      = round(one_time_price * 4.0,  2),
  three_months_price = round(one_time_price * 4.5,  2),
  updated_at         = now()
where one_time_price > 0
  and five_days_price    = one_time_price
  and ten_days_price     = one_time_price
  and monthly_price      = one_time_price
  and three_months_price = one_time_price;
