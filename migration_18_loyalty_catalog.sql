-- =============================================================================
-- Migration 18 — Loyalty Catalog + Payment Seed
-- =============================================================================
-- Fixes the "Could not find the table ... in the schema cache" (PGRST205)
-- errors on the Loyalty, Rewards, and Payment screens by provisioning the
-- catalog tables the client app reads from:
--   • loyalty_tiers     (membership tiers shown on the Loyalty screen)
--   • loyalty_rewards   (redeemable rewards on the Loyalty + Rewards screens)
--   • payment_methods   (ensured + seeded so the Payment screen renders)
--
-- Idempotent and safe to run on any environment.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Loyalty tiers
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.loyalty_tiers (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                text NOT NULL UNIQUE,
  points_required     text NOT NULL DEFAULT '0 pts',
  points_required_val int  NOT NULL DEFAULT 0,
  icon_key            text NOT NULL DEFAULT 'stars',
  gradient_colors     text[] NOT NULL DEFAULT ARRAY[]::text[],
  perks               text[] NOT NULL DEFAULT ARRAY[]::text[],
  created_at          timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.loyalty_tiers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Loyalty tiers are readable" ON public.loyalty_tiers;
CREATE POLICY "Loyalty tiers are readable"
  ON public.loyalty_tiers
  FOR SELECT
  TO anon, authenticated
  USING (true);

GRANT SELECT ON public.loyalty_tiers TO anon, authenticated;

INSERT INTO public.loyalty_tiers
  (name, points_required, points_required_val, icon_key, gradient_colors, perks)
VALUES
  (
    'Bronze', '0 pts', 0, 'workspace_premium',
    ARRAY['4291657522', '4287458915'],
    ARRAY['Earn points on every trip', 'Member-only offers']
  ),
  (
    'Silver', '1000 pts', 1000, 'star',
    ARRAY['4289773253', '4284513675'],
    ARRAY['Everything in Bronze', 'Priority customer support']
  ),
  (
    'Gold', '2000 pts', 2000, 'stars',
    ARRAY['4294956367', '4294942720'],
    ARRAY['Everything in Silver', 'Free seat selection', 'Bonus points weekends']
  ),
  (
    'Platinum', '3000 pts', 3000, 'diamond',
    ARRAY['4287679225', '4280191205'],
    ARRAY['Everything in Gold', 'Dedicated support line', 'Exclusive rewards']
  )
ON CONFLICT (name) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 2. Loyalty rewards (redeemable catalog)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.loyalty_rewards (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title       text NOT NULL,
  description text NOT NULL DEFAULT '',
  points_cost int  NOT NULL DEFAULT 0,
  value_label text NOT NULL DEFAULT '',
  category    text NOT NULL DEFAULT 'Discount',
  coupon_code text NOT NULL DEFAULT '' UNIQUE,
  is_active   boolean NOT NULL DEFAULT true,
  sort_order  int NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.loyalty_rewards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Active loyalty rewards are readable" ON public.loyalty_rewards;
CREATE POLICY "Active loyalty rewards are readable"
  ON public.loyalty_rewards
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

GRANT SELECT ON public.loyalty_rewards TO anon, authenticated;

INSERT INTO public.loyalty_rewards
  (title, description, points_cost, value_label, category, coupon_code, is_active, sort_order)
VALUES
  ('EGP 10 ride credit', 'Apply EGP 10 off your next trip.', 500, 'EGP 10', 'Discount', 'RIDE10', true, 10),
  ('20% off next booking', 'Save 20% on your next single booking.', 800, '20% Off', 'Discount', 'SAVE20', true, 20),
  ('EGP 25 ride credit', 'Apply EGP 25 off your next trip.', 1000, 'EGP 25', 'Discount', 'RIDE25', true, 30),
  ('Free short trip', 'Redeem a free short-distance trip.', 1500, '1 Free Trip', 'Free Ride', 'FREETRIP', true, 40)
ON CONFLICT (coupon_code) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 3. Payment methods (ensure table + minimum seed so the screen renders)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type        text NOT NULL UNIQUE,
  title       text NOT NULL,
  subtitle    text NOT NULL,
  description text,
  is_active   boolean NOT NULL DEFAULT true,
  recommended boolean NOT NULL DEFAULT false,
  sort_order  int NOT NULL DEFAULT 0,
  metadata    jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT payment_methods_type_check CHECK (
    type IN (
      'credit_card',
      'instapay',
      'vodafone_cash',
      'wallet_balance',
      'cash_on_boarding'
    )
  )
);

ALTER TABLE public.payment_methods
  ADD COLUMN IF NOT EXISTS metadata jsonb NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Active payment methods are readable" ON public.payment_methods;
CREATE POLICY "Active payment methods are readable"
  ON public.payment_methods
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

GRANT SELECT ON public.payment_methods TO anon, authenticated;

INSERT INTO public.payment_methods
  (type, title, subtitle, description, is_active, recommended, sort_order, metadata)
VALUES
  (
    'cash_on_boarding', 'Cash with driver', 'Pay when boarding',
    'Pay the driver in cash when you board.', true, false, 30, '{}'::jsonb
  ),
  (
    'instapay', 'InstaPay', 'Transfer and attach the receipt',
    'Transfer via InstaPay then upload your receipt for confirmation.',
    true, false, 20, '{}'::jsonb
  )
ON CONFLICT (type) DO NOTHING;
