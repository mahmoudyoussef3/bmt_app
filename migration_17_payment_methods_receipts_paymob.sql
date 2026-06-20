-- migration_17_payment_methods_receipts_paymob.sql
-- Production payment setup:
-- - metadata for manual transfer destination accounts
-- - private receipt storage bucket for client uploads
-- - active card method entry for Paymob-backed checkout

ALTER TABLE public.payment_methods
  ADD COLUMN IF NOT EXISTS metadata jsonb NOT NULL DEFAULT '{}'::jsonb;

INSERT INTO storage.buckets (id, name, public)
VALUES ('payment-receipts', 'payment-receipts', false)
ON CONFLICT (id) DO UPDATE SET public = false;

DROP POLICY IF EXISTS payment_receipts_client_read_own ON storage.objects;
CREATE POLICY payment_receipts_client_read_own
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'payment-receipts'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS payment_receipts_client_upload_own ON storage.objects;
CREATE POLICY payment_receipts_client_upload_own
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'payment-receipts'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS payment_receipts_dashboard_read ON storage.objects;
CREATE POLICY payment_receipts_dashboard_read
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'payment-receipts'
  AND (
    public.has_role('operations_manager')
    OR public.has_role('dashboard_admin')
  )
);

UPDATE public.payment_methods
SET
  title = 'InstaPay',
  subtitle = 'حوّل عبر InstaPay وارفع إيصال التحويل',
  metadata = jsonb_build_object(
    'transfer_account', 'SET_YOUR_INSTAPAY_IPA_IN_DATABASE',
    'account_holder', 'SET_ACCOUNT_HOLDER_IN_DATABASE',
    'instructions', 'حوّل نفس المبلغ بالضبط ثم ارفع صورة الإيصال الواضحة.'
  ),
  is_active = true,
  recommended = true,
  sort_order = 10
WHERE type = 'instapay';

UPDATE public.payment_methods
SET
  title = 'Mobile Wallet',
  subtitle = 'Vodafone Cash / Etisalat Cash / Orange Cash / WE Pay',
  metadata = jsonb_build_object(
    'transfer_account', 'SET_MOBILE_WALLET_NUMBER_IN_DATABASE',
    'account_holder', 'SET_ACCOUNT_HOLDER_IN_DATABASE',
    'supported_channels', jsonb_build_array(
      'Vodafone Cash',
      'Etisalat Cash',
      'Orange Cash',
      'WE Pay'
    ),
    'instructions', 'ارفع صورة الإيصال بعد التحويل من أي محفظة مدعومة.'
  ),
  is_active = true,
  recommended = false,
  sort_order = 20
WHERE type = 'vodafone_cash';

INSERT INTO public.payment_methods (
  type,
  title,
  subtitle,
  description,
  is_active,
  recommended,
  sort_order,
  metadata
)
VALUES (
  'credit_card',
  'Card',
  'Pay securely by card via Paymob',
  'Online card payment through Paymob hosted checkout.',
  true,
  false,
  5,
  jsonb_build_object(
    'gateway', 'paymob',
    'integration_id', '4923808',
    'iframe_id', '893140'
  )
)
ON CONFLICT (type) DO UPDATE
SET
  title = EXCLUDED.title,
  subtitle = EXCLUDED.subtitle,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  sort_order = EXCLUDED.sort_order,
  metadata = EXCLUDED.metadata;
